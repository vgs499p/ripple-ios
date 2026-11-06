// SPDX-License-Identifier: GPL-2.0-or-later
// Separate-process Keychain checks. Uses only synthetic cookies in a dedicated item.
#import <Foundation/Foundation.h>
#import "RPClient.h"
#include <stdio.h>
@interface RPClient (SessionTest)
- (NSURLRequest *)withCookies:(NSURLRequest *)request;
- (void)receive:(NSHTTPURLResponse *)response;
@end
static int fail(NSString *text,NSError *error){printf("FAIL %s OSSTATUS:%ld\n",text.UTF8String,(long)error.code);return 1;}
int main(int argc,char **argv){@autoreleasepool{
 if(argc!=2)return 2;NSString *mode=[NSString stringWithUTF8String:argv[1]];
 NSString *service=@"tel.ripple.native.ios6.session.selftest";
 RPClient *client=[RPClient new];[client restoreSavedSession:service];
 if(client.sessionError)return fail(@"read Keychain",client.sessionError);
 if([mode isEqual:@"write"]){
  if(![client clearSession])return fail(@"clear test item",client.sessionError);
  client.account=@"@session-test";
  for(NSString *header in @[@"session=synthetic-one; Path=/; Secure; HttpOnly",@"scoped=synthetic; Path=/account; Secure",@"dead=expired; Max-Age=0; Path=/"]){NSHTTPURLResponse *response=[[NSHTTPURLResponse alloc]initWithURL:[NSURL URLWithString:@"https://ripple.tel/"] statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:@{@"Set-Cookie":header}];[client receive:response];}
  if(![client rememberSession])return fail(@"save Keychain",client.sessionError);
 }else if([mode isEqual:@"read"]||[mode isEqual:@"rotated"]){
  if(![client.account isEqual:@"@session-test"]||client.cookies.count!=2){printf("ACCOUNT_VALID:%d COOKIES:%lu\n",[client.account isEqual:@"@session-test"],(unsigned long)client.cookies.count);for(NSHTTPCookie *c in client.cookies.allValues)printf("TEST_COOKIE:%s EXPIRY:%s\n",c.name.UTF8String,c.expiresDate.description.UTF8String);return fail(@"restore account and unexpired cookies",nil);}
  NSURLRequest *root=[client withCookies:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://ripple.tel/"]]];
  NSString *expected=[mode isEqual:@"rotated"]?@"session=synthetic-two":@"session=synthetic-one";
  if(![[root valueForHTTPHeaderField:@"Cookie"]isEqual:expected])return fail(@"restore root cookie",nil);
  NSURLRequest *other=[client withCookies:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://example.com/account"]]];
  if([other valueForHTTPHeaderField:@"Cookie"].length)return fail(@"origin scope",nil);
  NSURLRequest *wrongPath=[client withCookies:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://ripple.tel/accounting"]]];
  if([[wrongPath valueForHTTPHeaderField:@"Cookie"]rangeOfString:@"scoped="].location!=NSNotFound)return fail(@"path boundary",nil);
  if([mode isEqual:@"read"]){NSHTTPURLResponse *response=[[NSHTTPURLResponse alloc]initWithURL:[NSURL URLWithString:@"https://ripple.tel/"] statusCode:302 HTTPVersion:@"HTTP/1.1" headerFields:@{@"Set-Cookie":@"session=synthetic-two; Path=/; Secure; HttpOnly"}];[client receive:response];if(client.sessionError)return fail(@"rotation",client.sessionError);}
 }else if([mode isEqual:@"clear"]){
  RPRequest *old=[RPRequest new];old.client=client;old.sessionGeneration=client.sessionGeneration;
  if(![client clearSession])return fail(@"delete Keychain",client.sessionError);
  NSURLRequest *late=[old connection:nil willSendRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://ripple.tel/"]] redirectResponse:nil];
  if(late||client.cookies.count)return fail(@"late response after sign-out",nil);
  RPClient *again=[RPClient new];[again restoreSavedSession:service];if(again.account.length||again.cookies.count)return fail(@"sign-out survives restart",nil);
 }else return 2;
 printf("PASS session %s\n",mode.UTF8String);return 0;
}}
