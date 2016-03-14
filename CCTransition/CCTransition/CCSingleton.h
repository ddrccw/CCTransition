//
//  CCSingleton.h
//
//
//  Modified by ddrccw on 13-10-24.
//  ref: http://www.cocoawithlove.com/2008/11/singletons-appdelegates-and-top-level.html
//
//  Copyright (c) 2013年 admin. All rights reserved.
//
/*
 * Implements the base protocol methods to do the appropriate things to ensure singleton status.
 * Applies to memory-managed code, not to garbage-collected code
 * 
 * - (id)retain;
 */

/*
 * Implements the base protocol methods to do the appropriate things to ensure singleton status.
 * Applies to memory-managed code, not to garbage-collected code
 *
 * - (NSUInteger)retainCount;
 */

/*
 * Implements the base protocol methods to do the appropriate things to ensure singleton status.
 * Applies to memory-managed code, not to garbage-collected code
 *
 * - (oneway void)release
 */

/*
 * Implements the base protocol methods to do the appropriate things to ensure singleton status.
 * Applies to memory-managed code, not to garbage-collected code
 *
 * - (id)autorelease
 */

/*
 * implement the default init method if you want to perform initialization
 */

/*
 * method to ensure that another instance is not allocated if someone tries to allocate
 * and initialize an instance of your class directly instead of using the class factory method.
 * Instead, it just returns the shared object.
 *
 *  + (id)allocWithZone:(NSZone *)zone;
 */

/*
 * Implements the base protocol methods to do the appropriate things to ensure singleton     status.
 * Applies to memory-managed code, not to garbage-collected code
 *
- (id)copyWithZone:(NSZone *)zone * 
 */


#import <objc/runtime.h>

#define CC_DECLARE_SINGLETON_FOR_CLASS(classname) \
+ (classname *)sharedInstance;

#if __has_feature(objc_arc)
    #define CC_SYNTHESIZE_SINGLETON_RETAIN_METHODS
#else
    #define CC_SYNTHESIZE_SINGLETON_RETAIN_METHODS \
    - (id)retain \
    { \
        return self; \
    } \
    \
    - (NSUInteger)retainCount \
    { \
        return NSUIntegerMax; \
    } \
    \
    - (oneway void)release \
    { \
    } \
    \
    - (id)autorelease \
    { \
        return self; \
    }
#endif

#define CC_SYNTHESIZE_SINGLETON_FOR_CLASS(classname) \
\
static classname *_sharedInstance = nil; \
\
+ (classname *)sharedInstance \
{ \
    static dispatch_once_t onceToken; \
    dispatch_once(&onceToken, ^{      \
		if(_sharedInstance == nil) { \
			_sharedInstance = [super allocWithZone:NULL]; \
			_sharedInstance = [_sharedInstance init];     \
			method_exchangeImplementations(\
				class_getClassMethod([_sharedInstance class], @selector(sharedInstance)),\
				class_getClassMethod([_sharedInstance class], @selector(cc_lockless_sharedInstance)));\
			method_exchangeImplementations(\
				class_getInstanceMethod([_sharedInstance class], @selector(init)),\
				class_getInstanceMethod([_sharedInstance class], @selector(cc_onlyInitOnce)));\
		}  \
    }); \
  \
   return _sharedInstance; \
} \
\
+ (classname *)cc_lockless_sharedInstance \
{ \
	return _sharedInstance; \
} \
\
+ (id)allocWithZone:(NSZone *)zone \
{ \
	return [self sharedInstance]; \
} \
\
- (id)copyWithZone:(NSZone *)zone \
{ \
	return self; \
} \
- (id)cc_onlyInitOnce \
{ \
	return self;\
} \
\
CC_SYNTHESIZE_SINGLETON_RETAIN_METHODS
