//
//  ISViewController.m
//  InfiniteScrollViewDemo
//
//  Created by Zheng on 7/31/14.
//  Copyright (c) 2014 Zheng Zhang. All rights reserved.
//

#import "ISViewController.h"
#import "InfiniteScrollView.h"

@interface ISViewController ()

@property (nonatomic, strong) InfiniteScrollView *infinite;

@end

@implementation ISViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    _infinite = [[InfiniteScrollView alloc] initWithFrame:self.view.bounds];
    UIView *view1 = [UIView new];
    view1.backgroundColor = [UIColor blackColor];
    view1.bounds = _infinite.bounds;
    
    UIView *view2 = [UIView new];
    view2.backgroundColor = [UIColor whiteColor];
    view2.bounds = _infinite.bounds;
    
    UIView *view3 = [UIView new];
    view3.backgroundColor = [UIColor greenColor];
    view3.bounds = _infinite.bounds;
    
    UIView *view4 = [UIView new];
    view4.backgroundColor = [UIColor redColor];
    view4.bounds = _infinite.bounds;
    
    UIView *view5 = [UIView new];
    view5.backgroundColor = [UIColor grayColor];
    view5.bounds = _infinite.bounds;
    
    [_infinite addViews:@[view1, view2, view3, view4, view5]];
    _infinite.pagingEnabled = YES;

    NSTimer *timer = [NSTimer timerWithTimeInterval:2
                                             target:self
                                           selector:@selector(testScroll)
                                           userInfo:nil
                                            repeats:YES];
   [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    [self.view addSubview:_infinite];
    [_infinite selectItemAtIndex:2 animated:NO];
    [_infinite setNeedsLayout];
}

- (void)testScroll
{
    [_infinite selectItemAtIndex:(arc4random() % 5)
                        animated:YES];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
