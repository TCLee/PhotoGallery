//
//  TCFileHelper.m
//  PhotoGallery
//
//  Created by Lee Tze Cheun on 7/14/11.
//  Copyright 2011 TC Lee. All rights reserved.
//

#import "TCFileHelper.h"

@implementation TCFileHelper

#pragma mark -
#pragma mark Public API

- (NSString *) documentsDirectory {
    if (nil == _documentsDirectory) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, 
                                                             NSUserDomainMask, YES);
        _documentsDirectory = [[paths objectAtIndex: 0] copy];
    }
    return _documentsDirectory;
}


#pragma mark -
#pragma mark Singleton Design Pattern

static TCFileHelper *sharedHelper = nil;

+ (TCFileHelper *) sharedHelper {
    if (nil == sharedHelper) {
        sharedHelper = [[super allocWithZone: NULL] init];
    }
    return sharedHelper;        
}

+ (id) allocWithZone: (NSZone *) zone {
    return [[self sharedHelper] retain];
}

- (id) copyWithZone: (NSZone *) zone {
    return self;
}

- (id) retain {
    return self;
}

- (NSUInteger) retainCount {
    // denotes an object that cannot be released
    return NSUIntegerMax;  
}

- (void) release {
    // do nothing
}

- (id) autorelease {
    return self;
}


#pragma mark -
#pragma mark Memory Management

- (void) dealloc {
    [_documentsDirectory release], _documentsDirectory = nil;
    [super dealloc];
}

@end