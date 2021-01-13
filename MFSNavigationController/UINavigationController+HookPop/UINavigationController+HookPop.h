//
//  UINavigationController+HookPop.h
//  MFSNavigationController
//
//  Created by maxfong on 15/5/23.
//
//  https://github.com/maxfong/MFSNavHookPop
//  截图滑动返回（需iOS7及以上，弃用系统滑动返回是避免引起Bar堆栈冲突）及Nav堆栈过滤设定的页面

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
 支持方法内使用navigationController执行PUSH、POP等页面切换操作
 block内可传self
 不支持childViewController拦截
 */
- (BOOL)shouldHookDragPopAndActionBlock:(void(^)(void (^)(NSDictionary *options)))block;

@end

@interface UIViewController (MFSPopAction) <MFSPopActionProtocol>

/** 关闭当前viewController滑动返回
 */
@property (nonatomic, assign) BOOL disableDragBack;

/** 支持滑动返回且底部无页面截图
    开启会默认设置disableDragBack为NO
    关闭会默认设置disableDragBack为YES
    如有需要，设置enableFastDrag后再重新设置disableDragBack
 */
@property (nonatomic, assign) BOOL enableFastDrag;

/** viewController标识符，生成后唯一且不可改变
 */
@property (nonatomic, strong, readonly) NSString *aIdentifier;

@end
