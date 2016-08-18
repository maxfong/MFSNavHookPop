//
//  UINavigationController+MFSPopOut.h
//  MFSNavigationController
//
//  Created by maxfong on 15/5/23.
//
//  https://github.com/maxfong/MFSNavigationController
//  此库会强制修改UINavigationController的delegate和interactivePopGestureRecognizer的取值

#import <UIKit/UIKit.h>

@interface UINavigationController (MFSPopOut)

/** pop lastViewController because currentViewController process error
    only support one back
 */
@property (nonatomic, assign) BOOL wantsPopLast;

/** disable drag back white list, the class name of the parameter is string
 */
- (void)addDisableDragBackWhiteList:(NSArray<NSString *> *)clsNames;

@end

@protocol MFSPopActionProtocol <NSObject>

@optional
/** navigationController pop，out current ViewController
 tip：rootViewController cannot remove
 */
- (BOOL)shouldPopActionSkipController;

/** pop finish can do some clean
 */
- (void)popActionDidFinish;

/** hook pop action, custom operation
 */
- (BOOL)shouldHookPopAction;

@end

@interface UIViewController (MFSPopAction) <MFSPopActionProtocol>

/** the viewController disenable drag back
 */
@property (nonatomic, assign) BOOL disableDragBack;

@end
