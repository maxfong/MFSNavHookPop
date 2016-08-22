//
//  UINavigationController+HookPop.h
//  MFSNavigationController
//
//  Created by maxfong on 15/5/23.
//
//  https://github.com/maxfong/MFSNavHookPop
//  使用此库需iOS7及以上，并会强制修改UINavigationController的delegate和interactivePopGestureRecognizer的值，不允许修改

#import <UIKit/UIKit.h>

@interface UINavigationController (MFSHookPop)

/** 强制返回上一个页面，哪怕上一个页面设定shouldPopActionSkipController为YES
    每次push会增加且只是一次的强制返回机会
 */
@property (nonatomic, assign) BOOL wantsPopLast;

@end

@protocol MFSPopActionProtocol <NSObject>

@optional
/** 当前Controller是否需要加入Nav堆栈，默认NO
    设定YES后，返回（pop）会略过Controller
    提示：rootViewController不能被移除
 */
- (BOOL)shouldPopActionSkipController;

/** Pop操作完成后会执行，做一些清理操作
 */
- (void)popActionDidFinish;

/** 拦截Pop操作并自定义一些操作，如弹出Alert提示是否返回
 */
- (BOOL)shouldHookPopAndAction;

@end

@interface UIViewController (MFSPopAction) <MFSPopActionProtocol>

/** 关闭当前viewController滑动返回
 */
@property (nonatomic, assign) BOOL disableDragBack;

@end

