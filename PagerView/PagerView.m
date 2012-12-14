//
//  PageScroller.m
//  Copyright (c) 2011 kernel@realm. All rights reserved.
//
//

#import "PagerView.h"
#import "PagerItemView+Internal.h"

static const CGFloat	kDefaultPanDistanceToSwitch = 150.;

@interface PagerView () <PagerItemViewDelegate>
@property (strong, nonatomic, readwrite) IBOutlet UIView *backgroundView;
@property (strong, nonatomic) IBOutlet UIView *viewsContainer;

@property (strong, nonatomic) UIPanGestureRecognizer* pan;
@property (nonatomic) CGFloat panDistanceOffset;

@property (strong, nonatomic) NSMutableSet*			dequeuedViews;
@property (strong, nonatomic) NSMutableArray*		views;

// pageContainerClass - PagerItemViewContainer based class.
@property (nonatomic) Class	pageContainerClass;
@property (nonatomic, readonly) CGSize itemContainerSize;

- (void)prepareView;
- (void)setupView;
- (void)displayPage:(NSUInteger)index animated:(BOOL)animated;
- (NSUInteger)prevIndexForIndex:(NSUInteger)index;
- (NSUInteger)nextIndexForIndex:(NSUInteger)index;
- (NSUInteger)hasPrevView;
- (NSUInteger)hasNextView;
@end

@implementation PagerView {
	BOOL isRenderable;
	// totalItemsCount. DataSource items count.
	NSUInteger totalItemsCount;
	NSUInteger renderItemsCount, cornerRenderItemsCount;
}
@dynamic panGestureEnabled, itemContainerSize;

- (void)dealloc {
	self.views = nil;
	self.dequeuedViews = nil;
}

- (id)initWithFrame:(CGRect)rect {
	self = [super initWithFrame:rect];
	if (self) {
		[self prepareView];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self prepareView];
	}
	return self;
}

- (void)prepareView {
	self.minSwitchDistance = kDefaultPanDistanceToSwitch;
	
	NSArray* arr = [[NSBundle mainBundle] loadNibNamed:@"PagerView" owner:self options:nil];
	UIView* view = [arr objectAtIndex:0];
	view.frame = self.bounds;
	[self addSubview:view];
	
	// Custom scrolling via GR(not UIScrollViewDelegate::scrollViewDidScroll) allows revealing content at x<0.
	self.pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(viewDidPan:)];
	[self.viewsContainer addGestureRecognizer:self.pan];
	
	isRenderable = NO;
}

// MARK: - Properties

- (BOOL)panGestureEnabled {
	return self.pan.enabled;
}

- (void)setPanGestureEnabled:(BOOL)enabled {
	if (enabled == self.pan.enabled) {
		return;
	}
	self.pan.enabled = enabled;
}

- (CGSize)itemContainerSize {
	// TODO:
	// Impl user-defined containers.
	return self.frame.size;
	//return [self.pageContainerClass containerViewSize];
}

// MARK: - Private

// DataSource index.
- (NSUInteger)prevIndexForIndex:(NSUInteger)index {
	// TODO: - implement PagerView::looped property.
	if (0 == totalItemsCount) {
		return 0;
	} else {
		/*
		 * Looped.
		if (0 == index) {
			return self.looped ? totalItemsCount-1 : index;
		} else {
			return index-1;
		}*/
		return 0==index ? totalItemsCount-1 : index-1;	// Remnant. Looping not supported.
	}
}

// DataSource index.
- (NSUInteger)nextIndexForIndex:(NSUInteger)index {
	// TODO: - implement PagerView::looped property.
	if (0 == totalItemsCount) {
		return 0;
	} else {
		/*
		 * Looped.
		if (totalItemsCount-1 == index) {
			return self.looped ? 0 : index;
		} else {
			return index+1;
		}*/
		return index==totalItemsCount-1 ? 0 : index+1;	// Remnant. Looping not supported.
	}
}

// YES when scrolling to left is possible.
- (NSUInteger)hasPrevView {
	return !(!self.looped && 0==self.selectedIndex);
}

// YES when scrolling to right is possible.
- (NSUInteger)hasNextView {
	return !(!self.looped && totalItemsCount-1==self.selectedIndex);
}

