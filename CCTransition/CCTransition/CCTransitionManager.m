//
//  CCTransitionManager.m
//  testPush
//
//  Created by ddrccw on 15/10/15.
//  Copyright © 2015年 ddrccw. All rights reserved.
//

#import "CCTransitionManager.h"
#import "UINavigationController+CCTransition.h"

@import UIKit;

@interface CCTransitionManager()

@end

@implementation CCTransitionManager
CC_SYNTHESIZE_SINGLETON_FOR_CLASS(CCTransitionManager)

- (instancetype)init {
    if (self = [super init]) {
        _animator = [CCTransitionAnimator new];
    }
    return self;
}

- (id <UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController
                          interactionControllerForAnimationController:(id <UIViewControllerAnimatedTransitioning>) animationController
{
    if ([navigationController backGestureWasTriggeredInteractively]) {
        return self.animator;
    }
    return nil;
}

- (id <UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                   animationControllerForOperation:(UINavigationControllerOperation)operation
                                                fromViewController:(UIViewController *)fromVC
                                                  toViewController:(UIViewController *)toVC
{
    return self.animator;
}

@end
