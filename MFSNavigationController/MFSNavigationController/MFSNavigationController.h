//
//  MFSNavigationController.h
//  MFSNavigationController
//
//  Created by maxfong on 15/5/23.
//
//  https://github.com/maxfong/MFSNavigationController

#import <UIKit/UIKit.h>

@protocol MFSPopProtocol <NSObject>

@optional
/** navigationController pop，out current ViewController
 tip：rootViewController cannot remove
 */
- (BOOL)shouldPopOut;

@end

@interface UIViewController (MFSPop) <MFSPopProtocol> @end

@interface MFSNavigationController : UINavigationController

/** pop lastViewController because currentViewController process error
 */
@property (nonatomic, assign) BOOL wantsPopLast;

@end


