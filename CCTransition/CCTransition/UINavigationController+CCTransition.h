//
//  UINavigationController+CCTransition.h
//  testPush
//
//  Created by ddrccw on 15/10/15.
//  Copyright © 2015年 ddrccw. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CCTransitionConst.h"

@interface UIViewController (CCTransition)
@property(assign, nonatomic) BOOL prefersNavigationBarHidden;
@end

@interface UINavigationController (CCTransition)
@property(weak, nonatomic) id<CCNavigationTransitionGestureDelegate> backGestureDelegate;
@property(strong, nonatomic) UIPanGestureRecognizer *backGesture;

////////////////////////////////////////////////////////////////////////////////
#pragma mark - push and pop callback
- (void)setWillTransitBlock:(CCTransitionBlock_t)block;
- (void)setDidTransitBlock:(CCTransitionBlock_t)block;
- (CCTransitionBlock_t)didTransitBlock;

////////////////////////////////////////////////////////////////////////////////
#pragma mark - push and pop 
- (void)pushViewController:(UIViewController *)viewController option:(CCTransitionAnimationOption)option;
- (NSArray *)popToViewController:(UIViewController *)viewController option:(CCTransitionAnimationOption)option;
- (NSArray *)popToRootViewControllerWithOption:(CCTransitionAnimationOption)option;
- (NSArray *)popViewControllerWithOption:(CCTransitionAnimationOption)option;

- (void)pushViewController:(UIViewController *)viewController;
- (NSArray *)popToViewController:(UIViewController *)viewController;
- (NSArray *)popToRootViewController;
- (NSArray *)popViewController;

////////////////////////////////////////////////////////////////////////////////
#pragma mark - gesture
- (void)addBackGesture;
- (void)removeBackGesture;
- (BOOL)backGestureWasTriggeredInteractively;
@end
