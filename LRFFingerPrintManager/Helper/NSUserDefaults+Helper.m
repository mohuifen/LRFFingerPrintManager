//
//  NSUserDefaults+Helper.m
//  BigHuobi
//
//  Created by LRF on 15/8/21.
//  Copyright (c) 2015年 Huobi. All rights reserved.
//

#import "NSUserDefaults+Helper.h"

@implementation NSUserDefaults (Helper)

/**
 *  NSUserDefaults 设置键值，在未保存过数据时设置默认的值
 *
 *  @param value        需要设置的value
 *  @param key          key
 *  @param defaultValue 默认值
 */
- (void)setValue:(NSObject *)value
                      forKey:(NSString *)key
            withDefaultValue:(NSObject *)defaultValue {
    
    if (![self valueForKey:key]) {
        [self setValue:defaultValue forKey:key];
        [[NSUserDefaults standardUserDefaults] synchronize];
        return;
    }
    if (value) {
        [self setValue:value forKey:key];
        [[NSUserDefaults standardUserDefaults] synchronize];
        return;
    }
}

@end
