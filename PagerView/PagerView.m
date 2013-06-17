//
//  PagerView.m
//  Copyright (c) 2011 kernel@realm. All rights reserved.
//

#import "PagerView.h"
#import "PagerItemView+Internal.h"

static const CGFloat DefaultPanDistanceToSwitch = 150.;
static const NSString *ViewState = @"ViewState";
static const NSString *ViewDataSourceIndex = @"ViewDataSourceIndex";

@interface PagerView () <PagerItemViewDelegate>
@property (strong, nonatomic, readwrite) IBOutlet UIView *backgroundView;
@property (strong, nonatomic) IBOutlet UIView *viewsContainer;

@property (strong, nonatomic) UIPanGestureRecognizer* pan;
@property () CGFloat panDistanceOffset;

// Dictionary format: <identifier (NSString)> => <views (NSMutableSet)>
@property (strong, nonatomic) NSMutableDictionary *dequeuedViews;
@property (strong, nonatomic) NSMutableArray *views;

// pageContainerClass - PagerItemViewContainer based class.
@property (nonatomic) Class	pageContainerClass;
@property (readonly) CGSize itemContainerSize;

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
	self.minSwitchDistance = DefaultPanDistanceToSwitch;
	self.clipsToBounds = YES;
	
	NSString *className = NSStringFromClass(self.class);
	NSArray* arr = [NSBundle.mainBundle loadNibNamed:className owner:self options:nil];
	UIView* view = arr[0];
	view.frame = self.bounds;
	[self addSubview:view];
	
	// Custom scrolling via GR(not UIScrollViewDelegate::scrollViewDidScroll) allows revealing content at x<0.
	self.pan = [UIPanGestureRecognizer.alloc initWithTarget:self action:@selector(viewDidPan:)];
	[self.viewsContainer addGestureRecognizer:self.pan];
	
	isRenderable = NO;
}

#pragma mark - Properties

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
	return self.frame.size;
}

#pragma mark Private methods

// DataSource index.
- (NSUInteger)prevIndexForIndex:(NSUInteger)index {
	if (0 == totalItemsCount) {
		return 0;
	} else {
		return 0 == index ? totalItemsCount - 1 : index - 1;
	}
}

// DataSource index.
- (NSUInteger)nextIndexForIndex:(NSUInteger)index {
	if (0 == totalItemsCount) {
		return 0;
	} else {
		return index == totalItemsCount - 1 ? 0 : index + 1;
	}
}

// YES when scrolling to left is possible.
- (NSUInteger)hasPrevView {
	return !(!self.looped && 0 == self.selectedIndex) && totalItemsCount > 1;
}

// YES when scrolling to right is possible.
- (NSUInteger)hasNextView {
	return !(!self.looped && totalItemsCount-1 == self.selectedIndex) && totalItemsCount > 1;
}

