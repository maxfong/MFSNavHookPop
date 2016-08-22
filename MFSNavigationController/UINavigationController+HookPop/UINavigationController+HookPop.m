//
//  UINavigationController+HookPop.m
//  MFSNavigationController
//
//  Created by maxfong on 15/5/23.
//
//  https://github.com/maxfong/MFSNavHookPop

#import "UINavigationController+HookPop.h"
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface NSObject (Swizzle)

+ (void)mfs_swizzleSelector:(SEL)originalSelector newSelector:(SEL)newSelector;

@end

@implementation NSObject (Swizzle)

+ (void)mfs_swizzleSelector:(SEL)originalSelector newSelector:(SEL)newSelector {
    Method originalMethod = class_getInstanceMethod(self, originalSelector);
    Method newMethod = class_getInstanceMethod(self, newSelector);
    
    BOOL methodAdded = class_addMethod([self class], originalSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod));
    if (methodAdded) {
        class_replaceMethod([self class], newSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    }
    else {
        method_exchangeImplementations(originalMethod, newMethod);
    }
}

@end

@interface MFSPopAnimation : NSObject <UIViewControllerAnimatedTransitioning> @end

@implementation MFSPopAnimation

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return 0.25;
}
- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containerView = [transitionContext containerView];
    [containerView insertSubview:toViewController.view belowSubview:fromViewController.view];
    
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    [UIView animateWithDuration:duration animations:^{
        fromViewController.view.transform = CGAffineTransformMakeTranslation([UIScreen mainScreen].bounds.size.width, 0);
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
    }];
}

@end

@interface UINavigationController () <UINavigationControllerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSMutableArray *popOutControllers;
@property (nonatomic, assign, getter=isPopFilter) BOOL popFilter;
@property (nonatomic, strong) UIViewController *removedPopOutViewController;

//Drag Back callback
@property (nonatomic, strong) UIPercentDrivenInteractiveTransition *interactivePopTransition;
@property (nonatomic, weak) UIViewController *popFromViewController;
@property (nonatomic, strong) UIPanGestureRecognizer *popRecognizer;

@end

@implementation UINavigationController (MFSHookPop)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL iwrvc = @selector(initWithRootViewController:);
        SEL mfs_iwrvc = @selector(mfs_initWithRootViewController:);
        [self mfs_swizzleSelector:iwrvc newSelector:mfs_iwrvc];
        
        SEL vdl = @selector(viewDidLoad);
        SEL mfs_vdl = @selector(mfs_viewDidLoad);
        [self mfs_swizzleSelector:vdl newSelector:mfs_vdl];
        
        SEL pvca = @selector(pushViewController:animated:);
        SEL mfs_pvca = @selector(mfs_pushViewController:animated:);
        [self mfs_swizzleSelector:pvca newSelector:mfs_pvca];
        
        SEL povca = @selector(popViewControllerAnimated:);
        SEL mfs_povca = @selector(mfs_popViewControllerAnimated:);
        [self mfs_swizzleSelector:povca newSelector:mfs_povca];
        
        SEL ptvca = @selector(popToViewController:animated:);
        SEL mfs_ptvca = @selector(mfs_popToViewController:animated:);
        [self mfs_swizzleSelector:ptvca newSelector:mfs_ptvca];
        
        SEL ptrvca = @selector(popToRootViewControllerAnimated:);
        SEL mfs_ptrvca = @selector(mfs_popToRootViewControllerAnimated:);
        [self mfs_swizzleSelector:ptrvca newSelector:mfs_ptrvca];
        
        SEL sd = @selector(setDelegate:);
        SEL mfs_sd = @selector(mfs_setDelegate:);
        [self mfs_swizzleSelector:sd newSelector:mfs_sd];
        
        SEL ipgr = @selector(interactivePopGestureRecognizer);
        SEL mfs_ipgr = @selector(mfs_interactivePopGestureRecognizer);
        [self mfs_swizzleSelector:ipgr newSelector:mfs_ipgr];
    });
}

- (instancetype)mfs_initWithRootViewController:(UIViewController *)rootViewController {
    if (rootViewController) [self.popOutControllers addObject:rootViewController];
    return [self mfs_initWithRootViewController:rootViewController];
}

