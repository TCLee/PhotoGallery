//
//  TCFileHelper.h
//  PhotoGallery
//
//  Created by Lee Tze Cheun on 7/14/11.
//  Copyright 2011 TC Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Utility class that provides useful methods for accessing the app's 
 * sandbox file system.
 */
@interface TCFileHelper : NSObject {
    
@private
    NSString *_documentsDirectory;
}

/** Get the Documents directory where the app's files are stored. */
@property (nonatomic, readonly) NSString *documentsDirectory;

/** Gets the shared singleton instance. */
+ (TCFileHelper *) sharedHelper;

@end