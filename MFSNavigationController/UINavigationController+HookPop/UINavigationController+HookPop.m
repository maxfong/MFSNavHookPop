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

@interface NSObject (HookPopSwizzle)

+ (void)mfshp_swizzleSelector:(SEL)originalSelector newSelector:(SEL)newSelector;

@end

@implementation NSObject (HookPopSwizzle)

+ (void)mfshp_swizzleSelector:(SEL)originalSelector newSelector:(SEL)newSelector {
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

@interface UINavigationController () <UINavigationControllerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSMutableArray<UIViewController *> *popOutControllers;
@property (nonatomic, assign, getter=isPopFilter) BOOL popFilter;
@property (nonatomic, strong) UIViewController *removedPopOutViewController;
@property (nonatomic, strong) NSMutableDictionary *screenShots;
@property (nonatomic, strong) UIImageView *dragBackgroundView;

@end

@implementation UINavigationController (MFSHookPop)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL iwrvc = @selector(initWithRootViewController:);
        SEL mfs_iwrvc = @selector(mfshp_initWithRootViewController:);
        [self mfshp_swizzleSelector:iwrvc newSelector:mfs_iwrvc];
        
        SEL vdl = @selector(viewDidLoad);
        SEL mfs_vdl = @selector(mfshp_viewDidLoad);
        [self mfshp_swizzleSelector:vdl newSelector:mfs_vdl];
        
        SEL pvca = @selector(pushViewController:animated:);
        SEL mfs_pvca = @selector(mfshp_pushViewController:animated:);
        [self mfshp_swizzleSelector:pvca newSelector:mfs_pvca];
        
        SEL povca = @selector(popViewControllerAnimated:);
        SEL mfs_povca = @selector(mfshp_popViewControllerAnimated:);
        [self mfshp_swizzleSelector:povca newSelector:mfs_povca];
        
        SEL ptvca = @selector(popToViewController:animated:);
        SEL mfs_ptvca = @selector(mfshp_popToViewController:animated:);
        [self mfshp_swizzleSelector:ptvca newSelector:mfs_ptvca];
        
        SEL ptrvca = @selector(popToRootViewControllerAnimated:);
        SEL mfs_ptrvca = @selector(mfshp_popToRootViewControllerAnimated:);
        [self mfshp_swizzleSelector:ptrvca newSelector:mfs_ptrvca];
        
        SEL svc = @selector(setViewControllers:);
        SEL mfs_svc = @selector(mfshp_setViewControllers:);
        [self mfshp_swizzleSelector:svc newSelector:mfs_svc];
        
        SEL svca = @selector(setViewControllers:animated:);
        SEL mfs_svca = @selector(mfshp_setViewControllers:animated:);
        [self mfshp_swizzleSelector:svca newSelector:mfs_svca];
    });
}

- (instancetype)mfshp_initWithRootViewController:(UIViewController *)rootViewController {
    if (rootViewController) [self.popOutControllers addObject:rootViewController];
    return [self mfshp_initWithRootViewController:rootViewController];
}

- (void)mfshp_viewDidLoad {
    [self mfshp_viewDidLoad];
    UIViewController *rootViewController = self.viewControllers.firstObject;
    if (rootViewController && self.popOutControllers.count == 0) {
        [self.popOutControllers addObject:rootViewController];
    }
    CALayer  *layer = nil;
    if ([self respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.interactivePopGestureRecognizer.enabled = NO;
        [self.interactivePopGestureRecognizer.view addGestureRecognizer:({
            UIScreenEdgePanGestureRecognizer *popRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(handleControllerPop:)];
            popRecognizer.edges = UIRectEdgeLeft;
            popRecognizer.delegate = self;
            popRecognizer;
        })];
        layer = self.interactivePopGestureRecognizer.view.layer;
    }
    else {
        [self.view addGestureRecognizer:({
            UIPanGestureRecognizer *popRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleControllerPop:)];
            popRecognizer.maximumNumberOfTouches = 1;
            popRecognizer.delegate = self;
            popRecognizer;
        })];
        layer = self.view.layer;
    }
    layer.shadowColor = [UIColor blackColor].CGColor;
    layer.shadowOffset = CGSizeMake(0, 5);
    layer.shadowOpacity = 0.5;
    layer.shadowRadius = 5;
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    BOOL disableDragBack = self.viewControllers.lastObject.disableDragBack;
    if (self.viewControllers.count <= 1 || disableDragBack) {
        return NO;
    }
    return YES;
}

