//
//  HBFingerprintUnlockManager.m
//  BigHuobi
//
//  Created by LRF on 15/9/2.
//  Copyright (c) 2015年 LRF. All rights reserved.
//

#import "HBFingerprintUnlockManager.h"

#import <LocalAuthentication/LocalAuthentication.h>

#import "NSUserDefaults+Helper.h"

#import "DLMainManager.h"

#import "KeychainItemWrapper.h"
#import "TLStringTools.h"
#import "AppDelegate.h"
#import "commond.h"

#import <sys/sysctl.h>

@implementation HBFingerprintUnlockManager

static HBFingerprintUnlockManager *fingerPrintUnlockManager = nil;


#pragma mark - SharedManager

/**
 *  单例
 *
 *  @return 该单一实例
 */
+ (instancetype)sharedManager {
    @synchronized(self) {
        if (!fingerPrintUnlockManager) {
            fingerPrintUnlockManager = [[self alloc] init];
//            fingerPrintUnlockManager.isNeedFingerprint = [fingerPrintUnlockManager getNeedFingerPrintFromUserDefaults];
            [fingerPrintUnlockManager addObserver:fingerPrintUnlockManager forKeyPath:@"isNeedFingerprint" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
        }
        fingerPrintUnlockManager.isNeedFingerprint = [fingerPrintUnlockManager getNeedFingerPrintFromUserDefaults];
    }
    return fingerPrintUnlockManager;
}

#pragma mark -  IsNeedFingerprint

/**
 *  NSUserDefaults  存储是否开启指纹密码的值的key
 *
 *  @return key
 */
- (NSString *)isNeedFingerprintKey {
    return [NSString stringWithFormat:@"%@_NeedFingerprintStr",[[DLMainManager sharedMainManager] loadAccountUID]];
}

/**
 *  从 NSUserDefaults 中读取之前设置的是否开启指纹密码的值，若无，则设置默认开启
 *
 *  @return 是否已开启指纹密码
 */
- (BOOL)getNeedFingerPrintFromUserDefaults {
    NSString  *key = [self isNeedFingerprintKey];
    NSNumber * needFingerPrintNum = [[NSUserDefaults standardUserDefaults] valueForKey:key];
    if (needFingerPrintNum == nil) {
        [[NSUserDefaults standardUserDefaults] setValue:nil forKey:key withDefaultValue:@0];
    }
    needFingerPrintNum = [[NSUserDefaults standardUserDefaults] valueForKey:key];
    return needFingerPrintNum.boolValue;
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
    
    [[NSUserDefaults standardUserDefaults] setValue:[change objectForKey:NSKeyValueChangeNewKey] forKey:[self isNeedFingerprintKey] withDefaultValue:nil];
    NSNumber* numValue = [change objectForKey:NSKeyValueChangeNewKey];
    if (numValue.boolValue == YES)
    {
        // 需要把session加密保存起来
        AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [delegate doesYou:delegate.accessToken];
    }
    else
    {
        NSString* strAccount = [[[DLMainManager sharedMainManager] loadAccountUID] stringValue];
        if (strAccount)
        {
            NSString* strIdentifier = [TLStringTools made16:strAccount];
            KeychainItemWrapper * keychin = [[KeychainItemWrapper alloc]initWithIdentifier:strIdentifier accessGroup:nil];
            [keychin setObject:strIdentifier forKey:(__bridge id)kSecAttrAccount];
            [keychin setObject:@"-1" forKey:(__bridge id)kSecValueData];
        }
        else
            HB_LOG(@"error!");
    }
    
}

#pragma mark - TouchId

- (BOOL)isTouchIdAvailable
{
    LAContext *context = [LAContext new];
    NSError *error = [NSError new];
    BOOL isAvailable = [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error];
    
    return isAvailable;
}

- (BOOL)isDeviceSupportTouchId {
    
    // 硬件设备不支持，或系统版本不支持 指纹解锁
    if (![self isSystemModelSupportTouchID] || ![commond isSystemVersionMoreThanVersion:7.0]) {
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

/**
 *  判断设备是否支持TouchID
 *
 *  @return 设备是否支持TouchID
 */
- (BOOL)isSystemModelSupportTouchID {
    BOOL isSupportTouchID = NO;
    NSString *systemModel = [self getCurrentDeviceModel];
    
    // 设备类型中的数字
    int number = 0;
    
    //是 iPhone 设备
    if ([systemModel containsString:@"iPhone"]) {
        
        // 设备类型中的数字大于 5
        number = [commond findNumFromStr:systemModel];
        if (number > 5) {
            isSupportTouchID = YES;
        }
        //设备是5s
        if ([systemModel containsString:@"5s"]) {
            isSupportTouchID = YES;
        }
    }
    //是 iPod Touch 设备
    else if ([systemModel containsString:@"iPod"]) {
        
        isSupportTouchID = NO;
    }
    //是 iPad 设备
    else if ([systemModel containsString:@"iPad"]) {

        if ([systemModel containsString:@"mini"]) {
            number = [commond findNumFromStr:systemModel];
            if (number > 2) {
                isSupportTouchID = YES;
            }
        }
        if ([systemModel containsString:@"Air"]) {
            number = [commond findNumFromStr:systemModel];
            if (number > 1) {
                isSupportTouchID = YES;
            }
        }
    }
    return isSupportTouchID;
}
//获得设备型号
- (NSString *)getCurrentDeviceModel
{
    int mib[2];
    size_t len;
    char *machine;
    
    mib[0] = CTL_HW;
    mib[1] = HW_MACHINE;
    sysctl(mib, 2, NULL, &len, NULL, 0);
    machine = malloc(len);
    sysctl(mib, 2, machine, &len, NULL, 0);
    
    NSString *platform = [NSString stringWithCString:machine encoding:NSASCIIStringEncoding];
    free(machine);
    
    if ([platform isEqualToString:@"iPhone1,1"]) return @"iPhone 2G (A1203)";
    if ([platform isEqualToString:@"iPhone1,2"]) return @"iPhone 3G (A1241/A1324)";
    if ([platform isEqualToString:@"iPhone2,1"]) return @"iPhone 3GS (A1303/A1325)";
    if ([platform isEqualToString:@"iPhone3,1"]) return @"iPhone 4 (A1332)";
    if ([platform isEqualToString:@"iPhone3,2"]) return @"iPhone 4 (A1332)";
    if ([platform isEqualToString:@"iPhone3,3"]) return @"iPhone 4 (A1349)";
    if ([platform isEqualToString:@"iPhone4,1"]) return @"iPhone 4S (A1387/A1431)";
    if ([platform isEqualToString:@"iPhone5,1"]) return @"iPhone 5 (A1428)";
    if ([platform isEqualToString:@"iPhone5,2"]) return @"iPhone 5 (A1429/A1442)";
    if ([platform isEqualToString:@"iPhone5,3"]) return @"iPhone 5c (A1456/A1532)";
    if ([platform isEqualToString:@"iPhone5,4"]) return @"iPhone 5c (A1507/A1516/A1526/A1529)";
    if ([platform isEqualToString:@"iPhone6,1"]) return @"iPhone 5s (A1453/A1533)";
    if ([platform isEqualToString:@"iPhone6,2"]) return @"iPhone 5s (A1457/A1518/A1528/A1530)";
    if ([platform isEqualToString:@"iPhone7,1"]) return @"iPhone 6 Plus (A1522/A1524)";
    if ([platform isEqualToString:@"iPhone7,2"]) return @"iPhone 6 (A1549/A1586)";
    
    if ([platform isEqualToString:@"iPod1,1"])   return @"iPod Touch 1G (A1213)";
    if ([platform isEqualToString:@"iPod2,1"])   return @"iPod Touch 2G (A1288)";
    if ([platform isEqualToString:@"iPod3,1"])   return @"iPod Touch 3G (A1318)";
    if ([platform isEqualToString:@"iPod4,1"])   return @"iPod Touch 4G (A1367)";
    if ([platform isEqualToString:@"iPod5,1"])   return @"iPod Touch 5G (A1421/A1509)";
    
    if ([platform isEqualToString:@"iPad1,1"])   return @"iPad 1G (A1219/A1337)";
    
    if ([platform isEqualToString:@"iPad2,1"])   return @"iPad 2 (A1395)";
    if ([platform isEqualToString:@"iPad2,2"])   return @"iPad 2 (A1396)";
    if ([platform isEqualToString:@"iPad2,3"])   return @"iPad 2 (A1397)";
    if ([platform isEqualToString:@"iPad2,4"])   return @"iPad 2 (A1395+New Chip)";
    if ([platform isEqualToString:@"iPad2,5"])   return @"iPad Mini 1G (A1432)";
    if ([platform isEqualToString:@"iPad2,6"])   return @"iPad Mini 1G (A1454)";
    if ([platform isEqualToString:@"iPad2,7"])   return @"iPad Mini 1G (A1455)";
    
    if ([platform isEqualToString:@"iPad3,1"])   return @"iPad 3 (A1416)";
    if ([platform isEqualToString:@"iPad3,2"])   return @"iPad 3 (A1403)";
    if ([platform isEqualToString:@"iPad3,3"])   return @"iPad 3 (A1430)";
    if ([platform isEqualToString:@"iPad3,4"])   return @"iPad 4 (A1458)";
    if ([platform isEqualToString:@"iPad3,5"])   return @"iPad 4 (A1459)";
    if ([platform isEqualToString:@"iPad3,6"])   return @"iPad 4 (A1460)";
    
    if ([platform isEqualToString:@"iPad4,1"])   return @"iPad Air (A1474)";
    if ([platform isEqualToString:@"iPad4,2"])   return @"iPad Air (A1475)";
    if ([platform isEqualToString:@"iPad4,3"])   return @"iPad Air (A1476)";
    if ([platform isEqualToString:@"iPad4,4"])   return @"iPad Mini 2G (A1489)";
    if ([platform isEqualToString:@"iPad4,5"])   return @"iPad Mini 2G (A1490)";
    if ([platform isEqualToString:@"iPad4,6"])   return @"iPad Mini 2G (A1491)";
    
    if ([platform isEqualToString:@"i386"])      return @"iPhone Simulator";
    if ([platform isEqualToString:@"x86_64"])    return @"iPhone Simulator";
    return platform;
}

- (void)useTouchIdWithUnAvailable:(void (^)(NSString *))unAvailableBlock
                       andSuccess:(void (^)(NSString *))successBlock
                       andFailues:(void (^)(NSString *))failuesBlock
                 andEnterPassword:(void (^)(NSString *))enterPasswordBlock {
    
#ifdef HB_FingerprintUnlock_Status
    
    //设置中关闭指纹解锁 or 设备无法使用touch ID，直接执行验证失败模块
    if (!self.isNeedFingerprint || ![self isDeviceSupportTouchId]) {
        failuesBlock(nil);
        return;
    }
    [self verificationTouchIdWithUnAvailable:unAvailableBlock
                                  andSuccess:successBlock
                                  andFailues:failuesBlock
                            andEnterPassword:enterPasswordBlock];


#else
    
    successBlock(nil);
    return;
    
#endif
    
    

}

- (void)verificationTouchIdWithUnAvailable:(void (^)(NSString *))unAvailableBlock
                                andSuccess:(void (^)(NSString *))successBlock
                                andFailues:(void (^)(NSString *))failuesBlock
                          andEnterPassword:(void (^)(NSString *))enterPasswordBlock {
   
    LAContext* context = [LAContext new];
    NSError*  error = [NSError new];
    BOOL isAvailable = [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error];
    
    if (isAvailable) {
        if (!self.hasEnterPasswordButton) {
            context.localizedFallbackTitle = @"";
        }
        [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:@"需要验证您的指纹来确认您的身份信息" reply:^(BOOL success, NSError *error) {
            if (success) {
                NSString* str = @"恭喜，您通过了Touch ID指纹验证！";
                NSLog(@"%@",str);
                dispatch_sync(dispatch_get_main_queue(), ^{
                    successBlock(str);
                });
            }
            else
            {
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
    }
    else {
        
        NSString *str = nil;
        //不支持指纹识别，LOG出错误详情
        
        switch (error.code) {
            case LAErrorTouchIDNotEnrolled://无可用指纹
            {
                str = NSLocalizedString(@"SR_NoFingerprintPassword",@"");
                break;
            }
            case LAErrorPasscodeNotSet://设备未开启密码
            {
                str = NSLocalizedString(@"SR_NoPhoneUnlockPassword",@"");
                break;
            }
            case LAErrorTouchIDNotAvailable:
            default:
            {
                NSLog(@"TouchID not available");
                break;
            }
        }
        unAvailableBlock(str);
    }

}

/// 移除KVO
- (void)dealloc {
    [fingerPrintUnlockManager removeObserver:self forKeyPath:@"isNeedFingerprint"];
}

@end
