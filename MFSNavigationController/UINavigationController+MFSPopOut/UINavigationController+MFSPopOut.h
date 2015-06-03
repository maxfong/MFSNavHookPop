//
//  UINavigationController+MFSPopOut.h
//  MFSNavigationController
//
//  Created by maxfong on 15/5/23.
//
//  https://github.com/maxfong/MFSNavigationController

#import <UIKit/UIKit.h>

@interface UINavigationController (MFSPopOut)

/** pop lastViewController because currentViewController process error
 */
@property (nonatomic, assign) BOOL wantsPopLast;

@end

@protocol MFSPopProtocol <NSObject>

@optional
/** navigationController pop，out current ViewController
 tip：rootViewController cannot remove
 */
- (BOOL)shouldPopOut;

@end

@interface UIViewController (MFSPop) <MFSPopProtocol> @end

