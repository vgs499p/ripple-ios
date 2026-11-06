// SPDX-License-Identifier: GPL-2.0-or-later
#import <Foundation/Foundation.h>
@interface RPAlerts : NSObject
@property(nonatomic,strong) NSTimer *timer;
@property(nonatomic,strong) NSMutableDictionary *baselines;
@property(nonatomic) BOOL busy;
+ (RPAlerts *)shared;
- (void)start;
- (void)stop;
@end
