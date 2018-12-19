//
//  Transport.h
//  robot
//
//  Created by Anonymous on 12/6/18.
//  Copyright © 2018 Anonymous. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Transport : NSObject
+ (void)transportRequest:(NSMutableURLRequest *_Nullable)request sync:(BOOL)sync completionHandler:(void (^_Nullable)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler;
@end
