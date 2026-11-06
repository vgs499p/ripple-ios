// SPDX-License-Identifier: GPL-2.0-or-later
#import "RPClient.h"
#import <libxml/HTMLparser.h>
#import <libxml/xpath.h>
static NSError *RPError(NSString *text) { return [NSError errorWithDomain:@"Ripple" code:1 userInfo:@{NSLocalizedDescriptionKey:text}]; }
static BOOL trusted(NSURL *url) { return [[url scheme] isEqual:@"https"] && [[url host] isEqual:@"ripple.tel"] && (![url port] || [[url port] intValue]==443) && ![url user] && ![url password]; }
@interface RPClient (Cookies)
- (void)receive:(NSHTTPURLResponse *)response;
- (NSURLRequest *)withCookies:(NSURLRequest *)request;
@end
@implementation RPRequest
- (void)finish:(NSError *)error { RPCompletion done=self.completion;self.completion=nil;[self.connection cancel];self.connection=nil; if(done)dispatch_async(dispatch_get_main_queue(),^{done(error?nil:self.body,self.response,error);}); }
- (NSURLRequest *)connection:(NSURLConnection *)c willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response {
    if(!trusted(request.URL)){[self finish:RPError(@"Ripple redirected outside its HTTPS address.")];return nil;}if(response)[self.client receive:(NSHTTPURLResponse *)response];return [self.client withCookies:request];
}
- (void)connection:(NSURLConnection *)c didReceiveResponse:(NSURLResponse *)r {self.response=(NSHTTPURLResponse *)r;self.body=[NSMutableData data];}
- (void)connection:(NSURLConnection *)c didReceiveData:(NSData *)d {if(self.body.length+d.length>4*1024*1024){[self finish:RPError(@"Response is too large.")];return;}[self.body appendData:d];}
- (void)connectionDidFinishLoading:(NSURLConnection *)c {NSInteger status=self.response.statusCode;[self finish:status>=400?RPError([NSString stringWithFormat:@"Ripple returned HTTP %ld.",(long)status]):nil];}
- (void)connection:(NSURLConnection *)c didFailWithError:(NSError *)error {[self finish:error];}
@end
@implementation RPClient
- (id)init {if((self=[super init])){ self.cookies=[NSMutableDictionary dictionary]; self.account=@"";self.requestSummary=[NSMutableArray array]; }return self;}
+ (NSString *)encode:(NSString *)text {NSData *d=[text dataUsingEncoding:NSUTF8StringEncoding];const unsigned char *p=d.bytes;NSMutableString *s=[NSMutableString string];for(NSUInteger i=0;i<d.length;i++){unsigned char c=p[i];if((c>='a'&&c<='z')||(c>='A'&&c<='Z')||(c>='0'&&c<='9')||c=='-'||c=='_'||c=='.'||c=='~')[s appendFormat:@"%c",c];else [s appendFormat:@"%%%02X",c];}return s;}
- (void)get:(NSString *)path completion:(RPCompletion)completion {[self send:path fields:nil completion:completion];}
- (void)post:(NSString *)path fields:(NSDictionary *)fields completion:(RPCompletion)completion {[self send:path fields:fields completion:completion];}
- (void)send:(NSString *)path fields:(NSDictionary *)fields completion:(RPCompletion)completion {
    NSURL *url=[NSURL URLWithString:path relativeToURL:[NSURL URLWithString:@"https://ripple.tel/"]];
    if(!trusted(url)){completion(nil,nil,RPError(@"Unsupported Ripple address."));return;}
    NSMutableURLRequest *r=[NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20];
    r.HTTPShouldHandleCookies=NO;[r setValue:@"RippleNative-iOS/0.1 (iOS 6; native UIKit)" forHTTPHeaderField:@"User-Agent"];
    NSArray *cookies=self.cookies.allValues;if(cookies.count){NSDictionary *headers=[NSHTTPCookie requestHeaderFieldsWithCookies:cookies];[r setValue:headers[@"Cookie"] forHTTPHeaderField:@"Cookie"];}
    if(fields){r.HTTPMethod=@"POST";[r setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];[r setValue:@"https://ripple.tel" forHTTPHeaderField:@"Origin"];[r setValue:@"https://ripple.tel/" forHTTPHeaderField:@"Referer"];NSMutableArray *pairs=[NSMutableArray array];for(NSString *key in fields)[pairs addObject:[NSString stringWithFormat:@"%@=%@",[RPClient encode:key],[RPClient encode:fields[key]]]];r.HTTPBody=[[pairs componentsJoinedByString:@"&"] dataUsingEncoding:NSUTF8StringEncoding];}
    RPRequest *job=[RPRequest new];job.client=self;job.body=[NSMutableData data];
    job.completion=^(NSData *data,NSHTTPURLResponse *response,NSError *error){
        if(response)[self receive:response];
        completion(data,response,error);
    };
    job.connection=[[NSURLConnection alloc] initWithRequest:r delegate:job startImmediately:YES];
}
- (void)receive:(NSHTTPURLResponse *)response {
    NSUInteger received=0;
    for(NSHTTPCookie *cookie in [NSHTTPCookie cookiesWithResponseHeaderFields:response.allHeaderFields forURL:response.URL])if([cookie.domain isEqual:@"ripple.tel"]||[cookie.domain isEqual:@".ripple.tel"]){received++;if(cookie.expiresDate&&[cookie.expiresDate timeIntervalSinceNow]<0)[self.cookies removeObjectForKey:cookie.name];else self.cookies[cookie.name]=cookie;}
    // Counts only: never record cookie values, credentials, bodies or URL queries.
    [self.requestSummary addObject:@{@"path":response.URL.path?:@"",@"status":@(response.statusCode),@"receivedCookieCount":@(received),@"storedCookieCount":@(self.cookies.count)}];if(self.requestSummary.count>12)[self.requestSummary removeObjectAtIndex:0];
}
- (NSURLRequest *)withCookies:(NSURLRequest *)request {
    NSMutableURLRequest *r=[request mutableCopy];r.HTTPShouldHandleCookies=NO;
    NSDictionary *headers=[NSHTTPCookie requestHeaderFieldsWithCookies:self.cookies.allValues];[r setValue:headers[@"Cookie"] forHTTPHeaderField:@"Cookie"];return r;
}