- (void)mfs_viewDidLoad {
    [self mfs_viewDidLoad];
    UIViewController *rootViewController = self.viewControllers.firstObject;
    if (rootViewController && self.popOutControllers.count == 0) {
        [self.popOutControllers addObject:rootViewController];
    }
    if ([self respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        [self configBackGestureRecognizer];
        self.delegate = self;
    }
}

- (void)configBackGestureRecognizer {
    self.mfs_interactivePopGestureRecognizer.enabled = NO;
    [self.mfs_interactivePopGestureRecognizer.view addGestureRecognizer:self.popRecognizer];
}

#pragma mark - forced to intercept
- (void)mfs_setDelegate:(id<UINavigationControllerDelegate>)delegate {
    [self mfs_setDelegate:self];
}
- (UIGestureRecognizer *)mfs_interactivePopGestureRecognizer {
    return nil;
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    BOOL disableDragBack = self.viewControllers.lastObject.disableDragBack;
    if (self.viewControllers.count <= 1 || disableDragBack) {
        return NO;
    }
    return !disableDragBack;
}

#pragma mark - UINavigationControllerDelegate
- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                  animationControllerForOperation:(UINavigationControllerOperation)operation
                                               fromViewController:(UIViewController *)fromVC
                                                 toViewController:(UIViewController *)toVC {
    if (operation == UINavigationControllerOperationPop) {
        self.popFromViewController = fromVC;
        return MFSPopAnimation.new;
    }
    return nil;
}

- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController
                         interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController {
    if ([animationController isKindOfClass:[MFSPopAnimation class]]) {
        return self.interactivePopTransition;
    }
    return nil;
}

#pragma mark - pushViewController
- (void)mfs_pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    BOOL popOut = NO;
    UIViewController *lastViewController = self.popOutControllers.lastObject;
    if ([lastViewController respondsToSelector:@selector(shouldPopActionSkipController)]) {
        popOut = [lastViewController shouldPopActionSkipController];
    }
    if (popOut && self.popOutControllers.count > 1) {   //rootViewController cannot remove
        [self.popOutControllers removeObject:lastViewController];
        self.removedPopOutViewController = lastViewController;
        [self setPopFilter:YES];
    }
    if (![self.popOutControllers containsObject:viewController]) {
        [self.popOutControllers addObject:viewController];
    }
    if (self.wantsPopLast) {
        [self setWantsPopLast:!self.wantsPopLast];
    }
    [self mfs_pushViewController:viewController animated:animated];
}

#pragma mark - pop
- (UIViewController *)mfs_popViewControllerAnimated:(BOOL)animated {
    if (self.wantsPopLast) {
        [self setWantsPopLast:!self.wantsPopLast];
        if (self.removedPopOutViewController) {
            NSUInteger index = self.popOutControllers.count - 1;
            [self.popOutControllers insertObject:self.removedPopOutViewController atIndex:index];
        }
    }
    self.removedPopOutViewController = nil;
    if (self.isPopFilter) {
        [self setPopFilter:!self.isPopFilter];
        self.viewControllers = self.popOutControllers;
    }
    UIViewController *poppedController = [self mfs_popViewControllerAnimated:animated];
    [self.popOutControllers removeObject:poppedController];
    return poppedController;
}

- (NSArray *)mfs_popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    NSArray *poppedControllers = [self mfs_popToViewController:viewController animated:animated];
    [self.popOutControllers removeObjectsInArray:poppedControllers];
    return poppedControllers;
}

- (NSArray *)mfs_popToRootViewControllerAnimated:(BOOL)animated {
    NSUInteger removeControllerCount = self.popOutControllers.count - 1;
    [self.popOutControllers removeObjectsInRange:NSMakeRange(1, removeControllerCount)];
    return [self mfs_popToRootViewControllerAnimated:animated];
}

