// SPDX-License-Identifier: GPL-2.0-or-later
#import "RPImages.h"
#import "RPClient.h"
#import <ImageIO/ImageIO.h>
@implementation RPImages
+ (RPImages *)shared{static RPImages *store;static dispatch_once_t once;dispatch_once(&once,^{store=[RPImages new];store.cache=[NSCache new];store.cache.totalCostLimit=6*1024*1024;});return store;}
- (void)load:(NSString *)url size:(NSUInteger)size completion:(void(^)(UIImage *))completion{
    NSString *key=[NSString stringWithFormat:@"%@:%lu",url,(unsigned long)size];UIImage *cached=[self.cache objectForKey:key];if(cached){completion(cached);return;}
    RPClient *media=[RPClient new];[media get:url completion:^(NSData *data,NSHTTPURLResponse *r,NSError *error){if(error||!data){completion(nil);return;}
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW,0),^{
            CGImageSourceRef source=CGImageSourceCreateWithData((__bridge CFDataRef)data,NULL);CGImageRef image=NULL;
            if(source){NSDictionary *options=@{(id)kCGImageSourceCreateThumbnailFromImageAlways:@YES,(id)kCGImageSourceThumbnailMaxPixelSize:@(size),(id)kCGImageSourceCreateThumbnailWithTransform:@YES};image=CGImageSourceCreateThumbnailAtIndex(source,0,(__bridge CFDictionaryRef)options);CFRelease(source);}
            UIImage *decoded=image?[UIImage imageWithCGImage:image]:nil;if(image)CGImageRelease(image);
            dispatch_async(dispatch_get_main_queue(),^{if(decoded)[self.cache setObject:decoded forKey:key cost:(NSUInteger)(decoded.size.width*decoded.size.height*4)];completion(decoded);});
        });
    }];
}
@end
