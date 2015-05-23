# MFSNavigationController

#####ViewController决定自己是否需要加入NavigationController堆栈；


###使用方法：
<pre><code>//ViewController内实现&lt;MFSPopProtocol&gt;:
\- (BOOL)shouldPopOut; {
    return YES;
}
</code></pre>
pop时，跳过未加入堆栈的ViewController；


支持iOS7滑动返回；<br />
iOS6功能未测试，设置滑动NavigationController类继承MFSNavigationController后，应该能达到相同的效果；

####Demo演示了A、B、C、D 4个页面push后再pop，跳过了A、B、C进入rootViewController；