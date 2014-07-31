//
//  ISAppDelegate.h
//  InfiniteScrollViewDemo
//
//  Created by Zheng on 7/31/14.
//  Copyright (c) 2014 Zheng Zhang. All rights reserved.
//

#import "InfiniteScrollView.h"

@interface InfiniteScrollView ()

@property (nonatomic, strong) NSMutableArray *visibleLabels;

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
    }
    return self;
}

- (void)setSelectedIndex:(NSInteger)selectedIndex
{
    _selectedIndex = selectedIndex;
    [self selectItemAtIndex:selectedIndex animated:NO];
}

- (void)addView:(UIView *)view
{
    [self.candidates addObject:view];
    [self setNeedsLayout];
}

- (void)addViews:(NSArray *)views
{
    [self.candidates addObjectsFromArray:views];
    [self setNeedsLayout];
}

- (NSInteger)currentIndex
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

- (void)selectItemAtIndex:(NSInteger)index
                 animated:(BOOL)animated
{
    _selectedIndex = index;
    if (_visibleLabels.count == 0) {
        [self layoutSubviews];
    }
    if (_candidates.count == 0 ||
        index < 0 || index >= _candidates.count) {
        return;
    }
    UIView *minVisibleView = _visibleLabels.firstObject;
    UIView *maxVisibleView = _visibleLabels.lastObject;
    NSInteger minVisibleIndex = [_candidates indexOfObject:minVisibleView];
    NSInteger maxVisibleIndex = [_candidates indexOfObject:maxVisibleView];
    CGPoint offset = CGPointZero;
    
    if (index >= minVisibleIndex && index <= maxVisibleIndex) {
        // if view is shown
        UIView *view = [_candidates objectAtIndex:index];
        offset = CGPointMake(CGRectGetMinX(view.frame), CGRectGetMinY(view.frame));

    } else if (index < minVisibleIndex) {
        NSInteger stepsLeft = minVisibleIndex - index;
        NSInteger stepsRight = (index + _candidates.count - maxVisibleIndex);
        if (stepsLeft < stepsRight &&
            CGRectGetMinX(minVisibleView.frame) - stepsLeft * CGRectGetWidth(self.bounds) > 0) {
            offset = CGPointMake(CGRectGetMinX(minVisibleView.frame) - stepsLeft * CGRectGetWidth(self.bounds), 0);
        } else if(CGRectGetMinX(maxVisibleView.frame) + stepsRight * CGRectGetWidth(self.bounds) < self.contentSize.width) {
            offset = CGPointMake(CGRectGetMinX(maxVisibleView.frame) + stepsRight * CGRectGetWidth(self.bounds), 0) ;
        }
    } else if (index > maxVisibleIndex) {
        NSInteger stepsLeft = minVisibleIndex + _candidates.count - index;
        NSInteger stepsRight = index - minVisibleIndex;
        if (stepsRight < stepsLeft &&
            CGRectGetMinX(maxVisibleView.frame) + stepsRight* CGRectGetWidth(self.bounds)) {
            offset = CGPointMake(CGRectGetMinX(maxVisibleView.frame) + stepsRight* CGRectGetWidth(self.bounds), 0);
        } else if (CGRectGetMinX(minVisibleView.frame) - stepsLeft * CGRectGetWidth(self.bounds)) {
            offset = CGPointMake(CGRectGetMinX(minVisibleView.frame) - stepsLeft * CGRectGetWidth(self.bounds), 0);
        }
    }
    [self setContentOffset:offset animated:animated];
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
    NSUInteger index = _selectedIndex;
    if (self.visibleLabels.count) {
        UIView *right = self.visibleLabels.lastObject;
        if (rightEdge) {
            index = ([self.candidates indexOfObject:right] + self.candidates.count + 1) % self.candidates.count;
        }
    }
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
    UILabel *lastLabel = [self.visibleLabels lastObject];
    CGFloat rightEdge = CGRectGetMaxX([lastLabel frame]);
    while (rightEdge < maximumVisibleX)
    {
        rightEdge = [self placeNewLabelOnRight:rightEdge];
    }
    
    // add labels that are missing on left side
    UILabel *firstLabel = self.visibleLabels[0];
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

@end
