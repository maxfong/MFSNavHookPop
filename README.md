# MFSNavigationController

#####ViewController决定自己是否需要加入NavigationController堆栈，拦截iOS7滑动返回的pop操作，并支持pop操作完成回调。


###使用方法：
<pre><code>//ViewController内实现&lt;MFSPopActionProtocol&gt;:
- (BOOL)shouldPopActionSkipController; {
    return YES;
}
</code></pre>
pop时，跳过未加入堆栈的ViewController；
<br />
<pre><code>//MFSNavigationController的属性:
@property (nonatomic, assign) BOOL wantsPopLast;
</code></pre>
最后的ViewController操作失败，需要返回上一个ViewController，nav设置wantsPopLast为YES；

###兼容性
支持iOS7及以上；<br />
~~iOS6功能未测试，设置滑动NavigationController类继承MFSNavigationController后，应该能达到相同的效果；~~

####Demo演示了A、B、C、D 4个页面push后再pop，跳过了A、B、C进入rootViewController；
![Alt text](MFSNavigationControllerDemo.gif)

####update
新增UINavigationController+MFSPopOut，不影响UINavigationController继承

###update2
<pre><code>
//
//  UINavigationController+MFSPopOut.h
//  MFSNavigationController
//
//  Created by maxfong on 15/5/23.
//
//  https://github.com/maxfong/MFSNavigationController
//  使用此库需iOS7及以上，并会强制修改UINavigationController的delegate和interactivePopGestureRecognizer的值，不允许修改

#import <UIKit/UIKit.h>

@interface UINavigationController (MFSPopOut)

/** 强制返回上一个页面，哪怕上一个页面设定shouldPopActionSkipController为YES
    每次push会增加且只是一次的强制返回机会
 */
@property (nonatomic, assign) BOOL wantsPopLast;

/** 添加白名单内的View将不再支持触摸滑动返回，参数是类名字符串
 */
~~- (void)addDisableDragBackWhiteList:(NSArray<NSString *> *)clsNames;~~

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
- (BOOL)shouldHookPopAction;

@end

@interface UIViewController (MFSPopAction) <MFSPopActionProtocol>

/** 关闭当前viewController滑动返回
 */
@property (nonatomic, assign) BOOL disableDragBack;

@end

</code></pre>
