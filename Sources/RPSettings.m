// SPDX-License-Identifier: GPL-2.0-or-later
#import "RPScreens.h"
#import "RPAlerts.h"
@implementation RPSettings
- (void)viewDidLoad{[super viewDidLoad];self.title=@"Account & Settings";}
- (void)viewWillAppear:(BOOL)animated{[super viewWillAppear:animated];[self.tableView reloadData];}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)table{return 3;}
- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section{return section==0?3:section==1?3:3;}
- (NSString *)tableView:(UITableView *)table titleForHeaderInSection:(NSInteger)section{return @[@"Ripple account",@"Post alerts",@"Application"][section];}
- (NSString *)tableView:(UITableView *)table titleForFooterInSection:(NSInteger)section{return section==1?@"Checks every minute while Ripple is open. Background alerts require a separate optional jailbreak helper. Mentions are checked automatically after sign-in.":nil;}
- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)index{
 UITableViewCell *cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
 if(index.section==0){cell.textLabel.text=index.row==0?(RPSharedClient().account.length?RPSharedClient().account:@"Sign in to Ripple"):index.row==1?@"My profile":@"Sign out";cell.detailTextLabel.text=index.row==0?@"Session saved in Keychain":@"";}
 if(index.section==1){cell.textLabel.text=@[@"Off",@"People I follow",@"Every public post"][index.row];cell.accessoryType=[[NSUserDefaults standardUserDefaults]integerForKey:@"RPPostAlerts"]==index.row?UITableViewCellAccessoryCheckmark:UITableViewCellAccessoryNone;}
 if(index.section==2){if(index.row==0){cell.textLabel.text=@"Accent color";NSInteger accent=[[NSUserDefaults standardUserDefaults]integerForKey:@"RPAccentColor"];NSArray *names=RPAccentNames();cell.detailTextLabel.text=accent>=0&&accent<(NSInteger)names.count?names[accent]:names[0];UIImageView *swatch=[[UIImageView alloc]initWithFrame:CGRectMake(0,0,22,22)];swatch.backgroundColor=RPAccent();cell.accessoryView=swatch;cell.accessoryType=UITableViewCellAccessoryNone;}else cell.textLabel.text=index.row==1?@"About Ripple":@"Open Ripple in Safari";}return cell;
}
- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)index{
 [table deselectRowAtIndexPath:index animated:YES];RPEvent(@"settings-row");
 if(index.section==0&&index.row==0){[self.navigationController pushViewController:[RPLogin new] animated:YES];return;}
 if(index.section==0&&index.row==1){if(!RPSharedClient().account.length){[self.navigationController pushViewController:[RPLogin new] animated:YES];return;}RPFeed *profile=[RPFeed new];profile.route=[@"/~" stringByAppendingString:[RPSharedClient().account stringByReplacingOccurrencesOfString:@"@" withString:@""]];profile.title=RPSharedClient().account;[self.navigationController pushViewController:profile animated:YES];}
 if(index.section==0&&index.row==2){if(![RPSharedClient()clearSession]){RPMessage(@"Could not sign out",RPSharedClient().sessionError.localizedDescription);return;}[[RPAlerts shared].baselines removeAllObjects];[[UIApplication sharedApplication]cancelAllLocalNotifications];[[NSNotificationCenter defaultCenter]postNotificationName:@"RippleSessionChanged" object:nil];[table reloadData];}
 if(index.section==1){if(index.row==1&&!RPSharedClient().account.length){[self.navigationController pushViewController:[RPLogin new] animated:YES];return;}[[NSUserDefaults standardUserDefaults]setInteger:index.row forKey:@"RPPostAlerts"];[[NSUserDefaults standardUserDefaults]synchronize];[[RPAlerts shared]start];[table reloadData];}
 if(index.section==2&&index.row==0){UIActionSheet *sheet=[[UIActionSheet alloc]initWithTitle:@"Choose an accent" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:nil];sheet.tag=26;for(NSString *name in RPAccentNames())[sheet addButtonWithTitle:name];[sheet showFromTabBar:self.tabBarController.tabBar];}
 if(index.section==2&&index.row==1)RPMessage(@"Ripple for iOS",@"Development build 0.1.9 • iOS 6+ / armv7\nNative UIKit • direct HTTPS\n\nGPL version 2 or later.\n\nProfile pages, saved sign-in, accent colors, and foreground post alerts are available. Background helper and photo uploads are still in development.");
 if(index.section==2&&index.row==2)[[UIApplication sharedApplication]openURL:[NSURL URLWithString:@"https://ripple.tel/"]];
}
- (void)actionSheet:(UIActionSheet *)sheet clickedButtonAtIndex:(NSInteger)button{if(sheet.tag!=26||button<0)return;NSArray *names=RPAccentNames();NSString *selected=[sheet buttonTitleAtIndex:button];NSUInteger accent=[names indexOfObject:selected];if(accent==NSNotFound)return;[[NSUserDefaults standardUserDefaults]setInteger:(NSInteger)accent forKey:@"RPAccentColor"];[[NSUserDefaults standardUserDefaults]synchronize];[[NSNotificationCenter defaultCenter]postNotificationName:@"RippleAccentChanged" object:nil];[self.tableView reloadData];}
@end