- (void)setupView {
	// TODO:
	// Impl user-defined containers.
	self.pageContainerClass = PagerItemViewContainer.class;
	
	if (self.customRenderPoolSize > 0) {
		renderItemsCount = self.customRenderPoolSize;
	} else {
		// *3: cover 3 pages: virtual left cached page, visible center, virtual right cached page plus 1 temporary cache page(+1 also normalizes if *3=0).
		NSUInteger x1 = ceil(self.frame.size.width / self.itemContainerSize.width);
		renderItemsCount = x1 + 2;
		
		if (!self.looped) {
			renderItemsCount = totalItemsCount < renderItemsCount ? totalItemsCount : renderItemsCount;
		}
		// Hack.
		renderItemsCount = 2 == renderItemsCount ? 3 : renderItemsCount;
	}
	//NSLog(@"renderItemsCount: %d", renderItemsCount);
	
	CGFloat centerX = self.frame.size.width/2;
	// Left renderable items count.
	NSUInteger ln = 0;
	if (renderItemsCount > 0) {
		ln = (renderItemsCount - 1) / 2;
	}
	// Determine the most left(first) datasource item index.
	NSUInteger startIndex = self.defaultPage;
	for (int i = 0; i < ln; i++) {
		NSUInteger index = [self prevIndexForIndex:startIndex];
		if (index == startIndex) {
			ln -= i + 1;
			break;
		}
		startIndex = index;
	}
	
	// On reloading - use remnant views as dequeued(cached) views.
	self.dequeuedViews = NSMutableDictionary.dictionary;
	for (PagerItemViewContainer *container in self.views) {
		if (container.subviews.count > 0) {
			PagerItemView *userView = container.subviews[0];
			
			if (userView.identifier) {
				NSMutableSet *views = self.dequeuedViews[userView.identifier];
				if (!views) {
					views = NSMutableSet.set;
					self.dequeuedViews[userView.identifier] = views;
				}
				[views addObject:userView];
			}
		}
	}
	// Remove * subviews.
	for (UIView *v in self.viewsContainer.subviews) {
		[v removeFromSuperview];
	}
	
	// Create new view containers.
	NSUInteger displayIndex = startIndex;
	self.views = [NSMutableArray arrayWithCapacity:renderItemsCount];
	for (int i = 0; i < renderItemsCount; i++) {
		if (i > 0) {
			displayIndex = [self nextIndexForIndex:displayIndex];
		}
		
		PagerItemViewContainer *container = self.pageContainerClass.new;
		container.frame = CGRectMake(.0, .0, self.itemContainerSize.width, self.itemContainerSize.height);
		
		BOOL needsDisplay = YES;
		if (!self.looped) {
			NSUInteger index = self.defaultPage;
			BOOL leftNeedsDisplay = !(i <= ln && displayIndex > index);	// before 0.
			BOOL rightNeedsDisplay = !(startIndex+i >= index && displayIndex < index);	// after last.
			needsDisplay = leftNeedsDisplay && rightNeedsDisplay;
		}
		container.displayState = needsDisplay ? PagerItemViewDisplayStateLoading : PagerItemViewDisplayStateHidden;
		//container.x += i * container.width;
		
		int k = i - ln;
		CGFloat value = self.itemContainerSize.width;
		CGFloat offset = k * value;
		CGFloat x = centerX + offset;
		container.center = CGPointMake(x, container.center.y);
		
		[self.views addObject:container];
		[self.viewsContainer addSubview:container];
	}
}

- (PagerItemView*)requestViewForIndex:(NSUInteger)index {
	PagerItemView *v = [self.dataSource pager:self pageAtIndex:index];
	v.delegate = self;
	return v;
}

#pragma mark - Instance methods

- (void)reloadData {
	totalItemsCount = [self.dataSource numberOfPages];
	
	_selectedIndex = self.defaultPage;
	[self displayPage:self.selectedIndex animated:YES];
}

- (NSArray*)sortedViews {
	NSArray *arr = [self.views sortedArrayUsingComparator:(NSComparator)^(PagerItemViewContainer *v1, PagerItemViewContainer *v2){
		return v1.userView.datasourceIndex - v2.userView.datasourceIndex;
	}];
	return [NSMutableArray arrayWithArray:arr];
}

