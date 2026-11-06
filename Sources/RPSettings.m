// SPDX-License-Identifier: GPL-2.0-or-later
#import "RPScreens.h"
#import "RPAlerts.h"
@implementation RPSettings
- (void)viewDidLoad{[super viewDidLoad];self.title=@"Account & Settings";}
- (void)viewWillAppear:(BOOL)animated{[super viewWillAppear:animated];[self.tableView reloadData];}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)table{return 3;}
- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section{return section==0?3:section==1?3:2;}
- (NSString *)tableView:(UITableView *)table titleForHeaderInSection:(NSInteger)section{return @[@"Ripple account",@"Post alerts",@"Application"][section];}
- (NSString *)tableView:(UITableView *)table titleForFooterInSection:(NSInteger)section{return section==1?@"Checks every minute while Ripple is open. Background alerts require a separate optional jailbreak helper. Mentions are checked automatically after sign-in.":nil;}
- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)index{
 UITableViewCell *cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
 if(index.section==0){cell.textLabel.text=index.row==0?(RPSharedClient().account.length?RPSharedClient().account:@"Sign in to Ripple"):index.row==1?@"My profile":@"Sign out";cell.detailTextLabel.text=index.row==0?@"Session stays in memory":@"";}
 if(index.section==1){cell.textLabel.text=@[@"Off",@"People I follow",@"Every public post"][index.row];cell.accessoryType=[[NSUserDefaults standardUserDefaults]integerForKey:@"RPPostAlerts"]==index.row?UITableViewCellAccessoryCheckmark:UITableViewCellAccessoryNone;}
 if(index.section==2)cell.textLabel.text=index.row==0?@"About Ripple":@"Open Ripple in Safari";return cell;
}
- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)index{
 [table deselectRowAtIndexPath:index animated:YES];RPEvent(@"settings-row");
 if(index.section==0&&index.row==0){[self.navigationController pushViewController:[RPLogin new] animated:YES];return;}
 if(index.section==0&&index.row==1){if(!RPSharedClient().account.length){[self.navigationController pushViewController:[RPLogin new] animated:YES];return;}RPFeed *profile=[RPFeed new];profile.route=[@"/" stringByAppendingString:[RPSharedClient().account stringByReplacingOccurrencesOfString:@"@" withString:@""]];profile.title=RPSharedClient().account;[self.navigationController pushViewController:profile animated:YES];}
 if(index.section==0&&index.row==2){[RPSharedClient().cookies removeAllObjects];RPSharedClient().account=@"";[[RPAlerts shared].baselines removeAllObjects];[[UIApplication sharedApplication]cancelAllLocalNotifications];[[NSNotificationCenter defaultCenter]postNotificationName:@"RippleSessionChanged" object:nil];[table reloadData];}
 if(index.section==1){if(index.row==1&&!RPSharedClient().account.length){[self.navigationController pushViewController:[RPLogin new] animated:YES];return;}[[NSUserDefaults standardUserDefaults]setInteger:index.row forKey:@"RPPostAlerts"];[[NSUserDefaults standardUserDefaults]synchronize];[[RPAlerts shared]start];[table reloadData];}
 if(index.section==2&&index.row==0)RPMessage(@"Ripple for iOS",@"Development build 0.1.3 • iOS 6+ / armv7\nNative UIKit • direct HTTPS\n\nGPL version 2 or later.\n\nForeground post alerts are available. Background helper and photo uploads are still in development.");
 if(index.section==2&&index.row==1)[[UIApplication sharedApplication]openURL:[NSURL URLWithString:@"https://ripple.tel/"]];
}
@end
