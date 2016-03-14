//
//  CCTransitionManager.h
//  testPush
//
//  Created by ddrccw on 15/10/15.
//  Copyright © 2015年 ddrccw. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCSingleton.h"
#import "CCTransitionAnimator.h"

@interface CCTransitionManager : NSObject<UINavigationControllerDelegate>
CC_DECLARE_SINGLETON_FOR_CLASS(CCTransitionManager)

@property (strong, nonatomic) CCTransitionAnimator *animator;

@end