- (void)setupView {
	// TODO:
	// Impl user-defined containers.
	self.pageContainerClass = [PagerItemViewContainer class];
	
	if (self.customRenderPoolSize > 0) {
		renderItemsCount = self.customRenderPoolSize;
	} else {
		// *3: cover 3 pages: virtual left cache page, visible center, virtual right cache plus 1 temporary cache page(+1 also normalizes if *3=0).
		//renderItemsCount = floor(self.width / itemContainerSize.width) * 3 + 1;
		NSUInteger x1 = ceil(self.frame.size.width / self.itemContainerSize.width);
		renderItemsCount = x1 + 2;
		// 
		if (!self.looped) {
			renderItemsCount = totalItemsCount<renderItemsCount ? totalItemsCount : renderItemsCount;
		}
		// Hack.
		renderItemsCount = 2 == renderItemsCount ? 3 : renderItemsCount;
	}
	//NSLog(@"renderItemsCount: %d", renderItemsCount);
	
	CGFloat centerX = self.frame.size.width/2;
	// Left renderable items count.
	NSUInteger ln = 0;
	if (renderItemsCount > 0) {
		ln = (renderItemsCount-1) / 2;
	}
	// Determine the most left(first) datasource item index.
	NSUInteger startIndex = self.defaultPage;
	for (int i=0; i<ln; i++) {
		NSUInteger index = [self prevIndexForIndex:startIndex];
		if (index == startIndex) {
			ln -= i+1;
			break;
		}
		startIndex = index;
	}
	
	// On reloading - use remnant views as dequeued(cached) views.
	self.dequeuedViews = [NSMutableSet setWithCapacity:renderItemsCount];
	for (PagerItemViewContainer* container in self.views) {
		if ([container.subviews count] > 0) {
			UIView* userView = [container.subviews objectAtIndex:0];
			[self.dequeuedViews addObject:userView];
		}
	}
	// Remove * subviews.
	for (UIView *v in self.viewsContainer.subviews) {
		[v removeFromSuperview];
	}
	
	// Create new view containers.
	NSUInteger displayIndex = startIndex;
	self.views = [NSMutableArray arrayWithCapacity:renderItemsCount];
	for (int i=0; i<renderItemsCount; i++) {
		if (i>0) {
			displayIndex = [self nextIndexForIndex:displayIndex];
		}
		
		PagerItemViewContainer* container = [self.pageContainerClass new];
		container.frame = CGRectMake(.0, .0, self.itemContainerSize.width, self.itemContainerSize.height);
		
		BOOL needsDisplay = YES;
		if (!self.looped) {
			NSUInteger index = self.defaultPage;
			BOOL leftNeedsDisplay = !(i<=ln && displayIndex>index);	// before 0.
			BOOL rightNeedsDisplay = !(startIndex+i>=index && displayIndex<index);	// after last.
			needsDisplay = leftNeedsDisplay && rightNeedsDisplay;
		}
		container.displayState = needsDisplay ? PagerItemViewDisplayStateLoading : PagerItemViewDisplayStateHidden;
		//container.x += i * container.width;
		//
		int k = i - ln;
		CGFloat value = self.itemContainerSize.width;
		CGFloat offset = k*value;
		CGFloat x = centerX + offset;
		container.center = CGPointMake(x, container.center.y);
		
		[self.views addObject:container];
		[self.viewsContainer addSubview:container];
	}
}

- (PagerItemView*)requestViewForIndex:(NSUInteger)index {
	PagerItemView* v = [self.dataSource pager:self pageAtIndex:index];
	v.delegate = self;
	return v;
}

// MARK: - Instance methods

- (void)reloadData {
	totalItemsCount = [self.dataSource numberOfPages];
	
	_selectedIndex = self.defaultPage;
	[self displayPage:self.selectedIndex animated:YES];
}

- (NSArray*)sortedViews {
	return [NSMutableArray arrayWithArray:[self.views sortedArrayUsingComparator:(NSComparator)^(id obj1, id obj2){
		PagerItemViewContainer* v1 = (PagerItemViewContainer*)obj1;
		PagerItemViewContainer* v2 = (PagerItemViewContainer*)obj2;
		return v1.userView.datasourceIndex - v2.userView.datasourceIndex;
	}]];
}

- (NSMutableArray*)sortedViewsWithCenterView:(NSUInteger)index {
	NSArray* arr = [self sortedViews];
	[self.viewsContainer bringSubviewToFront:[arr objectAtIndex:self.selectedIndex]];
	[self.viewsContainer bringSubviewToFront:[arr objectAtIndex:index]];
	
	// Start index.
	NSUInteger startIndex = index;
	for (int i=0; i<cornerRenderItemsCount; i++) {
		startIndex = [self prevIndexForIndex:startIndex];
	}
	
	// Create normalized array.
	NSMutableArray* normalizedArr = [NSMutableArray arrayWithCapacity:[arr count]];
	NSUInteger displayIndex = startIndex;
	for (int i=0; i<renderItemsCount; i++) {
		[normalizedArr addObject:[arr objectAtIndex:displayIndex]];
		
		displayIndex = [self nextIndexForIndex:displayIndex];
	}
	
	return normalizedArr;
}

