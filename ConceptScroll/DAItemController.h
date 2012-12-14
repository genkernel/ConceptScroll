//
//  DAItemController.h
//  ConceptScroll
//
//  Created by kernel on 14/12/12.
//  Copyright (c) 2012 kernel@realm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DAItem.h"

@interface DAItemController : UIViewController
- (void)loadItem:(DAItem *)item;
- (void)animateHintMessage:(NSString *)str;

@property (nonatomic) NSUInteger loadedItemIdx;

@property (strong, nonatomic) IBOutlet UIImageView *mainImg;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel, *hintLabel;
@end
