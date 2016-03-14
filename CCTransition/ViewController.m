//
//  ViewController.m
//  CCTransition
//
//  Created by ddrccw on 15/6/4.
//  Copyright (c) 2015年 netease. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.navigationController.viewControllers.count != 1) {
        CCSetBackButtonSelectorInNavigationController(@selector(back));
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)back {
    [self.navigationController popViewController];
}

- (IBAction)crossDissolve:(id)sender {
    ViewController *vc = [ViewController new];
    vc.view.backgroundColor = [UIColor yellowColor];
    [self.navigationController pushViewController:vc option:CCTransitionAnimationOptionCrossDissolvePush];
}

- (IBAction)defaultAction:(id)sender {
    [self.navigationController pushViewController:[ViewController new] option:CCTransitionAnimationOptionDefaultPush];
}

@end
