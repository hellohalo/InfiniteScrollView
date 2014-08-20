//
//  ISAppDelegate.h
//  InfiniteScrollViewDemo
//
//  Created by Zheng on 7/31/14.
//  Copyright (c) 2014 Zheng Zhang. All rights reserved.
//

#import "InfiniteScrollView.h"

@interface InfiniteScrollView ()

@end


@implementation InfiniteScrollView

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        _visibleLabels = [[NSMutableArray alloc] init];
        _candidates = [[NSMutableArray alloc] init];
        self.contentSize = CGSizeMake(5000, self.frame.size.height);
        // hide horizontal scroll indicator so our recentering trick is not revealed
        [self setShowsHorizontalScrollIndicator:NO];
        [self addObserver:self
               forKeyPath:@"contentOffset"
                  options:NSKeyValueObservingOptionNew
                  context:nil];
    }
    return self;
}

- (void)setSelectedIndex:(NSInteger)selectedIndex
{
    [self centerItemAtIndex:selectedIndex animated:NO];
}

- (void)adjustContentSize
{
    CGFloat width = 0.0f;
    for (UIView *view in self.candidates) {
        width += CGRectGetWidth(view.frame);
    }
    width = width * 2;
    CGSize size = self.contentSize;
    size.width = width;
    self.contentSize = size;
}

- (void)addView:(UIView *)view
{
    [self.candidates addObject:view];
    [self adjustContentSize];
    [self setNeedsLayout];
}

- (void)addViews:(NSArray *)views
{
    [self adjustContentSize];
    [self.candidates addObjectsFromArray:views];
    [self setNeedsLayout];
}

// return the center item
- (NSInteger)currentIndex
{
    NSInteger maxIndex = INT_MAX;
    CGFloat minDistance = self.contentSize.width;
    CGRect visibleRect = self.bounds;
    visibleRect.origin = self.contentOffset;
    CGFloat centerx = CGRectGetMidX(visibleRect);
    for (UIView *view in self.visibleLabels) {
        if (fabs(view.center.x - centerx) < minDistance) {
            maxIndex = [self.candidates indexOfObject:view];
            minDistance = fabs(view.center.x - centerx);
        }
    }
    return maxIndex;
}

- (NSInteger)selectedIndex
{
    CGRect visibleFrame = self.bounds;
    visibleFrame.origin.x = self.contentOffset.x;
    for (UIView *view in _visibleLabels) {
        if (CGRectContainsPoint(visibleFrame, view.frame.origin)) {
            return [_candidates indexOfObject:view];
        }
    }
    return 0;
}

- (void)centerItemAtIndex:(NSInteger)index
                 animated:(BOOL)animated
{
//    _selectedIndex = index;
    if (_visibleLabels.count == 0) {
        [self layoutSubviews];
    }
    if (_candidates.count == 0 ||
        index < 0 || index >= _candidates.count) {
        return;
    }
    
    UIView *selectedView = _candidates[index];
    CGPoint offset = CGPointZero;
    // 1. View is shown
    if ([_visibleLabels indexOfObject:selectedView] != NSNotFound) {
        // if view is shown
        CGPoint contentOffset = self.contentOffset;
        
        UIView *view = [_candidates objectAtIndex:index];
        CGFloat distance = CGRectGetMidX(view.frame) - contentOffset.x - CGRectGetWidth(self.frame) / 2;

        
        offset = self.contentOffset;
        offset.x += distance;
        
        [self setContentOffset:offset
                      animated:animated];
    } else {
        // to make it easy, clean stack and restart;
        for (UIView *view in [self.visibleLabels copy]) {
            [view removeFromSuperview];
            [self.visibleLabels removeObject:view];
        }
        
        [self placeLable:index OnRight:self.contentOffset.x];
        
    }
    [self setNeedsLayout];
}

#pragma mark - Layout

