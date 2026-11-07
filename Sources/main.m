// SPDX-License-Identifier: GPL-2.0-or-later
#import <UIKit/UIKit.h>
#import "RPScreens.h"
#import "RPAlerts.h"
#ifdef RIPPLE_DEVICE_TEST
#import <QuartzCore/QuartzCore.h>
#endif
RPClient *RPSharedClient(void){static RPClient *client;static dispatch_once_t once;dispatch_once(&once,^{client=[RPClient new];[client restoreSavedSession:@"tel.ripple.native.ios6.session"];});return client;}
NSArray *RPAccentNames(void){return @[@"Ripple Red",@"Breeze Orange",@"Leaf Green",@"Rose Pink",@"Nord Blue",@"Amethyst",@"Graphite"] ;}
UIColor *RPAccent(void){NSArray *colors=@[[UIColor colorWithRed:210/255.0 green:4/255.0 blue:4/255.0 alpha:1],[UIColor colorWithRed:0.96 green:0.54 blue:0.16 alpha:1],[UIColor colorWithRed:0.20 green:0.62 blue:0.42 alpha:1],[UIColor colorWithRed:0.86 green:0.39 blue:0.55 alpha:1],[UIColor colorWithRed:0.34 green:0.56 blue:0.76 alpha:1],[UIColor colorWithRed:0.49 green:0.36 blue:0.72 alpha:1],[UIColor colorWithRed:0.28 green:0.31 blue:0.36 alpha:1]];NSInteger index=[[NSUserDefaults standardUserDefaults]integerForKey:@"RPAccentColor"];return index>=0&&index<(NSInteger)colors.count?colors[index]:colors[0];}
void RPMessage(NSString *title,NSString *text){[[[UIAlertView alloc]initWithTitle:title message:text delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]show];}
void RPEvent(NSString *event){
 NSArray *paths=NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES);if(!paths.count)return;NSString *dir=paths[0];NSDictionary *state=@{@"version":@"0.1.10",@"os":[UIDevice currentDevice].systemVersion,@"event":event,@"signedIn":@(RPSharedClient().account.length>0),@"time":@([[NSDate date]timeIntervalSince1970]),@"requests":RPSharedClient().requestSummary?:@[]};NSData *json=[NSJSONSerialization dataWithJSONObject:state options:0 error:NULL];[json writeToFile:[dir stringByAppendingPathComponent:@"Ripple-state.json"] atomically:YES];
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
 for(NSUInteger i=0;i<4;i++){UIViewController *root;if(i==3)root=[[RPSettings alloc]initWithStyle:UITableViewStyleGrouped];else{RPFeed *feed=[RPFeed new];feed.route=@[@"/",@"/?tlmode=mentions",@"/users"][i];root=feed;}root.title=titles[i];UINavigationController *nav=[[UINavigationController alloc]initWithRootViewController:root];nav.navigationBar.tintColor=[UIColor colorWithRed:0.12 green:0.14 blue:0.16 alpha:1];nav.navigationBar.titleTextAttributes=@{UITextAttributeTextColor:[UIColor whiteColor],UITextAttributeTextShadowOffset:[NSValue valueWithUIOffset:UIOffsetZero]};nav.tabBarItem=[[UITabBarItem alloc]initWithTitle:titles[i] image:[UIImage imageNamed:@[@"Timeline.png",@"Notifications.png",@"People.png",@"Account.png"][i]] tag:i];[controllers addObject:nav];}
 self.tabs=[UITabBarController new];self.tabs.viewControllers=controllers;self.tabs.tabBar.tintColor=[UIColor colorWithRed:0.12 green:0.14 blue:0.16 alpha:1];self.tabs.tabBar.selectedImageTintColor=RPAccent();self.window.rootViewController=self.tabs;[self.window makeKeyAndVisible];[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(accentChanged) name:@"RippleAccentChanged" object:nil];RPEvent(@"launched");if(RPSharedClient().sessionError)dispatch_async(dispatch_get_main_queue(),^{RPMessage(@"Saved sign-in",RPSharedClient().sessionError.localizedDescription);});return YES;
}
- (void)accentChanged{self.tabs.tabBar.selectedImageTintColor=RPAccent();for(UINavigationController *nav in self.tabs.viewControllers){UIViewController *screen=nav.topViewController;if([screen isKindOfClass:[RPFeed class]])[(RPFeed *)screen applyAccent];}}
- (void)applicationDidBecomeActive:(UIApplication *)application{[[RPAlerts shared]start];}
- (void)applicationDidEnterBackground:(UIApplication *)application{[[RPAlerts shared]stop];}
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)source annotation:(id)annotation{
 NSString *host=url.host;UINavigationController *nav=self.tabs.viewControllers[0];self.tabs.selectedIndex=0;[nav popToRootViewControllerAnimated:NO];
 if([host isEqual:@"login"]){[nav pushViewController:[RPLogin new] animated:NO];RPEvent(@"login-open");}
 else if([host isEqual:@"account"]){self.tabs.selectedIndex=3;RPEvent(@"account-open");}
 else if([host isEqual:@"notifications"]){self.tabs.selectedIndex=1;RPEvent(@"notifications-open");}
 else if([host isEqual:@"profile"]){NSString *path=url.path.length?url.path:@"/";if(![path hasPrefix:@"/~"])path=[@"/~" stringByAppendingString:[path stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]]];RPFeed *profile=[RPFeed new];profile.route=path;[nav pushViewController:profile animated:NO];RPEvent(@"profile-open");}
 else if([host isEqual:@"thread"]){RPFeed *f=[RPFeed new];f.route=[@"/status" stringByAppendingString:url.path];f.title=@"Conversation";[nav pushViewController:f animated:NO];}
 else {RPFeed *feed=(RPFeed *)nav.viewControllers[0];[feed refresh];}return YES;
}
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)note{
 UIView *banner=[[UIView alloc]initWithFrame:CGRectMake(0,64,self.window.bounds.size.width,54)];banner.backgroundColor=[UIColor colorWithRed:.15 green:.15 blue:.15 alpha:.96];UILabel *label=[[UILabel alloc]initWithFrame:CGRectInset(banner.bounds,10,5)];label.numberOfLines=2;label.font=[UIFont systemFontOfSize:13];label.textColor=[UIColor whiteColor];label.backgroundColor=[UIColor clearColor];label.text=note.alertBody;[banner addSubview:label];[self.window addSubview:banner];dispatch_after(dispatch_time(DISPATCH_TIME_NOW,4*NSEC_PER_SEC),dispatch_get_main_queue(),^{[banner removeFromSuperview];});RPEvent(@"local-alert");
}
@end
int main(int argc,char **argv){@autoreleasepool{return UIApplicationMain(argc,argv,nil,NSStringFromClass([RPApp class]));}}
