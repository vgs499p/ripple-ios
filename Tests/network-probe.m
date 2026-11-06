// SPDX-License-Identifier: GPL-2.0-or-later
#import <Foundation/Foundation.h>
#import "RPClient.h"
#include <stdio.h>
int main(void){@autoreleasepool{
 __block BOOL done=NO;__block int result=1;RPClient *client=[RPClient new];
 [client get:@"/login" completion:^(NSData *data,NSHTTPURLResponse *response,NSError *error){
  NSDictionary *form=RPParseLoginForm(data,response.URL);
  printf("HTTP_STATUS:%ld BYTES:%lu LOGIN_FORM:%d SUBMIT_FIELD:%d TARGET_LOGIN:%d\n",(long)response.statusCode,(unsigned long)data.length,form!=nil,form[@"hidden"][@"submit"]!=nil,[form[@"action"] isEqual:@"https://ripple.tel/login"]);
  if(error)printf("NETWORK_ERROR:%s (%s:%ld)\n",error.localizedDescription.UTF8String,error.domain.UTF8String,(long)error.code);
  result=(!error&&form)?0:1;done=YES;
 }];
 NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:30];
 while(!done&&deadline.timeIntervalSinceNow>0)[[NSRunLoop mainRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
 return done?result:2;
}}
