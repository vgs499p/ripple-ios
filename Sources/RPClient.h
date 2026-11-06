// SPDX-License-Identifier: GPL-2.0-or-later
#import <Foundation/Foundation.h>
typedef void (^RPCompletion)(NSData *, NSHTTPURLResponse *, NSError *);
@class RPClient;
@interface RPRequest : NSObject <NSURLConnectionDataDelegate>
@property(nonatomic,strong) NSURLConnection *connection;
@property(nonatomic,strong) RPClient *client;
@property(nonatomic,strong) NSMutableData *body;
@property(nonatomic,strong) NSHTTPURLResponse *response;
@property(nonatomic,copy) RPCompletion completion;
@end
@interface RPClient : NSObject
@property(nonatomic,strong) NSMutableDictionary *cookies;
@property(nonatomic,copy) NSString *account;
@property(nonatomic,strong) NSMutableArray *requestSummary;
- (void)get:(NSString *)path completion:(RPCompletion)completion;
- (void)post:(NSString *)path fields:(NSDictionary *)fields completion:(RPCompletion)completion;
+ (NSString *)encode:(NSString *)text;
@end
NSDictionary *RPParse(NSData *data);
NSDictionary *RPParseLoginForm(NSData *data, NSURL *pageURL);
NSDictionary *RPLoginPageSummary(NSData *data, NSURL *pageURL);