- (NSMutableArray*)sortedViewsWithCenterView:(NSUInteger)index {
	NSArray* arr = [self sortedViews];
	[self.viewsContainer bringSubviewToFront:arr[self.selectedIndex]];
	[self.viewsContainer bringSubviewToFront:arr[index]];
	
	// Start index.
	NSUInteger startIndex = index;
	for (int i = 0; i < cornerRenderItemsCount; i++) {
		startIndex = [self prevIndexForIndex:startIndex];
	}
	
	// Create normalized array.
	NSMutableArray* normalizedArr = [NSMutableArray arrayWithCapacity:arr.count];
	NSUInteger displayIndex = startIndex;
	for (int i = 0; i < renderItemsCount; i++) {
		[normalizedArr addObject:arr[displayIndex]];
		
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
	
	// Move the most right view to the left corner.
	[self.viewsContainer sendSubviewToBack:moveView];
	// Mark user's view as reusable.
	if (moveView.userView.identifier) {
		NSMutableSet *views = self.dequeuedViews[moveView.userView.identifier];
		if (!views) {
			views = NSMutableSet.set;
			self.dequeuedViews[moveView.userView.identifier] = views;
		}
		[views addObject:moveView.userView];
	}
	
	NSMutableArray* arr = [NSMutableArray arrayWithCapacity:renderItemsCount];
	[arr addObject:moveView];
	for (int i = 0; i < renderItemsCount-1; i++) {
		[arr addObject:self.views[i]];
	}
	self.views = arr;
	
	_selectedIndex = [self prevIndexForIndex:self.selectedIndex];
	[self displayPage:self.selectedIndex animated:YES];
}

- (void)navigateRightAnimated:(BOOL)animated {
	PagerItemViewContainer *moveView = [self.views objectAtIndex:0];
	moveView.displayState = PagerItemViewDisplayStateHidden;
	
	if (totalItemsCount == renderItemsCount) {
		[self navigateToPage:[self nextIndexForIndex:self.selectedIndex] animated:animated];
		return;
	}
	
	// Move the most left view to the right corner.
	[self.viewsContainer sendSubviewToBack:moveView];
	// Mark user's view as reusable.
	if (moveView.userView.identifier) {
		NSMutableSet *views = self.dequeuedViews[moveView.userView.identifier];
		if (!views) {
			views = NSMutableSet.set;
			self.dequeuedViews[moveView.userView.identifier] = views;
		}
		[views addObject:moveView.userView];
	}
	
	NSMutableArray* arr = [NSMutableArray arrayWithCapacity:renderItemsCount];
	for (int i = 1; i < renderItemsCount; i++) {
		[arr addObject:self.views[i]];
	}
	[arr addObject:moveView];
	self.views = arr;
	
	_selectedIndex = [self nextIndexForIndex:self.selectedIndex];
	[self displayPage:self.selectedIndex animated:YES];
}

- (void)renderIndex:(NSUInteger)index animated:(BOOL)animated {
	__block NSArray *displayStates = nil;
	
	void (^loadItem)(PagerItemViewContainer *, NSUInteger) = ^(PagerItemViewContainer *container, NSUInteger displayIndex){
		PagerItemView *v = container.userView;
		
		//NSLog(@"REQUEST. %d --> %d",  v.datasourceIndex, displayIndex);
		v = [self requestViewForIndex:displayIndex];
		v.datasourceIndex = displayIndex;
		
		// removeAllSubviews.
		for (UIView * v in container.subviews) {
			[v removeFromSuperview];
		}
		v.frame = container.bounds;
		[container addSubview:v];
	};
	
	void (^completeTransition)() = ^(){
		for (int i = 0; i < renderItemsCount; i++) {
			NSDictionary *stateInfo = displayStates[i];
			
			PagerItemViewContainer* container = self.views[i];
			container.displayState = [stateInfo[ViewState] intValue];
			
			BOOL shouldReloadItem = nil != stateInfo[ViewDataSourceIndex];
			if (shouldReloadItem) {
				NSUInteger idx = [stateInfo[ViewDataSourceIndex] intValue];
				loadItem(container, idx);
			}
		}
		
		_selectedIndex = index;
		if ([self.delegate respondsToSelector:@selector(pager:centerItemDidChange:)]) {
			[self.delegate pager:self centerItemDidChange:self.selectedIndex];
		}
	};
	
	if (animated) {
		//[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
		[UIView animateWithDuration:.350 delay:.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			displayStates = [self renderIndex:index];
		} completion:^(BOOL finished) {
			//[[UIApplication sharedApplication] endIgnoringInteractionEvents];
			completeTransition();
		}];
	} else {
		displayStates = [self renderIndex:index];
		completeTransition();
	}
}

