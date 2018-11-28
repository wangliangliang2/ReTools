//
//  Common.m
//  robot
//
//  Created by Anonymous on 11/15/18.
//  Copyright © 2018 Anonymous. All rights reserved.
//


#import <CommonCrypto/CommonHMAC.h>
#import "Common.h"

#define ACCESS_KEY @"填写自己的公钥"
#define SECRET_KEY @"填写自己的秘钥"


@implementation Common


void HookMethod(Class originalClass, SEL originalSelector, Class swizzledClass, SEL swizzledSelector) {
    Method originalMethod = class_getInstanceMethod(originalClass, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(swizzledClass, swizzledSelector);
    if(originalMethod && swizzledMethod) {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}


void HookClassMethod(Class originalClass, SEL originalSelector, Class swizzledClass, SEL swizzledSelector) {
    Method originalMethod = class_getClassMethod(originalClass, originalSelector);
    Method swizzledMethod = class_getClassMethod(swizzledClass, swizzledSelector);
    if(originalMethod && swizzledMethod) {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}



void DispactchSetSpecific(dispatch_queue_t queue, const void *key) {
    CFStringRef context = CFSTR("context");
    dispatch_queue_set_specific(queue,
                                key,
                                (void*)context,
                                (dispatch_function_t)CFRelease);
}

void DispatchSync(dispatch_queue_t queue, const void *key, dispatch_block_t block) {
    CFStringRef context = (CFStringRef)dispatch_get_specific(key);
    if (context) {
        block();
    } else {
        dispatch_sync(queue, block);
    }
}

void DispatchAsync(dispatch_queue_t queue, const void *key, dispatch_block_t block) {
    CFStringRef context = (CFStringRef)dispatch_get_specific(key);
    if (context) {
        block();
    } else {
        dispatch_async(queue, block);
    }
}

+ (void)TransportWithURLString:(NSString *_Nonnull)urlString Info:(NSDictionary *_Nullable)info useQiniuAuth:(BOOL)useAuth IsSync:(BOOL)isSync CallBack:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))callback{
    
    dispatch_semaphore_t signal;
    
    if (isSync) {
        signal = dispatch_semaphore_create(0);
    }
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10.0];
    
    if (info) {
        NSData *postData = [NSJSONSerialization dataWithJSONObject:info options:NSJSONWritingPrettyPrinted error:NULL];
        request.HTTPBody = postData;
        request.allHTTPHeaderFields = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"application/json",@"Content-Type", nil];
    }
    
    /*
     依据实际需求自己更改 [HTTPMethod]，这里只是因为我这边项目服务端被某个人强行设置为 PUT 才允许接受
     */
    request.HTTPMethod = @"PUT";
    
    
    
    if (useAuth){
        [request qiniuAuthV2ByAccessKey:ACCESS_KEY AndSecretKey:SECRET_KEY];
    }
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
       
        callback(data,response,error);
        
        if (isSync) {
            dispatch_semaphore_signal(signal);
        }
        
    }] resume];
    
    if (isSync) {
        dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
    }
}

@end


@implementation NSString (Base64)

- (NSString *)base64EncodedString
{
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    return [data base64EncodedStringWithOptions:0];
}

- (NSString *)base64DecodedString
{
    NSData *data = [[NSData alloc]initWithBase64EncodedString:self options:0];
    return [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
}

- (NSString *)base64UrlSafeEncodedString
{
    NSString *base64EncodedString = [self base64EncodedString];
    
    return [[base64EncodedString stringByReplacingOccurrencesOfString:@"/" withString:@"_"] stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
}

- (NSString *)base64UrlSafeDecodedString
{
    NSString *base64encodeString = [[self stringByReplacingOccurrencesOfString:@"_" withString:@"/"] stringByReplacingOccurrencesOfString:@"-" withString:@"+"];
    
    return [base64encodeString base64DecodedString];
}

- (NSString *)base64ToUrlSafe
{
    return [[self stringByReplacingOccurrencesOfString:@"/" withString:@"_"] stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
}

- (NSString *)hmac_SHA1WithSecretKey:(NSString *)encryptKey {
    
    const char *cKey = [encryptKey cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [self cStringUsingEncoding:NSASCIIStringEncoding];
    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    NSData *hash = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
    
    NSString *encodeSign = [[hash base64EncodedStringWithOptions:0] base64ToUrlSafe];

    return encodeSign;
}

@end


@implementation NSMutableURLRequest (QiniuAuth)

- (void)qiniuAuthV2ByAccessKey:(NSString *)accessKey AndSecretKey:(NSString *)secretKey {
    
    NSMutableString *rawString = [NSMutableString stringWithFormat:@"%@ %@",self.HTTPMethod,self.URL.path];

    if (self.URL.query && ![self.URL.query isEqualToString:@""]) {
        [rawString appendFormat:@"?%@",self.URL.query];
    }
    [rawString appendFormat:@"\nHost: %@",self.URL.host];
    
    if (self.URL.port) {
        [rawString appendFormat:@":%@",self.URL.port];
    }

    NSString *contentType =  self.allHTTPHeaderFields[@"Content-Type"];
    if (contentType && ![contentType isEqualToString:@""]){
        [rawString appendFormat:@"\nContent-Type: %@",contentType];
    }
    
    [rawString appendString:@"\n\n"];
    
    if (self.HTTPBody && contentType && ([contentType isEqualToString:@"application/x-www-form-urlencoded"] || [contentType isEqualToString:@"application/json"])){
        
        NSMutableString *bodyString = [[NSMutableString alloc] initWithData:self.HTTPBody encoding:NSUTF8StringEncoding];

        [rawString appendString:bodyString];
        
    }
    
    NSString *encodeSign = [rawString hmac_SHA1WithSecretKey:secretKey];
    
    NSMutableDictionary *headers =[NSMutableDictionary dictionaryWithDictionary:self.allHTTPHeaderFields];
    [headers setObject:[NSString stringWithFormat:@"Qiniu %@:%@",accessKey,encodeSign] forKey:@"Authorization"];
    self.allHTTPHeaderFields = headers;
    
}

@end









