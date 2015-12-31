//
//  ViewController.m
//  LRFFingerPrintManager
//
//  Created by LRF on 15/9/16.
//  Copyright (c) 2015年 LRF. All rights reserved.
//

#import "ViewController.h"
#import "LRFFingerprintUnlockManager.h"
#import "Utils.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}
- (IBAction)onIsSupportFingerprintUnlock:(id)sender {
    LRFFingerprintUnlockManager * lrf=[LRFFingerprintUnlockManager sharedManager];
    if ([lrf isDeviceSupportTouchId]) {
        showAlertWithMsg(@"支持指纹解锁功能", @"确定");
    } else {
        showAlertWithMsg(@"抱歉，不支持指纹解锁功能", @"确定");
    }
}
- (IBAction)onUserFingrtprintUnlock:(id)sender {
    LRFFingerprintUnlockManager * lrf=[LRFFingerprintUnlockManager sharedManager];
    [lrf useTouchIdWithUnAvailable:^(NSString *str) {
        
    } andSuccess:^(NSString *str) {
        showAlertWithMsg(str, @"确定");
        
    } andFailues:^(NSString *str) {
        showAlertWithMsg(str, @"确定");
        
    } andEnterPassword:^(NSString *str) {
        showAlertWithMsg(str, @"确定");
    }];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
