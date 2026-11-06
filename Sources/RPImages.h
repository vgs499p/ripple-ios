// SPDX-License-Identifier: GPL-2.0-or-later
#import <UIKit/UIKit.h>
@interface RPImages : NSObject
@property(nonatomic,strong) NSCache *cache;
+ (RPImages *)shared;
- (void)load:(NSString *)url size:(NSUInteger)size completion:(void(^)(UIImage *))completion;
@end
