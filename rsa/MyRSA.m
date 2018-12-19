//
//  MyRSA.m
//  robot
//
//  Created by Anonymous on 12/13/18.
//  Copyright © 2018 Anonymous. All rights reserved.
//

#import "MyRSA.h"
#import <openssl/rsa.h>
#import <openssl/pem.h>

@interface MyRSA ()

@property (nonatomic,assign) RSA *rsaPublic;
@end
@implementation MyRSA

+ (instancetype)sharedInstance  {
    static MyRSA *rsa = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        rsa = [[MyRSA alloc] init];
        [rsa setPublicKeyOfPEMFormat];
    });
    return rsa;
}

- (void)setPublicKeyOfPEMFormat
{
    NSString *publicKey = @"-----BEGIN PUBLIC KEY-----\n"
    "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCuGl1VVikFfttFM2+wqt9Bv7vC\n"
    "-----END PUBLIC KEY-----";
    NSData *publicData = [publicKey dataUsingEncoding:NSUTF8StringEncoding];
    
    BIO *publicBio = BIO_new_mem_buf((void *)publicData.bytes, (int)publicData.length);
    PEM_read_bio_RSA_PUBKEY(publicBio, &_rsaPublic, NULL, NULL);
    
    BIO_free_all(publicBio);
}



- (NSData *)decryptCipherDataWithPublicKeyUsingPKCS1:(NSData *)cipherData
{
    
    return [self rsaProcessingData:cipherData WithEncode:NO];
    
    
}

- (NSData *)encryptDataWithPublicKeyUsingPKCS1:(NSData *)plainData
{
    
    return [self rsaProcessingData:plainData WithEncode:YES];
    
}


- (NSData *)rsaProcessingData:(NSData *)data WithEncode:(BOOL)isEncode{
    int dataLen = (int)data.length;
    int keylen = RSA_size(_rsaPublic);
    int blocklen;
    int proceedlen;
    if (isEncode) {
        blocklen = keylen - 11;
        proceedlen = keylen;
    }else {
        blocklen = keylen;
        proceedlen = keylen - 11;
    }
    
    int blockCount = (int)ceil((double)dataLen/blocklen);
    NSMutableData *mutableData = [NSMutableData data];
    for (int i = 0; i < blockCount; i++) {
        int loc = i * blocklen;
        int curentlen = MIN(blocklen, dataLen - loc);
        NSData *sebData = [data subdataWithRange:NSMakeRange(loc, curentlen)];
        NSMutableData *buffer = [NSMutableData dataWithLength:(NSUInteger)blocklen];
        if (isEncode) {
            RSA_public_encrypt(curentlen, sebData.bytes, buffer.mutableBytes, _rsaPublic,  RSA_PKCS1_PADDING);
        }else {
            RSA_public_decrypt(curentlen, sebData.bytes, buffer.mutableBytes, _rsaPublic, RSA_PKCS1_PADDING);
        }
        NSData *processedData = [[NSData alloc] initWithBytes:buffer.mutableBytes length:proceedlen];
        if (processedData) {
            [mutableData appendData:processedData];
        }
    }
    if (!isEncode) {
        /*
         出去最后的 0000 数据
         */
        NSData *trimData= [[NSString stringWithUTF8String:[mutableData bytes]] dataUsingEncoding:NSUTF8StringEncoding];
        mutableData = [NSMutableData dataWithData:trimData];
    }
    return [mutableData mutableCopy];
}




- (void)dealloc
{
    if (_rsaPublic) {
        RSA_free(_rsaPublic);
    }
}


@end
