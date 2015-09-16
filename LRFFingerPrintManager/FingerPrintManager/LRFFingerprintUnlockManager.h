//
//  LRFFingerprintUnlockManager.h
//  BigHuobi
//
//  Created by LRF on 15/9/2.
//  Copyright (c) 2015年 LRF. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  指纹解锁
 */
@interface LRFFingerprintUnlockManager : NSObject

@property (assign, nonatomic)BOOL isOpenedFingerprint;///< 设置中是否打开指纹验证，yes：开启，no：关闭

@property (assign, nonatomic)BOOL isShowEnterPasswordButton;///< 是否显示输入密码的button


/**
 *  单例
 *
 *  @return 返回该单一实例
 */
+ (instancetype)sharedManager;

/**
 *  判断设备是否支持指纹，如果没有录入指纹或未开启设备密码，返回YES
 *
 *  @return 设备是否支持指纹，yes，支持，no，不支持
 */
- (BOOL)isDeviceSupportTouchId;

/**
 *  判断指纹解锁是否可用，如果没有录入指纹或未开启设备密码则不可用,返回No
 *
 *  @return 指纹解锁是否可用，yes，可用，no，不可用
 */
- (BOOL)isTouchIdAvailable;


/**
 *  使用指纹解锁，若设置中关闭了该功能，则不验证，直接走验证成功方法块，若打开了，则调用下面的验证指纹解锁方法
 *
 *  @param unAvailableBlock 指纹解锁不可用时执行的代码块
 *  @param successBlock     指纹解锁成功后执行的代码块
 *  @param failuesBlock     指纹解锁失败时执行的代码块
 *  @param enterPasswordBlock 输入密码执行的代码块
 */
- (void)useTouchIdWithUnAvailable:(void (^)(NSString *str))unAvailableBlock
                       andSuccess:(void (^)(NSString *str))successBlock
                       andFailues:(void (^)(NSString *str))failuesBlock
                 andEnterPassword:(void (^)(NSString *str))enterPasswordBlock;


/**
 *  验证指纹解锁，主要用于设置页面的验证指纹的开关切换
 *
 *  @param unAvailableBloick 指纹解锁不可用时执行的代码块
 *  @param successBloick     指纹解锁成功后执行的代码块
 *  @param failuesBloick     指纹解锁失败时执行的代码块
 *  @param enterPasswordBlock 输入密码执行的代码块
 */
- (void)verificationTouchIdWithUnAvailable:(void (^)(NSString *str))unAvailableBlock
                                andSuccess:(void (^)(NSString *str))successBlock
                                andFailues:(void (^)(NSString *str))failuesBlock
                          andEnterPassword:(void (^)(NSString *str))enterPasswordBlock;
@end
