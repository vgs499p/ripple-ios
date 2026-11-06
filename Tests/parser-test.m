// SPDX-License-Identifier: GPL-2.0-or-later
#import <Foundation/Foundation.h>
#import "RPClient.h"
#include <stdio.h>
int main(int argc,char **argv){@autoreleasepool{
 NSString *html=@"<a class='brand' href='/'></a><div class='userpost' id='post-42'><b class='displayname'>Alice</b><span class='username'>@alice</span><div class='hover-card'><div class='hover-card-header' style=\"background-image: url('/content/banner/42.jpg');\"></div><a href='/~alice'><img class='hover-card-avatar' src='/content/pfp/42.jpg'><h4>Alice <small>@alice</small></h4></a><p class='hover-card-bio'>Hello profile</p><div class='hover-card-stats'><span><strong>7</strong> Followers</span><span><strong>8</strong> Following</span><span><strong>9</strong> Posts</span></div></div><p>Hello<br>world<img alt='!'></p></div><a href='/?pageno=2'>Older →</a><form method='post' action='/login'><input type='hidden' name='csrf' value='test'><input name='username'><input type='password' name='password'></form>";
 NSDictionary *page=RPParse([html dataUsingEncoding:NSUTF8StringEncoding]);
 NSCAssert([page[@"posts"] count]==1,@"post count");NSCAssert([page[@"posts"][0][@"text"] isEqual:@"Hello\nworld!"],@"paragraphs, emoji and hover cards");
 NSCAssert([page[@"profiles"]count]==1&&[page[@"profiles"][0][@"handle"]isEqual:@"@alice"],@"profile identity from native hover card");NSCAssert([page[@"profiles"][0][@"banner"]isEqual:@"/content/banner/42.jpg"]&&[page[@"profiles"][0][@"bio"]isEqual:@"Hello profile"],@"profile banner and bio");NSCAssert([page[@"profiles"][0][@"stats"][@"followers"]isEqual:@"7"]&&[page[@"profiles"][0][@"stats"][@"following"]isEqual:@"8"]&&[page[@"profiles"][0][@"stats"][@"posts"]isEqual:@"9"],@"profile counts");
 NSCAssert([page[@"older"] boolValue],@"pagination");NSCAssert([page[@"forms"][@"login"][@"hidden"][@"csrf"] isEqual:@"test"],@"hidden fields");
 NSCAssert([[RPClient encode:@"hello & café"] isEqual:@"hello%20%26%20caf%C3%A9"],@"form encoding");
 if(argc>1){NSData *d=[NSData dataWithContentsOfFile:[NSString stringWithUTF8String:argv[1]]];NSDictionary *live=RPParse(d);NSCAssert([live[@"posts"] count]>0,@"public captured markup");NSCAssert([live[@"profiles"] count]>0,@"profile cards from public captured markup");printf("Captured posts: %lu; profiles: %lu\n",(unsigned long)[live[@"posts"] count],(unsigned long)[live[@"profiles"] count]);}
 NSDictionary *signedPage=RPParse([@"<a class='brand'></a><ul><li><a href='/~alice'>myRipple</a></li></ul><form id='npform' method='post' action='/post'><textarea name='postcontents'></textarea></form><a href='/logout'>Log out</a>" dataUsingEncoding:NSUTF8StringEncoding]);
 NSCAssert([signedPage[@"account"]isEqual:@"@alice"],@"own-profile menu recognizes signed-in account without username label");
 NSURL *loginURL=[NSURL URLWithString:@"https://ripple.tel/login"];
 NSString *standalone=@"<h3>Login to Ripple</h3><form method='POST' action=''><fieldset><input name='username'><input name='password' type='PASSWORD'><input name='submit' type='submit' value='Login'><input type='hidden' name='token' value='one&amp;two'></fieldset></form>";
 NSDictionary *form=RPParseLoginForm([standalone dataUsingEncoding:NSUTF8StringEncoding],loginURL);
 NSCAssert([form[@"action"] isEqual:loginURL.absoluteString],@"empty action resolves to current page");
 NSCAssert([form[@"hidden"][@"submit"] isEqual:@"Login"]&&[form[@"hidden"][@"token"] isEqual:@"one&two"],@"submit and hidden controls survive");
 for(NSString *action in @[@"https://example.com/login",@"http://ripple.tel/login",@"//example.com/login"]){NSString *unsafe=[standalone stringByReplacingOccurrencesOfString:@"action=''" withString:[NSString stringWithFormat:@"action='%@'",action]];NSCAssert(!RPParseLoginForm([unsafe dataUsingEncoding:NSUTF8StringEncoding],loginURL),@"credentials never target another origin");}
 NSCAssert(!RPParseLoginForm([@"<form method='post' action='/login'><input name='username'></form>" dataUsingEncoding:NSUTF8StringEncoding],loginURL),@"reject incomplete form");
 if(argc>2){NSDictionary *captured=RPParseLoginForm([NSData dataWithContentsOfFile:[NSString stringWithUTF8String:argv[2]]],loginURL);NSCAssert([captured[@"action"] isEqual:loginURL.absoluteString]&&[captured[@"hidden"][@"submit"] isEqual:@"Login"],@"actual standalone login markup");}
 puts("PASS legacy parser and form encoding");return 0;
}}
