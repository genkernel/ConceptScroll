//
//  DAItem.m
//  ConceptScroll
//
//  Created by kernel on 14/12/12.
//  Copyright (c) 2012 kernel@realm. All rights reserved.
//

#import "DAItem.h"

static NSString *kTitleKey = @"Title";
static NSString *kImageKey = @"Image";

@implementation DAItem

+ (id)itemWithDictionary:(NSDictionary *)dict {
	return [[[self class] alloc] initWithDictionary:dict];
}

- (id)initWithDictionary:(NSDictionary *)dict {
	self = [self init];
	if (self) {
		_title = dict[kTitleKey];
		_img = [UIImage imageNamed:dict[kImageKey]];
	}
	return self;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"[%@. Title: %@]", NSStringFromClass([self class]), self.title];
}

@end
