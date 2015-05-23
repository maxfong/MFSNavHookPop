//
//  MFSNavigationController.h
//  MFSNavigationController
//
//  Created by maxfong on 15/5/23.
//
//

#import <UIKit/UIKit.h>

@protocol MFSPopProtocol <NSObject>

@optional
/** navigationController pop，out current ViewController
 tip：rootViewController cannot remove
 */
- (BOOL)shouldPopOut;

@end

@interface UIViewController (MFSPop) <MFSPopProtocol> @end

@interface MFSNavigationController : UINavigationController @end


