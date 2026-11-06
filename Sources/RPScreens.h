// SPDX-License-Identifier: GPL-2.0-or-later
#import <UIKit/UIKit.h>
#import "RPClient.h"
RPClient *RPSharedClient(void);
UIColor *RPAccent(void);
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
@property(nonatomic,copy) NSString *selectedID;
@property(nonatomic,strong) UILabel *status;
@property(nonatomic,strong) UIButton *older;
@property(nonatomic,strong) UIButton *newer;
- (void)load:(NSInteger)number;
- (void)refresh;
- (void)postAction:(NSString *)action post:(NSDictionary *)post;
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
@interface RPSettings : UITableViewController
@end
