//
//  HBFingerprintUnlockManager.m
//  BigHuobi
//
//  Created by LRF on 15/9/2.
//  Copyright (c) 2015年 LRF. All rights reserved.
//

#import "LRFFingerprintUnlockManager.h"

#import <LocalAuthentication/LocalAuthentication.h>

#import "NSUserDefaults+Helper.h"

#import "Utils.h"

#import "AppDelegate.h"



@implementation LRFFingerprintUnlockManager

// 默认在设置页面是否打开使用指纹解锁
#define DefaultIsOpenedFingerprint  1


static LRFFingerprintUnlockManager *fingerPrintUnlockManager = nil;


#pragma mark - SharedManager


+ (instancetype)sharedManager {
    @synchronized(self) {
        if (!fingerPrintUnlockManager) {
            fingerPrintUnlockManager = [[self alloc] init];
            
            // 添加指纹解锁开关改变状态的KVO
            [fingerPrintUnlockManager addObserver:fingerPrintUnlockManager forKeyPath:@"isNeedFingerprint" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
        }
        fingerPrintUnlockManager.isOpenedFingerprint = [fingerPrintUnlockManager getIsOpenedFingerPrintFromUserDefaults];
    }
    return fingerPrintUnlockManager;
}

#pragma mark - KVO

/**
 *  KVO 监听 isNeedFingerprint 值的改变
 *
 *  @param keyPath key
 *  @param object  NSObject
 *  @param change  改变的信息，包括旧值和新值
 *  @param context 内容，NULL
 */
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    [[NSUserDefaults standardUserDefaults] setValue:[change objectForKey:NSKeyValueChangeNewKey] forKey:[self isOpenedFingerprintKey] withDefaultValue:nil];
}

#pragma mark -  IsOpenedFingerprint

/**
 *  NSUserDefaults  存储是否开启指纹密码的值的key
 *
 *  @return key
 */
- (NSString *)isOpenedFingerprintKey {
    return @"isOpenedFingerprintKey";
}

/**
 *  从 NSUserDefaults 中读取之前设置的是否开启指纹密码的值，若无，则设置默认开启
 *
 *  @return 是否已开启指纹密码
 */
- (BOOL)getIsOpenedFingerPrintFromUserDefaults {
    NSString  *key = [self isOpenedFingerprintKey];
    NSNumber * needFingerPrintNum = [[NSUserDefaults standardUserDefaults] valueForKey:key];
    if (needFingerPrintNum == nil) {
        [self setDefaultIsOpenedFingerprint:DefaultIsOpenedFingerprint];
    }
    needFingerPrintNum = [[NSUserDefaults standardUserDefaults] valueForKey:key];
    return needFingerPrintNum.boolValue;
}
/**
 *  设置默认的在设置中是否打开使用 指纹解锁
 *
 *  @param isOpenedFingerprint
 */
- (void)setDefaultIsOpenedFingerprint:(BOOL)isOpenedFingerprint {
    [[NSUserDefaults standardUserDefaults] setValue:nil forKey:[self isOpenedFingerprintKey] withDefaultValue:@(isOpenedFingerprint)];
}

#pragma mark - TouchId Available

- (BOOL)isTouchIdAvailable
{
    LAContext *context = [LAContext new];
    NSError *error = [NSError new];
    BOOL isAvailable = [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error];
    
    return isAvailable;
}

- (BOOL)isDeviceSupportTouchId {
    
    // 硬件设备不支持，或系统版本不支持 指纹解锁
    if (![Utils isSystemModelSupportTouchID] || ![Utils isSystemVersionMoreThanVersion:7.0]) {
        return NO;
    }
    
    LAContext *context = [LAContext new];
    NSError *error = [NSError new];
    
    BOOL isDeviceSupportTouchId = [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error];
    
    if (!isDeviceSupportTouchId) {
        
        //不支持指纹识别，LOG出错误详情
        
        switch (error.code) {
                
            case LAErrorTouchIDNotEnrolled:
                
            case LAErrorPasscodeNotSet:
            {
                isDeviceSupportTouchId = YES;
                break;
            }
            case LAErrorTouchIDNotAvailable:
            default:
            {
                isDeviceSupportTouchId = NO;
                break;
            }
        }
    }
    

    return isDeviceSupportTouchId;
}



#pragma mark - Use TouchId

- (void)useTouchIdWithUnAvailable:(void (^)(NSString *))unAvailableBlock
                       andSuccess:(void (^)(NSString *))successBlock
                       andFailues:(void (^)(NSString *))failuesBlock
                 andEnterPassword:(void (^)(NSString *))enterPasswordBlock {
    
    
    //设置中关闭指纹解锁 or 设备无法使用touch ID，直接执行验证失败模块
    if (!self.isOpenedFingerprint || ![self isDeviceSupportTouchId]) {
        failuesBlock(@"无法使用指纹解锁");
        return;
    }
    [self verificationTouchIdWithUnAvailable:unAvailableBlock
                                  andSuccess:successBlock
                                  andFailues:failuesBlock
                            andEnterPassword:enterPasswordBlock];

    

}

- (void)verificationTouchIdWithUnAvailable:(void (^)(NSString *))unAvailableBlock
                                andSuccess:(void (^)(NSString *))successBlock
                                andFailues:(void (^)(NSString *))failuesBlock
                          andEnterPassword:(void (^)(NSString *))enterPasswordBlock {
   
    LAContext* context = [LAContext new];
    NSError*  error = [NSError new];
    BOOL isAvailable = [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error];
    
    if (isAvailable) {
        if (!self.isShowEnterPasswordButton) {
            context.localizedFallbackTitle = @"";
        }
        [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:@"需要验证您的指纹来确认您的身份信息" reply:^(BOOL success, NSError *error) {
            if (success) {
                NSString* str = @"恭喜，您通过了Touch ID指纹验证！";
                NSLog(@"%@",str);
                dispatch_async(dispatch_get_main_queue(), ^{
                    successBlock(str);
                });
            } else {
                NSString* str = [NSString stringWithFormat:@"抱歉，您未能通过Touch ID指纹验证！\n%@",error];
                NSLog(@"%@",str);
                switch (error.code) {
                        
                    case LAErrorUserFallback://输入密码
                        enterPasswordBlock(str);
                        break;
                        
                    case LAErrorUserCancel://取消
                        failuesBlock(str);
                        break;
                        
                    case LAErrorAuthenticationFailed://认证失败
                    case LAErrorSystemCancel://系统取消，如切换app
                        break;
                        
                    default:
                        failuesBlock(str);
                        break;
                }
                
            }
        }];
    } else {
        
        NSString *str = [self getErrorStringWithError:error];
        unAvailableBlock(str);
    }

}
- (NSString *)getErrorStringWithError:(NSError *)error {
    NSString *str = nil;
    
    switch (error.code) {
        case LAErrorTouchIDNotEnrolled://无可用指纹
        {
            str = @"您尚未设置指纹密码，请在手机系统“设置--Touch ID与密码”中添加您的指纹";
            break;
        }
        case LAErrorPasscodeNotSet://设备未开启密码
        {
            str = @"您尚未设置手机解锁密码，请在手机系统“设置--Touch ID与密码”中设置开启密码";
            break;
        }
        case LAErrorTouchIDNotAvailable:
        default:
        {
            str = @"TouchID不可用";
            break;
        }
    }
    return str;
}
#pragma mark - Remove KVO

- (void)dealloc {
    [fingerPrintUnlockManager removeObserver:self forKeyPath:@"isNeedFingerprint"];
}

@end
