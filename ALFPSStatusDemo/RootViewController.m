//
//  RootViewController.m
//  ALFPSStatusDemo
//
//  Created by arien on 16/7/20.
//  Copyright © 2016年 ArienLau. All rights reserved.
//

#import "RootViewController.h"
#import "ALFPSStatus.h"

@implementation RootViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(100, 100, 100, 70);
    [button setTitle:@"End" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(endAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(100, 200, 100, 70);
    [button setTitle:@"Start" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(startAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
}

- (void)endAction
{
    [[ALFPSStatus shareInstance] end];
}

- (void)startAction
{
    [[ALFPSStatus shareInstance] start];
}

@end
