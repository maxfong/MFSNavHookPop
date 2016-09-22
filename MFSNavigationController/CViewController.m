//
//  CViewController.m
//  MFSNavigationControllerDemo
//
//  Created by maxfong on 15/5/23.
//  Copyright (c) 2015年 maxfong. All rights reserved.
//

#import "CViewController.h"
#import "UINavigationController+HookPop.h"
#import "DViewController.h"

@interface CViewController ()

@end

@implementation CViewController

- (BOOL)shouldPopActionSkipController {
    return NO;
}

- (BOOL)shouldHookDragPopAndActionBlock:(void (^)(void (^)(NSDictionary *)))block {
    block(^(NSDictionary *options) {
        DViewController *viewController = DViewController.new;
        viewController.view.backgroundColor = [UIColor redColor];
        [self.navigationController pushViewController:viewController animated:YES];
    });
    return YES;
}

- (void)popActionDidFinish {
    NSLog(@"C pop finish");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
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
