//
//  PagerItemViewContainer.m
//  Copyright (c) 2011 kernel@realm. All rights reserved.
//
//

#import "PagerItemViewContainer.h"

@implementation PagerItemViewContainer

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
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
	self.backgroundColor = UIColor.clearColor;
	self.autoresizingMask = (NSUInteger)-1;	// All masks.
	
	// PagerItemViewDisplayStateHidden: default state with alpha=0.
	self.alpha = .0;
}

- (NSString*)description {
	return [NSString stringWithFormat:@"[%@. %@. userView: [%@]]", NSStringFromClass(self.class), NSStringFromCGRect(self.frame), self.userView];
}

- (PagerItemView *)userView {
	return [self.subviews count] > 0 ? self.subviews[0] : nil;
}

- (void)applyFullscreenConstraintsWithOffset:(CGFloat)x {
	
	// top + bottom.
	
	NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.superview attribute:NSLayoutAttributeTop multiplier:1. constant:.0];
	[self.superview addConstraint:top];
	
	NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.superview attribute:NSLayoutAttributeBottom multiplier:1. constant:.0];
	[self.superview addConstraint:bottom];
	
	// centerX + width.
	
	_centerX = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.superview attribute:NSLayoutAttributeCenterX multiplier:1. constant:x];
	[self.superview addConstraint:self.centerX];
	
	NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.superview attribute:NSLayoutAttributeWidth multiplier:1. constant:.0];
	[self.superview addConstraint:width];
}

#pragma mark Properties

- (void)setDisplayState:(PagerItemViewDisplayStates)state {
	if (state == self.displayState) {
		return;
	}
	_displayState = state;
	
	self.alpha = PagerItemViewDisplayStateHidden == state ? .0 : 1.;
}

@end
