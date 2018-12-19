//
//  Common.m
//  robot
//
//  Created by Anonymous on 11/15/18.
//  Copyright © 2018 Anonymous. All rights reserved.
//


#import <CommonCrypto/CommonHMAC.h>
#import "Utilities.h"
#import "MyRSA.h"
@implementation NSData (Utilities)

- (NSString *)translateToString{
    return [[NSString  alloc] initWithData:self encoding:NSUTF8StringEncoding];
}

- (NSData *)encryptWithRSA{
    
    return [[[MyRSA sharedInstance] encryptDataWithPublicKeyUsingPKCS1:self] base64UrlSafeEncoded];
}

- (NSData *)decryptWithRSA{
    
    NSData *rawData = [[NSData alloc]initWithBase64EncodedString:[[self translateToString] urlSafeTobase64] options:0];
    return [[MyRSA sharedInstance] decryptCipherDataWithPublicKeyUsingPKCS1:rawData];
}

- (NSString *)base64Encoded{
    return [self base64EncodedStringWithOptions:0];
}

- (NSData *)base64UrlSafeEncoded{
    
    return [[[self base64Encoded] base64ToUrlSafe] dataUsingEncoding:NSUTF8StringEncoding];
}

@end

@implementation NSDate (Utilities)

- (NSString *)translateToString{
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    return [dateFormatter stringFromDate:self];
    
}


@end


@implementation NSString (Utilities)

- (NSString *)base64EncodedString
{
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    return [data base64Encoded];
}

- (NSString *)base64DecodedString
{
    NSData *data = [[NSData alloc]initWithBase64EncodedString:self options:0];
    return [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
}

- (NSString *)base64UrlSafeEncodedString
{
    
    return [[self base64EncodedString] base64ToUrlSafe];
}

- (NSString *)base64UrlSafeDecodedString
{
    
    return [[self urlSafeTobase64] base64DecodedString];
}

- (NSString *)urlSafeTobase64
{
    return [[self stringByReplacingOccurrencesOfString:@"_" withString:@"/"] stringByReplacingOccurrencesOfString:@"-" withString:@"+"];
}

- (NSString *)base64ToUrlSafe
{
    return [[self stringByReplacingOccurrencesOfString:@"/" withString:@"_"] stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
}

- (NSString *)hmac_SHA1WithSecretKey:(NSString *)encryptKey {
    
    const char *cKey = [encryptKey cStringUsingEncoding:NSUTF8StringEncoding];
    const char *cData = [self cStringUsingEncoding:NSUTF8StringEncoding];
    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    NSData *hash = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
    
    NSString *encodeSign = [[hash base64EncodedStringWithOptions:0] base64ToUrlSafe];
    
    return encodeSign;
}

- (NSString *)timeStringConvertTodateString{
    NSTimeInterval time=[self doubleValue];
    NSDate *detailDate=[NSDate dateWithTimeIntervalSince1970:time];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *currentDateStr = [dateFormatter stringFromDate: detailDate];
    return currentDateStr;
}

- (BOOL)isBlankString {
    NSCharacterSet *set = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *trimmedStr = [self stringByTrimmingCharactersInSet:set];
    if (!trimmedStr.length) {
        return YES;
    }
    return NO;
}

- (BOOL)isNumber {
    NSString * tmp = [self stringByTrimmingCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]];
    if(tmp.length > 0) {
        return NO;
    }
    return YES;
}


@end


@implementation NSMutableURLRequest (Utilities)

/*
 专门用于传输到 robot 服务器的 request
 */
+ (instancetype)requestWithHttpMethod:(NSString *)method urlString:(NSString *)urlString body:(NSDictionary *_Nullable)body encrypt:(BOOL)encrypt{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10.0];
    
    if (body) {
        NSError *error = nil;
        NSData *postData = [NSJSONSerialization dataWithJSONObject:body options:NSJSONWritingPrettyPrinted error:&error];
        if (error) {
            NSLog(@"requestWithURLString:%@",error);
        }
        if (encrypt) {
            postData = [postData encryptWithRSA];
        }
        request.HTTPBody = postData;
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    }
    if (!method||[method isBlankString]) {
        method = @"PUT";
    }
    request.HTTPMethod = method;
    [request qiniuAuthV2ByTitle:@"Qiniu" AccessKey:ROBOT_ACCESS_KEY AndSecretKey:ROBOT_SECRET_KEY];
    return request;
}

/*
 专门用于 qqrobot bucket 设置回源请求
 */
+ (instancetype)requestsetQiniuSyncFetchHeaders:(NSArray *)headers{
    
    return [self requestWithHeaders:headers bucket:BUCKET accessKey:ACCESS_KEY secretKey:SECRET_KEY];
}

/*
 设置同步请求回源携带头部, headers 等于 nil 时候 重置
 针对空间的配置，只要不改就一直生效。
 所以一般不会使用了。放这里仅仅是防止以后有可能需要改动
 
 */
