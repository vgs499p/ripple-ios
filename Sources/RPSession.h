// SPDX-License-Identifier: GPL-2.0-or-later
#import <Foundation/Foundation.h>
NSData *RPSessionRead(NSString *service, NSError **error);
BOOL RPSessionWrite(NSString *service, NSData *data, NSError **error);
BOOL RPSessionDelete(NSString *service, NSError **error);
