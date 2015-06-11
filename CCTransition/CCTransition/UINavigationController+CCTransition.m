//
//  UINavigationController+CCTransition.m
//  
//
//  Created by user on 14-3-6.
//  Copyright (c) 2014年 user. All rights reserved.
//

#import "UINavigationController+CCTransition.h"
#import <objc/runtime.h>

////////////////////////////////////////////////////////////////////////////////
static const float kTransitionSpeed = 0.5;
static const float kCrossDissolveDuration = .3;

static NSString * const kCCTransitionAnimationOptionDefaultKey = @"kCCTransitionAnimationOptionDefaultKey";
static NSString * const kCCTransitionAnimationOptionCrossDissolveKey = @"kCCTransitionAnimationOptionCrossDissolveKey";

// 'kRevealViewTriggerLevel' defines the least amount of offset that needs to be panned until the front view snaps _BACK_ to the right edge.
static const UInt16 kRevealViewTriggerLevel = 100;
// 'kVelocityRequiredForQuickFlick' is the minimum speed of the finger required to instantly trigger a reveal/hide.
static const UInt16 kVelocityRequiredForQuickFlick = 1300;

#define ANIMATION_TIMING_FUNC [CAMediaTimingFunction functionWithControlPoints:0.3f :0.0f :0.0f :1.0f]

static CABasicAnimation *createiOS7StyleAnimation(NSString *keyPath, NSValue *fromValue, NSValue *toValue, float speed) {
    CABasicAnimation *theAnimation;
    
    // create the animation object, specifying the position property as the key path
    // the key path is relative to the target animation object (in this case a CALayer)
    theAnimation = [CABasicAnimation animationWithKeyPath:keyPath];
    
    // set the fromValue and toValue to the appropriate points
    theAnimation.fromValue = fromValue;
    theAnimation.toValue = toValue;
    
    theAnimation.speed = speed;
    
    // set a custom timing function
    theAnimation.timingFunction = ANIMATION_TIMING_FUNC;
    
    return theAnimation;
}

