//
//  PageScroller.h
//  Copyright (c) 2011 kernel@realm. All rights reserved.
//
//

#import "PagerItemViewContainer.h"

typedef	enum {
	PageSCrollerPositionLeft, 
	PageSCrollerPositionRight, 
	PageSCrollerPositionCenter
} PageScrollerPositions;

@protocol PagerViewDelegate, PagerViewDataSource;


@interface PagerView : UIView
@property (weak, nonatomic) IBOutlet id<PagerViewDelegate>	delegate;
@property (weak, nonatomic) IBOutlet id<PagerViewDataSource>	dataSource;

@property (nonatomic, getter=isLooped) BOOL	looped;
@property (nonatomic) BOOL	panGestureEnabled;
// TODO: - Implement.
//@property (assign, nonatomic) BOOL	bounces;
// Default page index to display at the beggining.
@property (nonatomic) NSUInteger defaultPage;
@property (nonatomic) NSUInteger customRenderPoolSize;
@property (nonatomic) CGFloat minSwitchDistance;
@property (nonatomic, readonly) NSUInteger selectedIndex;

@property (strong, nonatomic, readonly) UIView *backgroundView;

- (void)navigateToPage:(NSUInteger)index animated:(BOOL)animated;
- (void)navigateLeftAnimated:(BOOL)animated;
- (void)navigateRightAnimated:(BOOL)animated;
- (void)prepare;
- (void)reloadData;
- (PagerItemView*)dequeueView;
@end


@protocol PagerViewDelegate<NSObject>
@optional
- (void)pager:(PagerView *)pagerView centerItemDidChange:(NSUInteger)index;
- (void)pager:(PagerView *)pagerView viewDidTap:(PagerItemView*)itemView withItem:(NSUInteger)dataSourceIndex;
@end

@protocol PagerViewDataSource<NSObject>
@required
- (NSUInteger)numberOfPages;
- (PagerItemView *)pager:(PagerView*)pagerView pageAtIndex:(NSUInteger)index;
@end

