//
//  MFSNavigationController.m
//  MFSNavigationController
//
//  Created by maxfong on 15/5/23.
//
//

#import "MFSNavigationController.h"
#import <Foundation/Foundation.h>

@interface MFSNavigationController () <UINavigationControllerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSMutableArray *popOutControllers;
@property (nonatomic, assign, getter=isPopFilter) BOOL popFilter;

@end

@implementation MFSNavigationController

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController {
    if (rootViewController) [self.popOutControllers addObject:rootViewController];
    return [super initWithRootViewController:rootViewController];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIViewController *rootViewController = self.viewControllers.firstObject;
    if (rootViewController && self.popOutControllers.count == 0) {
        [self.popOutControllers addObject:rootViewController];
    }
    if ([self respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.interactivePopGestureRecognizer.enabled = YES;
        self.interactivePopGestureRecognizer.delegate = self;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (self.popOutControllers.count <= 1) {
        return NO;
    }
    return YES;
}

#pragma mark - UINavigationControllerDelegate
///TODO:UIViewControllerAnimatedTransitioning

#pragma mark - MFSPopProtocol
- (NSMutableArray *)popOutControllers {
    return _popOutControllers ?: ({_popOutControllers = NSMutableArray.new;});
}

#pragma mark - pushViewController
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    BOOL popOut = NO;
    UIViewController *lastViewController = self.popOutControllers.lastObject;
    if ([lastViewController respondsToSelector:@selector(shouldPopOut)]) {
        popOut = [lastViewController shouldPopOut];
    }
    if (popOut && self.popOutControllers.count > 1) {   //rootViewController cannot remove
        [self.popOutControllers removeObject:lastViewController];
        [self setPopFilter:YES];
    }
    if (![self.popOutControllers containsObject:viewController]) {
        [self.popOutControllers addObject:viewController];
    }
    [super pushViewController:viewController animated:animated];
}

#pragma mark - pop
- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
    if (self.isPopFilter) {
        [self setPopFilter:!self.isPopFilter];
        self.viewControllers = self.popOutControllers;
    }
    UIViewController *poppedController = [super popViewControllerAnimated:animated];
    [self.popOutControllers removeObject:poppedController];
    return poppedController;
}

- (NSArray *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    NSArray *poppedControllers = [super popToViewController:viewController animated:animated];
    [self.popOutControllers removeObjectsInArray:poppedControllers];
    return poppedControllers;
}

- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated
{
    NSUInteger removeControllerCount = self.popOutControllers.count - 1;
    [self.popOutControllers removeObjectsInRange:NSMakeRange(1, removeControllerCount)];
    return [super popToRootViewControllerAnimated:animated];
}

@end