- (NSArray *)renderIndex:(NSUInteger)index {
	if (0 == totalItemsCount) {
		return nil;
	}
	NSMutableArray *displayStates = NSMutableArray.array;
	
	CGFloat centerX = CGRectGetWidth(self.frame) / 2;
	
	// Left renderable items count.
	NSUInteger ln = 0;
	if (renderItemsCount > 0) {
		ln = (renderItemsCount - 1) / 2;
	}
	// Determine the most left(first) datasource item index.
	NSUInteger startIndex = index;
	for (int i = 0; i < ln; i++) {
		NSUInteger index = [self prevIndexForIndex:startIndex];
		if (index == startIndex) {
			ln -= i + 1;
			break;
		}
		startIndex = index;
	}
	cornerRenderItemsCount = ln;
	
	// Request datasource views & align view containers.
	NSUInteger displayIndex = startIndex;
	for (int i = 0; i < renderItemsCount; i++) {
		if (i > 0) {
			displayIndex = [self nextIndexForIndex:displayIndex];
		}
		
		PagerItemViewContainer *container = self.views[i];
		
		NSMutableDictionary *stateInfo = NSMutableDictionary.dictionary;
		[displayStates addObject:stateInfo];
		
		// Center container view.
		int k = i - ln;
		CGFloat value = self.itemContainerSize.width;
		CGFloat offset = k * value;
		CGFloat x = centerX + offset;
		container.center = CGPointMake(x, container.center.y);
		
		// Determine display status.
		BOOL needsDisplay = YES;
		if (!self.looped) {
			BOOL leftNeedsDisplay = !(i <= ln && displayIndex > index);	// before 0.
			BOOL rightNeedsDisplay = !(startIndex+i >= index && displayIndex < index);	// after last.
			needsDisplay = leftNeedsDisplay && rightNeedsDisplay;
		}
		
		PagerItemViewDisplayStates state = needsDisplay ? PagerItemViewDisplayStateVisible : PagerItemViewDisplayStateHidden;
		stateInfo[ViewState] = @(state);
		
		// Request view if required.
		BOOL shouldReloadItemDataSource = PagerItemViewDisplayStateHidden == container.displayState || !container.userView || container.userView.datasourceIndex != displayIndex;
		
		if (shouldReloadItemDataSource) {
			PagerItemView *v = container.userView;
			if (!v || displayIndex != v.datasourceIndex) {
				stateInfo[ViewDataSourceIndex] = @(displayIndex);
			}
		}
	}
	
	return displayStates;
}

- (void)displayPage:(NSUInteger)index animated:(BOOL)animated {
	if (!isRenderable) {
		// First run.
		[self prepare];
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

- (PagerItemView *)dequeueViewWithIdentifier:(NSString *)identifier {
	PagerItemView *reusableView = nil;
	
	NSMutableSet *views = self.dequeuedViews[identifier];
	if (views.count) {
		reusableView = views.anyObject;
		[views removeObject:reusableView];
	}
	
	return reusableView;
}

#pragma mark - Actions

- (void)viewDidPan:(UIPanGestureRecognizer*)gr {
	CGPoint translationPoint = [gr translationInView:self.viewsContainer];
	
	// TODO:
	// Impl self.bounces.
	
	if (translationPoint.x < 0.0 && !self.hasNextView) {
		// L --> R.
		return;
	} else if (translationPoint.x >= 0.0 && !self.hasPrevView) {
		// L <-- R.
		return;
	}
	
	if (UIGestureRecognizerStateChanged == gr.state) {
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
		} else if (translationPoint.x < -self.minSwitchDistance) {
			[self navigateRightAnimated:YES];
		} else {
			// Animate previously selected page at center.
			[self displayPage:self.selectedIndex animated:YES];
		}
	}
}

#pragma mark PagerItemViewDelegate

- (void)itemTapped:(PagerItemView *)itemView {
	if ([self.delegate respondsToSelector:@selector(pager:viewDidTap:withItem:)]) {
		[self.delegate pager:self viewDidTap:itemView withItem:itemView.datasourceIndex];
	}
}

@end