@end
static NSArray *nodes(xmlDocPtr doc,xmlNodePtr node,const char *query){xmlXPathContextPtr context=xmlXPathNewContext(doc);context->node=node;xmlXPathObjectPtr result=xmlXPathEvalExpression((const xmlChar *)query,context);NSMutableArray *out=[NSMutableArray array];if(result&&result->nodesetval)for(int i=0;i<result->nodesetval->nodeNr;i++)[out addObject:[NSValue valueWithPointer:result->nodesetval->nodeTab[i]]];if(result)xmlXPathFreeObject(result);xmlXPathFreeContext(context);return out;}
static void appendText(xmlNodePtr node,NSMutableString *out) {
    if(!node)return;
    if(node->type==XML_TEXT_NODE||node->type==XML_CDATA_SECTION_NODE){if(node->content)[out appendString:[NSString stringWithUTF8String:(char *)node->content]?:@""];return;}
    if(xmlStrEqual(node->name,(xmlChar *)"script")||xmlStrEqual(node->name,(xmlChar *)"style"))return;
    if(xmlStrEqual(node->name,(xmlChar *)"br"))[out appendString:@"\n"];
    if(xmlStrEqual(node->name,(xmlChar *)"img")){xmlChar *alt=xmlGetProp(node,(xmlChar *)"alt");if(alt){[out appendString:[NSString stringWithUTF8String:(char *)alt]?:@""];xmlFree(alt);}}
    for(xmlNodePtr child=node->children;child;child=child->next)appendText(child,out);
}
static NSString *content(xmlNodePtr node){NSMutableString *s=[NSMutableString string];appendText(node,s);return [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];}

