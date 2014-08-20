//
//  ISAppDelegate.h
//  InfiniteScrollViewDemo
//
//  Created by Zheng on 7/31/14.
//  Copyright (c) 2014 Zheng Zhang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InfiniteScrollView : UIScrollView <UIScrollViewDelegate>

@property (nonatomic, strong) NSMutableArray *visibleLabels;
@property (nonatomic, strong) NSMutableArray *candidates;
@property (nonatomic) NSInteger selectedIndex;

- (void)centerItemAtIndex:(NSInteger)index
                 animated:(BOOL)animated;
- (NSInteger)currentIndex;
- (void)addViews:(NSArray *)views;
- (void)addView:(UIView *)view;

@end
