//
//  DAItem.h
//  ConceptScroll
//
//  Created by kernel on 14/12/12.
//  Copyright (c) 2012 kernel@realm. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DAItem : NSObject
+ (id)itemWithDictionary:(NSDictionary *)dict;
- (id)initWithDictionary:(NSDictionary *)dict;

@property (strong, nonatomic, readonly) NSString *title;
@property (strong, nonatomic, readonly) UIImage *img;
@end
