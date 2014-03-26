//
//  PagerItemView.m
//  kernel@realm
//
//

#import "PagerItemView.h"
#import "PagerItemView+Internal.h"

typedef enum {
	PagerItemViewTouchStateDefault, 
	PagerItemViewTouchStateBegan, 
	PagerItemViewTouchStateMoved, 
	PagerItemViewTouchStateEnded, 
	PagerItemViewTouchStateCancelled
} PagerItemViewTouchState;

@implementation PagerItemView {
	PagerItemViewTouchState touchState;
}
// Synthesize explicitly to generate readwrite.
@synthesize datasourceIndex;

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		self.datasourceIndex = NSNotFound;
	}
	return self;
}

- (NSString*)description {
	return [NSString stringWithFormat:@"[%@. DataSource: %lu]", NSStringFromClass(self.class), (unsigned long)self.datasourceIndex];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	touchState = PagerItemViewTouchStateBegan;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	touchState = PagerItemViewTouchStateMoved;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if (PagerItemViewTouchStateBegan == touchState) {
		// Generate 'tap' event.
		[self.delegate itemTapped:self];
	}
	touchState = PagerItemViewTouchStateEnded;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	touchState = PagerItemViewTouchStateCancelled;
}

@end
