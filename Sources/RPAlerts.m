// SPDX-License-Identifier: GPL-2.0-or-later
#import <UIKit/UIKit.h>
#import "RPAlerts.h"
#import "RPScreens.h"
@implementation RPAlerts
+ (RPAlerts *)shared{static RPAlerts *alerts;static dispatch_once_t once;dispatch_once(&once,^{alerts=[RPAlerts new];alerts.baselines=[NSMutableDictionary dictionary];});return alerts;}
- (void)start{[self stop];self.timer=[NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(poll) userInfo:nil repeats:YES];[self poll];}
- (void)stop{[self.timer invalidate];self.timer=nil;}
- (void)notify:(NSString *)message path:(NSString *)path{
 UILocalNotification *note=[UILocalNotification new];note.fireDate=[NSDate dateWithTimeIntervalSinceNow:1];note.alertBody=message;note.soundName=UILocalNotificationDefaultSoundName;note.userInfo=@{@"path":path};note.applicationIconBadgeNumber=[UIApplication sharedApplication].applicationIconBadgeNumber+1;[[UIApplication sharedApplication]scheduleLocalNotification:note];
}
- (void)check:(NSString *)route mentions:(BOOL)mentions completion:(void(^)(void))completion{
 [RPSharedClient() get:route completion:^(NSData *data,NSHTTPURLResponse *response,NSError *error){NSDictionary *page=RPParse(data);if(error||!page){completion();return;}
 NSString *key=[NSString stringWithFormat:@"%@:%@",RPSharedClient().account,route];long long previous=[self.baselines[key] longLongValue],newest=previous;NSUInteger count=0;NSDictionary *latest=nil;
 for(NSDictionary *post in page[@"posts"]){long long pid=[post[@"id"] longLongValue];newest=MAX(newest,pid);if(previous&&pid>previous&&![post[@"handle"] isEqual:RPSharedClient().account]){count++;if(!latest)latest=post;}}
 self.baselines[key]=@(newest);if(count){NSString *body=mentions?[NSString stringWithFormat:@"New notification from %@",latest[@"author"]]:count>1?[NSString stringWithFormat:@"%lu new posts on Ripple",(unsigned long)count]:[NSString stringWithFormat:@"%@: %@",latest[@"author"],[latest[@"text"] length]?latest[@"text"]:@"Photo post"];if(body.length>160)body=[body substringToIndex:160];[self notify:body path:route];}completion();
 }];
}
- (void)poll{
 if(self.busy)return;NSInteger mode=[[NSUserDefaults standardUserDefaults]integerForKey:@"RPPostAlerts"];BOOL signedIn=RPSharedClient().account.length>0;if(!mode&&!signedIn)return;self.busy=YES;
 void(^posts)(void)=^{if(mode==2||(mode==1&&signedIn))[self check:mode==1?@"/?tlmode=following":@"/" mentions:NO completion:^{self.busy=NO;}];else self.busy=NO;};
 if(signedIn)[self check:@"/?tlmode=mentions" mentions:YES completion:posts];else posts();
}
@end
