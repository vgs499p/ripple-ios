// SPDX-License-Identifier: GPL-2.0-or-later
#import "RPSession.h"
#import <Security/Security.h>
static NSDictionary *query(NSString *service){return @{(__bridge id)kSecClass:(__bridge id)kSecClassGenericPassword,(__bridge id)kSecAttrService:service,(__bridge id)kSecAttrAccount:@"ripple.tel"};}
static BOOL result(OSStatus status,NSError **error){if(status==errSecSuccess)return YES;if(error)*error=[NSError errorWithDomain:@"RippleKeychain" code:status userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Keychain could not save or restore your sign-in (error %ld). Unlock the device and try again.",(long)status]}];return NO;}
NSData *RPSessionRead(NSString *service,NSError **error){
 NSMutableDictionary *q=[query(service)mutableCopy];q[(__bridge id)kSecReturnData]=@YES;q[(__bridge id)kSecMatchLimit]=(__bridge id)kSecMatchLimitOne;
 CFTypeRef value=NULL;OSStatus status=SecItemCopyMatching((__bridge CFDictionaryRef)q,&value);if(status==errSecItemNotFound)return nil;if(!result(status,error))return nil;return CFBridgingRelease(value);
}
BOOL RPSessionWrite(NSString *service,NSData *data,NSError **error){
 NSDictionary *attributes=@{(__bridge id)kSecValueData:data,(__bridge id)kSecAttrAccessible:(__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly};
 OSStatus status=SecItemUpdate((__bridge CFDictionaryRef)query(service),(__bridge CFDictionaryRef)attributes);
 if(status==errSecItemNotFound){NSMutableDictionary *item=[query(service)mutableCopy];[item addEntriesFromDictionary:attributes];status=SecItemAdd((__bridge CFDictionaryRef)item,NULL);}return result(status,error);
}
BOOL RPSessionDelete(NSString *service,NSError **error){OSStatus status=SecItemDelete((__bridge CFDictionaryRef)query(service));return status==errSecItemNotFound?YES:result(status,error);}
