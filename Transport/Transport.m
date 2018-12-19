//
//  Transport.m
//  robot
//
//  Created by Anonymous on 12/6/18.
//  Copyright © 2018 Anonymous. All rights reserved.
//

#import "Transport.h"

@implementation Transport

+ (void)transportRequest:(NSMutableURLRequest *)request sync:(BOOL)sync completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler{
    
    dispatch_semaphore_t signal;
    if (sync) {
        signal = dispatch_semaphore_create(0);
    }
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (completionHandler) {
            completionHandler(data,response,error);
        }
        if (sync) {
            dispatch_semaphore_signal(signal);
        }
    }] resume];
    
    if (sync) {
        dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
    }
    
}

@end