static CABasicAnimation *createFastEaseOutAnimation(NSString *keyPath, NSValue *fromValue, NSValue *toValue) {
    CABasicAnimation *theAnimation;
    
    // create the animation object, specifying the position property as the key path
    // the key path is relative to the target animation object (in this case a CALayer)
    theAnimation = [CABasicAnimation animationWithKeyPath:keyPath];
    
    // set the fromValue and toValue to the appropriate points
    theAnimation.fromValue = fromValue;
    theAnimation.toValue = toValue;
    
    theAnimation.speed = 1.5;
    
    // set a custom timing function
    theAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    
    return theAnimation;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - CALayer + CCTransition -
static const char kControlPoint1Key;
static const char kControlPoint2Key;
static const char kCurrentPositionKey;
static int GlobalPrevLayerZPositionIndex = -1000;  //affect all navi
@interface CALayer (CCTransition)
@property (nonatomic, assign) CGPoint controlPoint1;  //view在可视区域内中央附近的点
@property (nonatomic, assign) CGPoint controlPoint2;  //view在可视区域外的点
@property (nonatomic, assign) CGPoint currentPosition;
@end

@implementation CALayer (CCTransition)

- (CGPoint)controlPoint1 {
    return  [objc_getAssociatedObject(self, &kControlPoint1Key) CGPointValue];
}

- (void)setControlPoint1:(CGPoint)controlPoint1 {
    objc_setAssociatedObject(self,
                            &kControlPoint1Key,
                            [NSValue valueWithCGPoint:controlPoint1],
                            OBJC_ASSOCIATION_RETAIN);
}

- (CGPoint)controlPoint2 {
    return  [objc_getAssociatedObject(self, &kControlPoint2Key) CGPointValue];
}

- (void)setControlPoint2:(CGPoint)controlPoint2 {
    objc_setAssociatedObject(self,
                             &kControlPoint2Key,
                             [NSValue valueWithCGPoint:controlPoint2],
                             OBJC_ASSOCIATION_RETAIN);
}

- (CGPoint)currentPosition {
    return  [objc_getAssociatedObject(self, &kCurrentPositionKey) CGPointValue];
}

- (void)setCurrentPosition:(CGPoint)currentPosition {
    objc_setAssociatedObject(self,
                             &kCurrentPositionKey,
                             [NSValue valueWithCGPoint:currentPosition],
                             OBJC_ASSOCIATION_RETAIN);
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark - UINavigationController+CCTransition -
static const char kDummyPrevLayerStackKey;
static const char kPrevLayerKey;
static const char kTransitionLayerKey;
static const char kTransitionAnimatingKey;
static const char kPushingKey;
static const char kBackGestureKey;
static const char kBackGestureDelegateKey;
static const char kWillPushViewControllerKey;
static const char kWillPopToViewControllerKey;
static const char kDidPushViewControllerKey;
static const char kDidPopToViewControllerKey;
static const char kTargetViewControllerKey;

@interface UINavigationController () <UIGestureRecognizerDelegate>

@end

@implementation UINavigationController (CCTransition)

- (void)manualDealloc {
    [self clearDummyPrevLayers];
}

- (UIImage *)snapshot {
    UIView *v = self.view;
    UIGraphicsBeginImageContextWithOptions(v.bounds.size, v.opaque, v.window.screen.scale);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [v.layer renderInContext:ctx];
    UIImage *anImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return anImage;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - getter and setter -

#pragma mark Layer stack

- (NSArray *)popDummyPrevLayerAtIndex:(NSUInteger)index {
    NSMutableArray *dummyLayers = objc_getAssociatedObject(self, &kDummyPrevLayerStackKey);
    NSArray *ret = nil;
    if (dummyLayers && dummyLayers.count > 0) {
        NSUInteger len = dummyLayers.count - index;
        NSRange range = NSMakeRange(index, len);
        ret = [dummyLayers subarrayWithRange:range];
        [dummyLayers removeObjectsInRange:range];
        GlobalPrevLayerZPositionIndex -= len;
    }
    
    return ret;
}

- (CALayer *)dummyPrevLayerAtIndex:(NSUInteger)index {
    NSMutableArray *dummyLayers = objc_getAssociatedObject(self, &kDummyPrevLayerStackKey);
    if (dummyLayers && dummyLayers.count > 0) {
        return [dummyLayers objectAtIndex:index];
    }
    return nil;
}

- (void)popDummyPrevLayer {
    NSMutableArray *dummyLayers = objc_getAssociatedObject(self, &kDummyPrevLayerStackKey);
    if (dummyLayers && dummyLayers.count > 0) {
        [dummyLayers removeObjectAtIndex:dummyLayers.count - 1];
        --GlobalPrevLayerZPositionIndex;
    }
}

- (CALayer *)topDummyPrevLayer {
    NSMutableArray *dummyLayers = objc_getAssociatedObject(self, &kDummyPrevLayerStackKey);
    if (dummyLayers && dummyLayers.count > 0) {
        return dummyLayers[dummyLayers.count - 1];
    }
    return nil;
}

- (void)pushDummyPrevLayer:(CALayer *)dummyPrevLayer {
    NSMutableArray *dummyLayers = objc_getAssociatedObject(self, &kDummyPrevLayerStackKey);
    if (!dummyLayers) {
        dummyLayers = [NSMutableArray array];
        objc_setAssociatedObject(self, &kDummyPrevLayerStackKey, dummyLayers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    dummyPrevLayer.zPosition = GlobalPrevLayerZPositionIndex++;
    [dummyLayers addObject:dummyPrevLayer];
}

- (void)clearDummyPrevLayers {
    NSMutableArray *dummyLayers = objc_getAssociatedObject(self, &kDummyPrevLayerStackKey);
    if (dummyLayers) {
        GlobalPrevLayerZPositionIndex -= dummyLayers.count;
        [dummyLayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
        [dummyLayers removeAllObjects];
    }
}

- (CALayer *)primitivePrevLayer {
    return objc_getAssociatedObject(self, &kPrevLayerKey);
}

- (CALayer *)prevLayer {
    CALayer *prevLayer = objc_getAssociatedObject(self, &kPrevLayerKey);
    if (!prevLayer) {
        prevLayer = [CALayer layer];
        //来电话时会导致y=20
        float x = self.view.frame.origin.x;
        float y = self.view.frame.origin.y;
        float w = self.view.frame.size.width;
        float h = self.view.frame.size.height;
        if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation) &&
            !CGAffineTransformEqualToTransform(self.view.transform, CGAffineTransformIdentity)) {
            prevLayer.controlPoint1 = CGPointMake(x + w / 2, h / 2);
            prevLayer.controlPoint2 = CGPointMake(x + w / 2, self.view.bounds.size.height / 3.0);
            prevLayer.transform = self.view.layer.transform;
        }
        else {
            prevLayer.controlPoint1 = CGPointMake(w / 2, y + h / 2);
            prevLayer.controlPoint2 = CGPointMake(self.view.bounds.size.width / 3.0, y + h / 2);
        }
        prevLayer.currentPosition = CGPointZero;
        prevLayer.frame = self.view.frame;
        prevLayer.contents = (id)[self snapshot].CGImage;
        objc_setAssociatedObject(self, &kPrevLayerKey, prevLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return prevLayer;
}

- (void)setPrevLayer:(CALayer *)aLayer {
    objc_setAssociatedObject(self, &kPrevLayerKey, aLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CALayer *)realTransitionLayer {
    return self.view.layer;
}

- (CALayer *)transitionLayer {
    return objc_getAssociatedObject(self, &kTransitionLayerKey);
}

- (void)setTransitionLayer:(CALayer *)aLayer {
    //来电话时会导致y=20
    float x = self.view.frame.origin.x;
    float y = self.view.frame.origin.y;
    float w = self.view.frame.size.width;
    float h = self.view.frame.size.height;
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation) &&
        !CGAffineTransformEqualToTransform(self.view.transform, CGAffineTransformIdentity)) {
        aLayer.controlPoint1 = CGPointMake(x + w / 2, h / 2);
        aLayer.controlPoint2 = CGPointMake(x + w / 2, h / 2 + h);
    }
    else {
        aLayer.controlPoint1 = CGPointMake(w / 2, y + h / 2);;
        aLayer.controlPoint2 = CGPointMake(w / 2 + w, y + h / 2);
    }
    
    aLayer.shadowOffset = CGSizeMake(-1, 0);
    aLayer.shadowColor = [UIColor blackColor].CGColor;
    aLayer.shadowOpacity = 1;
    aLayer.shadowPath = [UIBezierPath bezierPathWithRect:self.view.bounds].CGPath;
    aLayer.shouldRasterize = YES;
    aLayer.rasterizationScale = [UIScreen mainScreen].scale;
    objc_setAssociatedObject(self, &kTransitionLayerKey, aLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark Guesture

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

#pragma mark others

- (BOOL)transitionAnimating {
    NSNumber *animating = objc_getAssociatedObject(self, &kTransitionAnimatingKey);
    return [animating boolValue];
}

- (void)setTransitionAnimating:(BOOL)animating {
    objc_setAssociatedObject(self, &kTransitionAnimatingKey, @(animating), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)pushing {
    NSNumber *pushing = objc_getAssociatedObject(self, &kPushingKey);
    return [pushing boolValue];
}

- (void)setPushing:(BOOL)pushing {
    objc_setAssociatedObject(self, &kPushingKey, @(pushing), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIViewController *)targetViewController {
    return objc_getAssociatedObject(self, &kTargetViewControllerKey);
}

- (void)setTargetViewController:(UIViewController *)targetViewController {
    objc_setAssociatedObject(self, &kTargetViewControllerKey, targetViewController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSUInteger)targetViewControllerIndex {
    if (self.targetViewController) {
        return [self.viewControllers indexOfObject:self.targetViewController];
    }
    return NSNotFound;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - push and pop callback
- (void)setWillPushViewControllerBlock:(CCTransitionBlock_t)block {
    objc_setAssociatedObject(self, &kWillPushViewControllerKey, block, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (CCTransitionBlock_t)willPushViewControllerBlock {
    return objc_getAssociatedObject(self, &kWillPushViewControllerKey);
}

- (void)setWillPopToViewControllerBlock:(CCTransitionBlock_t)block {
    objc_setAssociatedObject(self, &kWillPopToViewControllerKey, block, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (CCTransitionBlock_t)willPopToViewControllerBlock {
    return objc_getAssociatedObject(self, &kWillPopToViewControllerKey);
}

- (void)setDidPushViewControllerBlock:(CCTransitionBlock_t)block {
    objc_setAssociatedObject(self, &kDidPushViewControllerKey, block, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (CCTransitionBlock_t)didPushViewControllerBlock {
    return objc_getAssociatedObject(self, &kDidPushViewControllerKey);
}

- (void)setDidPopToViewControllerBlock:(CCTransitionBlock_t)block {
    objc_setAssociatedObject(self, &kDidPopToViewControllerKey, block, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (CCTransitionBlock_t)didPopToViewControllerBlock {
    return objc_getAssociatedObject(self, &kDidPopToViewControllerKey);
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - gesture 
- (void)addBackGesture {
    [self.view addGestureRecognizer:self.backGesture];
}

- (void)removeBackGesture {
    [self.view removeGestureRecognizer:self.backGesture];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    NSUInteger index = [self.viewControllers indexOfObject:self.topViewController];
    if (index > 0) {
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
    if ([self transitionAnimating]) return;
    CGPoint velocity = [gesture velocityInView:self.view];
    NSUInteger index = [self.viewControllers indexOfObject:self.topViewController];

    // 1. Ask the delegate (if appropriate) if we are allowed to do the particular interaction:
    // 2. Now that we've know we're here, we check whether we're just about to _START_ an interaction,...
    if (UIGestureRecognizerStateBegan == [gesture state]){
        if (velocity.x > 0) {
            CALayer *prevLayer = [self topDummyPrevLayer];
            self.prevLayer = prevLayer;
            if (!prevLayer.superlayer) {
                [self.view.layer.superlayer insertSublayer:prevLayer below:self.view.layer];
            }
            [CATransaction begin];
            [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
            self.prevLayer.hidden = NO;
            [CATransaction commit];
            self.transitionLayer = [self realTransitionLayer];
            CALayer *transLayer = [self transitionLayer];
            transLayer.currentPosition = CGPointZero;
            transLayer.position = transLayer.controlPoint1;
        }
        
        if (velocity.x > kVelocityRequiredForQuickFlick)
		{
            //            NSLog(@"quick flick");
            [self popToViewController:self.viewControllers[index - 1]
                               option:CCTransitionAnimationOptionDefault
                           inProgress:YES];
		}
    }
    
    // 3. ...or maybe the interaction already _ENDED_?
	else if (UIGestureRecognizerStateEnded == [gesture state])
	{
		// Case a): Quick finger flick fast enough to cause instant change:
		if (velocity.x > kVelocityRequiredForQuickFlick)
		{
//            NSLog(@"quick flick");
            [self popToViewController:self.viewControllers[index - 1]
                               option:CCTransitionAnimationOptionDefault
                           inProgress:YES];
		}
		// Case b) Slow pan/drag ended:
		else
		{
            float dynamicTriggerLevel = kRevealViewTriggerLevel;
            float offset = 0;
            if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation) &&
                !CGAffineTransformEqualToTransform(self.view.transform, CGAffineTransformIdentity))
            {
                offset = fabs(self.transitionLayer.position.y - self.transitionLayer.controlPoint1.y);
            }
            else {
                offset = fabs(self.transitionLayer.position.x - self.transitionLayer.controlPoint1.x);
            }
//            NSLog(@"Slow pan/drag=%f, position.x=%f", offset, self.transitionLayer.position.x);
			if (offset >= dynamicTriggerLevel) {
//                NSLog(@"Slow pan/drag pop");
                [self popToViewController:self.viewControllers[index - 1]
                                   option:CCTransitionAnimationOptionDefault
                               inProgress:YES];
            }
			else if (offset < dynamicTriggerLevel && offset != 0.0f) {
//                NSLog(@"Slow pan/drag push");
                [self pushViewController:self.topViewController fake:YES];
            }
		}
		
		return;
	}
    else {
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];

        // 4. None of the above? That means it's _IN PROGRESS_!
        CGFloat panX = [gesture translationInView:self.view].x;
//        NSLog(@"%@", NSStringFromCGPoint([gesture translationInView:self.view]));
        CGFloat fakePanX = panX * 1;
        if (fakePanX > 0) {
            CGPoint c = self.transitionLayer.controlPoint1;
            CGFloat w = self.view.bounds.size.width;
           
            if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation) &&
                !CGAffineTransformEqualToTransform(self.view.transform, CGAffineTransformIdentity))
            {
                float offsetY = 0;
                offsetY = (fakePanX * (c.y - w / 3.0)) / w;
                float prevLayerExpectedOffsetY = w / 3.0 + offsetY;
                float transLayerExpectedOffsetY = c.y + fakePanX;
                if (prevLayerExpectedOffsetY > self.prevLayer.controlPoint1.y) {
                    self.prevLayer.position = self.prevLayer.controlPoint1;
                    self.prevLayer.currentPosition = self.prevLayer.position;
                    if (transLayerExpectedOffsetY > self.transitionLayer.controlPoint2.y) {
                        self.transitionLayer.position = self.transitionLayer.controlPoint2;
                        self.transitionLayer.currentPosition = self.transitionLayer.position;
                    }
                    else {
                        self.transitionLayer.position = CGPointMake(c.x, transLayerExpectedOffsetY);
                        self.transitionLayer.currentPosition = self.transitionLayer.position;
                    }
                }
                else {
                    self.prevLayer.position = CGPointMake(c.x, prevLayerExpectedOffsetY);
                    self.prevLayer.currentPosition = self.prevLayer.position;
                    self.transitionLayer.position = CGPointMake(c.x, transLayerExpectedOffsetY);
                    self.transitionLayer.currentPosition = self.transitionLayer.position;
                }
            }
            else {
                float offsetX = 0;
                offsetX = (fakePanX * (c.x - w / 3.0)) / w;
                float prevLayerExpectedOffsetX = w / 3.0 + offsetX;
                float transLayerExpectedOffsetX = c.x + fakePanX;
                if (prevLayerExpectedOffsetX > self.prevLayer.controlPoint1.x) {
                    self.prevLayer.position = self.prevLayer.controlPoint1;
                    self.prevLayer.currentPosition = self.prevLayer.position;
                    if (transLayerExpectedOffsetX > self.transitionLayer.controlPoint2.x) {
                        self.transitionLayer.position = self.transitionLayer.controlPoint2;
                        self.transitionLayer.currentPosition = self.transitionLayer.position;
                    }
                    else {
                        self.transitionLayer.position = CGPointMake(transLayerExpectedOffsetX, c.y);
                        self.transitionLayer.currentPosition = self.transitionLayer.position;
                    }
                }
                else {
                    self.prevLayer.position = CGPointMake(prevLayerExpectedOffsetX, c.y);
                    self.prevLayer.currentPosition = self.prevLayer.position;
                    self.transitionLayer.position = CGPointMake(transLayerExpectedOffsetX, c.y);
                    self.transitionLayer.currentPosition = self.transitionLayer.position;
                }
            }
        }
        [CATransaction commit];
    }
}
////////////////////////////////////////////////////////////////////////////////
#pragma mark - push and pop
- (void)pushViewController:(UIViewController *)viewController fake:(BOOL)fake {
    [self pushViewController:viewController option:CCTransitionAnimationOptionDefault fake:fake];
}

- (void)pushViewController:(UIViewController *)viewController option:(CCTransitionAnimationOption)option fake:(BOOL)fake {
    if ([self transitionAnimating]) return;
    [self setTransitionAnimating:YES];
    [self setPushing:YES];
    self.targetViewController = viewController;

    if (CCTransitionAnimationOptionCrossDissolve == option) {
        self.backGesture.enabled = NO;
        CALayer *prevLayer = self.prevLayer;
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        self.prevLayer.hidden = NO;
        [CATransaction commit];
        [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
        CCTransitionBlock_t willPush = [self willPushViewControllerBlock];
        if (willPush) {
            willPush(viewController, option);
        }
        [self pushViewController:viewController animated:NO];
        [self pushDummyPrevLayer:prevLayer];
        self.transitionLayer = self.realTransitionLayer;
        
        if (!prevLayer.superlayer) {
            [self.view.layer.superlayer insertSublayer:prevLayer below:self.view.layer];
        }
        
        CABasicAnimation *ani1 = createiOS7StyleAnimation(@"opacity",
                                                          @.3,
                                                          @0,
                                                          .5);
        ani1.delegate = self;
        ani1.removedOnCompletion = NO;
        ani1.fillMode = kCAFillModeForwards;
        ani1.duration = kCrossDissolveDuration;
        [self.prevLayer addAnimation:ani1 forKey:kCCTransitionAnimationOptionCrossDissolveKey];
        
        CABasicAnimation *ani2 = createiOS7StyleAnimation(@"opacity",
                                                         @0.7,
                                                         @1,
                                                         .5);
        ani2.delegate = self;
        ani2.duration = kCrossDissolveDuration;
        ani2.removedOnCompletion = NO;
        ani2.fillMode = kCAFillModeForwards;
        [self.transitionLayer addAnimation:ani2 forKey:kCCTransitionAnimationOptionCrossDissolveKey];
    }
    else if (CCTransitionAnimationOptionDefault == option) {
        self.backGesture.enabled = NO;
        CALayer *prevLayer = nil;
        if (!fake) {
            prevLayer = self.prevLayer;
            [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
            CCTransitionBlock_t willPush = [self willPushViewControllerBlock];
            if (willPush) {
                willPush(viewController, option);
            }
            [self pushViewController:viewController animated:NO];
            [self pushDummyPrevLayer:prevLayer];
        }
        else {
            self.prevLayer = [self topDummyPrevLayer];
            prevLayer = self.prevLayer;
        }
        
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        self.prevLayer.hidden = NO;
        [CATransaction commit];

        self.transitionLayer = self.realTransitionLayer;
        CALayer *transLayer = self.transitionLayer;
        if (!prevLayer.superlayer) {
            [self.view.layer.superlayer insertSublayer:prevLayer below:self.view.layer];
        }
        
        CGPoint fromPoint = CGPointZero;
        if (!CGPointEqualToPoint(CGPointZero, prevLayer.currentPosition)) {
            fromPoint = prevLayer.currentPosition;
        }
        else {
            fromPoint = prevLayer.controlPoint1;
        }
        
        CABasicAnimation *ani1 = nil;
        if (!fake) {
            ani1 = createiOS7StyleAnimation(@"position",
                                            [NSValue valueWithCGPoint:fromPoint],
                                            [NSValue valueWithCGPoint:prevLayer.controlPoint2],
                                            kTransitionSpeed);

        }
        else {
            ani1 = createFastEaseOutAnimation(@"position",
                                              [NSValue valueWithCGPoint:fromPoint],
                                              [NSValue valueWithCGPoint:prevLayer.controlPoint2]);
        }
        
        ani1.delegate = self;
        ani1.removedOnCompletion = NO;
        ani1.fillMode = kCAFillModeForwards;
        [self.prevLayer addAnimation:ani1 forKey:kCCTransitionAnimationOptionDefaultKey];
        
        if (!CGPointEqualToPoint(CGPointZero, transLayer.currentPosition)) {
            fromPoint = transLayer.currentPosition;
        }
        else {
            fromPoint = transLayer.controlPoint2;
        }
        
        CABasicAnimation* ani2 = nil;
        if (!fake) {
            ani2 = createiOS7StyleAnimation(@"position",
                                            [NSValue valueWithCGPoint:fromPoint],
                                            [NSValue valueWithCGPoint:transLayer.controlPoint1],
                                            kTransitionSpeed);
        }
        else {
            ani2 = createFastEaseOutAnimation(@"position",
                                              [NSValue valueWithCGPoint:fromPoint],
                                              [NSValue valueWithCGPoint:transLayer.controlPoint1]);

        }
        ani2.delegate = self;
        ani2.removedOnCompletion = NO;
        ani2.fillMode = kCAFillModeForwards;
        [self.transitionLayer addAnimation:ani2 forKey:kCCTransitionAnimationOptionDefaultKey];
    }
    else {
        self.backGesture.enabled = NO;
        CALayer *prevLayer = nil;
        if (!fake) {
            prevLayer = self.prevLayer;
            if (!prevLayer.superlayer) {
                [self.view.layer.superlayer insertSublayer:prevLayer below:self.view.layer];
            }
            [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
            CCTransitionBlock_t willPush = [self willPushViewControllerBlock];
            if (willPush) {
                willPush(viewController, option);
            }
            [self pushViewController:viewController animated:NO];
            [self pushDummyPrevLayer:prevLayer];
            [CATransaction begin];
            [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
            self.prevLayer.hidden = YES;
            [CATransaction commit];
        }
        else {
            //DO NOTHING
        }
        self.prevLayer = nil;
        CCTransitionBlock_t block = [self didPushViewControllerBlock];
        if (block) {
            block(self.topViewController, option);
        }
        self.targetViewController = nil;
        self.transitionAnimating = NO;
        self.backGesture.enabled = YES;
    }
}

- (void)pushViewController:(UIViewController *)viewController option:(CCTransitionAnimationOption)option {
    [self pushViewController:viewController option:option fake:NO];
}

- (void)pushViewController:(UIViewController *)viewController {
    [self pushViewController:viewController fake:NO];
}

- (NSArray *)popToViewController:(UIViewController *)viewController option:(CCTransitionAnimationOption)option inProgress:(BOOL)inProgress {
    if ([self transitionAnimating]) return nil;
    [self setTransitionAnimating:YES];
    [self setPushing:NO];
    self.targetViewController = viewController;
    [[NSNotificationCenter defaultCenter] removeObserver:self.topViewController
                                                    name:UIKeyboardWillChangeFrameNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self.topViewController
                                                    name:UIKeyboardDidChangeFrameNotification
                                                  object:nil];
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
    NSArray *arr = nil;
    if (CCTransitionAnimationOptionCrossDissolve == option) {
        self.backGesture.enabled = NO;
        self.transitionLayer = self.realTransitionLayer;
        CCTransitionBlock_t willPop = [self willPopToViewControllerBlock];
        if (willPop) {
            willPop(viewController, option);
        }
        NSUInteger idx = [self targetViewControllerIndex] + 1;
        arr = [self.viewControllers subarrayWithRange:NSMakeRange(idx, [self.viewControllers count] - idx)];
        CALayer *prevLayer = [self dummyPrevLayerAtIndex:idx - 1];
        self.prevLayer = prevLayer;
        if (!prevLayer.superlayer) {
            [self.view.layer.superlayer insertSublayer:prevLayer below:self.view.layer];
        }
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        self.prevLayer.hidden = NO;
        [CATransaction commit];
        CABasicAnimation *ani1 = createiOS7StyleAnimation(@"opacity",
                                                          @.8,
                                                          @1,
                                                          .5);
        ani1.delegate = self;
        ani1.removedOnCompletion = NO;
        ani1.fillMode = kCAFillModeForwards;
        ani1.duration = kCrossDissolveDuration;
        [self.prevLayer addAnimation:ani1 forKey:kCCTransitionAnimationOptionCrossDissolveKey];
        
        CABasicAnimation *ani2 = createiOS7StyleAnimation(@"opacity",
                                                          @0.2,
                                                          @0,
                                                          .5);
        ani2.delegate = self;
        ani2.duration = kCrossDissolveDuration;
        ani2.removedOnCompletion = NO;
        ani2.fillMode = kCAFillModeForwards;
        [self.transitionLayer addAnimation:ani2 forKey:kCCTransitionAnimationOptionCrossDissolveKey];
    }
    else if (CCTransitionAnimationOptionDefault == option) {
        self.backGesture.enabled = NO;
        self.transitionLayer = self.realTransitionLayer;
        CALayer *transLayer = self.realTransitionLayer;
        CCTransitionBlock_t willPop = [self willPopToViewControllerBlock];
        if (willPop) {
            willPop(viewController, option);
        }
        
        NSUInteger idx = [self targetViewControllerIndex] + 1;
        arr = [self.viewControllers subarrayWithRange:NSMakeRange(idx, [self.viewControllers count] - idx)];
        CALayer *prevLayer = [self dummyPrevLayerAtIndex:idx - 1];
        self.prevLayer = prevLayer;
        if (!prevLayer.superlayer) {
            [self.view.layer.superlayer insertSublayer:prevLayer below:self.view.layer];
        }
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        self.prevLayer.hidden = NO;
        [CATransaction commit];

        CGPoint fromPoint = CGPointZero;
        if (!CGPointEqualToPoint(CGPointZero, prevLayer.currentPosition)) {
            fromPoint = prevLayer.currentPosition;
        }
        else {
            fromPoint = prevLayer.controlPoint2;
        }
        CABasicAnimation* ani1 = createiOS7StyleAnimation(@"position",
                                                          [NSValue valueWithCGPoint:fromPoint],
                                                          [NSValue valueWithCGPoint:prevLayer.controlPoint1],
                                                          kTransitionSpeed);
        ani1.delegate = self;
        ani1.removedOnCompletion = NO;
        ani1.fillMode = kCAFillModeForwards;
        [prevLayer addAnimation:ani1 forKey:kCCTransitionAnimationOptionDefaultKey];
        
        if (!CGPointEqualToPoint(CGPointZero, transLayer.currentPosition)) {
            fromPoint = transLayer.currentPosition;
        }
        else {
            fromPoint = transLayer.controlPoint1;
        }
        
        CABasicAnimation *ani2 = nil;
        if (inProgress) {
            ani2 = createFastEaseOutAnimation(@"position",
                                              [NSValue valueWithCGPoint:fromPoint],
                                              [NSValue valueWithCGPoint:transLayer.controlPoint2]);
        }
        else {
            ani2 = createiOS7StyleAnimation(@"position",
                                            [NSValue valueWithCGPoint:fromPoint],
                                            [NSValue valueWithCGPoint:transLayer.controlPoint2],
                                            kTransitionSpeed);
        }

        ani2.delegate = self;
        ani2.removedOnCompletion = NO;
        ani2.fillMode = kCAFillModeForwards;
        [transLayer addAnimation:ani2 forKey:kCCTransitionAnimationOptionDefaultKey];
        
    }
    else {
        self.backGesture.enabled = NO;
        CCTransitionBlock_t willPop = [self willPopToViewControllerBlock];
        if (willPop) {
            willPop(viewController, option);
        }
        
        arr = [self popToViewController:viewController animated:NO];
        CCTransitionBlock_t block = [self didPopToViewControllerBlock];
        NSUInteger idx = [self targetViewControllerIndex];
        NSArray *dummyPrevLayers = [self popDummyPrevLayerAtIndex:idx];
        [dummyPrevLayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
        if (block) {
            block(self.topViewController, option);
        }
        self.targetViewController = nil;
        self.transitionAnimating = NO;
        self.backGesture.enabled = YES;
        
    }
    
    return arr;
}

- (NSArray *)popToViewController:(UIViewController *)viewController option:(CCTransitionAnimationOption)option {
    return [self popToViewController:viewController option:option inProgress:NO];
}

- (NSArray *)popToViewController:(UIViewController *)viewController {
    return [self popToViewController:viewController option:CCTransitionAnimationOptionDefault];
}

- (NSArray *)popToRootViewControllerWithOption:(CCTransitionAnimationOption)option {
    return [self popToViewController:self.viewControllers[0] option:option];
}

- (NSArray *)popViewControllerWithOption:(CCTransitionAnimationOption)option {
    NSUInteger index = [self.viewControllers indexOfObject:self.topViewController];
    NSArray *arr = nil;
    if (NSNotFound != index && index) {
        arr = [self popToViewController:self.viewControllers[--index] option:option];
    }
    
    return arr;
}

- (NSArray *)popToRootViewController {
    return [self popToViewController:self.viewControllers[0]];
}

- (NSArray *)popViewController {
    return [self popViewControllerWithOption:CCTransitionAnimationOptionDefault];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - animation delegate
- (void)handleWhenFinishAnimation {
    CCTransitionBlock_t block = nil;
    if ([self pushing]) {
        block = [self didPushViewControllerBlock];
    }
    else {
        [self popToViewController:self.targetViewController animated:NO];
        block = [self didPopToViewControllerBlock];
        NSUInteger idx = [self targetViewControllerIndex];
        NSArray *dummyPrevLayers = [self popDummyPrevLayerAtIndex:idx];
        [dummyPrevLayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    }
    
    if (block) {
        block(self.topViewController, CCTransitionAnimationOptionDefault);
    }
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [[self realTransitionLayer] removeAllAnimations];
    [self realTransitionLayer].position = [self realTransitionLayer].controlPoint1;
    [CATransaction commit];
    [self realTransitionLayer].currentPosition = CGPointZero;
    self.targetViewController = nil;
    self.transitionAnimating = NO;
    self.backGesture.enabled = YES;
}

- (void)animationDidStop:(CAAnimation *)animation finished:(BOOL)flag {
    if (animation == [self.primitivePrevLayer animationForKey:kCCTransitionAnimationOptionDefaultKey]) {
        [[self primitivePrevLayer] removeAllAnimations];
        self.primitivePrevLayer.currentPosition = CGPointZero;
        if ([self pushing]) {
            self.primitivePrevLayer.position = self.primitivePrevLayer.controlPoint2;
        }
        else {
            self.primitivePrevLayer.position = self.primitivePrevLayer.controlPoint1;
        }
        self.primitivePrevLayer.hidden = YES;

        self.prevLayer = nil;
        if (![self transitionLayer]) {
            [self handleWhenFinishAnimation];
        }
    }
    else if (animation == [self.transitionLayer animationForKey:kCCTransitionAnimationOptionDefaultKey]) {
        self.transitionLayer = nil;
        if (![self primitivePrevLayer]) {
            [self handleWhenFinishAnimation];
        }
    }
    else if (animation == [self.primitivePrevLayer animationForKey:kCCTransitionAnimationOptionCrossDissolveKey]) {
        [[self primitivePrevLayer] removeAllAnimations];
        self.primitivePrevLayer.currentPosition = CGPointZero;
        self.primitivePrevLayer.hidden = YES;
        self.prevLayer = nil;
        if (![self transitionLayer]) {
            [self handleWhenFinishAnimation];
        }

    }
    else if (animation == [[self transitionLayer] animationForKey:kCCTransitionAnimationOptionCrossDissolveKey]) {
        self.transitionLayer = nil;
        if (![self primitivePrevLayer]) {
            [self handleWhenFinishAnimation];
        }
    }
}
@end
