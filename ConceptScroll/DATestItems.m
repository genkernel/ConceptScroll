//
//  DATestItems.m
//  ConceptScroll
//
//  Created by kernel on 14/12/12.
//  Copyright (c) 2012 kernel@realm. All rights reserved.
//

#import "DATestItems.h"

static NSString *kResourceFilename = @"TestItems.plist";

@implementation DATestItems

- (id)init {
	self = [super init];
	if (self) {
		NSString *path = [[NSBundle mainBundle] pathForResource:kResourceFilename.stringByDeletingPathExtension ofType:kResourceFilename.pathExtension];
		NSArray *list = [NSArray arrayWithContentsOfFile:path];
		
		NSMutableArray *arr = [NSMutableArray arrayWithCapacity:list.count];
		for (NSDictionary *dict in list) {
			[arr addObject:[DAItem itemWithDictionary:dict]];
		}
		_items = [NSArray arrayWithArray:arr];
	}
	return self;
}

@end
