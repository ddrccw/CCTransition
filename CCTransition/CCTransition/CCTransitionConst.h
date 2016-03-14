//
//  CCTransitionConst.h
//  testPush
//
//  Created by ddrccw on 15/10/15.
//  Copyright © 2015年 ddrccw. All rights reserved.
//

#ifndef CCTransitionConst_h
#define CCTransitionConst_h

#import <UIKit/UIKit.h>

enum {
    CCTransitionAnimationOptionNonePush = UINavigationControllerOperationNone - 1,
    CCTransitionAnimationOptionNonePop = UINavigationControllerOperationNone,
    CCTransitionAnimationOptionDefaultPush = UINavigationControllerOperationPush,
    CCTransitionAnimationOptionDefaultPop = UINavigationControllerOperationPop,
    CCTransitionAnimationOptionCrossDissolvePush,
    CCTransitionAnimationOptionCrossDissolvePop
};
typedef NSInteger CCTransitionAnimationOption;

static inline BOOL CCTransitionAnimationOptionIsPushing(CCTransitionAnimationOption option) {
    return ((option == CCTransitionAnimationOptionNonePush || (option == CCTransitionAnimationOptionDefaultPush) ||
             option == CCTransitionAnimationOptionCrossDissolvePush));
}

@protocol CCNavigationTransitionGestureDelegate <NSObject>
- (BOOL)backGestureRecognizerShouldBegin:(UIPanGestureRecognizer *)backGesture;
@end

@protocol CCTransitionAnimatorProtocol <NSObject>
@property (assign, nonatomic) CCTransitionAnimationOption operation;
- (BOOL)isAnimating;
@end

typedef void(^CCTransitionBlock_t)(UIViewController *fromViewController, UIViewController *toViewController, CCTransitionAnimationOption option);

static const CGFloat kTransitionSpeed = 0.5;
static const CGFloat kCrossDissolveDuration = .3;
static const CGFloat kCrossDissolvePopBarInitOpacityValue = 0.5;

static NSString * const kCCTransitionAnimationOptionDefaultKey = @"kCCTransitionAnimationOptionDefaultKey";
static NSString * const kCCTransitionAnimationOptionCrossDissolveKey = @"kCCTransitionAnimationOptionCrossDissolveKey";
static NSString * const kCCTransitionBarAnimationOptionKey = @"kCCTransitionBarAnimationOptionKey";

// 'kRevealViewTriggerLevel' defines the least amount of offset that needs to be panned until the front view snaps _BACK_ to the right edge.
static const UInt16 kRevealViewTriggerLevel = 100;
// 'kVelocityRequiredForQuickFlick' is the minimum speed of the finger required to instantly trigger a reveal/hide.
static const UInt16 kVelocityRequiredForQuickFlick = 1300;

#define ANIMATION_TIMING_FUNC [CAMediaTimingFunction functionWithControlPoints:0.3f :0.0f :0.0f :1.0f]

__unused static CABasicAnimation *createAnimationWithTimingFunciton(NSString *keyPath, NSValue *fromValue, NSValue *toValue, float speed, CAMediaTimingFunction *timingFunction) {
    CABasicAnimation *theAnimation;
    
    // create the animation object, specifying the position property as the key path
    // the key path is relative to the target animation object (in this case a CALayer)
    theAnimation = [CABasicAnimation animationWithKeyPath:keyPath];
    
    // set the fromValue and toValue to the appropriate points
    theAnimation.fromValue = fromValue;
    theAnimation.toValue = toValue;
    
    theAnimation.speed = speed;
    
    // set a custom timing function
    theAnimation.timingFunction = timingFunction;
    
    return theAnimation;
}

__unused static CABasicAnimation *createLinearAnimation(NSString *keyPath, id fromValue, id toValue) {
    CABasicAnimation *theAnimation;
    
    // create the animation object, specifying the position property as the key path
    // the key path is relative to the target animation object (in this case a CALayer)
    theAnimation = [CABasicAnimation animationWithKeyPath:keyPath];
    
    // set the fromValue and toValue to the appropriate points
    theAnimation.fromValue = fromValue;
    theAnimation.toValue = toValue;
    
    // set a custom timing function
    theAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    
    return theAnimation;
}

__unused static CABasicAnimation *createiOS7StyleAnimation(NSString *keyPath, NSValue *fromValue, NSValue *toValue, float speed) {
    return createAnimationWithTimingFunciton(keyPath, fromValue, toValue, speed, ANIMATION_TIMING_FUNC);
}

__unused static CABasicAnimation *createFastEaseOutAnimation(NSString *keyPath, NSValue *fromValue, NSValue *toValue, float speed) {
    CABasicAnimation *theAnimation;
    
    // create the animation object, specifying the position property as the key path
    // the key path is relative to the target animation object (in this case a CALayer)
    theAnimation = [CABasicAnimation animationWithKeyPath:keyPath];
    
    // set the fromValue and toValue to the appropriate points
    theAnimation.fromValue = fromValue;
    theAnimation.toValue = toValue;
    
    theAnimation.speed = speed;
    
    // set a custom timing function
    theAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    
    return theAnimation;
}

#endif /* CCTransitionConst_h */
