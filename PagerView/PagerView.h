//
//  PagerView.h
//  Copyright (c) 2011 kernel@realm. All rights reserved.
//

#import "PagerItemViewContainer.h"

@protocol PagerViewDelegate, PagerViewDataSource;

@interface PagerView : UIView
@property (weak, nonatomic) IBOutlet id<PagerViewDelegate> delegate;
@property (weak, nonatomic) IBOutlet id<PagerViewDataSource> dataSource;

@property (nonatomic, getter=isLooped) BOOL looped;
@property () BOOL panGestureEnabled;
// Default page index to display at the beggining.
@property () NSUInteger defaultPage;
@property () NSUInteger customRenderPoolSize;
@property () CGFloat minSwitchDistance;
@property (readonly) NSUInteger selectedIndex;

// TODO: Implement bounces.
//@property () BOOL	bounces;

@property (strong, nonatomic, readonly) UIView *backgroundView;

- (void)navigateToPage:(NSUInteger)index animated:(BOOL)animated;
- (void)navigateLeftAnimated:(BOOL)animated;
- (void)navigateRightAnimated:(BOOL)animated;
- (void)prepare;
- (void)reloadData;
- (PagerItemView *)dequeueViewWithIdentifier:(NSString *)identifier;
@end


@protocol PagerViewDelegate<NSObject>
@optional
- (void)pager:(PagerView *)pagerView centerItemDidChange:(NSUInteger)index;
- (void)pager:(PagerView *)pagerView viewDidTap:(PagerItemView*)itemView withItem:(NSUInteger)dataSourceIndex;
@end

@protocol PagerViewDataSource<NSObject>
@required
- (NSUInteger)numberOfPages;
- (PagerItemView *)pager:(PagerView *)pagerView pageAtIndex:(NSUInteger)index;
@end

