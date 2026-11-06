// SPDX-License-Identifier: GPL-2.0-or-later
#import "RPPostCell.h"
#import "RPImages.h"
@implementation RPPostCell
+ (CGFloat)bodyHeight:(NSDictionary *)post width:(CGFloat)width {return [post[@"text"] sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:CGSizeMake(width-76,1000) lineBreakMode:NSLineBreakByWordWrapping].height;}
+ (CGFloat)height:(NSDictionary *)post width:(CGFloat)width{return 88+MAX(20,[self bodyHeight:post width:width])+([post[@"images"] count]?154:0);}
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)identifier {
 if((self=[super initWithStyle:style reuseIdentifier:identifier])){
  self.selectionStyle=UITableViewCellSelectionStyleNone;self.contentView.backgroundColor=[UIColor whiteColor];self.avatar=[[UIImageView alloc]initWithFrame:CGRectZero];self.avatar.contentMode=UIViewContentModeScaleAspectFill;self.avatar.clipsToBounds=YES;self.avatar.backgroundColor=[UIColor colorWithWhite:.92 alpha:1];[self.contentView addSubview:self.avatar];
  self.name=[UILabel new];self.name.font=[UIFont boldSystemFontOfSize:13];self.name.textColor=[UIColor colorWithWhite:.22 alpha:1];self.name.backgroundColor=[UIColor clearColor];[self.contentView addSubview:self.name];self.time=[UILabel new];self.time.font=[UIFont systemFontOfSize:11];self.time.textColor=[UIColor grayColor];[self.contentView addSubview:self.time];
  self.body=[UILabel new];self.body.font=[UIFont systemFontOfSize:14];self.body.textColor=[UIColor colorWithWhite:.22 alpha:1];self.body.backgroundColor=[UIColor clearColor];self.body.numberOfLines=0;[self.contentView addSubview:self.body];
  self.profileButton=[UIButton buttonWithType:UIButtonTypeCustom];[self.profileButton addTarget:self action:@selector(openProfile) forControlEvents:UIControlEventTouchUpInside];[self.contentView addSubview:self.profileButton];
  self.photo=[UIButton buttonWithType:UIButtonTypeCustom];self.photo.imageView.contentMode=UIViewContentModeScaleAspectFit;self.photo.clipsToBounds=YES;self.photo.backgroundColor=[UIColor colorWithWhite:.95 alpha:1];[self.photo setTitleColor:RPAccent() forState:UIControlStateNormal];[self.photo addTarget:self action:@selector(showPhoto) forControlEvents:UIControlEventTouchUpInside];[self.contentView addSubview:self.photo];
  NSMutableArray *buttons=[NSMutableArray array];NSArray *titles=@[@"Like",@"Reply",@"Repost",@"More"];
  for(NSUInteger i=0;i<4;i++){UIButton *button=[UIButton buttonWithType:UIButtonTypeCustom];button.tag=i;button.titleLabel.font=[UIFont systemFontOfSize:11];[button setTitle:titles[i] forState:UIControlStateNormal];[button setTitleColor:RPAccent() forState:UIControlStateNormal];[button addTarget:self action:@selector(action:) forControlEvents:UIControlEventTouchUpInside];[self.contentView addSubview:button];[buttons addObject:button];}self.actions=buttons;
 }
 return self;
}
- (void)configure:(NSDictionary *)post feed:(RPFeed *)feed {
 self.post=post;self.feed=feed;self.name.text=[NSString stringWithFormat:@"%@ %@",post[@"author"],post[@"handle"]];self.time.text=post[@"time"];self.body.text=post[@"text"];self.avatar.image=nil;
 NSString *pid=post[@"id"];if([post[@"avatar"] length])[[RPImages shared]load:post[@"avatar"] size:88 completion:^(UIImage *image){if([self.post[@"id"] isEqual:pid])self.avatar.image=image;}];
 NSArray *titles=@[[NSString stringWithFormat:@"♥ %@",post[@"likes"]],[NSString stringWithFormat:@"Reply %@",post[@"replies"]],[NSString stringWithFormat:@"↻ %@",post[@"reposts"]],@"More…"];
 for(NSUInteger i=0;i<4;i++){[(UIButton *)self.actions[i] setTitle:titles[i] forState:UIControlStateNormal];[(UIButton *)self.actions[i]setTitleColor:RPAccent() forState:UIControlStateNormal];}
 NSArray *images=post[@"images"];self.photo.hidden=!images.count;[self.photo setTitleColor:RPAccent() forState:UIControlStateNormal];[self.photo setImage:nil forState:UIControlStateNormal];[self.photo setTitle:@"Loading photo…" forState:UIControlStateNormal];
 if(images.count)[[RPImages shared]load:images[0] size:480 completion:^(UIImage *image){if(![self.post[@"id"] isEqual:pid])return;[self.photo setImage:image forState:UIControlStateNormal];[self.photo setTitle:image?@"":@"Tap to view photo" forState:UIControlStateNormal];}];[self setNeedsLayout];
}
- (void)layoutSubviews{[super layoutSubviews];CGFloat w=self.contentView.bounds.size.width;self.avatar.frame=CGRectMake(10,12,44,44);self.name.frame=CGRectMake(64,10,w-74,20);self.time.frame=CGRectMake(64,30,w-74,16);self.profileButton.frame=CGRectMake(60,6,w-68,42);CGFloat h=MAX(20,[[self class]bodyHeight:self.post width:w]);self.body.frame=CGRectMake(64,50,w-76,h);CGFloat y=54+h;if(!self.photo.hidden){self.photo.frame=CGRectMake(64,y,w-76,146);y+=154;}for(NSUInteger i=0;i<4;i++)[(UIButton *)self.actions[i] setFrame:CGRectMake(60+i*(w-68)/4,y,(w-68)/4,28)];}
- (void)openProfile{[self.feed postAction:@"profile" post:self.post];}
- (void)action:(UIButton *)button {NSArray *actions=@[@"like",@"reply",@"repost",@"more"];[self.feed postAction:actions[button.tag] post:self.post];}
- (void)showPhoto{[self.feed postAction:@"photo" post:self.post];}
@end