- (void)navigateToPage:(NSUInteger)index animated:(BOOL)animated {
	if (index == self.selectedIndex) {
		// Page is already centered.
		return;
	} else {
		if (totalItemsCount == renderItemsCount) {
			self.views = [self sortedViewsWithCenterView:index];
			[self displayPage:index animated:animated];
		} else {
			if (index > self.selectedIndex) {
				_selectedIndex = [self prevIndexForIndex:index];
				[self navigateRightAnimated:animated];
			} else {
				_selectedIndex = [self nextIndexForIndex:index];
				[self navigateLeftAnimated:animated];
			}
		}
	}
}

- (void)navigateLeftAnimated:(BOOL)animated {
	PagerItemViewContainer* moveView = [self.views lastObject];
	moveView.displayState = PagerItemViewDisplayStateHidden;
	
	if (totalItemsCount == renderItemsCount) {
		[self navigateToPage:[self prevIndexForIndex:self.selectedIndex] animated:animated];
		return;
	}
	
	//if (self.looped) {
	// Move the most right view to the left corner.
	// * //PagerItemViewContainer* moveView = [self.views lastObject];
	// * //moveView.displayState = PagerItemViewDisplayStateHidden;
	[self.viewsContainer sendSubviewToBack:moveView];
	// Mark user's view as reusable.
	[self.dequeuedViews addObject:moveView.userView];
	
	NSMutableArray* arr = [NSMutableArray arrayWithCapacity:renderItemsCount];
	[arr addObject:moveView];
	for (int i=0; i<renderItemsCount-1; i++) {
		[arr addObject:[self.views objectAtIndex:i]];
	}
	self.views = arr;
	//}
	
	_selectedIndex = [self prevIndexForIndex:self.selectedIndex];
	[self displayPage:self.selectedIndex animated:YES];
}

- (void)navigateRightAnimated:(BOOL)animated {
	PagerItemViewContainer* moveView = [self.views objectAtIndex:0];
	moveView.displayState = PagerItemViewDisplayStateHidden;
	
	if (totalItemsCount == renderItemsCount) {
		[self navigateToPage:[self nextIndexForIndex:self.selectedIndex] animated:animated];
		return;
	}
	
	//if (self.looped) {
	// Move the most left view to the right corner.
	// * //PagerItemViewContainer* moveView = [self.views objectAtIndex:0];
	// * //moveView.displayState = PagerItemViewDisplayStateHidden;
	[self.viewsContainer sendSubviewToBack:moveView];
	// Mark user's view as reusable.
	[self.dequeuedViews addObject:moveView.userView];
	
	NSMutableArray* arr = [NSMutableArray arrayWithCapacity:renderItemsCount];
	for (int i=1; i<renderItemsCount; i++) {
		[arr addObject:[self.views objectAtIndex:i]];
	}
	[arr addObject:moveView];
	self.views = arr;
	//}
	
	[self displayPage:[self nextIndexForIndex:self.selectedIndex] animated:YES];
}

