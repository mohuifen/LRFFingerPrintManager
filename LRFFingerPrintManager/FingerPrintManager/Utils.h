//
//  Utils.h
//  LRFFingerPrintManager
//
//  Created by LRF on 15/9/16.
//  Copyright (c) 2015年 LRF. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface Utils : NSObject

/**
 *  弹出警告框
 *
 *  @param msg         警告的信息
 *  @param buttonTitle 确定按钮的 title
 */
void showAlertWithMsg(NSString * msg,  NSString *buttonTitle);

/**
 *  查找一段字符串中的第一个数字
 *
 *  @param string 字符串
 *
 *  @return 数字
 */
+ (int)findNumFromStr:(NSString *)string;

/**
 *  判断设备系统版本号是否大于version
 *
 *  @param version 被比较的版本号
 *
 *  @return 系统版本号是否大于version
 */
+ (BOOL)isSystemVersionMoreThanVersion:(CGFloat)version;


/**
 *  获得设备类型字符串
 *
 *  @return 设备类型字符串
 */
+ (NSString *)getCurrentDeviceModel;

/**
 *  判断设备是否支持TouchID
 *
 *  @return 设备是否支持TouchID
 */
+ (BOOL)isSystemModelSupportTouchID;

@end
