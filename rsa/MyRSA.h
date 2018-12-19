//
//  MyRSA.h
//  robot
//
//  Created by Anonymous on 12/13/18.
//  Copyright © 2018 Anonymous. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MyRSA : NSObject
+ (instancetype)sharedInstance;
- (NSData *)decryptCipherDataWithPublicKeyUsingPKCS1:(NSData *)cipherData;
- (NSData *)encryptDataWithPublicKeyUsingPKCS1:(NSData *)data;
@end