- (void)renderIndex:(NSUInteger)index animated:(BOOL)animated {
	__block NSArray *displayStates = nil;
	
	if (animated) {
		[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
		
		[UIView animateWithDuration:0.6 delay:0.0 
							options:UIViewAnimationOptionCurveEaseOut 
						 animations:^{
							 displayStates = [self renderIndex:index];
						 }
						 completion:^(BOOL finished) {
							 [[UIApplication sharedApplication] endIgnoringInteractionEvents];
							 
							 for (int i=0; i<renderItemsCount; i++) {
								 PagerItemViewContainer* container = self.views[i];
								 container.displayState = [displayStates[i] intValue];
							 }
							 
							 if (finished) {
								 _selectedIndex = index;
								 if ([self.delegate respondsToSelector:@selector(pager:centerItemDidChange:)]) {
									 [self.delegate pager:self centerItemDidChange:self.selectedIndex];
								 }
							 } else {
								 NSLog(@"WARN. Page animation did not finish.");
							 }
						 }];
	} else {
		displayStates = [self renderIndex:index];
		
		for (int i=0; i<renderItemsCount; i++) {
			PagerItemViewContainer* container = self.views[i];
			container.displayState = [displayStates[i] intValue];
		}
		
		_selectedIndex = index;
		if ([self.delegate respondsToSelector:@selector(pager:centerItemDidChange:)]) {
			[self.delegate pager:self centerItemDidChange:self.selectedIndex];
		}
	}
}

- (NSArray *)renderIndex:(NSUInteger)index {
	if (0 == totalItemsCount) {
		return nil;
	}
	NSMutableArray *displayStates = [NSMutableArray array];
	
	CGFloat centerX = CGRectGetWidth(self.frame) / 2;
	
	// Left renderable items count.
	NSUInteger ln = 0;
	if (renderItemsCount > 0) {
		ln = (renderItemsCount-1) / 2;
	}
	// Determine the most left(first) datasource item index.
	NSUInteger startIndex = index;
	for (int i=0; i<ln; i++) {
		NSUInteger index = [self prevIndexForIndex:startIndex];
		if (index == startIndex) {
			ln -= i+1;
			break;
		}
		startIndex = index;
	}
	cornerRenderItemsCount = ln;
	
	// Request datasource views & align view containers.
	NSUInteger displayIndex = startIndex;
	for (int i=0; i<renderItemsCount; i++) {
		if (i>0) {
			displayIndex = [self nextIndexForIndex:displayIndex];
		}
		PagerItemViewContainer* container = self.views[i];
		
		// Center container view.
		int k = i - ln;
		CGFloat value = self.itemContainerSize.width;
		CGFloat offset = k*value;
		CGFloat x = centerX + offset;
		container.center = CGPointMake(x, container.center.y);
		
		// Determine display status.
		BOOL needsDisplay = YES;
		if (!self.looped) {
			BOOL leftNeedsDisplay = !(i<=ln && displayIndex>index);	// before 0.
			BOOL rightNeedsDisplay = !(startIndex+i>=index && displayIndex<index);	// after last.
			needsDisplay = leftNeedsDisplay && rightNeedsDisplay;
			/*if (NO == needsDisplay) {
				NSLog(@"%d needsDisplay: %d", displayIndex, needsDisplay);
			}*/
		}
		PagerItemViewDisplayStates state = needsDisplay ? PagerItemViewDisplayStateVisible : PagerItemViewDisplayStateHidden;
		[displayStates addObject:[NSNumber numberWithInt:state]];
		
		// Request view if required.
		if (PagerItemViewDisplayStateHidden==container.displayState || 
			!container.userView || 
			container.userView.datasourceIndex!=displayIndex) {
			PagerItemView* v = container.userView;
			if (!v || displayIndex!=v.datasourceIndex) {
				//NSLog(@"REQUEST. %d --> %d",  v.datasourceIndex, displayIndex);
				v = [self requestViewForIndex:displayIndex];
				v.datasourceIndex = displayIndex;
				
				// removeAllSubviews.
				for (UIView * v in container.subviews) {
					[v removeFromSuperview];
				}
				v.frame = container.bounds;
				[container addSubview:v];
			}
		}
	}
	
	return displayStates;
}

- (void)displayPage:(NSUInteger)index animated:(BOOL)animated {
	if (!isRenderable) {
		// First run.
		[self prepare];
		
		// First run - not animated.
		[self renderIndex:index animated:NO];
	} else {
		[self renderIndex:index animated:animated];
	}	
}

- (void)prepare {
	totalItemsCount = [self.dataSource numberOfPages];
	
	[self setupView];
	isRenderable = YES;
}

- (UIView*)dequeueView {
	UIView* reusableView = [self.dequeuedViews anyObject];
	if (reusableView) {
		[self.dequeuedViews removeObject:reusableView];
	}
	return reusableView;
}

// MARK: - Actions

- (void)viewDidPan:(UIPanGestureRecognizer*)gr {
	CGPoint translationPoint = [gr translationInView:self.viewsContainer];
	
	// TODO:
	// Impl self.bounces.
	
	if (translationPoint.x < 0.0 && ![self hasNextView]) {
		// L --> R.
		return;
	} else if (translationPoint.x >= 0.0 && ![self hasPrevView]) {
		// L <-- R.
		return;
	}
	
	if (UIGestureRecognizerStateBegan == gr.state) {
	} else if (UIGestureRecognizerStateChanged == gr.state) {
		
		for (UIView *container in self.views) {
			CGFloat offset = translationPoint.x - self.panDistanceOffset;
			container.center = CGPointMake(container.center.x + offset, container.center.y);
		}
		self.panDistanceOffset = translationPoint.x;
		
	} else if (UIGestureRecognizerStateEnded == gr.state) {
		// TODO:
		// Case with multiple visible views:
		// Navigate to variable views count(currently 1) depending on offset.
		
		self.panDistanceOffset = .0;
		
		if (translationPoint.x > self.minSwitchDistance) {
			[self navigateLeftAnimated:YES];
		} else if (translationPoint.x < -1*self.minSwitchDistance) {
			[self navigateRightAnimated:YES];
		} else {
			// Animate previously selected page at center.
			[self displayPage:self.selectedIndex animated:YES];
		}
	}
}

// MARK: PagerItemViewDelegate

- (void)itemTapped:(PagerItemView *)itemView {
	if ([self.delegate respondsToSelector:@selector(pager:viewDidTap:withItem:)]) {
		[self.delegate pager:self viewDidTap:itemView withItem:itemView.datasourceIndex];
	}
}

@end
