//
//  Helper.h
//  CCTransition
//
//  Created by ddrccw on 15/6/4.
//  Copyright (c) 2015年 netease. All rights reserved.
//

#ifndef CCTransition_Helper_h
#define CCTransition_Helper_h

#define RGBA(r, g, b, a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]
#define RGB(r, g, b) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1]

// left navigationItems
#if !defined(CCSetLeftButtonSelectorInNavigationController)
#define __CCSetLeftButtonSelectorInNavigationController__(                    \
    _SEL_, _IMG_, _HL_IMG_, _TITLE_, L)                                        \
  do {                                                                         \
    UIButton *__NSX_PASTE__(__btn, L) =                                        \
        [UIButton buttonWithType:UIButtonTypeCustom];                          \
    if (_IMG_) {                                                               \
      [__NSX_PASTE__(__btn, L) setBackgroundImage:_IMG_                        \
                                         forState:UIControlStateNormal];       \
    }                                                                          \
    if (_HL_IMG_) {                                                            \
      [__NSX_PASTE__(__btn, L) setBackgroundImage:_HL_IMG_                     \
                                         forState:UIControlStateHighlighted];  \
    }                                                                          \
    if (![NSString isNilOrEmptyForString:_TITLE_]) {                           \
      [__NSX_PASTE__(__btn, L) setTitle:_TITLE_                                \
                               forState:UIControlStateNormal];                 \
      [__NSX_PASTE__(__btn, L) setTitleColor:[UIColor whiteColor]              \
                                    forState:UIControlStateNormal];            \
      [__NSX_PASTE__(__btn, L) setTitleColor:RGBA(255, 255, 255, 0.8)          \
                                    forState:UIControlStateHighlighted];       \
      [__NSX_PASTE__(__btn, L) setTitleColor:RGBA(255, 255, 255, 0.8)          \
                                    forState:UIControlStateDisabled];          \
    }                                                                          \
    [__NSX_PASTE__(__btn, L) addTarget:self                                    \
                                action:_SEL_                                   \
                      forControlEvents:UIControlEventTouchUpInside];           \
    [__NSX_PASTE__(__btn, L) sizeToFit];                                       \
    UIBarButtonItem *__NSX_PASTE__(__spacer, L) = [[UIBarButtonItem alloc]     \
        initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace            \
                             target:nil                                        \
                             action:nil];                                      \
                                                                               \
    if ([Helper isEqualOrGreaterThanIOS7]) {                              \
      __NSX_PASTE__(__spacer, L).width = -6;                                   \
    } else {                                                                   \
      __NSX_PASTE__(__spacer, L).width = 5;                                    \
    }                                                                          \
                                                                               \
    UIBarButtonItem *__NSX_PASTE__(__btnItem, L) =                             \
        [[UIBarButtonItem alloc] initWithCustomView:__NSX_PASTE__(__btn, L)];  \
    self.navigationItem.leftBarButtonItems =                                   \
        @[ __NSX_PASTE__(__spacer, L), __NSX_PASTE__(__btnItem, L) ];          \
  } while (0)
#define CCSetLeftButtonSelectorInNavigationController(_SEL_, _IMG_, _HL_IMG_, \
                                                       _TITLE_)                \
  __CCSetLeftButtonSelectorInNavigationController__(_SEL_, _IMG_, _HL_IMG_,   \
                                                     _TITLE_, __COUNTER__)
#endif

#if !defined(CCSetBackButtonSelectorInNavigationController)
#define CCSetBackButtonSelectorInNavigationController(_SEL_)                  \
  __CCSetLeftButtonSelectorInNavigationController__(                          \
      _SEL_, [UIImage imageNamed:@"back-white"],                               \
      [UIImage imageNamed:@"back-white-transparent"], nil, __COUNTER__)
#endif

// right navigationItems
#if !defined(CCSetRightButtonSelectorInNavigationController)
#define __CCSetRightButtonSelectorInNavigationController__(                   \
    _SEL_, _IMG_, _HL_IMG_, _TITLE_, L)                                        \
  do {                                                                         \
    UIButton *__NSX_PASTE__(__btn, L) =                                        \
        [UIButton buttonWithType:UIButtonTypeCustom];                          \
    if (_IMG_) {                                                               \
      [__NSX_PASTE__(__btn, L) setBackgroundImage:_IMG_                        \
                                         forState:UIControlStateNormal];       \
    }                                                                          \
    if (_HL_IMG_) {                                                            \
      [__NSX_PASTE__(__btn, L) setBackgroundImage:_HL_IMG_                     \
                                         forState:UIControlStateHighlighted];  \
    }                                                                          \
    if (![NSString isNilOrEmptyForString:_TITLE_]) {                           \
      [__NSX_PASTE__(__btn, L) setTitle:_TITLE_                                \
                               forState:UIControlStateNormal];                 \
      [__NSX_PASTE__(__btn, L) setTitleColor:[UIColor whiteColor]              \
                                    forState:UIControlStateNormal];            \
      [__NSX_PASTE__(__btn, L) setTitleColor:RGBA(255, 255, 255, 0.8)          \
                                    forState:UIControlStateHighlighted];       \
      [__NSX_PASTE__(__btn, L) setTitleColor:RGBA(255, 255, 255, 0.8)          \
                                    forState:UIControlStateDisabled];          \
    }                                                                          \
    [__NSX_PASTE__(__btn, L) addTarget:self                                    \
                                action:_SEL_                                   \
                      forControlEvents:UIControlEventTouchUpInside];           \
    [__NSX_PASTE__(__btn, L) sizeToFit];                                       \
    UIBarButtonItem *__NSX_PASTE__(__spacer, L) = [[UIBarButtonItem alloc]     \
        initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace            \
                             target:nil                                        \
                             action:nil];                                      \
                                                                               \
    if ([Helper isEqualOrGreaterThanIOS7]) {                              \
      __NSX_PASTE__(__spacer, L).width = -6;                                   \
    } else {                                                                   \
      __NSX_PASTE__(__spacer, L).width = 5;                                    \
    }                                                                          \
                                                                               \
    UIBarButtonItem *__NSX_PASTE__(__btnItem, L) =                             \
        [[UIBarButtonItem alloc] initWithCustomView:__NSX_PASTE__(__btn, L)];  \
    self.navigationItem.rightBarButtonItems =                                  \
        @[ __NSX_PASTE__(__spacer, L), __NSX_PASTE__(__btnItem, L) ];          \
  } while (0)
#define CCSetRightButtonSelectorInNavigationController(_SEL_, _IMG_,          \
                                                        _HL_IMG_, _TITLE_)     \
  __CCSetRightButtonSelectorInNavigationController__(_SEL_, _IMG_, _HL_IMG_,  \
                                                      _TITLE_, __COUNTER__)
#endif

#endif

#define IOS_VERSION [[UIDevice currentDevice] systemVersion]

@interface Helper : NSObject
+ (BOOL)isEqualOrGreaterThanIOS7;
@end

@interface NSString (Utility)
+ (BOOL)isNilOrEmptyForString:(NSString *)aString;
@end


















