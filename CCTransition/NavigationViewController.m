//
//  NavigationViewController.m
//  CCTransition
//
//  Created by ddrccw on 15/6/4.
//  Copyright (c) 2015年 netease. All rights reserved.
//

#import "NavigationViewController.h"

@interface NavigationViewController ()

@end

@implementation NavigationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationBar.backgroundColor = [UIColor blackColor];
    [self addBackGesture];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [self manualDealloc];
}

@end
