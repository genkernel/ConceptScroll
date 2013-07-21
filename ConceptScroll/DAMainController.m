//
//  DAViewController.m
//  ConceptScroll
//
//  Created by kernel on 14/12/12.
//  Copyright (c) 2012 kernel@realm. All rights reserved.
//

#import "DAMainController.h"
#import "DATestItems.h"

@interface DAMainController ()
@property (strong, nonatomic, readonly) NSMutableArray *ctrls;
@property (strong, nonatomic, readonly) DATestItems *model;
@end

@implementation DAMainController {
	NSInteger tag;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	_ctrls = [NSMutableArray array];
	
	_model = [DATestItems new];
	
	UIImageView *backgroundImage = [[UIImageView alloc] initWithFrame:self.pager.backgroundView.bounds];
	backgroundImage.image = [UIImage imageNamed:@"background.jpg"];
	backgroundImage.autoresizingMask = (NSUInteger)-1;	// Set all.
	[self.pager.backgroundView addSubview:backgroundImage];
	
	srand(time(0));
	self.pager.defaultPage = arc4random() % self.model.items.count;
	self.pager.looped = YES;
	self.pager.minSwitchDistance = 100.;
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.pager reloadData];
	});
}

- (void)viewDidUnload {
	[self setPager:nil];
	[super viewDidUnload];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
	
	_ctrls = [NSMutableArray array];
}

#pragma mark PagerViewDataSource

- (NSUInteger)numberOfPages {
	return self.model.items.count;
}

- (PagerItemView *)pager:(PagerView*)pagerView pageAtIndex:(NSUInteger)idx
{
	DAItemController *ctrl = nil;
	NSString *name = NSStringFromClass(DAItemController.class);
	
	PagerItemView* v = [pagerView dequeueViewWithIdentifier:name];
	if (!v) {
		// Create new view ctrl.
		ctrl = [[DAItemController alloc] initWithNibName:name bundle:nil];
		
		((PagerItemView *)ctrl.view).identifier = name;
		
		[self.ctrls addObject:ctrl];
		ctrl.view.tag = tag;
		tag++;
	} else {
		// Reuse view ctrl.
		if (self.ctrls.count > v.tag) {
			ctrl = [self.ctrls objectAtIndex:v.tag];
		} else {
			NSLog(@"ERR. Invalid viewCtrls stack.");
		}
	}
	
	DAItem *item = self.model.items[idx];
	[ctrl loadItem:item];
	ctrl.loadedItemIdx = idx;
	
	return (PagerItemView *)ctrl.view;
}

#pragma mark PagerViewDelegate

- (void)pager:(PagerView *)pagerView centerItemDidChange:(NSUInteger)index {
	if (pagerView.defaultPage != index) {
		return;
	}
	for (DAItemController *ctrl in self.ctrls) {
		if (ctrl.loadedItemIdx == index) {
			NSString *message = [NSString stringWithFormat:@"1 of %d", self.model.items.count];
			[ctrl animateHintMessage:message];
			break;
		}
	}
}

@end