#pragma mark - pushViewController
- (void)mfshp_pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
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
    if (self.viewControllers.count) {
        NSString *key = self.viewControllers.lastObject.aIdentifier;
        [self.screenShots setObject:self.capture forKey:key];
        viewController.hidesBottomBarWhenPushed = YES;
    }
    if (![self.popOutControllers containsObject:viewController]) {
        [self.popOutControllers addObject:viewController];
    }
    if (self.wantsPopLast) {
        [self setWantsPopLast:!self.wantsPopLast];
    }
    [self mfshp_pushViewController:viewController animated:animated];
}

#pragma mark - pop
- (UIViewController *)mfshp_popViewControllerAnimated:(BOOL)animated {
    [self correctPopViewControllers];
    UIViewController *poppedController = [self mfshp_popViewControllerAnimated:animated];
    if ([poppedController respondsToSelector:@selector(popActionDidFinish)]) {
        [poppedController popActionDidFinish];
    }
    [self.popOutControllers removeObject:poppedController];
    if (self.viewControllers.count <= 1) {
        [self.screenShots removeAllObjects];
    }
    else {
        NSString *key = self.popOutControllers.lastObject.aIdentifier;
        [self.screenShots removeObjectForKey:key];
        //检查内存清理无用占用，随着项目规模可酌情修改
        @synchronized (self) {
            static NSUInteger holdID = 0;
            if (self.screenShots.count > (5 * ++holdID)) {
                if (holdID > 5) { holdID = 0; }
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSArray *tmpArray = self.popOutControllers;
                    NSMutableDictionary *tmpDictionary = [NSMutableDictionary dictionary];
                    [tmpArray enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        tmpDictionary[obj.aIdentifier] = self.screenShots[obj.aIdentifier];
                    }];
                    [self.screenShots removeAllObjects];
                    [self.screenShots addEntriesFromDictionary:tmpDictionary];
                });
            }
        }
    }
    return poppedController;
}

- (NSArray *)mfshp_popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    NSArray *poppedControllers = [self mfshp_popToViewController:viewController animated:animated];
    UIViewController *lastViewController = poppedControllers.lastObject;
    if ([lastViewController respondsToSelector:@selector(popActionDidFinish)]) {
        [lastViewController popActionDidFinish];
    }
    [self.popOutControllers removeObjectsInArray:poppedControllers];
    return poppedControllers;
}

- (NSArray *)mfshp_popToRootViewControllerAnimated:(BOOL)animated {
    NSArray *poppedControllers = [self mfshp_popToRootViewControllerAnimated:animated];
    UIViewController *lastViewController = poppedControllers.lastObject;
    if ([lastViewController respondsToSelector:@selector(popActionDidFinish)]) {
        [lastViewController popActionDidFinish];
    }
    [self.screenShots removeAllObjects];
    [self.popOutControllers removeObjectsInRange:NSMakeRange(1, (self.popOutControllers.count - 1))];
    return poppedControllers;
}

- (void)mfshp_setViewControllers:(NSArray<UIViewController *> *)viewControllers animated:(BOOL)animated {
    [self mfshp_setViewControllers:[self viewControllersWithCorrectSetViewControllers:viewControllers] animated:animated];
}
- (void)mfshp_setViewControllers:(NSArray<__kindof UIViewController *> *)viewControllers {
    [self mfshp_setViewControllers:[self viewControllersWithCorrectSetViewControllers:viewControllers]];
}
- (NSArray *)viewControllersWithCorrectSetViewControllers:(NSArray<__kindof UIViewController *> *)viewControllers {
    NSMutableArray *array = [NSMutableArray arrayWithArray:viewControllers];
    if ([self isMemberOfClass:[UINavigationController class]]) {
        [viewControllers enumerateObjectsUsingBlock:^(UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (![self.popOutControllers containsObject:obj]) { [array removeObject:obj]; }
        }];
        self.popOutControllers = array;
        self.removedPopOutViewController = nil;
    }
    return array;
}