static NSString *prop(xmlNodePtr node,const char *name){xmlChar *p=xmlGetProp(node,(const xmlChar *)name);NSString *s=p?[NSString stringWithUTF8String:(char *)p]:nil;if(p)xmlFree(p);return s;}
static NSString *first(xmlDocPtr d,xmlNodePtr n,const char *query){NSArray *a=nodes(d,n,query);return a.count?content([a[0] pointerValue]):@"";}
static NSString *accountName(xmlDocPtr doc,xmlNodePtr root){
    NSString *account=first(doc,root,"//*[contains(@class,'secondary-nav')]//*[contains(concat(' ',normalize-space(@class),' '),' username ')]");
    if(account.length)return account;
    // The account dropdown's own-profile link survives older libxml HTML repairs
    // that can move the username outside its expected navbar container.
    for(NSValue *v in nodes(doc,root,"//a[normalize-space(.)='myRipple' and @href]")){
        NSURL *url=[NSURL URLWithString:prop(v.pointerValue,"href") relativeToURL:[NSURL URLWithString:@"https://ripple.tel/"]];if(!trusted(url))continue;NSString *handle=[url.path stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/~"]];
        NSCharacterSet *invalid=[[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"]invertedSet];if(handle.length&&handle.length<=16&&[handle rangeOfCharacterFromSet:invalid].location==NSNotFound)return [@"@" stringByAppendingString:handle];
    }
    return @"";
}
static NSDictionary *loginForm(xmlDocPtr doc,xmlNodePtr root,NSURL *pageURL){
    if(!trusted(pageURL))return nil;
    for(NSValue *v in nodes(doc,root,"//form")){
        xmlNodePtr form=v.pointerValue;
        if(![[prop(form,"method") lowercaseString] isEqual:@"post"])continue;
        // Identify credentials by controls, including the standalone /login page
        // whose action is empty and which has no main-site navbar or logo.
        if(!nodes(doc,form,".//input[@name='username']").count||!nodes(doc,form,".//input[@name='password' and translate(@type,'PASSWORD','password')='password']").count)continue;
        NSString *action=prop(form,"action")?:@"";
        NSURL *target=action.length?[[NSURL URLWithString:action relativeToURL:pageURL] absoluteURL]:pageURL;
        if(!trusted(target))continue;
        NSMutableDictionary *fields=[NSMutableDictionary dictionary];
        for(NSValue *input in nodes(doc,form,".//input[@name] | .//button[@name]")){
            xmlNodePtr n=input.pointerValue;NSString *type=[prop(n,"type") lowercaseString];
            if(prop(n,"disabled"))continue;
            if([type isEqual:@"hidden"]||[type isEqual:@"submit"]||(xmlStrEqual(n->name,(xmlChar *)"button")&&(!type.length||[type isEqual:@"submit"])))fields[prop(n,"name")]=prop(n,"value")?:@"";
        }
        return @{@"action":target.absoluteString,@"hidden":fields};
    }
    return nil;
}
NSDictionary *RPParseLoginForm(NSData *data,NSURL *pageURL){
    if(!data.length||!trusted(pageURL))return nil;
    xmlDocPtr doc=htmlReadMemory(data.bytes,(int)data.length,pageURL.absoluteString.UTF8String,"UTF-8",HTML_PARSE_RECOVER|HTML_PARSE_NOERROR|HTML_PARSE_NOWARNING|HTML_PARSE_NONET);
    if(!doc)return nil;NSDictionary *form=loginForm(doc,xmlDocGetRootElement(doc),pageURL);xmlFreeDoc(doc);return form;
}
NSDictionary *RPLoginPageSummary(NSData *data,NSURL *pageURL){
    if(!data.length)return @{};
    xmlDocPtr doc=htmlReadMemory(data.bytes,(int)data.length,"https://ripple.tel/","UTF-8",HTML_PARSE_RECOVER|HTML_PARSE_NOERROR|HTML_PARSE_NOWARNING|HTML_PARSE_NONET);if(!doc)return @{};xmlNodePtr root=xmlDocGetRootElement(doc);
    NSString *message=first(doc,root,"//*[contains(concat(' ',normalize-space(@class),' '),' error ') or contains(concat(' ',normalize-space(@class),' '),' alert-error ') or contains(concat(' ',normalize-space(@class),' '),' alert-danger ')]");if(message.length>240)message=[message substringToIndex:240];
    NSDictionary *result=@{@"loginForm":@(loginForm(doc,root,pageURL)!=nil),@"composer":@(nodes(doc,root,"//form[@id='npform']").count>0),@"logoutLink":@(nodes(doc,root,"//a[contains(@href,'logout')]").count>0),@"account":@(first(doc,root,"//*[contains(@class,'secondary-nav')]//*[contains(concat(' ',normalize-space(@class),' '),' username ')]").length>0),@"message":message};xmlFreeDoc(doc);return result;
}
NSDictionary *RPParse(NSData *data){
    if(!data.length)return nil;
    xmlDocPtr doc=htmlReadMemory(data.bytes,(int)data.length,"https://ripple.tel/","UTF-8",HTML_PARSE_RECOVER|HTML_PARSE_NOERROR|HTML_PARSE_NOWARNING|HTML_PARSE_NONET);
    if(!doc)return nil;xmlNodePtr root=xmlDocGetRootElement(doc);
    if(!nodes(doc,root,"//a[contains(concat(' ',normalize-space(@class),' '),' brand ')] | //img[@alt='Ripple']").count){xmlFreeDoc(doc);return nil;}
    NSMutableArray *posts=[NSMutableArray array];
    for(NSValue *v in nodes(doc,root,"//div[contains(concat(' ',normalize-space(@class),' '),' userpost ') and starts-with(@id,'post-')]")){
        xmlNodePtr n=v.pointerValue;NSString *pid=[prop(n,"id") substringFromIndex:5];NSString *author=first(doc,n,".//*[contains(concat(' ',normalize-space(@class),' '),' displayname ')]");NSString *handle=first(doc,n,".//*[contains(concat(' ',normalize-space(@class),' '),' username ')]");
        NSMutableArray *paragraphs=[NSMutableArray array];for(NSValue *p in nodes(doc,n,".//p[not(ancestor::*[contains(@class,'hover-card')])]")){NSString *text=content(p.pointerValue);if(text.length)[paragraphs addObject:text];}
        NSString *time=first(doc,n,".//*[contains(concat(' ',normalize-space(@class),' '),' timeago ')]");
        NSMutableArray *images=[NSMutableArray array];
        for(NSValue *img in nodes(doc,n,".//img[contains(@class,'attachment')]")){NSString *src=prop(img.pointerValue,"src");if(src.length)[images addObject:src];}
        NSArray *avatars=nodes(doc,n,".//img[contains(@class,'postpfp')]");NSString *avatar=avatars.count?prop([avatars[0] pointerValue],"src"):@"";
        NSArray *actions=nodes(doc,n,".//*[contains(@class,'interactions')]//a[@href]");NSMutableDictionary *links=[NSMutableDictionary dictionary];NSMutableArray *counts=[NSMutableArray array];
        for(NSValue *link in actions){xmlNodePtr linkNode=link.pointerValue;NSString *href=prop(linkNode,"href");NSString *count=first(doc,linkNode,".//*[contains(@class,'count')]");if(count.length)[counts addObject:count];if([href rangeOfString:@"like"].location!=NSNotFound)links[@"like"]=href;if([href rangeOfString:@"repost"].location!=NSNotFound)links[@"repost"]=href;}
        [posts addObject:@{@"id":pid?:@"",@"author":author,@"handle":handle,@"text":[paragraphs componentsJoinedByString:@"\n"],@"time":time,@"avatar":avatar?:@"",@"images":images,@"actions":links,@"likes":counts.count?counts[0]:@"0",@"replies":counts.count>1?counts[1]:@"0",@"reposts":counts.count>2?counts[2]:@"0"}];

    }
    NSMutableDictionary *forms=[NSMutableDictionary dictionary];
    for(NSValue *v in nodes(doc,root,"//form")){
        xmlNodePtr n=v.pointerValue;if(![[prop(n,"method") lowercaseString] isEqual:@"post"])continue;NSString *action=prop(n,"action")?:@"";NSString *ident=prop(n,"id")?:@"";NSMutableDictionary *hidden=[NSMutableDictionary dictionary];NSString *field=@"";
        for(NSValue *input in nodes(doc,n,".//input[@name] | .//textarea[@name] | .//button[@type='submit' and @name]")){
            xmlNodePtr i=input.pointerValue;NSString *name=prop(i,"name"),*type=prop(i,"type");if([type isEqual:@"hidden"]||[type isEqual:@"submit"]||xmlStrEqual(i->name,(xmlChar *)"button"))hidden[name]=prop(i,"value")?:@"";
            if(xmlStrEqual(i->name,(xmlChar *)"textarea"))field=name;
        }
        if(([ident isEqual:@"npform"]||[ident isEqual:@"quoteForm"])&&field.length)forms[[ident isEqual:@"quoteForm"]?@"quote":@"composer"]=@{@"action":action,@"hidden":hidden,@"field":field};
    }
    NSDictionary *login=loginForm(doc,root,[NSURL URLWithString:@"https://ripple.tel/"]);if(login)forms[@"login"]=login;
    NSMutableArray *people=[NSMutableArray array];
    for(NSValue *v in nodes(doc,root,"//*[contains(concat(' ',normalize-space(@class),' '),' urow ')]//*[contains(concat(' ',normalize-space(@class),' '),' thumbnail ')]")){
      xmlNodePtr n=v.pointerValue;NSArray *links=nodes(doc,n,".//h3//a[@href]");if(!links.count)continue;xmlNodePtr a=[links[0] pointerValue];NSString *href=prop(a,"href");NSString *handle=[href hasPrefix:@"/~"]?[href substringFromIndex:2]:@"";NSArray *imgs=nodes(doc,n,".//img[@src]");[people addObject:@{@"name":content(a),@"handle":handle,@"avatar":imgs.count?prop([imgs[0] pointerValue],"src"):@""}];
    }
    NSString *account=accountName(doc,root);
    BOOL older=nodes(doc,root,"//a[contains(.,'Older') and contains(@href,'pageno=')] | //li[contains(concat(' ',normalize-space(@class),' '),' next ') and not(contains(@class,'disabled'))]/a[contains(@href,'pageno=')]").count>0;
    NSDictionary *result=@{@"posts":posts,@"people":people,@"forms":forms,@"account":account,@"older":@(older)};xmlFreeDoc(doc);return result;
}
