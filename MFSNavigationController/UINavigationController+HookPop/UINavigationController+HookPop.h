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
/** 当前Controller是否需要加入navigationController堆栈，默认NO
 设定YES后，返回和滑动返回（POP）会略过Controller
 提示：rootViewController不能被移除
 不支持childViewController拦截
 */
- (BOOL)shouldPopActionSkipController;

/** 页面执行POP操作后会被调用，可以做一些清理
 不支持方法内使用navigationController执行PUSH、POP等页面切换操作
 支持childViewController调用
 */
- (void)popActionDidFinish;

/** 只拦截滑动返回POP操作并可自定义执行内容，如弹出Alert提示是否返回
 不支持方法内使用navigationController执行PUSH、POP等页面切换操作
 不支持childViewController拦截
 */
- (BOOL)shouldHookDragPopAndAction;

@end

@interface UIViewController (MFSPopAction) <MFSPopActionProtocol>

/** 关闭当前viewController滑动返回
 */
@property (nonatomic, assign) BOOL disableDragBack;

@end

