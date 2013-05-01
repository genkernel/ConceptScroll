//
//  PagerItemViewContainer.h
//  Copyright (c) 2011 kernel@realm. All rights reserved.
//
//

#import "PagerItemView.h"

typedef enum {
	PagerItemViewDisplayStateHidden, 
	PagerItemViewDisplayStateLoading, 
	PagerItemViewDisplayStateVisible
} PagerItemViewDisplayStates;

@interface PagerItemViewContainer : UIView
@property (nonatomic) PagerItemViewDisplayStates displayState;
@property (strong, nonatomic, readonly) PagerItemView *userView;
@end
