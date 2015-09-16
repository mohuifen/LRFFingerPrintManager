//
//  NSUserDefaults+Helper.h
//  BigHuobi
//
//  Created by LRF on 15/8/21.
//  Copyright (c) 2015年 Huobi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSUserDefaults (Helper)

- (void)setValue:(NSObject *)value
                      forKey:(NSString *)key
            withDefaultValue:(NSObject *)defaultValue;
@end
