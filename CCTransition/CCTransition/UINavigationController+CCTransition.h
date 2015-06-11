//
//  UINavigationController+CCTransition.h
//  
//
//  Created by user on 14-3-6.
//  Copyright (c) 2014年 user. All rights reserved.
//

#import <UIKit/UIKit.h>

enum {
    CCTransitionAnimationOptionNone,
    CCTransitionAnimationOptionDefault,
    CCTransitionAnimationOptionCrossDissolve
};
typedef int CCTransitionAnimationOption;

typedef void(^CCTransitionBlock_t)(UIViewController *viewController, CCTransitionAnimationOption option);


@protocol CCNavigationTransitionGestureDelegate <NSObject>
- (BOOL)backGestureRecognizerShouldBegin:(UIPanGestureRecognizer *)backGesture;
@end

@interface UINavigationController (CCTransition)

////////////////////////////////////////////////////////////////////////////////
#pragma mark - getter and setter
@property(strong, nonatomic) CALayer *prevLayer;
@property(strong, nonatomic) CALayer *transitionLayer;
@property(assign, nonatomic) BOOL transitionAnimating;
@property(strong, nonatomic) UIPanGestureRecognizer *backGesture;
@property(assign, nonatomic) id<CCNavigationTransitionGestureDelegate> backGestureDelegate;
@property(strong, nonatomic) UIViewController *targetViewController;

////////////////////////////////////////////////////////////////////////////////
#pragma mark - push and pop callback
- (void)setWillPushViewControllerBlock:(CCTransitionBlock_t)block;
- (void)setWillPopToViewControllerBlock:(CCTransitionBlock_t)block;
- (void)setDidPushViewControllerBlock:(CCTransitionBlock_t)block;
- (void)setDidPopToViewControllerBlock:(CCTransitionBlock_t)block;

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
- (void)manualDealloc; //!IMPORTANT: need to be called in dealloc ONLY
@end
