//
//  CCTransitionAnimator.h
//  testPush
//
//  Created by ddrccw on 15/10/14.
//  Copyright © 2015年 ddrccw. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCTransitionConst.h"
@import UIKit;

@interface CCTransitionAnimator : UIPercentDrivenInteractiveTransition
<UIViewControllerAnimatedTransitioning, CCTransitionAnimatorProtocol>

@property (assign, nonatomic) CCTransitionAnimationOption operation;

@end
