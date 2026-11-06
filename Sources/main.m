// SPDX-License-Identifier: GPL-2.0-or-later
#import <UIKit/UIKit.h>
#import "RPScreens.h"
#import "RPAlerts.h"
#ifdef RIPPLE_DEVICE_TEST
#import <QuartzCore/QuartzCore.h>
#endif
RPClient *RPSharedClient(void){static RPClient *client;static dispatch_once_t once;dispatch_once(&once,^{client=[RPClient new];});return client;}
UIColor *RPAccent(void){return [UIColor colorWithRed:210/255.0 green:4/255.0 blue:4/255.0 alpha:1];}
void RPMessage(NSString *title,NSString *text){[[[UIAlertView alloc]initWithTitle:title message:text delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]show];}
void RPEvent(NSString *event){
 NSArray *paths=NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES);if(!paths.count)return;NSString *dir=paths[0];NSDictionary *state=@{@"version":@"0.1.3",@"os":[UIDevice currentDevice].systemVersion,@"event":event,@"signedIn":@(RPSharedClient().account.length>0),@"time":@([[NSDate date]timeIntervalSince1970])};NSData *json=[NSJSONSerialization dataWithJSONObject:state options:0 error:NULL];[json writeToFile:[dir stringByAppendingPathComponent:@"Ripple-state.json"] atomically:YES];
#ifdef RIPPLE_DEVICE_TEST
 dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC),dispatch_get_main_queue(),^{UIWindow *w=[UIApplication sharedApplication].keyWindow;if(!w)return;UIGraphicsBeginImageContextWithOptions(w.bounds.size,NO,[UIScreen mainScreen].scale);[w.layer renderInContext:UIGraphicsGetCurrentContext()];UIImage *image=UIGraphicsGetImageFromCurrentImageContext();UIGraphicsEndImageContext();[UIImagePNGRepresentation(image)writeToFile:[dir stringByAppendingPathComponent:@"Ripple-preview.png"] atomically:YES];});
#endif
}
@interface RPApp : UIResponder <UIApplicationDelegate>
@property(nonatomic,strong) UIWindow *window;
@property(nonatomic,strong) UITabBarController *tabs;
@end
@implementation RPApp
- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)options{
 self.window=[[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];NSMutableArray *controllers=[NSMutableArray array];
 NSArray *titles=@[@"Timeline",@"Notifications",@"People",@"Account"];
 for(NSUInteger i=0;i<4;i++){UIViewController *root;if(i==3)root=[[RPSettings alloc]initWithStyle:UITableViewStyleGrouped];else{RPFeed *feed=[RPFeed new];feed.route=@[@"/",@"/?tlmode=mentions",@"/users"][i];root=feed;}root.title=titles[i];UINavigationController *nav=[[UINavigationController alloc]initWithRootViewController:root];nav.navigationBar.tintColor=RPAccent();nav.tabBarItem=[[UITabBarItem alloc]initWithTitle:titles[i] image:[UIImage imageNamed:@[@"Timeline.png",@"Notifications.png",@"People.png",@"Account.png"][i]] tag:i];[controllers addObject:nav];}
 self.tabs=[UITabBarController new];self.tabs.viewControllers=controllers;self.tabs.tabBar.selectedImageTintColor=RPAccent();self.window.rootViewController=self.tabs;[self.window makeKeyAndVisible];RPEvent(@"launched");return YES;
}
- (void)applicationDidBecomeActive:(UIApplication *)application{[[RPAlerts shared]start];}
- (void)applicationDidEnterBackground:(UIApplication *)application{[[RPAlerts shared]stop];}
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)source annotation:(id)annotation{
 NSString *host=url.host;UINavigationController *nav=self.tabs.viewControllers[0];self.tabs.selectedIndex=0;[nav popToRootViewControllerAnimated:NO];
 if([host isEqual:@"login"]){[nav pushViewController:[RPLogin new] animated:NO];RPEvent(@"login-open");}
 else if([host isEqual:@"account"]){self.tabs.selectedIndex=3;RPEvent(@"account-open");}
 else if([host isEqual:@"notifications"]){self.tabs.selectedIndex=1;RPEvent(@"notifications-open");}
 else if([host isEqual:@"thread"]){RPFeed *f=[RPFeed new];f.route=[@"/status" stringByAppendingString:url.path];f.title=@"Conversation";[nav pushViewController:f animated:NO];}
 else {RPFeed *feed=(RPFeed *)nav.viewControllers[0];[feed refresh];}return YES;
}
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)note{
 UIView *banner=[[UIView alloc]initWithFrame:CGRectMake(0,64,self.window.bounds.size.width,54)];banner.backgroundColor=[UIColor colorWithRed:.15 green:.15 blue:.15 alpha:.96];UILabel *label=[[UILabel alloc]initWithFrame:CGRectInset(banner.bounds,10,5)];label.numberOfLines=2;label.font=[UIFont systemFontOfSize:13];label.textColor=[UIColor whiteColor];label.backgroundColor=[UIColor clearColor];label.text=note.alertBody;[banner addSubview:label];[self.window addSubview:banner];dispatch_after(dispatch_time(DISPATCH_TIME_NOW,4*NSEC_PER_SEC),dispatch_get_main_queue(),^{[banner removeFromSuperview];});RPEvent(@"local-alert");
}
@end
int main(int argc,char **argv){@autoreleasepool{return UIApplicationMain(argc,argv,nil,NSStringFromClass([RPApp class]));}}