- (void)correctPopViewControllers {
    if (self.removedPopOutViewController) {
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
    }
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

#pragma mark -
- (void)handleControllerPop:(UIPanGestureRecognizer *)recognizer {
    CGPoint touchPoint = [recognizer locationInView:[[UIApplication sharedApplication]keyWindow]];
    static CGFloat startX = 0;
    CGFloat offsetX = touchPoint.x - startX;
    if(recognizer.state == UIGestureRecognizerStateBegan) {
        [self correctPopViewControllers];
        [self planScreenDragBack];
        startX = touchPoint.x;
    }
    else if(recognizer.state == UIGestureRecognizerStateChanged) {
        [self doMoveViewWithX:offsetX];
    }
    else if(recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        BOOL hookPop = NO;
        UIViewController *popFromViewController = self.viewControllers.lastObject;
        __block void (^actionBlock)(NSDictionary *options) = nil;
        if ([popFromViewController respondsToSelector:@selector(shouldHookDragPopAndActionBlock:)]) {
            hookPop = [popFromViewController shouldHookDragPopAndActionBlock:^(void (^block)(NSDictionary *options)) {
                actionBlock = block;
            }];
        }
        if (!hookPop && offsetX > (width/3) && recognizer.state != UIGestureRecognizerStateCancelled) {
            [UIView animateWithDuration:0.15 animations:^{
                [self doMoveViewWithX:width];
            } completion:^(BOOL finished) {
                [self completionDragBackAnimation];
                [self recursionPopFinishFromViewController:popFromViewController];
            }];
        }
        else {
            [UIView animateWithDuration:0.15 animations:^{
                [self doMoveViewWithX:0];
            } completion:^(BOOL finished) {
                if (hookPop && offsetX > (width/3) && actionBlock) { actionBlock(nil); }
                [self.dragBackgroundView removeFromSuperview];
            }];
        }
    }
}

- (void)recursionPopFinishFromViewController:(UIViewController *)controller {
    NSArray<__kindof UIViewController *> *childViewControllers = controller.childViewControllers;
    [childViewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(popActionDidFinish)]) {
            [obj popActionDidFinish];
        }
        [self recursionPopFinishFromViewController:obj];
    }];
}

#pragma mark -
- (UIImage *)capture {
    UIGraphicsBeginImageContextWithOptions(self.view.superview.bounds.size, self.view.superview.opaque, 0.0);
    [self.view.superview.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image ?: UIImage.new;;
}

-(void)doMoveViewWithX:(CGFloat)x{
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    x = x > width ? width : x;
    x = x < 0 ? 0 : x;
    CGRect frame = self.view.frame;
    frame.origin.x = x;
    self.view.frame = frame;
    self.dragBackgroundView.frame = CGRectMake(-(width*0.6)+ x*0.6, 0, width, height);
}

-(void)completionDragBackAnimation {
    [self popViewControllerAnimated:NO];
    CGRect frame = self.view.frame;
    frame.origin.x = 0;
    self.view.frame = frame;
    [self.dragBackgroundView removeFromSuperview];
}

- (void)planScreenDragBack {
    [self.view.superview insertSubview:self.dragBackgroundView belowSubview:self.view];
    NSUInteger index = (self.popOutControllers.count - 2) > 0 ? self.popOutControllers.count - 2 : 0;
    NSString *key = self.popOutControllers[index].aIdentifier;
    self.dragBackgroundView.image = [self.screenShots objectForKey:key];
}

- (NSMutableDictionary *)screenShots {
    return objc_getAssociatedObject(self, _cmd) ?: ({
        self.screenShots = [NSMutableDictionary dictionary];
    });
}
- (void)setScreenShots:(NSMutableDictionary *)screenShots {
    objc_setAssociatedObject(self, @selector(screenShots), screenShots, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIImageView *)dragBackgroundView {
    return objc_getAssociatedObject(self, _cmd) ?: ({
        UIImageView *aView = [[UIImageView alloc]initWithFrame:self.view.bounds];
        aView.backgroundColor = [UIColor blackColor];
        self.dragBackgroundView = aView;
    });
}
- (void)setDragBackgroundView:(UIView *)dragBackgroundView {
    objc_setAssociatedObject(self, @selector(dragBackgroundView), dragBackgroundView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation UIViewController (MFSPopAction)

- (void)setDisableDragBack:(BOOL)disableDragBack {
    objc_setAssociatedObject(self, @selector(disableDragBack), @(disableDragBack), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (BOOL)disableDragBack {
    return ((NSNumber *)objc_getAssociatedObject(self, _cmd)).boolValue;
}

- (NSString *)aIdentifier {
    return objc_getAssociatedObject(self, _cmd) ?: ({
        self.aTCIdentifier = [[NSUUID UUID] UUIDString];
    });
}
- (void)setATCIdentifier:(NSString *)aIdentifier {
    objc_setAssociatedObject(self, @selector(aIdentifier), aIdentifier, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
