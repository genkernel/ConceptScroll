//
//  DAItemController.m
//  ConceptScroll
//
//  Created by kernel on 14/12/12.
//  Copyright (c) 2012 kernel@realm. All rights reserved.
//

#import "DAItemController.h"
#import "PagerItemView.h"

@interface DAItemController ()
@end

@implementation DAItemController

- (void)viewDidUnload {
	[self setMainImg:nil];
	[self setTitleLabel:nil];
	[self setHintLabel:nil];
	[super viewDidUnload];
}

- (void)loadItem:(DAItem *)item {
	self.titleLabel.text = item.title;
	self.mainImg.image = item.img;
}

- (void)animateHintMessage:(NSString *)str {
	self.hintLabel.text = str;
	
	[UIView animateWithDuration:.9 animations:^{
		self.hintLabel.alpha = 1.;
	}completion:^(BOOL finished){
		[UIView animateWithDuration:.9 animations:^{
			self.hintLabel.alpha = .0;
		}];
	}];
}

@end