// recenter content periodically to achieve impression of infinite scrolling
- (void)recenterIfNecessary
{
    CGPoint currentOffset = [self contentOffset];
    CGFloat contentWidth = [self contentSize].width;
    int centerOffsetX =  (int)(contentWidth / CGRectGetWidth(self.bounds)) / 2 * CGRectGetWidth(self.bounds);
    CGFloat distanceFromCenter = currentOffset.x - centerOffsetX;
    CGFloat move = 0.0f;
    UIView *referenceView = nil;
    if (distanceFromCenter >=0) {
        // in the right side of center
        referenceView = self.visibleLabels.firstObject;
    } else {
        referenceView = self.visibleLabels.lastObject;
    }
    
    move = centerOffsetX - CGRectGetMinX(referenceView.frame);
    if (fabs(distanceFromCenter) > (contentWidth / 4.0))
    {
        self.contentOffset = CGPointMake(currentOffset.x + move, currentOffset.y);
        
        // move content by the same amount so it appears to stay still
        for (UILabel *label in self.visibleLabels) {
            CGPoint center = label.center;
            center.x += move;
            label.center = center;
        }
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self recenterIfNecessary];
    
    // tile content in visible bounds
    CGRect visibleBounds = self.bounds;
    visibleBounds.origin.x = self.contentOffset.x;
    CGFloat minimumVisibleX = CGRectGetMinX(visibleBounds);
    CGFloat maximumVisibleX = CGRectGetMaxX(visibleBounds);
    
    [self tileLabelsFromMinX:minimumVisibleX toMaxX:maximumVisibleX];
}

- (CGFloat)placeNewLabelOnRight:(CGFloat)rightEdge
{
    NSInteger index = 0;
    if (self.visibleLabels.count) {
        UIView *right = self.visibleLabels.lastObject;
        if (rightEdge) {
            index = ([self.candidates indexOfObject:right] + self.candidates.count + 1) % self.candidates.count;
            if ([self isKindOfClass:[VUPageView class]]) {
                NSLog(@"place view %d on the right", index);
            }
        }
    }
    return [self placeLable:index OnRight:rightEdge];
}

- (CGFloat)placeLable:(NSInteger)index OnRight:(CGFloat)rightEdge
{
    UIView *insert = self.candidates[index];
    [self.visibleLabels addObject:insert]; // add rightmost label at the end of the array
    
    CGRect frame = [insert frame];
    frame.origin.x = rightEdge;
    frame.origin.y = 0;
    [insert setFrame:frame];
    [self addSubview:insert];
    return CGRectGetMaxX(frame);
}

- (CGFloat)placeNewLabelOnLeft:(CGFloat)leftEdge
{
    // Find the left node of the current leftmost node
    NSUInteger index = 0;
    if (self.visibleLabels.count) {
        UIView *leftMost = [self.visibleLabels objectAtIndex:0];
        if (leftEdge) {
            index = ([self.candidates indexOfObject:leftMost] + self.candidates.count - 1) % self.candidates.count;
            NSLog(@"place view %d on the left", index);
        }
    }
    UIView *insert = self.candidates[index];
    
    [self.visibleLabels insertObject:insert atIndex:0]; // add leftmost label at the beginning of the array
    
    CGRect frame = [insert frame];
    frame.origin.x = leftEdge - frame.size.width;
    frame.origin.y = 0;
    [insert setFrame:frame];
    [self addSubview:insert];
    return CGRectGetMinX(frame);
}

- (void)tileLabelsFromMinX:(CGFloat)minimumVisibleX toMaxX:(CGFloat)maximumVisibleX
{
    if (!self.candidates.count) {
        return;
    }
    // the upcoming tiling logic depends on there already being at least one label in the visibleLabels array, so
    // to kick off the tiling we need to make sure there's at least one label
    if ([self.visibleLabels count] == 0)
    {
        [self placeNewLabelOnRight:minimumVisibleX];
    }
    
    // add labels that are missing on right side
    UIView *lastLabel = [self.visibleLabels lastObject];
    CGFloat rightEdge = CGRectGetMaxX([lastLabel frame]);
    while (rightEdge < maximumVisibleX)
    {
        rightEdge = [self placeNewLabelOnRight:rightEdge];
    }
    
    // add labels that are missing on left side
    UIView *firstLabel = self.visibleLabels[0];
    CGFloat leftEdge = CGRectGetMinX([firstLabel frame]);
    while (leftEdge > minimumVisibleX)
    {
        leftEdge = [self placeNewLabelOnLeft:leftEdge];
    }
    
    // remove labels that have fallen off right edge
    lastLabel = [self.visibleLabels lastObject];
    while ([lastLabel frame].origin.x > maximumVisibleX)
    {
        [lastLabel removeFromSuperview];
        [self.visibleLabels removeLastObject];
        lastLabel = [self.visibleLabels lastObject];
    }
    
    // remove labels that have fallen off left edge
    firstLabel = self.visibleLabels[0];
    while (CGRectGetMaxX([firstLabel frame]) < minimumVisibleX)
    {
        [firstLabel removeFromSuperview];
        [self.visibleLabels removeObjectAtIndex:0];
        firstLabel = self.visibleLabels[0];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    
}

@end
