//
//  CCTransitionAnimator.m
//  testPush
//
//  Created by ddrccw on 15/10/14.
//  Copyright © 2015年 ddrccw. All rights reserved.
//

#import "CCTransitionAnimator.h"
#import <objc/runtime.h>
#import "UINavigationController+CCTransition.h"

////////////////////////////////////////////////////////////////////////////////
#pragma mark - CALayer + CCTransition -
static const char kControlPoint1Key;
static const char kControlPoint2Key;
static const char kIsAnimatingKey;

@interface CALayer (CCTransition)
@property (nonatomic, assign) CGPoint controlPoint1;  //view在可视区域内中央附近的点
@property (nonatomic, assign) CGPoint controlPoint2;  //view在可视区域外的点
@property (nonatomic, assign) BOOL isAnimating;
@end

@implementation CALayer (CCTransition)

- (CGPoint)controlPoint1 {
    return  [objc_getAssociatedObject(self, &kControlPoint1Key) CGPointValue];
}

- (void)setControlPoint1:(CGPoint)controlPoint1 {
    objc_setAssociatedObject(self,
                             &kControlPoint1Key,
                             [NSValue valueWithCGPoint:controlPoint1],
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGPoint)controlPoint2 {
    return  [objc_getAssociatedObject(self, &kControlPoint2Key) CGPointValue];
}

- (void)setControlPoint2:(CGPoint)controlPoint2 {
    objc_setAssociatedObject(self,
                             &kControlPoint2Key,
                             [NSValue valueWithCGPoint:controlPoint2],
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isAnimating {
    return [objc_getAssociatedObject(self, &kIsAnimatingKey) boolValue];
}

- (void)setIsAnimating:(BOOL)isAnimating {
    objc_setAssociatedObject(self,
                             &kIsAnimatingKey,
                             @(isAnimating),
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end

////////////////////////////////////////////////////////////////////////////////
@interface CCTransitionAnimator ()
@property (strong, nonatomic) id <UIViewControllerContextTransitioning>transitionContext;
//@property (assign, nonatomic) BOOL transitionAnimating;

- (UIViewController *)fromViewController;
- (UIViewController *)toViewController;
- (UIView *)fromView;
- (UIView *)toView;
- (CALayer *)fromViewLayer;
- (CALayer *)toViewLayer;
- (UIView *)containerView;
- (UINavigationBar *)navigationBar;
@end

@implementation CCTransitionAnimator

+ (BOOL)isEqualOrGreaterThanIOS8 {
    return ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) ? YES : NO;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - getter
- (UIViewController *)fromViewController {
    if (self.transitionContext) {
        return [self.transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    }
    else {
        return nil;
    }
}

- (UIViewController *)toViewController {
    if (self.transitionContext) {
        return [self.transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    }
    else {
        return nil;
    }
}


- (UIView *)fromView {
    if (self.transitionContext) {
        UIView *fromView = nil;
        if ([self.transitionContext respondsToSelector:@selector(viewForKey:)]) {
            fromView = [self.transitionContext viewForKey:UITransitionContextFromViewKey];
        }
        else {
            fromView = self.fromViewController.view;
        }
        return fromView;
    }
    else {
        return nil;
    }
}

- (UIView *)toView {
    if (self.transitionContext) {
        UIView *toView = nil;
        if ([self.transitionContext respondsToSelector:@selector(viewForKey:)]) {
            toView = [self.transitionContext viewForKey:UITransitionContextToViewKey];
        }
        else {
            toView = self.toViewController.view;
        }
        return toView;
    }
    else {
        return nil;
    }
}

- (CALayer *)fromViewLayer {
    if (self.transitionContext) {
        UIView *fromView = self.fromView;
        return fromView.layer;
    }
    else {
        return nil;
    }
}

- (CALayer *)toViewLayer {
    if (self.transitionContext) {
        UIView *toView = self.toView;
        return toView.layer;
    }
    else {
        return nil;
    }
}

- (UIView *)containerView {
    return [self.transitionContext containerView];
}

- (UINavigationBar *)navigationBar {
    return self.toViewController.navigationController.navigationBar;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - public api
- (BOOL)isAnimating {
    return (self.fromViewLayer.isAnimating || self.toViewLayer.isAnimating);
}

- (void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    [super startInteractiveTransition:transitionContext];
    [self initNavigationBar];
}

//TODO: 暂时未做CCTransitionAnimationOptionCrossDissolvePop的处理
- (void)updateInteractiveTransition:(CGFloat)percentComplete {
    UINavigationController *navi = self.toViewController.navigationController;
    UINavigationBar *bar = navi.navigationBar;
    CGFloat w = bar.frame.size.width;
    CGPoint toPoint = bar.center;
    CGFloat progress = fabs(percentComplete);

    //NSLog(@"navi center=%@, p=%f", NSStringFromCGPoint(navi.navigationBar.center), progress);
    //不要用CATransaction，否则和view transition不同步
    if (!self.fromViewController.prefersNavigationBarHidden &&
        self.toViewController.prefersNavigationBarHidden)
    {
        [bar.layer removeAllAnimations];
        toPoint.x = bar.layer.controlPoint2.x - w * (1 - progress);
        toPoint.y = bar.layer.controlPoint2.y;
        bar.layer.position = toPoint;
    }
    else if (self.fromViewController.prefersNavigationBarHidden &&
             !self.toViewController.prefersNavigationBarHidden)
    {
        [bar.layer removeAllAnimations];
        toPoint.x = bar.layer.controlPoint2.x + w * progress;
        toPoint.y = bar.layer.controlPoint2.y;
        bar.layer.position = toPoint;
    }
    [super updateInteractiveTransition:progress];
}

//TODO: 暂时未做CCTransitionAnimationOptionCrossDissolvePop的处理
- (void)finishInteractiveTransition {
    [super finishInteractiveTransition];
    UINavigationController *navi = self.toViewController.navigationController;
    UINavigationBar *bar = navi.navigationBar;
    CGPoint toPoint = bar.layer.controlPoint1;
    CGPoint fromPoint = bar.center;
    
    if (!self.fromViewController.prefersNavigationBarHidden &&
        self.toViewController.prefersNavigationBarHidden)
    {
        toPoint = bar.layer.controlPoint2;
        [bar.layer removeAllAnimations];
        bar.layer.position = toPoint;
        CABasicAnimation *ani1 = createAnimationWithTimingFunciton(@"position",
                                                                   [NSValue valueWithCGPoint:fromPoint],
                                                                   [NSValue valueWithCGPoint:toPoint],
                                                                   self.completionSpeed,
                                                                   [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]);
        ani1.duration = [self transitionDuration:self.transitionContext] * (1 - self.percentComplete);
        ani1.delegate = self;
        ani1.removedOnCompletion = NO;
        [bar.layer addAnimation:ani1 forKey:kCCTransitionBarAnimationOptionKey];
    }
    else if (self.fromViewController.prefersNavigationBarHidden &&
             !self.toViewController.prefersNavigationBarHidden)
    {
        toPoint = bar.layer.controlPoint1;
        [bar.layer removeAllAnimations];
        [self handleWhenFinishBarAnimation];
//        CABasicAnimation *ani1 = createAnimationWithTimingFunciton(@"position",
//                                                                   [NSValue valueWithCGPoint:fromPoint],
//                                                                   [NSValue valueWithCGPoint:toPoint],
//                                                                   self.completionSpeed,
//                                                                   [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]);
//        ani1.duration = [self transitionDuration:self.transitionContext] * (1 - self.percentComplete);
//        ani1.delegate = self;
//        ani1.removedOnCompletion = NO;
//        [bar.layer addAnimation:ani1 forKey:kCCTransitionBarAnimationOptionKey];
    }
}

- (void)cancelInteractiveTransition {
    [super cancelInteractiveTransition];
    UINavigationController *navi = self.toViewController.navigationController;
    UINavigationBar *bar = navi.navigationBar;
    CGPoint toPoint = bar.center;
    CGPoint fromPoint = bar.center;

    if (!self.fromViewController.prefersNavigationBarHidden &&
        self.toViewController.prefersNavigationBarHidden)
    {
        toPoint = bar.layer.controlPoint1;
        [bar.layer removeAllAnimations];
        [self handleWhenFinishBarAnimation];
//        CABasicAnimation *ani1 = createAnimationWithTimingFunciton(@"position",
//                                                                   [NSValue valueWithCGPoint:fromPoint],
//                                                                   [NSValue valueWithCGPoint:toPoint],
//                                                                   self.completionSpeed,
//                                                                   [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]);
//        ani1.duration = [self transitionDuration:self.transitionContext] * self.percentComplete;
//        [bar.layer addAnimation:ani1 forKey:nil];
    }
    else if (self.fromViewController.prefersNavigationBarHidden &&
             !self.toViewController.prefersNavigationBarHidden)
    {
        toPoint = bar.layer.controlPoint2;
        [bar.layer removeAllAnimations];
        bar.layer.position = toPoint;
        bar.hidden = NO;
        CABasicAnimation *ani1 = createAnimationWithTimingFunciton(@"position",
                                                                   [NSValue valueWithCGPoint:fromPoint],
                                                                   [NSValue valueWithCGPoint:toPoint],
                                                                   self.completionSpeed,
                                                                   [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]);
        ani1.duration = [self transitionDuration:self.transitionContext] * self.percentComplete;
        ani1.delegate = self;
        ani1.removedOnCompletion = NO;
        [bar.layer addAnimation:ani1 forKey:kCCTransitionBarAnimationOptionKey];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIViewControllerAnimatedTransitioning
/*
    interactive transitions
 */
// This is used for percent driven interactive transitions, as well as for container controllers that have companion animations that might need to
// synchronize with the main animation.
- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContex {
    return 0.5;
}

/* 
    noninteractive transitions
 */
// This method can only  be a nop if the transition is interactive and not a percentDriven interactive transition.
- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    self.transitionContext = transitionContext;
    // Get the set of relevant objects.
    UIView *containerView = [transitionContext containerView];
    containerView.backgroundColor = [UIColor whiteColor];
    UIView *fromView = self.fromView;
//    [[NSNotificationCenter defaultCenter] removeObserver:self.topViewController
//                                                    name:UIKeyboardWillChangeFrameNotification
//                                                  object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self.topViewController
//                                                    name:UIKeyboardDidChangeFrameNotification
//                                                  object:nil];
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
    UIView *toView = self.toView;
    CGRect frameForToViewController = CGRectZero;
    //以下3种情况因为bar的hidden自己控制，所以frame也要自己计算
    if (self.operation == CCTransitionAnimationOptionDefaultPush ||
        self.operation == CCTransitionAnimationOptionDefaultPop ||
        self.operation == CCTransitionAnimationOptionCrossDissolvePush ||
        self.operation == CCTransitionAnimationOptionCrossDissolvePop)
    {
        if (!self.fromViewController.prefersNavigationBarHidden &&
            self.toViewController.prefersNavigationBarHidden)
        {
            frameForToViewController = containerView.bounds;
        }
        else if (self.fromViewController.prefersNavigationBarHidden &&
                 !self.toViewController.prefersNavigationBarHidden)
        {
            frameForToViewController = containerView.bounds;
            UINavigationBar *bar = self.toViewController.navigationController.navigationBar;
            frameForToViewController.origin.y = CGRectGetMaxY(bar.frame);
            frameForToViewController.size.height -= CGRectGetMaxY(bar.frame);
        }
        else {
            frameForToViewController = [self.transitionContext finalFrameForViewController:self.toViewController];
        }
    }
    else {
        frameForToViewController = [self.transitionContext finalFrameForViewController:self.toViewController];
    }
    toView.frame = frameForToViewController;
    
//    float x = containerView.frame.origin.x;
    __block CGFloat y = 0;
    __block CGFloat w = 0;
    __block CGFloat h = 0;
    
    y = fromView.frame.origin.y;
    w = fromView.frame.size.width;
    h = fromView.frame.size.height;
    
    void(^adjustForToView)(void) = ^(void) {
        y = frameForToViewController.origin.y;
        w = frameForToViewController.size.width;
        h = frameForToViewController.size.height;
    };
    
    if (self.operation == CCTransitionAnimationOptionDefaultPush) {
        [containerView addSubview:toView];

        self.fromViewLayer.controlPoint1 = CGPointMake(w / 2, y + h / 2);
        self.fromViewLayer.controlPoint2 = CGPointMake(containerView.bounds.size.width / 3.0, y + h / 2);
        adjustForToView();
        self.toViewLayer.controlPoint1 = CGPointMake(w / 2, y + h / 2);
        self.toViewLayer.controlPoint2 = CGPointMake(w / 2 + w, y + h / 2);
        
        self.fromViewLayer.position = self.fromViewLayer.controlPoint1;
        self.toViewLayer.position = self.toViewLayer.controlPoint2;
        [self pushOrPopAnimation];
        [self pushOrPopBarAnimation];
    }
    else if (self.operation == CCTransitionAnimationOptionDefaultPop) {
        [containerView insertSubview:toView belowSubview:fromView];
        self.fromViewLayer.controlPoint1 = CGPointMake(w / 2, y + h / 2);
        self.fromViewLayer.controlPoint2 = CGPointMake(w / 2 + w, y + h / 2);
        adjustForToView();
        self.toViewLayer.controlPoint1 = CGPointMake(w / 2, y + h / 2);
        self.toViewLayer.controlPoint2 = CGPointMake(containerView.bounds.size.width / 3.0, y + h / 2);
        self.fromViewLayer.position = self.fromViewLayer.controlPoint1;
        self.toViewLayer.position = self.toViewLayer.controlPoint2;
        
        if ([self.transitionContext isInteractive]) {
            [self addShadowForLayer:self.fromViewLayer];
            self.fromViewLayer.isAnimating = YES;
            self.toViewLayer.isAnimating = YES;

            [UIView animateWithDuration:[self transitionDuration:self.transitionContext]
                                  delay:0 options:UIViewAnimationOptionCurveLinear
                             animations:^
            {
                self.fromViewLayer.position = [self.fromViewLayer controlPoint2];
                self.toViewLayer.position = self.toViewLayer.controlPoint1;
             } completion:^(BOOL finished) {
                 [self handleWhenFinishAnimation];
             }];
        }
        else {
            [self pushOrPopAnimation];
            [self pushOrPopBarAnimation];
        }
    }
    else if (self.operation == CCTransitionAnimationOptionCrossDissolvePush) {
        [containerView addSubview:toView];
        adjustForToView();
        self.toViewLayer.controlPoint1 = CGPointMake(w / 2, y + h / 2);
        [self crossDissolvePushOrPopAnimation];
        [self crossDissolvePushOrPopBarAnimation];
    }
    else if (self.operation ==  CCTransitionAnimationOptionCrossDissolvePop) {
        [containerView insertSubview:toView belowSubview:fromView];
        adjustForToView();
        self.toViewLayer.controlPoint1 = CGPointMake(w / 2, y + h / 2);
        [self crossDissolvePushOrPopAnimation];
        [self crossDissolvePushOrPopBarAnimation];
    }
    else {
        
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - animation delegate
- (void)addShadowForLayer:(CALayer *)aLayer {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    if (self.operation == CCTransitionAnimationOptionDefaultPush ||
        self.operation == CCTransitionAnimationOptionDefaultPop)
    {
        aLayer.masksToBounds = NO;
        aLayer.shadowOffset = CGSizeMake(-1, 0);
        aLayer.shadowColor = [UIColor lightGrayColor].CGColor;
        aLayer.shadowOpacity = 1;
        aLayer.shadowPath = [UIBezierPath bezierPathWithRect:self.containerView.bounds].CGPath;
        aLayer.shouldRasterize = YES;
        aLayer.rasterizationScale = [UIScreen mainScreen].scale;
    }
    else {
        aLayer.shadowColor = [UIColor clearColor].CGColor;
    }
    [CATransaction commit];
}

- (void)addShadowForBarLayer {
//    CALayer *aLayer = self.navigationBar.layer;
//    [CATransaction begin];
//    [CATransaction setDisableActions:YES];
//    aLayer.shadowOffset = CGSizeMake(-1, 0);
//    aLayer.shadowColor = [UIColor blackColor].CGColor;
//    aLayer.shadowOpacity = 1;
//    UIBezierPath *path = [UIBezierPath bezierPath];
//
//    [path moveToPoint:CGPointMake(0.0, -20)];// -self.navigationBar.frame.origin.y)];
//    [path addLineToPoint:CGPointMake(20, -20)];//-self.navigationBar.frame.origin.y)];
//
////    // This is the extra point in the middle :) Its the secret sauce.
//    [path addLineToPoint:CGPointMake(20, 40)];
//    // Move to the Bottom Left Corner
//    [path addLineToPoint:CGPointMake(0, 43)];
//    // Move to the Close the Path
//    [path closePath];
//    aLayer.shadowPath = path.CGPath;
////    aLayer.shouldRasterize = YES;
////    aLayer.rasterizationScale = [UIScreen mainScreen].scale;
//    [CATransaction commit];
}


//only work in  CCTransitionAnimationOptionDefaultPush or CCTransitionAnimationOptionDefaultPop
//           or CCTransitionAnimationOptionCrossDissolvePush or CCTransitionAnimationOptionCrossDissolvePop
- (void)initNavigationBar {
    UINavigationController *navi = self.toViewController.navigationController;
    UINavigationBar *bar = navi.navigationBar;
    CGRect frame = bar.frame;
    if (!self.fromViewController.prefersNavigationBarHidden &&
        self.toViewController.prefersNavigationBarHidden)
    {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        
        //CCTransitionAnimationOptionDefaultPush or CCTransitionAnimationOptionDefaultPop
        if (self.operation != CCTransitionAnimationOptionCrossDissolvePush &&
            self.operation != CCTransitionAnimationOptionCrossDissolvePop)
        {
            frame.origin.x = 0;
            frame.origin.y = 0;
            if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]) &&
                [UIApplication sharedApplication].statusBarHidden)
            {
                frame.size.height = 44;
            }
            else {
                frame.size.height = 64;
            }
            bar.frame = frame;
            CGPoint c = CGPointMake(frame.size.width / 2, frame.size.height / 2);
            CGFloat w = bar.frame.size.width;
            
            bar.layer.controlPoint1 = c;
            if (self.operation == CCTransitionAnimationOptionDefaultPush) {
                bar.layer.controlPoint2 = CGPointMake(c.x - w, c.y);
            }
            else {
                bar.layer.controlPoint2 = CGPointMake(c.x + w, c.y);
            }
            bar.layer.position = bar.layer.controlPoint1;
        }
        bar.layer.opacity = 1;
        bar.hidden = NO;
        [CATransaction flush];
        [CATransaction commit];
    }
    else if (self.fromViewController.prefersNavigationBarHidden &&
             !self.toViewController.prefersNavigationBarHidden)
    {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        
        //CCTransitionAnimationOptionDefaultPush or CCTransitionAnimationOptionDefaultPop
        if (self.operation != CCTransitionAnimationOptionCrossDissolvePush &&
            self.operation != CCTransitionAnimationOptionCrossDissolvePop)
        {
            frame.origin.x = 0;
            frame.origin.y = 0;
            if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]) &&
                [UIApplication sharedApplication].statusBarHidden)
            {
                frame.size.height = 44;
            }
            else {
                frame.size.height = 64;
            }
            bar.frame = frame;
            CGPoint c = CGPointMake(frame.size.width / 2, frame.size.height / 2);
            CGFloat w = bar.frame.size.width;
            
            bar.layer.controlPoint1 = c;
            if (self.operation == CCTransitionAnimationOptionDefaultPush) {
                bar.layer.controlPoint2 = CGPointMake(c.x + w, c.y);
            }
            else {
                bar.layer.controlPoint2 = CGPointMake(c.x - w, c.y);
            }
            
            bar.layer.position = bar.layer.controlPoint2;
            bar.layer.opacity = 1;
            bar.hidden = NO;
        }
        else {
            if (self.operation != CCTransitionAnimationOptionCrossDissolvePush) {
                bar.layer.opacity = kCrossDissolvePopBarInitOpacityValue;
                bar.hidden = NO;
            }
            else {
                bar.layer.opacity = 0;
            }
        }
        [CATransaction flush];
        [CATransaction commit];
    }
    else {
//        frame.origin.x = 0;
//        frame.origin.y = UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]) ? 0 : 20;
//        bar.frame = frame;
//        CGPoint c = bar.center;
//        CGFloat w = bar.frame.size.width;
//
//        bar.layer.controlPoint2 = c;
//        bar.layer.position = bar.layer.controlPoint1;
    }
    
    [self addShadowForBarLayer];
}

//only work in  CCTransitionAnimationOptionDefaultPush or CCTransitionAnimationOptionDefaultPop
- (void)pushOrPopBarAnimation {
    [self initNavigationBar];

    UINavigationController *navi = self.toViewController.navigationController;
    UINavigationBar *bar = navi.navigationBar;
    CGPoint fromPoint = CGPointZero;
    CGPoint toPoint = CGPointZero;

    if (!self.fromViewController.prefersNavigationBarHidden &&
        self.toViewController.prefersNavigationBarHidden)
    {

        fromPoint = bar.layer.controlPoint1;
        toPoint = bar.layer.controlPoint2;
    }
    else if (self.fromViewController.prefersNavigationBarHidden &&
             !self.toViewController.prefersNavigationBarHidden)
    {

        fromPoint = bar.layer.controlPoint2;
        toPoint = bar.layer.controlPoint1;
    }
    else {
        return;
    }
    
    //        POPBasicAnimation *positionAnim = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerPosition];
    //        positionAnim.fromValue = [NSValue valueWithCGPoint:fromPoint];
    //        positionAnim.toValue = [NSValue valueWithCGPoint:toPoint];
    //        positionAnim.timingFunction = ANIMATION_TIMING_FUNC;
    //        positionAnim.duration = [self transitionDuration:self.transitionContext];
    //        [positionAnim setCompletionBlock:^(POPAnimation *anim, BOOL finished) {
    //            [bar setHidden:YES];
    //        }];
    //        [bar.layer pop_addAnimation:positionAnim forKey:@"positionAnim"];
    
    CABasicAnimation* ani1 = createiOS7StyleAnimation(@"position",
                                                      [NSValue valueWithCGPoint:fromPoint],
                                                      [NSValue valueWithCGPoint:toPoint],
                                                      kTransitionSpeed);
    ani1.delegate = self;
    ani1.removedOnCompletion = NO;
    ani1.fillMode = kCAFillModeForwards;
    [navi.navigationBar.layer addAnimation:ani1 forKey:kCCTransitionBarAnimationOptionKey];
 
}

- (void)pushOrPopAnimation {
    if (self.operation == CCTransitionAnimationOptionDefaultPush) {
        [self addShadowForLayer:self.toViewLayer];
    }
    else {
        [self addShadowForLayer:self.fromViewLayer];
    }
    CGPoint fromPoint = self.fromViewLayer.controlPoint1;
    CGPoint toPoint = self.fromViewLayer.controlPoint2;
    CABasicAnimation* ani1 = nil;
    if ([self.transitionContext isInteractive]) {
        ani1 = createLinearAnimation(@"position",
                                     [NSValue valueWithCGPoint:fromPoint],
                                     [NSValue valueWithCGPoint:toPoint]);
    }
    else {
        ani1 = createiOS7StyleAnimation(@"position",
                                        [NSValue valueWithCGPoint:fromPoint],
                                        [NSValue valueWithCGPoint:toPoint],
                                        kTransitionSpeed);
    }
    ani1.delegate = self;
    ani1.removedOnCompletion = NO;
    ani1.fillMode = kCAFillModeForwards;
    [self.fromViewLayer addAnimation:ani1 forKey:kCCTransitionAnimationOptionDefaultKey];
    self.fromViewLayer.isAnimating = YES;
    
    fromPoint = self.toViewLayer.controlPoint2;
    toPoint = self.toViewLayer.controlPoint1;
    CABasicAnimation *ani2 = nil;
    if ([self.transitionContext isInteractive]) {
        ani2 = createLinearAnimation(@"position",
                                     [NSValue valueWithCGPoint:fromPoint],
                                     [NSValue valueWithCGPoint:toPoint]);
    }
    else {
        ani2 = createiOS7StyleAnimation(@"position",
                                        [NSValue valueWithCGPoint:fromPoint],
                                        [NSValue valueWithCGPoint:toPoint],
                                        kTransitionSpeed);
    }
    ani2.delegate = self;
    ani2.removedOnCompletion = NO;
    ani2.fillMode = kCAFillModeForwards;
    [self.toViewLayer addAnimation:ani2 forKey:kCCTransitionAnimationOptionDefaultKey];
    self.toViewLayer.isAnimating = YES;
}

- (void)crossDissolvePushOrPopBarAnimation {
    [self initNavigationBar];
    
    UINavigationController *navi = self.toViewController.navigationController;
    UINavigationBar *bar = navi.navigationBar;
    CGFloat fromValue = 0;
    CGFloat toValue = 0;
    if (!self.fromViewController.prefersNavigationBarHidden &&
        self.toViewController.prefersNavigationBarHidden)
    {
        fromValue = 1;
        toValue = 0;
    }
    else if (self.fromViewController.prefersNavigationBarHidden &&
             !self.toViewController.prefersNavigationBarHidden)
    {
        fromValue = kCrossDissolvePopBarInitOpacityValue;
        toValue = 1;
    }
    else {
        return;
    }

    CABasicAnimation* ani1 = createLinearAnimation(@"opacity",
                                                   @(fromValue),
                                                   @(toValue)
                                                   );
    ani1.duration = kCrossDissolveDuration;
    ani1.delegate = self;
    ani1.removedOnCompletion = NO;
    ani1.fillMode = kCAFillModeForwards;
    [bar.layer addAnimation:ani1 forKey:kCCTransitionBarAnimationOptionKey];

}

- (void)crossDissolvePushOrPopAnimation {
    [self addShadowForLayer:self.fromViewLayer];
    [self addShadowForLayer:self.toViewLayer];
    CABasicAnimation *ani1 = createiOS7StyleAnimation(@"opacity",
                                                      @1,
                                                      @0,
                                                      kTransitionSpeed);
    ani1.delegate = self;
    ani1.removedOnCompletion = NO;
    ani1.fillMode = kCAFillModeForwards;
    ani1.duration = kCrossDissolveDuration;
    [self.fromViewLayer addAnimation:ani1 forKey:kCCTransitionAnimationOptionCrossDissolveKey];
    self.fromViewLayer.isAnimating = YES;
    
    CABasicAnimation *ani2 = createiOS7StyleAnimation(@"opacity",
                                                      @0,
                                                      @1,
                                                      kTransitionSpeed);
    ani2.delegate = self;
    ani2.duration = kCrossDissolveDuration;
    ani2.removedOnCompletion = NO;
    ani2.fillMode = kCAFillModeForwards;
    [self.toViewLayer addAnimation:ani2 forKey:kCCTransitionAnimationOptionCrossDissolveKey];
    self.toViewLayer.isAnimating = YES;
}

- (void)handleWhenFinishAnimation {
    self.fromViewLayer.isAnimating = NO;
    self.toViewLayer.isAnimating = NO;
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [self.toViewLayer removeAllAnimations];
    self.toViewLayer.position = self.toViewLayer.controlPoint1;
    if (![self.transitionContext transitionWasCancelled]) {
        [self.fromView removeFromSuperview];
    }
    [CATransaction commit];
    //    self.targetViewController = nil;
    //    self.transitionAnimating = NO;
    //    self.backGesture.enabled = YES;
    __weak __typeof__(self) wself = self;
    [CATransaction setCompletionBlock:^{
        __strong __typeof__(self) self = wself;
        UINavigationController *navi = self.toViewController.navigationController;
        self.fromViewController.view.userInteractionEnabled = YES;
        self.toViewController.view.userInteractionEnabled = YES;
        CCTransitionBlock_t didTransit = [navi didTransitBlock];
        if (didTransit) {
            CCTransitionAnimationOption opt = self.operation;
            if ([self.transitionContext transitionWasCancelled]) {
                if (CCTransitionAnimationOptionIsPushing(opt)) {
                    if (opt == CCTransitionAnimationOptionDefaultPush) {
                        opt = CCTransitionAnimationOptionDefaultPop;
                    }
                    else {
                        opt = CCTransitionAnimationOptionCrossDissolvePop;
                    }
                }
                else {
                    if (opt == CCTransitionAnimationOptionDefaultPop) {
                        opt = CCTransitionAnimationOptionDefaultPush;
                    }
                    else {
                        opt = CCTransitionAnimationOptionCrossDissolvePush;
                    }
                }
                didTransit(self.toViewController, self.fromViewController, opt);
            }
            else {
                didTransit(self.fromViewController, self.toViewController, opt);
            }
        }
        [self.transitionContext completeTransition:![self.transitionContext transitionWasCancelled]];
        self.transitionContext = nil;
    }];
}

- (void)handleWhenFinishBarAnimation {
    if (!self.fromViewController.prefersNavigationBarHidden &&
        self.toViewController.prefersNavigationBarHidden)
    {
        if ([self.transitionContext transitionWasCancelled]) {
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            //CCTransitionAnimationOptionDefaultPush or CCTransitionAnimationOptionDefaultPop
            if (self.operation != CCTransitionAnimationOptionCrossDissolvePush &&
                self.operation != CCTransitionAnimationOptionCrossDissolvePop)
            {
                self.navigationBar.layer.position = self.navigationBar.layer.controlPoint1;
            }
            self.navigationBar.layer.opacity = 1;
            self.navigationBar.hidden = NO;
            [CATransaction commit];
        }
        else {
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            //CCTransitionAnimationOptionDefaultPush or CCTransitionAnimationOptionDefaultPop
            //CCTransitionAnimationOptionDefaultPush or CCTransitionAnimationOptionDefaultPop
            if (self.operation != CCTransitionAnimationOptionCrossDissolvePush &&
                self.operation != CCTransitionAnimationOptionCrossDissolvePop)
            {
                self.navigationBar.layer.position = self.navigationBar.layer.controlPoint2;
            }
            self.navigationBar.layer.opacity = 0;
            self.navigationBar.hidden = YES;
            [CATransaction commit];
        }
    }
    else if (self.fromViewController.prefersNavigationBarHidden &&
             !self.toViewController.prefersNavigationBarHidden)
    {
        if ([self.transitionContext transitionWasCancelled]) {
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            //CCTransitionAnimationOptionDefaultPush or CCTransitionAnimationOptionDefaultPop
            if (self.operation != CCTransitionAnimationOptionCrossDissolvePush &&
                self.operation != CCTransitionAnimationOptionCrossDissolvePop)
            {
                self.navigationBar.layer.position = self.navigationBar.layer.controlPoint2;
            }
            self.navigationBar.layer.opacity = 0;
            self.navigationBar.hidden = YES;
            [CATransaction commit];
        }
        else {
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            //CCTransitionAnimationOptionDefaultPush or CCTransitionAnimationOptionDefaultPop
            if (self.operation != CCTransitionAnimationOptionCrossDissolvePush &&
                self.operation != CCTransitionAnimationOptionCrossDissolvePop)
            {
                self.navigationBar.layer.position = self.navigationBar.layer.controlPoint1;
            }
            self.navigationBar.layer.opacity = 1;
            self.navigationBar.hidden = NO;
            [CATransaction commit];
        }
    }
}

- (void)animationDidStop:(CAAnimation *)animation finished:(BOOL)flag {
    if (animation == [self.fromViewLayer animationForKey:kCCTransitionAnimationOptionDefaultKey]) {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [[self fromViewLayer] removeAllAnimations];
        if ([self.transitionContext transitionWasCancelled]) {
            self.fromViewLayer.position = self.fromViewLayer.controlPoint1;
        }
        else {
            self.fromViewLayer.position = self.fromViewLayer.controlPoint2;
        }
        [CATransaction commit];
        __weak __typeof__(self) wself = self;
        [CATransaction setCompletionBlock:^{
            __strong __typeof__(self) self = wself;
            if (![self.transitionContext transitionWasCancelled]) {
                [self.fromView removeFromSuperview];
            }
            self.fromViewLayer.isAnimating = NO;
            if (!self.toViewLayer.isAnimating) {
                [self handleWhenFinishAnimation];
            }
        }];
    }
    else if (animation == [self.toViewLayer animationForKey:kCCTransitionAnimationOptionDefaultKey] ||
             animation == [self.toViewLayer animationForKey:kCCTransitionAnimationOptionCrossDissolveKey])
    {
        self.toViewLayer.isAnimating = NO;
        if (!self.fromViewLayer.isAnimating) {
            [self handleWhenFinishAnimation];
        }
    }
    else if (animation == [self.fromViewLayer animationForKey:kCCTransitionAnimationOptionCrossDissolveKey]) {
        [[self fromViewLayer] removeAllAnimations];
        if (![self.transitionContext transitionWasCancelled]) {
            [self.fromView removeFromSuperview];
        }
        self.fromViewLayer.isAnimating = NO;
        if (!self.toViewLayer.isAnimating) {
            [self handleWhenFinishAnimation];
        }
    }
    else if (animation == [[self.navigationBar layer] animationForKey:kCCTransitionBarAnimationOptionKey]) {
        [self.navigationBar.layer removeAllAnimations];
        [self handleWhenFinishBarAnimation];
    }
}

@end