#pragma mark - AssociatedObject
- (void)setPopOutControllers:(NSMutableArray *)popOutControllers {
    objc_setAssociatedObject(self, @selector(popOutControllers), popOutControllers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (NSMutableArray *)popOutControllers {
    NSMutableArray *_popOutControllers = objc_getAssociatedObject(self, _cmd);
    return _popOutControllers ?: ({self.popOutControllers = NSMutableArray.new;});
}

- (void)setPopFilter:(BOOL)popFilter {
    objc_setAssociatedObject(self, @selector(isPopFilter), @(popFilter), OBJC_ASSOCIATION_ASSIGN);
}
- (BOOL)isPopFilter {
    NSNumber *popFileter = objc_getAssociatedObject(self, _cmd);
    return popFileter.boolValue;
}

- (void)setRemovedPopOutViewController:(UIViewController *)removedPopOutViewController{
    objc_setAssociatedObject(self, @selector(removedPopOutViewController), removedPopOutViewController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (UIViewController *)removedPopOutViewController {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setWantsPopLast:(BOOL)wantsPopLast {
    objc_setAssociatedObject(self, @selector(wantsPopLast), @(wantsPopLast), OBJC_ASSOCIATION_ASSIGN);
}
- (BOOL)wantsPopLast {
    NSNumber *wantsPopLast = objc_getAssociatedObject(self, _cmd);
    return wantsPopLast.boolValue;
}

- (void)setDisableDragBackWhiteList:(NSMutableArray *)disableDragBackWhiteList {
    objc_setAssociatedObject(self, @selector(disableDragBackWhiteList), disableDragBackWhiteList, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (NSMutableArray *)disableDragBackWhiteList {
    return objc_getAssociatedObject(self, _cmd) ?: ({
        self.disableDragBackWhiteList = NSMutableArray.new;
    });
}

- (void)setInteractivePopTransition:(UIPercentDrivenInteractiveTransition *)interactivePopTransition {
    objc_setAssociatedObject(self, @selector(interactivePopTransition), interactivePopTransition, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (UIPercentDrivenInteractiveTransition *)interactivePopTransition {
    return objc_getAssociatedObject(self, _cmd);
}
- (void)setPopFromViewController:(UIViewController *)popFromViewController {
    objc_setAssociatedObject(self, @selector(popFromViewController), popFromViewController, OBJC_ASSOCIATION_ASSIGN);
}
- (UIViewController *)popFromViewController {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setPopRecognizer:(UIPanGestureRecognizer *)popRecognizer {
    objc_setAssociatedObject(self, @selector(popRecognizer), popRecognizer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (UIPanGestureRecognizer *)popRecognizer {
    UIPanGestureRecognizer *popRecognizer = objc_getAssociatedObject(self, _cmd) ?: ({
        UIPanGestureRecognizer *popRecognizer = [[UIPanGestureRecognizer alloc] init];
        popRecognizer.delegate = self;
        popRecognizer.maximumNumberOfTouches = 1;
        [popRecognizer addTarget:self action:@selector(handleControllerPop:)];
        self.popRecognizer = popRecognizer;
    });
    return popRecognizer;
}
- (void)handleControllerPop:(UIPanGestureRecognizer *)recognizer {
    CGFloat progress = MIN(1.0, MAX(0.0, [recognizer translationInView:recognizer.view].x / recognizer.view.bounds.size.width));
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.interactivePopTransition = [[UIPercentDrivenInteractiveTransition alloc] init];
        [self popViewControllerAnimated:YES];
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged) {
        [self.interactivePopTransition updateInteractiveTransition:progress];
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
        if (progress > 0.5) {
            BOOL hookPop = NO;
            if ([self.popFromViewController respondsToSelector:@selector(shouldHookPopAndAction)]) {
                hookPop = [self.popFromViewController performSelector:@selector(shouldHookPopAndAction)];
            }
            if (!hookPop) {
                if ([self.popFromViewController respondsToSelector:@selector(popActionDidFinish)]) {
                    [self.popFromViewController performSelector:@selector(popActionDidFinish)];
                }
                [self.interactivePopTransition finishInteractiveTransition];
                self.interactivePopTransition = nil;
                return;
            }
        }
        [self.interactivePopTransition cancelInteractiveTransition];
        self.interactivePopTransition = nil;
    }
}

@end

@implementation UIViewController (MFSPopAction)

- (void)setDisableDragBack:(BOOL)disableDragBack {
    objc_setAssociatedObject(self, @selector(disableDragBack), @(disableDragBack), OBJC_ASSOCIATION_ASSIGN);
}
- (BOOL)disableDragBack {
    return ((NSNumber *)objc_getAssociatedObject(self, _cmd)).boolValue;
}

@end
