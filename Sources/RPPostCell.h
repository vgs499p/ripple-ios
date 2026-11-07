// SPDX-License-Identifier: GPL-2.0-or-later
#import <UIKit/UIKit.h>
#import "RPScreens.h"
@interface RPPostCell : UITableViewCell
@property(nonatomic,strong) NSDictionary *post;
@property(nonatomic,assign) RPFeed *feed;
@property(nonatomic,strong) UIImageView *avatar;
@property(nonatomic,strong) UILabel *name;
@property(nonatomic,strong) UILabel *time;
@property(nonatomic,strong) UILabel *body;
@property(nonatomic,strong) UILabel *sourceLabel;
@property(nonatomic,strong) UIButton *photo;
@property(nonatomic,strong) UIButton *profileButton;
@property(nonatomic,strong) NSArray *actions;
+ (CGFloat)height:(NSDictionary *)post width:(CGFloat)width;
- (void)configure:(NSDictionary *)post feed:(RPFeed *)feed;
@end
