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
//@property (assign, nonatomic, getter=isDisplayed) BOOL displayed;
@property (assign, nonatomic) PagerItemViewDisplayStates displayState;
@property (strong, nonatomic, readonly) PagerItemView *userView;

+ (CGSize)containerViewSize;
@end
