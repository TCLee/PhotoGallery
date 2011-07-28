//
//  XMLFeed.h
//  PhotoGallery
//
//  Created by Lee Tze Cheun on 7/15/11.
//  Copyright 2011 TC Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ParseOperation.h"

@protocol XMLFeedDelegate;

// TODO: Use ASIDownloadCache instead of trying to manually cache it ourselves!!!

/**
 * Fetches the XML feed and parses it asynchronously. 
 * Parsed results will be saved to disk, so that it can reused next time.
 */
@interface XMLFeed : NSObject <ParseOperationDelegate> {
    
@private
    id <XMLFeedDelegate> _delegate;
    NSString *_imageURLsPlistFilePath;
    NSOperationQueue *_parseQueue;
}

@property (nonatomic, assign) id <XMLFeedDelegate> delegate;

- (id) initWithDelegate: (id <XMLFeedDelegate>) delegate;

/** 
 * Fetches XML feed from web and parses it asynchronously. 
 */
- (void) fetch;

@end


#pragma mark -

@protocol XMLFeedDelegate <NSObject>

/** Called when started downloading XML feed. */
- (void) xmlFeedDidStartDownload: (XMLFeed *) xmlFeed;

/** Called when XML feed could not be downloaded or parsed. */
- (void) xmlFeed: (XMLFeed *) xmlFeed didFailWithError: (NSError *) error;

/** Called when XML feed has been parsed. */
- (void) xmlFeedDidFinishWithResult: (NSArray *) result;

@end

