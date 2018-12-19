//
//  Common.h
//  robot
//
//  Created by Anonymous on 11/15/18.
//  Copyright © 2018 Anonymous. All rights reserved.
//
/*
 这个类主要提供 一些 公用 东西
 */
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface NSDate (Utilities)

- (NSString *_Nullable)translateToString;

@end

@interface NSData (Utilities)
- (NSData *_Nullable)encryptWithRSA;
- (NSData *_Nullable)decryptWithRSA;
- (NSString *_Nullable)translateToString;

@end

@interface NSString (Utilities)
- (NSString * _Nonnull)base64EncodedString;

- (NSString * _Nonnull)base64DecodedString;

- (NSString * _Nonnull)base64UrlSafeEncodedString;

- (NSString * _Nonnull)base64UrlSafeDecodedString;

- (NSString * _Nonnull)base64ToUrlSafe;
- (NSString *_Nonnull)urlSafeTobase64;
- (NSString * _Nonnull)hmac_SHA1WithSecretKey:(NSString * _Nonnull)encryptKey;
- (NSString *_Nonnull)timeStringConvertTodateString;
- (BOOL)isBlankString;
- (BOOL)isNumber;
@end

@interface NSMutableURLRequest (Utilities)

- (void)qiniuAuthV2ByTitle:(NSString * _Nonnull)title AccessKey:(NSString *_Nonnull)accessKey AndSecretKey:(NSString *_Nonnull)secretKey;
- (void)qiniuAuthV1ByTitle:(NSString * _Nonnull)title AccessKey:(NSString *_Nonnull)accessKey AndSecretKey:(NSString *_Nonnull)secretKey;

+ (instancetype _Nonnull)requestWithHttpMethod:(NSString *_Nullable)method urlString:(NSString *_Nonnull)urlString body:(NSDictionary *_Nullable)body encrypt:(BOOL)encrypt;

+ (instancetype _Nonnull)requestsetQiniuSyncFetchHeaders:(NSArray *_Nullable)headers;
+ (instancetype _Nonnull)requestWithFetchURLString:(NSString *_Nonnull)urlString saveKey:(NSString *_Nullable)key headers:(NSDictionary *_Nullable)headers;

+ (instancetype _Nonnull)requestWithHeaders:(NSArray *_Nullable)headers bucket:(NSString *_Nonnull)bucket accessKey:(NSString *_Nonnull)accessKey secretKey:(NSString *_Nonnull)secretKey;
+ (instancetype _Nonnull)requestSyncFetchWebAssetWithURLString:(NSString *_Nonnull)urlString headers:(NSDictionary *_Nullable)headers saveKey:(NSString *_Nullable)key bucket:(NSString *_Nonnull)bucket zoneOfBucket:(NSString*_Nonnull)zone accessKey:(NSString *_Nonnull)accessKey secretKey:(NSString *_Nonnull)secretKey;
@end
