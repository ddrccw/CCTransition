//
//  UINavigationController+CCTransition.m
//  testPush
//
//  Created by ddrccw on 15/10/15.
//  Copyright © 2015年 ddrccw. All rights reserved.
//

#import "UINavigationController+CCTransition.h"
#import "CCTransitionManager.h"

////////////////////////////////////////////////////////////////////////////////
#pragma mark - UINavigationController -
static const char kPrefersNavigationBarHiddenKey;
typedef void (^_CCViewControllerWillAppearInjectBlock)(UIViewController *viewController, BOOL animated);

@interface UIViewController (CCTransitionPrivate)

@property (nonatomic, copy) _CCViewControllerWillAppearInjectBlock CC_willAppearInjectBlock;

@end

@implementation UIViewController (CCTransitionPrivate)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        SEL originalSelector = @selector(viewWillAppear:);
        SEL swizzledSelector = @selector(CC_viewWillAppear:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL success = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
        if (success) {
            class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (void)CC_viewWillAppear:(BOOL)animated
{
    // Forward to primary implementation.
    [self CC_viewWillAppear:animated];
    
    if (self.CC_willAppearInjectBlock) {
        self.CC_willAppearInjectBlock(self, animated);
    }
}

- (_CCViewControllerWillAppearInjectBlock)CC_willAppearInjectBlock
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setCC_willAppearInjectBlock:(_CCViewControllerWillAppearInjectBlock)block
{
    objc_setAssociatedObject(self, @selector(CC_willAppearInjectBlock), block, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end


@interface UIViewController ()
@end

@implementation UIViewController (CCTransition)

- (BOOL)prefersNavigationBarHidden {
    return [objc_getAssociatedObject(self, &kPrefersNavigationBarHiddenKey) boolValue];
}

- (void)setPrefersNavigationBarHidden:(BOOL)prefersNavigationBarHidden {
    objc_setAssociatedObject(self, &kPrefersNavigationBarHiddenKey, @(prefersNavigationBarHidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark - UINavigationController -
static const char kBackGestureKey;
static const char kBackGestureDelegateKey;
static const char kWillTransitKey;
static const char kDidTransitKey;

@interface UINavigationController () <UIGestureRecognizerDelegate>
@end

@implementation UINavigationController (CCTransition)

////////////////////////////////////////////////////////////////////////////////
#pragma mark - push and pop callback
- (void)setWillTransitBlock:(CCTransitionBlock_t)block {
    objc_setAssociatedObject(self, &kWillTransitKey, block, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (CCTransitionBlock_t)willTransitBlock {
    return objc_getAssociatedObject(self, &kWillTransitKey);
}

- (void)setDidTransitBlock:(CCTransitionBlock_t)block {
    objc_setAssociatedObject(self, &kDidTransitKey, block, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (CCTransitionBlock_t)didTransitBlock {
    return objc_getAssociatedObject(self, &kDidTransitKey);
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - push and pop
- (void)prepareForOption:(CCTransitionAnimationOption)option
      fromViewController:(UIViewController *)fromVC
        toViewController:(UIViewController *)toVC
{
    fromVC.view.userInteractionEnabled = NO;
    toVC.view.userInteractionEnabled = NO;
    if (fromVC != toVC) {
        CCTransitionBlock_t willTransit = [self willTransitBlock];
        if (willTransit) {
            willTransit(fromVC, toVC, option);
        }
    }
    
    BOOL prefersNavigationBarHiddenOfFromVC = fromVC.prefersNavigationBarHidden;
    BOOL prefersNavigationBarHiddenOfToVC = toVC.prefersNavigationBarHidden;
    
    if (CCTransitionAnimationOptionIsPushing(option)) {
        if (prefersNavigationBarHiddenOfFromVC && !prefersNavigationBarHiddenOfToVC) {
            [fromVC.navigationItem setHidesBackButton:YES animated:NO];
        }
        else if (!prefersNavigationBarHiddenOfFromVC && prefersNavigationBarHiddenOfToVC) {
            [toVC.navigationItem setHidesBackButton:YES animated:NO];
        }
        else if (prefersNavigationBarHiddenOfFromVC && prefersNavigationBarHiddenOfToVC) {
            [fromVC.navigationItem setHidesBackButton:YES animated:NO];
            [toVC.navigationItem setHidesBackButton:YES animated:NO];
        }
    }
    
    __weak __typeof__(self) wself = self;
    _CCViewControllerWillAppearInjectBlock block = ^(UIViewController *viewController, BOOL animated) {
        __strong __typeof__(self) self = wself;
        if (self) {
            if (animated) {
                if ((!prefersNavigationBarHiddenOfFromVC && prefersNavigationBarHiddenOfToVC) ||
                    (prefersNavigationBarHiddenOfFromVC && !prefersNavigationBarHiddenOfToVC))
                {
                    //自定义动画实现, animator
                    if (option == CCTransitionAnimationOptionDefaultPush ||
                        option == CCTransitionAnimationOptionDefaultPop ||
                        option == CCTransitionAnimationOptionCrossDissolvePush ||
                        option == CCTransitionAnimationOptionCrossDissolvePop)
                    {
                        [self setNavigationBarHidden:NO animated:NO];
                    }
                    else {
                        [self setNavigationBarHidden:prefersNavigationBarHiddenOfToVC animated:YES];
                    }
                }
                else {
                    [self setNavigationBarHidden:prefersNavigationBarHiddenOfToVC animated:YES];
                }
            }
            else {
                [self setNavigationBarHidden:prefersNavigationBarHiddenOfToVC animated:NO];
            }
        }
    };
    
    toVC.CC_willAppearInjectBlock = block;
}

- (void)doneForOption:(CCTransitionAnimationOption)option
   fromViewController:(UIViewController *)fromVC
     toViewController:(UIViewController *)toVC
{
    //CCTransitionAnimationOptionNone 不会触发 animator
    if (option == CCTransitionAnimationOptionNonePush ||
        option == CCTransitionAnimationOptionNonePop ||
        fromVC == toVC)
    {
        fromVC.view.userInteractionEnabled = YES;
        toVC.view.userInteractionEnabled = YES;
        if (fromVC != toVC) {
            CCTransitionBlock_t didTransit = [self didTransitBlock];
            if (didTransit) {
                didTransit(fromVC, toVC, option);
            }
        }
    }
}

- (void)pushViewController:(UIViewController *)viewController option:(CCTransitionAnimationOption)option
{
    [CCTransitionManager sharedInstance].animator.operation = option;
    UIViewController *fromVC = self.viewControllers.lastObject;
    UIViewController *toVC = viewController;
    [self prepareForOption:option fromViewController:fromVC toViewController:toVC];
    [self pushViewController:viewController animated:(option != CCTransitionAnimationOptionNonePush)];
    [self doneForOption:option fromViewController:fromVC toViewController:toVC];
}

- (NSArray *)popToViewController:(UIViewController *)viewController option:(CCTransitionAnimationOption)option
{
    [CCTransitionManager sharedInstance].animator.operation = option;
    UIViewController *fromVC = self.topViewController;
    UIViewController *toVC = viewController;
    [self prepareForOption:option fromViewController:fromVC toViewController:toVC];
    NSArray *vcs = [self popToViewController:viewController animated:(option != CCTransitionAnimationOptionNonePop)];
    [self doneForOption:option fromViewController:fromVC toViewController:toVC];
    return vcs;
}

- (NSArray *)popToRootViewControllerWithOption:(CCTransitionAnimationOption)option
{
    [CCTransitionManager sharedInstance].animator.operation = option;
    UIViewController *fromVC = self.topViewController;
    UIViewController *toVC = self.viewControllers[0];
    [self prepareForOption:option fromViewController:fromVC toViewController:toVC];
    NSArray *vcs = [self popToRootViewControllerAnimated:(option != CCTransitionAnimationOptionNonePop)];
    [self doneForOption:option fromViewController:fromVC toViewController:toVC];
    return vcs;
}

- (NSArray *)popViewControllerWithOption:(CCTransitionAnimationOption)option {
    NSUInteger index = [self.viewControllers indexOfObject:self.topViewController];
    NSArray *arr = nil;
    if (NSNotFound != index && index) {
        arr = [self popToViewController:self.viewControllers[--index] option:option];
    }
    
    return arr;
}

- (void)pushViewController:(UIViewController *)viewController
{
    [self pushViewController:viewController option:CCTransitionAnimationOptionDefaultPush];
}

- (NSArray *)popToViewController:(UIViewController *)viewController
{
    return [self popToViewController:viewController option:CCTransitionAnimationOptionDefaultPop];
}

- (NSArray *)popToRootViewController {
    return [self popToRootViewControllerWithOption:CCTransitionAnimationOptionDefaultPop];
}

- (NSArray *)popViewController {
    return [self popViewControllerWithOption:CCTransitionAnimationOptionDefaultPop];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - gesture
- (UIPanGestureRecognizer *)backGesture {
    UIPanGestureRecognizer *backGesture = objc_getAssociatedObject(self, &kBackGestureKey);
    if (!backGesture) {
        backGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(back:)];
        backGesture.delegate = self;
        objc_setAssociatedObject(self, &kBackGestureKey, backGesture, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return backGesture;
}

- (void)setBackGesture:(UIPanGestureRecognizer *)aGesture {
    objc_setAssociatedObject(self, &kBackGestureKey, aGesture, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id<CCNavigationTransitionGestureDelegate>)backGestureDelegate {
    return objc_getAssociatedObject(self, &kBackGestureDelegateKey);
}

- (void)setBackGestureDelegate:(id<CCNavigationTransitionGestureDelegate>)backGestureDelegate {
    objc_setAssociatedObject(self, &kBackGestureDelegateKey, backGestureDelegate, OBJC_ASSOCIATION_ASSIGN);
}

- (void)addBackGesture {
    [self.view addGestureRecognizer:self.backGesture];
}

- (void)removeBackGesture {
    [self.view removeGestureRecognizer:self.backGesture];
}

- (BOOL)backGestureWasTriggeredInteractively {
    return self.backGesture.state != UIGestureRecognizerStatePossible &&
           self.backGesture.state != UIGestureRecognizerStateFailed;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    NSUInteger index = [self.viewControllers indexOfObject:self.topViewController];
    if (index > 0) {
        // Ignore pan gesture when the navigation controller is currently in transition.
        if ([[self valueForKey:@"_isTransitioning"] boolValue]) {
            return NO;
        }
        
        if ([CCTransitionManager sharedInstance].animator.isAnimating) {
            return NO;
        }
        
        if (!gestureRecognizer.view) {
            return NO;
        }
        
        if ([[self backGestureDelegate] respondsToSelector:@selector(backGestureRecognizerShouldBegin:)]) {
            return [self.backGestureDelegate backGestureRecognizerShouldBegin:self.backGesture];
        }
        
        return YES;
    }
    else {
        return NO;
    }
}

- (void)back:(UIPanGestureRecognizer *)gesture {
    CGPoint velocity = [gesture velocityInView:self.view];
    CGFloat progress = [gesture translationInView:gesture.view].x / gesture.view.bounds.size.width;
    progress = MIN(1.0, MAX(0.0, progress));

    // 1. Ask the delegate (if appropriate) if we are allowed to do the particular interaction:
    // 2. Now that we've know we're here, we check whether we're just about to _START_ an interaction,...
    if (UIGestureRecognizerStateBegan == [gesture state]){
        if (velocity.x > 0) {
            [self popViewController];
        }
    }
    // 3. ...or maybe the interaction already _ENDED_?
    else if (UIGestureRecognizerStateEnded == [gesture state] ||
             UIGestureRecognizerStateCancelled == [gesture state])
    {
        if (velocity.x > kVelocityRequiredForQuickFlick) {
//            NSLog(@"> flick statue=%d", (int)[gesture state]);
            [[CCTransitionManager sharedInstance].animator finishInteractiveTransition];
        }
        else {
            if ([gesture translationInView:gesture.view].x > kRevealViewTriggerLevel) {
//                NSLog(@"> kRevealViewTriggerLevel statue=%d", (int)[gesture state]);
                [[CCTransitionManager sharedInstance].animator finishInteractiveTransition];
            } else {
//                NSLog(@"< kRevealViewTriggerLevel statue=%d", (int)[gesture state]);
                [[CCTransitionManager sharedInstance].animator cancelInteractiveTransition];
            }
        }
    }
    else {
//        NSLog(@"velocity=%f, progress=%f", velocity.x, progress);
        if (velocity.x < 0) {  //push
            progress = -progress;
        }
        [[CCTransitionManager sharedInstance].animator updateInteractiveTransition:progress];
    }
}

@end
















