//
//  PagerItemView.h
//  kernel@realm
//
//

#import <UIKit/UIKit.h>

@interface PagerItemView : UIView
@property (copy, nonatomic) NSString *identifier;
@property (nonatomic, readonly) NSUInteger datasourceIndex;
@end

