//
//  Header.h
//  surge
//
//  Created by anonymous on 2019/2/20.
//  Copyright © 2019 anonymous. All rights reserved.
//

#ifndef Header_h
#define Header_h

#import <Foundation/Foundation.h>
#import <objc/objc-runtime.h>

void hookMethod(Class originalClass, SEL originalSelector, Class swizzledClass, SEL swizzledSelector) {
    Method originalMethod = class_getInstanceMethod(originalClass, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(swizzledClass, swizzledSelector);

        BOOL didAddMethod =class_addMethod(originalClass,
                        swizzledSelector,
                        method_getImplementation(originalMethod),
                        method_getTypeEncoding(originalMethod));
        if (didAddMethod) {
        class_replaceMethod(originalClass,
                            originalSelector,
                            method_getImplementation(swizzledMethod),
                            method_getTypeEncoding(swizzledMethod));
        }else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }

}

void hookClassMethod(Class originalClass, SEL originalSelector, Class swizzledClass, SEL swizzledSelector) {
    Method originalMethod = class_getClassMethod(originalClass, originalSelector);
    Method swizzledMethod = class_getClassMethod(swizzledClass, swizzledSelector);
    
    method_exchangeImplementations(originalMethod, swizzledMethod);

}
#endif /* Header_h */
