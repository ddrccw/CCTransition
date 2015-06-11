//
//  Helper.m
//  CCTransition
//
//  Created by ddrccw on 15/6/8.
//  Copyright (c) 2015年 netease. All rights reserved.
//

#import "Helper.h"

@implementation Helper

+ (BOOL)isEqualOrGreaterThanIOS7 {
    return ([IOS_VERSION floatValue] >= 7.0) ? YES : NO;
}

@end

@implementation NSString (Utility)

+ (BOOL)isNilOrEmptyForString:(NSString *)aString {
    if ([aString isEqual:[NSNull null]] || !aString || !aString.length) {
        return YES;
    }
    return NO;
}

@end
