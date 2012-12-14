//
//  DAViewController.h
//  ConceptScroll
//
//  Created by kernel on 14/12/12.
//  Copyright (c) 2012 kernel@realm. All rights reserved.
//

#import "DAItemController.h"
#import "PagerView.h"

@interface DAMainController : UIViewController <PagerViewDataSource, PagerViewDelegate>
@property (strong, nonatomic) IBOutlet PagerView *pager;
@end
