//
//  UINavigationController+MFSPopOut.m
//  MFSNavigationController
//
//  Created by maxfong on 15/5/23.
//
//  https://github.com/maxfong/MFSNavigationController

#import "UINavigationController+MFSPopOut.h"
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface NSObject (Swizzle)

+ (void)mfs_SwizzleSelector:(SEL)originalSelector newSelector:(SEL)newSelector;

@end

@implementation NSObject (Swizzle)

+ (void)mfs_SwizzleSelector:(SEL)originalSelector newSelector:(SEL)newSelector;
{
    Method originalMethod = class_getInstanceMethod(self, originalSelector);
    Method newMethod = class_getInstanceMethod(self, newSelector);
    
    BOOL methodAdded = class_addMethod([self class],
                                       originalSelector,
                                       method_getImplementation(newMethod),
                                       method_getTypeEncoding(newMethod));
    
    if (methodAdded) {
        class_replaceMethod([self class],
                            newSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    }
    else {
        method_exchangeImplementations(originalMethod, newMethod);
    }
}

@end

static char *kPopOutControllers = "popOutControllers";
static char *kPopFilter = "popFilter";
static char *kRemovedPopOutViewController = "removedPopOutViewController";
static char *kWantsPopLast = "wantsPopLast";

@interface UINavigationController () <UINavigationControllerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSMutableArray *popOutControllers;
@property (nonatomic, assign, getter=isPopFilter) BOOL popFilter;
@property (nonatomic, weak) UIViewController *removedPopOutViewController;

@end

@implementation UINavigationController (MFSPopOut)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL iwrvc = @selector(initWithRootViewController:);
        SEL mfs_iwrvc = @selector(mfs_initWithRootViewController:);
        [self mfs_SwizzleSelector:iwrvc newSelector:mfs_iwrvc];
        
        SEL vdl = @selector(viewDidLoad);
        SEL mfs_vdl = @selector(mfs_viewDidLoad);
        [self mfs_SwizzleSelector:vdl newSelector:mfs_vdl];
        
        SEL pvca = @selector(pushViewController:animated:);
        SEL mfs_pvca = @selector(mfs_pushViewController:animated:);
        [self mfs_SwizzleSelector:pvca newSelector:mfs_pvca];
        
        SEL povca = @selector(popViewControllerAnimated:);
        SEL mfs_povca = @selector(mfs_popViewControllerAnimated:);
        [self mfs_SwizzleSelector:povca newSelector:mfs_povca];
        
        SEL ptvca = @selector(popToViewController:animated:);
        SEL mfs_ptvca = @selector(mfs_popToViewController:animated:);
        [self mfs_SwizzleSelector:ptvca newSelector:mfs_ptvca];
        
        SEL ptrvca = @selector(popToRootViewControllerAnimated:);
        SEL mfs_ptrvca = @selector(mfs_popToRootViewControllerAnimated:);
        [self mfs_SwizzleSelector:ptrvca newSelector:mfs_ptrvca];
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
        self.interactivePopGestureRecognizer.enabled = YES;
        self.interactivePopGestureRecognizer.delegate = self;
    }
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (self.viewControllers.count <= 1) {
        return NO;
    }
    return YES;
}

#pragma mark - UINavigationControllerDelegate
///TODO:UIViewControllerAnimatedTransitioning

#pragma mark - pushViewController
- (void)mfs_pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    BOOL popOut = NO;
    UIViewController *lastViewController = self.popOutControllers.lastObject;
    if ([lastViewController respondsToSelector:@selector(shouldPopOut)]) {
        popOut = [lastViewController shouldPopOut];
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
    objc_setAssociatedObject(self, kPopOutControllers, popOutControllers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (NSMutableArray *)popOutControllers {
    NSMutableArray *_popOutControllers = objc_getAssociatedObject(self, kPopOutControllers);
    return _popOutControllers ?: ({self.popOutControllers = NSMutableArray.new;});
}

- (void)setPopFilter:(BOOL)popFilter {
    objc_setAssociatedObject(self, kPopFilter, @(popFilter), OBJC_ASSOCIATION_ASSIGN);
}
- (BOOL)isPopFilter {
    NSNumber *popFileter = objc_getAssociatedObject(self, kPopFilter);
    return popFileter.boolValue;
}

- (void)setRemovedPopOutViewController:(UIViewController *)removedPopOutViewController{
    objc_setAssociatedObject(self, kRemovedPopOutViewController, removedPopOutViewController, OBJC_ASSOCIATION_ASSIGN);
}
- (UIViewController *)removedPopOutViewController {
    return objc_getAssociatedObject(self, kRemovedPopOutViewController);
}

- (void)setWantsPopLast:(BOOL)wantsPopLast {
    objc_setAssociatedObject(self, kWantsPopLast, @(wantsPopLast), OBJC_ASSOCIATION_ASSIGN);
}
- (BOOL)wantsPopLast {
    NSNumber *wantsPopLast = objc_getAssociatedObject(self, kWantsPopLast);
    return wantsPopLast.boolValue;
}

@end
