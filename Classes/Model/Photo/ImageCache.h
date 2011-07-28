//
//  ImageCache.h
//  PhotoGallery
//
//  Created by Lee Tze Cheun on 7/21/11.
//  Copyright 2011 TC Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ASIHTTPRequest;

@protocol ImageCacheDelegate;

/** Thumbnail's default size. */
extern const CGSize kThumbnailSize;

/**
 * Manages the image cache that stores the images downloaded from the web.
 * The operations on the image cache are asynchronous and therefore will not block the UI.
 */
@interface ImageCache : NSObject {

@private
    // Path to the image cache directory on disk.
    NSString *_cacheDirectoryPath;
    
    // Operation queue to save or load images from cache asynchronously.
    NSOperationQueue *_loadQueue;
    NSOperationQueue *_saveQueue;
}

/** Returns the shared singleton instance of the image cache. */
+ (ImageCache *) sharedImageCache;

/**
 * Loads an image from the cache asynchronously.
 *
 * @param url the URL of the image to be used as the cache's key
 * @param delegate the delegate object to be notified when image has been loaded from cache 
 */
- (void) loadImageForURL: (NSURL *) url delegate: (id <ImageCacheDelegate>) delegate;

/**
 * Loads a thumbnail from the cache asynchronously.
 *
 * @param url the URL of the image to be used as the cache's key
 * @param delegate the delegate object to be notified when thumbnail has been loaded from cache  
 */
- (void) loadThumbnailForURL: (NSURL *) url delegate: (id <ImageCacheDelegate>) delegate;

/**
 * Saves an image to the cache asynchronously.
 *
 * @param request the ASIHTTPRequest instance with the image response data to save to cache
 * @param delegate the delegate object to be notified when image has been saved to cache
 */
- (void) saveImageForRequest: (ASIHTTPRequest *) request delegate: (id <ImageCacheDelegate>) delegate;

@end


/** Protocol for ImageCache to communicate with its delegate. */
@protocol ImageCacheDelegate <NSObject>

@optional

//- (void) imageCache: (ImageCache *) imageCache didFinishLoadingImage: (UIImage *) image forThumbnailVersion: (BOOL) thumbnailVersion;

/** 
 * Called when image and thumbnail has been saved to cache. 
 * 
 * @param imageCache the ImageCache instance that sent this message
 */
//- (void) imageCacheDidFinishSaving: (ImageCache *) imageCache;


/**
 * Called when image was loaded from cache.
 *
 * @param imageCache the ImageCache instance that sent this message
 * @param image the image that was loaded from cache; nil if not found in cache
 */
- (void) imageCache: (ImageCache *) imageCache didFinishLoadingImage: (UIImage *) image;

/**
 * Called when thumbnail was loaded from cache.
 *
 * @param imageCache the ImageCache instance that sent this message
 * @param image the image that was loaded from cache; nil if not found in cache
 */
- (void) imageCache: (ImageCache *) imageCache didFinishLoadingThumbnail: (UIImage *) thumbnail;

- (void) imageCache: (ImageCache *) imageCache didFinishSavingImage: (UIImage *) image thumbnail: (UIImage *) thumbnail;

@end
