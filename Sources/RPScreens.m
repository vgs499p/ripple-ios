// SPDX-License-Identifier: GPL-2.0-or-later
#import "RPScreens.h"
#import "RPPostCell.h"
#import "RPImages.h"
@implementation RPLogin
- (void)loadView{
 self.title=@"Sign in";self.view=[[UIView alloc]initWithFrame:[UIScreen mainScreen].applicationFrame];self.view.backgroundColor=[UIColor colorWithWhite:.94 alpha:1];CGFloat w=self.view.bounds.size.width;
 self.username=[[UITextField alloc]initWithFrame:CGRectMake(16,24,w-32,44)];self.username.placeholder=@"Username";self.username.borderStyle=UITextBorderStyleRoundedRect;self.username.autocapitalizationType=UITextAutocapitalizationTypeNone;self.username.autocorrectionType=UITextAutocorrectionTypeNo;self.username.returnKeyType=UIReturnKeyNext;self.username.delegate=self;[self.view addSubview:self.username];
 self.password=[[UITextField alloc]initWithFrame:CGRectMake(16,80,w-32,44)];self.password.placeholder=@"Password";self.password.secureTextEntry=YES;self.password.borderStyle=UITextBorderStyleRoundedRect;self.password.returnKeyType=UIReturnKeyGo;self.password.delegate=self;[self.view addSubview:self.password];
 UIButton *button=[UIButton buttonWithType:UIButtonTypeRoundedRect];self.signInButton=button;button.frame=CGRectMake(16,140,w-32,44);[button setTitle:@"Sign in to Ripple" forState:UIControlStateNormal];[button setTitleColor:RPAccent() forState:UIControlStateNormal];[button addTarget:self action:@selector(signIn) forControlEvents:UIControlEventTouchUpInside];[self.view addSubview:button];
 self.status=[[UILabel alloc]initWithFrame:CGRectMake(16,196,w-32,100)];self.status.numberOfLines=0;self.status.font=[UIFont systemFontOfSize:14];self.status.textColor=[UIColor darkGrayColor];self.status.backgroundColor=[UIColor clearColor];self.status.text=@"Your password and session cookies stay in memory. They are sent only to Ripple over HTTPS.";[self.view addSubview:self.status];
}
- (void)viewDidLoad{[super viewDidLoad];[self checkLoginWithUsername:nil password:nil];}
- (BOOL)textFieldShouldReturn:(UITextField *)field{if(field==self.username)[self.password becomeFirstResponder];else [self signIn];return YES;}
- (void)completeSignIn:(NSString *)account{
 self.password.text=@"";RPSharedClient().account=account;RPEvent(@"login-confirmed");[[NSNotificationCenter defaultCenter]postNotificationName:@"RippleSessionChanged" object:nil];[self.navigationController popViewControllerAnimated:YES];
}
- (void)setLoginBusy:(BOOL)busy{self.signingIn=busy;self.signInButton.enabled=!busy;self.username.enabled=!busy;self.password.enabled=!busy;}
- (void)checkLoginWithUsername:(NSString *)name password:(NSString *)password{
 [self setLoginBusy:YES];BOOL submitting=name.length>0;self.status.text=submitting?@"Signing in…":@"Checking Ripple’s secure sign-in page…";
 [RPSharedClient() get:@"/login" completion:^(NSData *d,NSHTTPURLResponse *r,NSError *error){
  if(error){[self setLoginBusy:NO];self.status.text=error.localizedDescription;RPEvent(@"login-load-failed");return;}
  NSDictionary *page=RPParse(d);NSString *account=page[@"account"];
  if(account.length){[self setLoginBusy:NO];[self completeSignIn:account];return;}
  NSDictionary *form=RPParseLoginForm(d,r.URL);
  if(!form){[self setLoginBusy:NO];self.status.text=@"Ripple did not return a supported sign-in page. Tap Sign in to retry.";RPEvent([NSString stringWithFormat:@"login-form-missing:HTTP%ld",(long)r.statusCode]);return;}
  RPEvent(@"login-form-ready");
  if(!submitting){[self setLoginBusy:NO];self.status.text=@"Ready to sign in. Your password and session stay in memory and go only to Ripple over HTTPS.";return;}
  NSMutableDictionary *fields=[form[@"hidden"] mutableCopy];fields[@"username"]=name;fields[@"password"]=password;
  [RPSharedClient() post:form[@"action"] fields:fields completion:^(NSData *data,NSHTTPURLResponse *response,NSError *failure){
   NSDictionary *submitted=RPLoginPageSummary(data,response.URL);
   self.password.text=@"";if(failure){[self setLoginBusy:NO];self.status.text=failure.localizedDescription;return;}
   [RPSharedClient() get:@"/" completion:^(NSData *fresh,NSHTTPURLResponse *res,NSError *refreshError){
    [self setLoginBusy:NO];NSDictionary *confirmed=RPParse(fresh);NSDictionary *verification=RPLoginPageSummary(fresh,res.URL);NSString *signedIn=confirmed[@"account"];BOOL authenticated=[verification[@"composer"]boolValue]&&[verification[@"logoutLink"]boolValue]&&![verification[@"loginForm"]boolValue];
    if(!refreshError&&authenticated)[self completeSignIn:signedIn.length?signedIn:[@"@" stringByAppendingString:name]];else {self.status.text=refreshError.localizedDescription?:@"Sign-in was not confirmed. Check your username and password, then try again.";RPEvent(@"login-not-confirmed");NSMutableDictionary *diagnostic=[NSMutableDictionary dictionary];diagnostic[@"post"]=submitted;diagnostic[@"verify"]=verification;diagnostic[@"requests"]=RPSharedClient().requestSummary;NSString *dir=NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES)[0];[[NSJSONSerialization dataWithJSONObject:diagnostic options:0 error:NULL]writeToFile:[dir stringByAppendingPathComponent:@"Ripple-login-check.json"] atomically:YES];if([submitted[@"message"]length])self.status.text=submitted[@"message"];}
   }];
  }];
 }];
}
- (void)signIn{
 if(self.signingIn)return;RPEvent(@"login-submit");NSString *name=[self.username.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]],*password=[self.password.text copy];if(!name.length||!password.length){self.status.text=@"Enter your username and password.";return;}[self.view endEditing:YES];[self checkLoginWithUsername:name password:password];
}
@end
@implementation RPCompose
- (void)loadView{
 self.title=self.quoteID?@"Quote post":[self.route hasPrefix:@"/status/"]?@"Reply":@"New post";self.view=[[UIView alloc]initWithFrame:[UIScreen mainScreen].applicationFrame];self.view.backgroundColor=[UIColor whiteColor];self.editor=[[UITextView alloc]initWithFrame:CGRectMake(8,8,self.view.bounds.size.width-16,156)];self.editor.font=[UIFont systemFontOfSize:17];self.editor.delegate=self;self.editor.autoresizingMask=UIViewAutoresizingFlexibleWidth;[self.view addSubview:self.editor];
 self.counter=[[UILabel alloc]initWithFrame:CGRectMake(16,170,280,34)];self.counter.text=@"256 characters left";self.counter.font=[UIFont systemFontOfSize:13];self.counter.textColor=[UIColor grayColor];[self.view addSubview:self.counter];self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc]initWithTitle:@"Post" style:UIBarButtonItemStyleDone target:self action:@selector(publish)];self.navigationItem.rightBarButtonItem.enabled=NO;
}
- (void)viewDidAppear:(BOOL)animated{[super viewDidAppear:animated];[self.editor becomeFirstResponder];}
- (void)textViewDidChange:(UITextView *)view{NSInteger left=256-(NSInteger)view.text.length;self.counter.text=[NSString stringWithFormat:@"%ld characters left",(long)left];self.navigationItem.rightBarButtonItem.enabled=left>=0&&left<256;}
- (void)publish{
 RPEvent(@"publish-submit");NSString *draft=[self.editor.text copy];self.navigationItem.rightBarButtonItem.enabled=NO;self.counter.text=@"Publishing…";
 [RPSharedClient() get:self.route?:@"/" completion:^(NSData *data,NSHTTPURLResponse *res,NSError *error){NSDictionary *form=RPParse(data)[@"forms"][self.quoteID?@"quote":@"composer"];if(error||!form){self.counter.text=@"Not sent";RPMessage(@"Not posted",error.localizedDescription?:@"No supported post form. Check your sign-in.");[self textViewDidChange:self.editor];return;}
 NSMutableDictionary *fields=[form[@"hidden"] mutableCopy];fields[form[@"field"]]=draft;if(self.quoteID)fields[@"qid"]=self.quoteID;
 [RPSharedClient() post:form[@"action"] fields:fields completion:^(NSData *d,NSHTTPURLResponse *r,NSError *failure){if(failure){RPMessage(@"Check Ripple before retrying",failure.localizedDescription);[self textViewDidChange:self.editor];return;}
 NSDictionary *page=RPParse(d);BOOL found=NO;for(NSDictionary *p in page[@"posts"])if([p[@"text"] isEqual:draft])found=YES;
 if(!found){RPMessage(@"Post submitted",@"Check your timeline before trying again. The response did not confirm the new post.");[self textViewDidChange:self.editor];return;}
 [[NSNotificationCenter defaultCenter]postNotificationName:@"RipplePostPublished" object:nil];[self.navigationController popViewControllerAnimated:YES];
 }];}];
}
@end
@implementation RPPhoto
- (void)loadView{self.title=@"Photo";UIImageView *image=[[UIImageView alloc]initWithFrame:[UIScreen mainScreen].applicationFrame];image.backgroundColor=[UIColor blackColor];image.contentMode=UIViewContentModeScaleAspectFit;self.view=image;[[RPImages shared]load:self.url size:1024 completion:^(UIImage *photo){image.image=photo;if(!photo)RPMessage(@"Photo unavailable",@"The image could not be loaded within the memory/response limit.");}];}
@end
@implementation RPFeed
- (void)viewDidLoad{
 [super viewDidLoad];self.route=self.route?:@"/";self.number=1;self.posts=[NSMutableArray array];self.directory=[self.route hasPrefix:@"/users"];self.tableView.separatorColor=[UIColor colorWithWhite:.88 alpha:1];
 self.navigationItem.rightBarButtonItems=@[[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh)],[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(compose)]];
 if([self.route isEqual:@"/"]){self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(search)];UISegmentedControl *tabs=[[UISegmentedControl alloc]initWithItems:@[@"Public",@"Following"]];tabs.frame=CGRectMake(8,8,304,30);tabs.segmentedControlStyle=UISegmentedControlStyleBar;tabs.tintColor=RPAccent();tabs.selectedSegmentIndex=0;[tabs addTarget:self action:@selector(tab:) forControlEvents:UIControlEventValueChanged];UIView *header=[[UIView alloc]initWithFrame:CGRectMake(0,0,320,46)];[header addSubview:tabs];self.tableView.tableHeaderView=header;}
 UIView *footer=[[UIView alloc]initWithFrame:CGRectMake(0,0,320,64)];self.newer=[UIButton buttonWithType:UIButtonTypeRoundedRect];self.newer.frame=CGRectMake(8,12,82,34);[self.newer setTitle:@"Newer" forState:UIControlStateNormal];[self.newer addTarget:self action:@selector(previous) forControlEvents:UIControlEventTouchUpInside];[footer addSubview:self.newer];self.status=[[UILabel alloc]initWithFrame:CGRectMake(90,12,140,34)];self.status.backgroundColor=[UIColor clearColor];self.status.font=[UIFont systemFontOfSize:13];self.status.textAlignment=NSTextAlignmentCenter;[footer addSubview:self.status];self.older=[UIButton buttonWithType:UIButtonTypeRoundedRect];self.older.frame=CGRectMake(230,12,82,34);[self.older setTitle:@"Older" forState:UIControlStateNormal];[self.older addTarget:self action:@selector(next) forControlEvents:UIControlEventTouchUpInside];[footer addSubview:self.older];self.tableView.tableFooterView=footer;
 [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(refresh) name:@"RippleSessionChanged" object:nil];[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(refresh) name:@"RipplePostPublished" object:nil];[self load:1];
}
- (void)dealloc{[[NSNotificationCenter defaultCenter]removeObserver:self];}
- (void)tab:(UISegmentedControl *)tabs{RPEvent(@"timeline-tab");if(tabs.selectedSegmentIndex==1&&!RPSharedClient().account.length){tabs.selectedSegmentIndex=0;[self.navigationController pushViewController:[RPLogin new] animated:YES];return;}self.route=tabs.selectedSegmentIndex?@"/?tlmode=following":@"/";[self load:1];}
- (void)load:(NSInteger)number{
 if(self.loading)return;RPEvent(@"feed-load");self.loading=YES;self.status.text=@"Loading…";self.newer.enabled=NO;self.older.enabled=NO;
 NSString *path=number>1?[self.route stringByAppendingFormat:@"%cpageno=%ld",[self.route rangeOfString:@"?"].location==NSNotFound?'?':'&',(long)number]:self.route;
 [RPSharedClient() get:path completion:^(NSData *data,NSHTTPURLResponse *r,NSError *error){self.loading=NO;NSDictionary *page=RPParse(data);
  if(error||!page)RPMessage(@"Could not load Ripple",error.localizedDescription?:@"Ripple returned an unsupported page.");else{self.page=page;self.posts=[page[@"posts"] mutableCopy];self.people=page[@"people"];self.number=number;if([page[@"account"] length])RPSharedClient().account=page[@"account"];[self.tableView reloadData];[self.tableView setContentOffset:CGPointZero animated:NO];}
  self.status.text=[NSString stringWithFormat:@"Page %ld",(long)self.number];self.newer.enabled=self.number>1;self.older.enabled=[self.page[@"older"] boolValue];RPEvent([NSString stringWithFormat:@"loaded:%lu:HTTP%ld",(unsigned long)self.posts.count,(long)r.statusCode]);
 }];
}
- (void)refresh{[self load:self.number];}
- (void)previous{if(self.number>1)[self load:self.number-1];}
- (void)next{if([self.page[@"older"] boolValue])[self load:self.number+1];}
- (void)compose{RPEvent(@"compose-open");if(!RPSharedClient().account.length){[self.navigationController pushViewController:[RPLogin new] animated:YES];return;}RPCompose *c=[RPCompose new];c.route=self.route;[self.navigationController pushViewController:c animated:YES];}
- (void)search{RPEvent(@"search-open");UIAlertView *a=[[UIAlertView alloc]initWithTitle:@"Search Ripple" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Search",nil];a.alertViewStyle=UIAlertViewStylePlainTextInput;[a show];}
- (void)alertView:(UIAlertView *)a clickedButtonAtIndex:(NSInteger)index{if(index!=1)return;NSString *q=[a textFieldAtIndex:0].text;if(!q.length)return;RPFeed *f=[RPFeed new];f.route=[@"/results?q=" stringByAppendingString:[RPClient encode:q]];f.title=@"Search";[self.navigationController pushViewController:f animated:YES];}
- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section{return self.directory?self.people.count:MAX((NSUInteger)1,self.posts.count);}
- (CGFloat)tableView:(UITableView *)table heightForRowAtIndexPath:(NSIndexPath *)index{return self.directory?64:!self.posts.count?100:[RPPostCell height:self.posts[index.row] width:table.bounds.size.width];}
- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)index{
 if(self.directory){UITableViewCell *c=[table dequeueReusableCellWithIdentifier:@"person"];if(!c)c=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"person"];NSDictionary *p=self.people[index.row];c.textLabel.text=p[@"name"];c.detailTextLabel.text=[@"@" stringByAppendingString:p[@"handle"]];c.accessoryType=UITableViewCellAccessoryDisclosureIndicator;return c;}
 if(!self.posts.count){UITableViewCell *c=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];c.selectionStyle=UITableViewCellSelectionStyleNone;c.textLabel.text=self.loading?@"Loading Ripple…":[self.route rangeOfString:@"mentions"].location!=NSNotFound?@"No notifications yet":@"No posts found";c.detailTextLabel.text=RPSharedClient().account.length?@"Pull up the refresh button to check again.":@"Sign in from Account to use your personal feeds.";c.detailTextLabel.numberOfLines=0;return c;}
 RPPostCell *cell=(RPPostCell *)[table dequeueReusableCellWithIdentifier:@"post"];if(!cell)cell=[[RPPostCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"post"];[cell configure:self.posts[index.row] feed:self];return cell;
}
- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)index{if(self.directory){NSDictionary *person=self.people[index.row];RPFeed *profile=[RPFeed new];profile.route=[@"/" stringByAppendingString:person[@"handle"]];profile.title=person[@"name"];[self.navigationController pushViewController:profile animated:YES];}}
- (void)postAction:(NSString *)action post:(NSDictionary *)post{
 RPEvent([@"post-" stringByAppendingString:action]);
 if([action isEqual:@"photo"]){RPPhoto *photo=[RPPhoto new];photo.url=post[@"images"][0];[self.navigationController pushViewController:photo animated:YES];return;}
 if([action isEqual:@"more"]){self.selectedID=post[@"id"];UIActionSheet *menu=[[UIActionSheet alloc]initWithTitle:post[@"handle"] delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"View conversation",@"View profile",@"Quote post",nil];[menu showFromTabBar:self.tabBarController.tabBar];return;}
 if(!RPSharedClient().account.length){[self.navigationController pushViewController:[RPLogin new] animated:YES];return;}
 if([action isEqual:@"reply"]){RPCompose *c=[RPCompose new];c.route=[@"/status/" stringByAppendingString:post[@"id"]];[self.navigationController pushViewController:c animated:YES];return;}
 NSString *url=post[@"actions"][action];if(!url.length){RPMessage(@"Action unavailable",@"Ripple did not provide this action link. Refresh this page.");return;}
 [RPSharedClient() get:url completion:^(NSData *data,NSHTTPURLResponse *response,NSError *error){if(error){RPMessage(@"Could not confirm action",error.localizedDescription);return;}NSString *route=[@"/status/" stringByAppendingString:post[@"id"]];[RPSharedClient() get:route completion:^(NSData *d,NSHTTPURLResponse *r,NSError *failure){NSDictionary *fresh=RPParse(d);for(NSDictionary *update in fresh[@"posts"])if([update[@"id"] isEqual:post[@"id"]]){NSUInteger index=[self.posts indexOfObject:post];if(index==NSNotFound)break;NSMutableDictionary *merged=[post mutableCopy];for(NSString *key in @[@"likes",@"reposts",@"actions"])merged[key]=update[key];self.posts[index]=merged;CGPoint offset=self.tableView.contentOffset;[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationNone];[self.tableView setContentOffset:offset animated:NO];break;}if(failure)RPMessage(@"Action sent",@"Refresh to check the count before retrying.");}];}];
}
- (void)actionSheet:(UIActionSheet *)sheet clickedButtonAtIndex:(NSInteger)button{
 if(button==sheet.cancelButtonIndex)return;NSDictionary *post=nil;for(NSDictionary *p in self.posts)if([p[@"id"] isEqual:self.selectedID])post=p;if(!post)return;
 if(button==0){RPFeed *f=[RPFeed new];f.route=[@"/status/" stringByAppendingString:post[@"id"]];f.title=@"Conversation";[self.navigationController pushViewController:f animated:YES];}
 if(button==1){RPFeed *f=[RPFeed new];f.route=[@"/" stringByAppendingString:[post[@"handle"] stringByReplacingOccurrencesOfString:@"@" withString:@""]];f.title=post[@"author"];[self.navigationController pushViewController:f animated:YES];}
 if(button==2){if(!RPSharedClient().account.length){[self.navigationController pushViewController:[RPLogin new] animated:YES];return;}RPCompose *c=[RPCompose new];c.route=@"/";c.quoteID=post[@"id"];[self.navigationController pushViewController:c animated:YES];}
}
@end
