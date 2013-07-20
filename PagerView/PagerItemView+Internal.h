//
//  Internal.h
//  Copyright (c) 2012 kernel@realm. All rights reserved.
//

#import "PagerView.h"
#import "PagerItemView.h"

@protocol PagerItemViewDelegate <NSObject>
@required
- (void)itemTapped:(PagerItemView*)view;
@end

@interface PagerItemView ()
@property (weak, nonatomic) id<PagerItemViewDelegate> delegate;
// Index of the item currently loaded into this reusable view.
@property (nonatomic, readwrite) NSUInteger datasourceIndex;
@end


