// SPDX-License-Identifier: GPL-2.0-or-later
#import "RPScreens.h"
#import "RPPostCell.h"
#import "RPImages.h"
#import <QuartzCore/QuartzCore.h>
@implementation RPLogin
- (void)loadView{
 self.title=@"Sign in";self.view=[[UIView alloc]initWithFrame:[UIScreen mainScreen].applicationFrame];self.view.backgroundColor=[UIColor colorWithWhite:.94 alpha:1];CGFloat w=self.view.bounds.size.width;
 self.username=[[UITextField alloc]initWithFrame:CGRectMake(16,24,w-32,44)];self.username.placeholder=@"Username";self.username.borderStyle=UITextBorderStyleRoundedRect;self.username.autocapitalizationType=UITextAutocapitalizationTypeNone;self.username.autocorrectionType=UITextAutocorrectionTypeNo;self.username.returnKeyType=UIReturnKeyNext;self.username.delegate=self;[self.view addSubview:self.username];
 self.password=[[UITextField alloc]initWithFrame:CGRectMake(16,80,w-32,44)];self.password.placeholder=@"Password";self.password.secureTextEntry=YES;self.password.borderStyle=UITextBorderStyleRoundedRect;self.password.returnKeyType=UIReturnKeyGo;self.password.delegate=self;[self.view addSubview:self.password];
 UIButton *button=[UIButton buttonWithType:UIButtonTypeRoundedRect];self.signInButton=button;button.frame=CGRectMake(16,140,w-32,44);[button setTitle:@"Sign in to Ripple" forState:UIControlStateNormal];[button setTitleColor:RPAccent() forState:UIControlStateNormal];[button addTarget:self action:@selector(signIn) forControlEvents:UIControlEventTouchUpInside];[self.view addSubview:button];
 self.status=[[UILabel alloc]initWithFrame:CGRectMake(16,196,w-32,100)];self.status.numberOfLines=0;self.status.font=[UIFont systemFontOfSize:14];self.status.textColor=[UIColor darkGrayColor];self.status.backgroundColor=[UIColor clearColor];self.status.text=@"Your sign-in is saved in Keychain across restarts. Your password is never stored.";[self.view addSubview:self.status];
}
- (void)viewDidLoad{[super viewDidLoad];[self checkLoginWithUsername:nil password:nil];}
- (BOOL)textFieldShouldReturn:(UITextField *)field{if(field==self.username)[self.password becomeFirstResponder];else [self signIn];return YES;}
- (void)completeSignIn:(NSString *)account{
 self.password.text=@"";RPSharedClient().account=account;BOOL saved=[RPSharedClient()rememberSession];RPEvent(saved?@"login-confirmed-saved":@"login-confirmed-unsaved");if(!saved)RPMessage(@"Signed in for now",RPSharedClient().sessionError.localizedDescription?:@"The session could not be saved to Keychain.");[[NSNotificationCenter defaultCenter]postNotificationName:@"RippleSessionChanged" object:nil];[self.navigationController popViewControllerAnimated:YES];
}
- (void)setLoginBusy:(BOOL)busy{self.signingIn=busy;self.signInButton.enabled=!busy;self.username.enabled=!busy;self.password.enabled=!busy;}
- (void)checkLoginWithUsername:(NSString *)name password:(NSString *)password{
 [self setLoginBusy:YES];BOOL submitting=name.length>0;self.status.text=submitting?@"Signing in…":@"Checking Ripple’s secure sign-in page…";
 [RPSharedClient() get:@"/login" completion:^(NSData *d,NSHTTPURLResponse *r,NSError *error){
  if(error){[self setLoginBusy:NO];self.status.text=error.localizedDescription;RPEvent(@"login-load-failed");return;}
  NSDictionary *page=RPParse(d);NSString *account=page[@"account"];
  if(!account.length&&[RPLoginPageSummary(d,r.URL)[@"composer"]boolValue]&&[RPLoginPageSummary(d,r.URL)[@"logoutLink"]boolValue])account=RPSharedClient().account;
  if(account.length){[self setLoginBusy:NO];[self completeSignIn:account];return;}
  NSDictionary *form=RPParseLoginForm(d,r.URL);
  if(!form){[self setLoginBusy:NO];self.status.text=@"Ripple did not return a supported sign-in page. Tap Sign in to retry.";RPEvent([NSString stringWithFormat:@"login-form-missing:HTTP%ld",(long)r.statusCode]);return;}
  RPEvent(@"login-form-ready");
  if(!submitting){[self setLoginBusy:NO];self.status.text=@"Ready to sign in. Your session will be saved in Keychain. Your password goes only to Ripple over HTTPS.";return;}
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
 RPClient *client=RPSharedClient();NSString *account=[client.account copy];[client get:self.route?:@"/" completion:^(NSData *data,NSHTTPURLResponse *res,NSError *error){NSDictionary *before=RPParse(data);NSDictionary *form=before[@"forms"][self.quoteID?@"quote":@"composer"];if(error||!form){self.counter.text=@"Not sent";RPMessage(@"Not posted",error.localizedDescription?:@"No supported post form. Check your sign-in.");[self textViewDidChange:self.editor];return;}
 NSMutableDictionary *fields=[form[@"hidden"] mutableCopy];fields[form[@"field"]]=draft;if(self.quoteID)fields[@"qid"]=self.quoteID;
 [RPSharedClient() post:form[@"action"] fields:fields completion:^(NSData *d,NSHTTPURLResponse *r,NSError *failure){if(failure){RPMessage(@"Check Ripple before retrying",failure.localizedDescription);[self textViewDidChange:self.editor];return;}
 NSDictionary *page=RPParse(d);BOOL found=NO;for(NSDictionary *p in page[@"posts"]){NSString *text=p[@"text"]?:@"";BOOL isNew=YES;for(NSDictionary *old in before[@"posts"])if([old[@"id"] isEqual:p[@"id"]]){isNew=NO;break;}NSString *author=[p[@"handle"] lowercaseString];if(isNew&&[author isEqual:[account lowercaseString]]&&[text rangeOfString:draft].location!=NSNotFound&&(!self.quoteID||[text rangeOfString:self.quoteID].location!=NSNotFound)){found=YES;break;}}
 if(found){[[NSNotificationCenter defaultCenter]postNotificationName:@"RipplePostPublished" object:nil];[self.navigationController popViewControllerAnimated:YES];return;}
 // The POST may redirect to a login/message page. Refresh the public timeline
 // and confirm a fresh post before reporting success; never submit a second time.
 [client get:@"/" completion:^(NSData *fresh,NSHTTPURLResponse *response,NSError *refreshError){NSDictionary *timeline=RPParse(fresh);BOOL confirmed=NO;for(NSDictionary *p in timeline[@"posts"]){NSString *text=p[@"text"]?:@"";BOOL isNew=YES;for(NSDictionary *old in before[@"posts"])if([old[@"id"] isEqual:p[@"id"]]){isNew=NO;break;}if(isNew&&[[p[@"handle"] lowercaseString] isEqual:[account lowercaseString]]&&[text rangeOfString:draft].location!=NSNotFound&&(!self.quoteID||[text rangeOfString:self.quoteID].location!=NSNotFound)){confirmed=YES;break;}}
 if(confirmed){[[NSNotificationCenter defaultCenter]postNotificationName:@"RipplePostPublished" object:nil];[self.navigationController popViewControllerAnimated:YES];return;}RPMessage(@"Check Ripple before retrying",refreshError.localizedDescription?:@"Ripple did not confirm the new post. Your draft is still here; check your timeline before trying again.");self.counter.text=@"Not confirmed — draft kept";[self textViewDidChange:self.editor];}];
 }];}];
}
@end
@implementation RPPhoto
- (void)loadView{self.title=@"Photo";UIImageView *image=[[UIImageView alloc]initWithFrame:[UIScreen mainScreen].applicationFrame];image.backgroundColor=[UIColor blackColor];image.contentMode=UIViewContentModeScaleAspectFit;self.view=image;[[RPImages shared]load:self.url size:1024 completion:^(UIImage *photo){image.image=photo;if(!photo)RPMessage(@"Photo unavailable",@"The image could not be loaded within the memory/response limit.");}];}
@end
@implementation RPFeed
- (BOOL)isProfilePath:(NSString *)path{NSString *route=[[path componentsSeparatedByString:@"?"]objectAtIndex:0];route=[[route componentsSeparatedByString:@"#"]objectAtIndex:0];if(!route.length||[route isEqual:@"/"]||[route hasPrefix:@"/status"]||[route hasPrefix:@"/users"]||[route hasPrefix:@"/results"]||[route hasPrefix:@"/trending"]||[route hasPrefix:@"/account"])return NO;return [route hasPrefix:@"/~"]||([route hasPrefix:@"/"]&&[route rangeOfString:@"/" options:0 range:NSMakeRange(1,route.length-1)].location==NSNotFound);}
- (NSString *)profileHandleFromPath:(NSString *)path{NSString *handle=[path hasPrefix:@"/~"]?[path substringFromIndex:2]:[path hasPrefix:@"/"]?[path substringFromIndex:1]:path;return [handle stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];}
- (UIView *)makeProfileHeader{
 UIView *header=[[UIView alloc]initWithFrame:CGRectMake(0,0,self.tableView.bounds.size.width,252)];header.backgroundColor=[UIColor whiteColor];self.profileBanner=[[UIImageView alloc]initWithFrame:CGRectMake(0,0,header.bounds.size.width,104)];self.profileBanner.autoresizingMask=UIViewAutoresizingFlexibleWidth;self.profileBanner.contentMode=UIViewContentModeScaleAspectFill;self.profileBanner.clipsToBounds=YES;self.profileBanner.backgroundColor=[UIColor colorWithWhite:.18 alpha:1];[header addSubview:self.profileBanner];
 self.profileAvatar=[[UIImageView alloc]initWithFrame:CGRectMake(14,68,78,78)];self.profileAvatar.contentMode=UIViewContentModeScaleAspectFill;self.profileAvatar.clipsToBounds=YES;self.profileAvatar.layer.borderColor=[UIColor whiteColor].CGColor;self.profileAvatar.layer.borderWidth=3;self.profileAvatar.backgroundColor=[UIColor colorWithWhite:.9 alpha:1];[header addSubview:self.profileAvatar];
 self.profileTitle=[[UILabel alloc]initWithFrame:CGRectMake(102,108,header.bounds.size.width-112,24)];self.profileTitle.font=[UIFont boldSystemFontOfSize:19];self.profileTitle.textColor=[UIColor colorWithWhite:.18 alpha:1];self.profileTitle.backgroundColor=[UIColor clearColor];[header addSubview:self.profileTitle];
 self.profileSubtitle=[[UILabel alloc]initWithFrame:CGRectMake(102,132,header.bounds.size.width-112,20)];self.profileSubtitle.font=[UIFont systemFontOfSize:13];self.profileSubtitle.textColor=[UIColor grayColor];self.profileSubtitle.backgroundColor=[UIColor clearColor];[header addSubview:self.profileSubtitle];
 self.profileStats=[[UILabel alloc]initWithFrame:CGRectMake(14,154,header.bounds.size.width-28,24)];self.profileStats.font=[UIFont boldSystemFontOfSize:13];self.profileStats.textColor=RPAccent();self.profileStats.backgroundColor=[UIColor clearColor];[header addSubview:self.profileStats];
 self.profileBio=[[UILabel alloc]initWithFrame:CGRectMake(14,181,header.bounds.size.width-28,54)];self.profileBio.font=[UIFont systemFontOfSize:13];self.profileBio.textColor=[UIColor darkGrayColor];self.profileBio.backgroundColor=[UIColor clearColor];self.profileBio.numberOfLines=3;[header addSubview:self.profileBio];UIView *line=[[UIView alloc]initWithFrame:CGRectMake(0,251,header.bounds.size.width,1)];line.autoresizingMask=UIViewAutoresizingFlexibleWidth;line.backgroundColor=[UIColor colorWithWhite:.86 alpha:1];[header addSubview:line];return header;
}
- (void)updateProfileHeader:(NSDictionary *)profile{
 self.profile=profile;if(!self.profileRoute)return;if(!self.tableView.tableHeaderView)self.tableView.tableHeaderView=[self makeProfileHeader];NSString *name=profile[@"name"],*handle=profile[@"handle"];self.profileTitle.text=name.length?name:self.title;self.profileSubtitle.text=handle.length?handle:[@"@" stringByAppendingString:[self profileHandleFromPath:self.route]];self.profileBio.text=profile[@"bio"];
 NSDictionary *stats=profile[@"stats"];NSMutableArray *parts=[NSMutableArray array];if([stats[@"posts"]length])[parts addObject:[NSString stringWithFormat:@"%@ posts",stats[@"posts"]]];if([stats[@"followers"]length])[parts addObject:[NSString stringWithFormat:@"%@ followers",stats[@"followers"]]];if([stats[@"following"]length])[parts addObject:[NSString stringWithFormat:@"%@ following",stats[@"following"]]];self.profileStats.text=[parts componentsJoinedByString:@"   "];
 NSString *avatar=profile[@"avatar"],*banner=profile[@"banner"];if(avatar.length)[[RPImages shared]load:avatar size:180 completion:^(UIImage *image){self.profileAvatar.image=image;}];if(banner.length)[[RPImages shared]load:banner size:640 completion:^(UIImage *image){self.profileBanner.image=image;}];
}
- (void)viewDidLoad{
 [super viewDidLoad];self.route=self.route?:@"/";self.number=1;self.posts=[NSMutableArray array];self.directory=[self.route hasPrefix:@"/users"];self.profileRoute=[self isProfilePath:self.route];self.tableView.backgroundColor=[UIColor colorWithWhite:.94 alpha:1];self.tableView.separatorColor=[UIColor colorWithWhite:.86 alpha:1];if([self.route isEqual:@"/"]){UIImageView *brand=[[UIImageView alloc]initWithImage:[UIImage imageNamed:@"logo.png"]];brand.contentMode=UIViewContentModeScaleAspectFit;brand.frame=CGRectMake(0,0,88,28);self.navigationItem.titleView=brand;}else if(self.profileRoute){self.tableView.tableHeaderView=[self makeProfileHeader];self.profileTitle.text=self.title;}
 self.navigationItem.rightBarButtonItems=@[[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh)],[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(compose)]];
 if([self.route isEqual:@"/"]){self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(search)];UISegmentedControl *tabs=[[UISegmentedControl alloc]initWithItems:@[@"Public",@"Following"]];tabs.frame=CGRectMake(8,8,304,30);tabs.segmentedControlStyle=UISegmentedControlStyleBar;tabs.tintColor=[UIColor colorWithRed:.15 green:.17 blue:.19 alpha:1];tabs.selectedSegmentIndex=0;[tabs addTarget:self action:@selector(tab:) forControlEvents:UIControlEventValueChanged];UIView *header=[[UIView alloc]initWithFrame:CGRectMake(0,0,320,46)];[header addSubview:tabs];self.tableView.tableHeaderView=header;}
 UIView *footer=[[UIView alloc]initWithFrame:CGRectMake(0,0,320,64)];self.newer=[UIButton buttonWithType:UIButtonTypeRoundedRect];self.newer.frame=CGRectMake(8,12,82,34);[self.newer setTitle:@"Newer" forState:UIControlStateNormal];[self.newer addTarget:self action:@selector(previous) forControlEvents:UIControlEventTouchUpInside];[footer addSubview:self.newer];self.status=[[UILabel alloc]initWithFrame:CGRectMake(90,12,140,34)];self.status.backgroundColor=[UIColor clearColor];self.status.font=[UIFont systemFontOfSize:13];self.status.textAlignment=NSTextAlignmentCenter;[footer addSubview:self.status];self.older=[UIButton buttonWithType:UIButtonTypeRoundedRect];self.older.frame=CGRectMake(230,12,82,34);[self.older setTitle:@"Older" forState:UIControlStateNormal];[self.older addTarget:self action:@selector(next) forControlEvents:UIControlEventTouchUpInside];[footer addSubview:self.older];self.tableView.tableFooterView=footer;
 [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(refresh) name:@"RippleSessionChanged" object:nil];[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(refresh) name:@"RipplePostPublished" object:nil];[self load:1];
}
- (void)dealloc{[[NSNotificationCenter defaultCenter]removeObserver:self];}
- (void)tab:(UISegmentedControl *)tabs{RPEvent(@"timeline-tab");if(tabs.selectedSegmentIndex==1&&!RPSharedClient().account.length){tabs.selectedSegmentIndex=0;[self.navigationController pushViewController:[RPLogin new] animated:YES];return;}self.route=tabs.selectedSegmentIndex?@"/?tlmode=following":@"/";[self load:1];}
- (void)load:(NSInteger)number{
 if(self.loading)return;RPEvent(@"feed-load");self.loading=YES;self.status.text=@"Loading…";self.newer.enabled=NO;self.older.enabled=NO;
 NSString *path=number>1?[self.route stringByAppendingFormat:@"%cpageno=%ld",[self.route rangeOfString:@"?"].location==NSNotFound?'?':'&',(long)number]:self.route;
 [RPSharedClient() get:path completion:^(NSData *data,NSHTTPURLResponse *r,NSError *error){self.loading=NO;NSDictionary *page=RPParse(data);
  if(error||!page)RPMessage(@"Could not load Ripple",error.localizedDescription?:@"Ripple returned an unsupported page.");else{if([self.route isEqual:@"/"]&&page[@"forms"][@"login"]&&!page[@"forms"][@"composer"]&&RPSharedClient().sessionEnabled){if(![RPSharedClient()clearSession])RPMessage(@"Saved sign-in",RPSharedClient().sessionError.localizedDescription);}
  self.page=page;self.posts=[page[@"posts"] mutableCopy];self.people=page[@"people"];self.number=number;if([page[@"account"] length])RPSharedClient().account=page[@"account"];
  if(self.profileRoute){NSString *wanted=[[self profileHandleFromPath:self.route]lowercaseString];NSDictionary *match=nil;for(NSDictionary *candidate in page[@"profiles"])if([[[candidate[@"handle"] stringByReplacingOccurrencesOfString:@"@" withString:@""]lowercaseString]isEqual:wanted]){match=candidate;break;}[self updateProfileHeader:match?:@{}];if([match[@"name"]length])self.title=match[@"name"];}
  [self.tableView reloadData];[self.tableView setContentOffset:CGPointZero animated:NO];}
  self.status.text=[NSString stringWithFormat:@"Page %ld",(long)self.number];self.newer.enabled=self.number>1;self.older.enabled=[self.page[@"older"] boolValue];RPEvent([NSString stringWithFormat:@"loaded:%lu:HTTP%ld",(unsigned long)self.posts.count,(long)r.statusCode]);
 }];
}
- (void)refresh{[self load:self.number];}
- (void)applyAccent{self.profileStats.textColor=RPAccent();[self.tableView reloadData];}
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
- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)index{if(self.directory){NSDictionary *person=self.people[index.row];RPFeed *profile=[RPFeed new];profile.route=[@"/~" stringByAppendingString:person[@"handle"]];profile.title=person[@"name"];[self.navigationController pushViewController:profile animated:YES];}}
- (void)postAction:(NSString *)action post:(NSDictionary *)post{
 RPEvent([@"post-" stringByAppendingString:action]);
 if([action isEqual:@"profile"]){NSString *handle=[post[@"handle"]stringByReplacingOccurrencesOfString:@"@" withString:@""];if(!handle.length)return;RPFeed *profile=[RPFeed new];profile.route=[@"/~" stringByAppendingString:handle];profile.title=post[@"author"];[self.navigationController pushViewController:profile animated:YES];return;}
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
 if(button==1){RPFeed *f=[RPFeed new];f.route=[@"/~" stringByAppendingString:[post[@"handle"] stringByReplacingOccurrencesOfString:@"@" withString:@""]];f.title=post[@"author"];[self.navigationController pushViewController:f animated:YES];}
 if(button==2){if(!RPSharedClient().account.length){[self.navigationController pushViewController:[RPLogin new] animated:YES];return;}RPCompose *c=[RPCompose new];c.route=@"/";c.quoteID=post[@"id"];[self.navigationController pushViewController:c animated:YES];}
}
@end
