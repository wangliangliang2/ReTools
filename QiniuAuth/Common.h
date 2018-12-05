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


@interface Common : NSObject

void HookMethod(Class _Nonnull originalClass , SEL _Nonnull originalSelector, Class _Nonnull swizzledClass, SEL _Nonnull swizzledSelector);

void HookClassMethod(Class _Nonnull originalClass, SEL _Nonnull originalSelector, Class _Nonnull swizzledClass, SEL _Nonnull swizzledSelector);

void DispactchSetSpecific(dispatch_queue_t _Nonnull queue, const void * _Nonnull key);

void DispatchSync(dispatch_queue_t _Nonnull queue , const void * _Nonnull key, dispatch_block_t _Nonnull block);

void DispatchAsync(dispatch_queue_t _Nonnull queue, const void * _Nonnull key, dispatch_block_t _Nonnull block);

+ (void)TransportWithURLString:(NSString * _Nonnull)urlString Info:(NSDictionary * _Nullable)info useQiniuAuth:(BOOL)useAuth IsSync:(BOOL)isSync CallBack:(void (^_Null_unspecified)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))callback;

@end

@interface NSString (Base64)
- (NSString * _Nonnull)base64EncodedString;

- (NSString * _Nonnull)base64DecodedString;

- (NSString * _Nonnull)base64UrlSafeEncodedString;

- (NSString * _Nonnull)base64UrlSafeDecodedString;

- (NSString * _Nonnull)base64ToUrlSafe;

- (NSString * _Nonnull)hmac_SHA1WithSecretKey:(NSString * _Nonnull)encryptKey;
- (NSString *_Nonnull)timeStringConvertTodateString;
@end

@interface NSMutableURLRequest (QiniuAuth)

- (void)qiniuAuthV2ByTitle:(NSString * _Nullable)title AccessKey:(NSString * _Nonnull)accessKey AndSecretKey:(NSString * _Nonnull)secretKey;
- (void)qiniuAuthV1ByTitle:(NSString * _Nullable)title AccessKey:(NSString * _Nonnull)accessKey AndSecretKey:(NSString * _Nonnull)secretKey;

@end
