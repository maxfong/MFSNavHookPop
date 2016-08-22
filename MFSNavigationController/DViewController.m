//
//  DViewController.m
//  MFSNavigationControllerDemo
//
//  Created by maxfong on 15/5/23.
//  Copyright (c) 2015年 maxfong. All rights reserved.
//

#import "DViewController.h"
#import "UINavigationController+HookPop.h"

@interface DViewController ()

@end

@implementation DViewController

- (BOOL)shouldPopActionSkipController {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationController.wantsPopLast = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
