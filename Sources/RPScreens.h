// SPDX-License-Identifier: GPL-2.0-or-later
#import <UIKit/UIKit.h>
#import "RPClient.h"
RPClient *RPSharedClient(void);
UIColor *RPAccent(void);
NSArray *RPAccentNames(void);
void RPMessage(NSString *,NSString *);
void RPEvent(NSString *);
@interface RPFeed : UITableViewController <UIActionSheetDelegate,UIAlertViewDelegate>
@property(nonatomic,copy) NSString *route;
@property(nonatomic,strong) NSMutableArray *posts;
@property(nonatomic,strong) NSArray *people;
@property(nonatomic,strong) NSDictionary *page;
@property(nonatomic) NSInteger number;
@property(nonatomic) BOOL loading;
@property(nonatomic) BOOL directory;
@property(nonatomic) BOOL profileRoute;
@property(nonatomic,strong) NSDictionary *profile;
@property(nonatomic,strong) UIImageView *profileBanner;
@property(nonatomic,strong) UIImageView *profileAvatar;
@property(nonatomic,strong) UILabel *profileTitle;
@property(nonatomic,strong) UILabel *profileSubtitle;
@property(nonatomic,strong) UILabel *profileBio;
@property(nonatomic,strong) UILabel *profileStats;
@property(nonatomic,copy) NSString *selectedID;
@property(nonatomic,strong) NSMutableSet *pendingActions;
@property(nonatomic,strong) UILabel *status;
@property(nonatomic,strong) UIButton *older;
@property(nonatomic,strong) UIButton *newer;
- (void)load:(NSInteger)number;
- (void)refresh;
- (void)postAction:(NSString *)action post:(NSDictionary *)post;
- (void)applyAccent;
@end
@interface RPLogin : UIViewController <UITextFieldDelegate>
@property(nonatomic,strong) UITextField *username;
@property(nonatomic,strong) UITextField *password;
@property(nonatomic,strong) UILabel *status;
@property(nonatomic,strong) UIButton *signInButton;
@property(nonatomic) BOOL signingIn;
@end
@interface RPCompose : UIViewController <UITextViewDelegate>
@property(nonatomic,strong) UITextView *editor;
@property(nonatomic,strong) UILabel *counter;
@property(nonatomic,copy) NSString *route;
@property(nonatomic,copy) NSString *quoteID;
@end
@interface RPPhoto : UIViewController
@property(nonatomic,copy) NSString *url;
@end
@interface RPSettings : UITableViewController <UIActionSheetDelegate>
@end