+ (instancetype)requestWithHeaders:(NSArray *)headers bucket:(NSString *)bucket accessKey:(NSString *)accessKey secretKey:(NSString *)secretKey{
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://uc.qbox.me/passFetchHeaders"] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:3];

    if (!headers) {
        headers = [NSArray array];
    }
    
    NSDictionary *body =  [NSDictionary dictionaryWithObjectsAndKeys:bucket,@"bucket",headers,@"headers", nil];

    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:NSJSONWritingPrettyPrinted error:NULL];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    [request qiniuAuthV2ByTitle:@"Qiniu" AccessKey:accessKey AndSecretKey:secretKey];

    return request;
}

/*
 专门用于 qqrobot 同步 fetch
*/

+ (instancetype)requestWithFetchURLString:(NSString *)urlString saveKey:(NSString *)key headers:(NSDictionary *)headers{
    
    return [self requestSyncFetchWebAssetWithURLString:urlString headers:headers saveKey:key bucket:TSWORK_QQROBOT_BUCKET zoneOfBucket:@"z0" accessKey:TSWORK_ACCESS_KEY secretKey:TSWORK__SECRET_KEY];
}


/*
 POST /glb/fetch/<EncodedURL>/to/<EncodedEntryURI>
 Host: iovip.qbox.me
 <EncodedEntryURI> 为 <bucket>:<GlobalKey>或者<bucket> 的 urlsafe base64 编码的目标位置，GlobalKey由<Region>/<Key>组成，该Region必须是io所在区域, EncodedEntryURI 为bucket的时，返回的key是 region/hash
 <EncodedURL> 为 urlsafe base64 编码的源 url
 */
+ (instancetype)requestSyncFetchWebAssetWithURLString:(NSString *)urlString headers:(NSDictionary *)headers saveKey:(NSString *)key bucket:(NSString *)bucket zoneOfBucket:(NSString*)zone accessKey:(NSString *)accessKey secretKey:(NSString *)secretKey{
    
    NSString *encodeURL = [urlString base64UrlSafeEncodedString];

    NSString *encodedEntryURI = [[NSString stringWithFormat:@"%@:%@/%@",bucket,zone,key] base64UrlSafeEncodedString];

    NSString *url = [NSString stringWithFormat:@"https://iovip.qbox.me/glb/fetch/%@/to/%@",encodeURL,encodedEntryURI];
    
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:200.0];
    if (headers) {
        request.allHTTPHeaderFields = headers;
    }
    
    request.HTTPMethod = @"POST";
    
    [request qiniuAuthV1ByTitle:@"QBox" AccessKey:accessKey AndSecretKey:secretKey];

    return request;
}





- (void)qiniuAuthV2ByTitle:(NSString * )title AccessKey:(NSString *)accessKey AndSecretKey:(NSString *)secretKey {
    NSMutableString *rawString = [NSMutableString stringWithFormat:@"%@ %@",self.HTTPMethod,self.URL.path];
    
    if (self.URL.query && ![self.URL.query isEqualToString:@""]) {
        [rawString appendFormat:@"?%@",self.URL.query];
    }
    [rawString appendFormat:@"\nHost: %@",self.URL.host];
    
    if (self.URL.port) {
        [rawString appendFormat:@":%@",self.URL.port];
    }
    
    NSString *contentType =  [self valueForHTTPHeaderField:@"Content-Type"];
    
    if (contentType && ![contentType isEqualToString:@""]){
        [rawString appendFormat:@"\nContent-Type: %@",contentType];
    }
    
    [rawString appendString:@"\n\n"];
    
    if (self.HTTPBody && contentType && ([contentType isEqualToString:@"application/x-www-form-urlencoded"] || [contentType isEqualToString:@"application/json"])){
        
        NSMutableString *bodyString = [[NSMutableString alloc] initWithData:self.HTTPBody encoding:NSUTF8StringEncoding];
        
        [rawString appendString:bodyString];
        
    }
    
    NSString *encodeSign = [rawString hmac_SHA1WithSecretKey:secretKey];
    
    [self setValue:[NSString stringWithFormat:@"%@ %@:%@",title,accessKey,encodeSign] forHTTPHeaderField:@"Authorization"];
    
}


- (void)qiniuAuthV1ByTitle:(NSString *)title AccessKey:(NSString *)accessKey AndSecretKey:(NSString *)secretKey {
    
    NSMutableString *rawString = [NSMutableString stringWithFormat:@"%@",self.URL.path];
    
    
    if (self.URL.query && ![self.URL.query isEqualToString:@""]) {
        [rawString appendFormat:@"?%@",self.URL.query];
    }
    [rawString appendString:@"\n"];
    
    NSString *contentType =  [self valueForHTTPHeaderField:@"Content-Type"];
    if (self.HTTPBody && contentType && [contentType isEqualToString:@"application/x-www-form-urlencoded"]){
        
        NSMutableString *bodyString = [[NSMutableString alloc] initWithData:self.HTTPBody encoding:NSUTF8StringEncoding];
        
        [rawString appendString:bodyString];
        
    }
    
    NSString *encodeSign = [rawString hmac_SHA1WithSecretKey:secretKey];
    

    [self setValue:[NSString stringWithFormat:@"%@ %@:%@",title,accessKey,encodeSign] forHTTPHeaderField:@"Authorization"];
    
}

@end






