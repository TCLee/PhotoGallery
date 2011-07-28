//
//  Photo.h
//  PhotoGallery
//
//  Created by Lee Tze Cheun on 7/14/11.
//  Copyright 2011 TC Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ImageCache.h"

@class ASIHTTPRequest;


#pragma mark Constants

/** Posted when Photo model has started loading image. */
extern NSString * const PhotoDidStartLoadNotification;

/** Posted when Photo model has failed to load image. */
extern NSString * const PhotoDidFailLoadNotification;

/** Posted when Photo model has updated load progress. */
extern NSString * const PhotoDidUpdateLoadProgressNotification;

/** Posted when Photo model has loaded image. */
extern NSString * const PhotoDidLoadImageNotification;

/** Posted when Photo model has loaded thumbnail. */
extern NSString * const PhotoDidLoadThumbnailNotification;


#pragma mark -

/**
 * Photo model class that represents a photo downloaded from the server.
 */
@interface Photo : NSObject <ImageCacheDelegate> {

@private
    NSURL *_imageURL;
    UIImage *_image;
    UIImage *_thumbnail;    
    ASIHTTPRequest *_request;
    
    NSUInteger _index;
    CGFloat _progress;
    BOOL _loadingImageFromNetwork;
    BOOL _loadingImageFromCache;
    BOOL _loadingThumbnailFromCache;
}

/** Gets the URL of the image. */
@property (nonatomic, readonly) NSURL *imageURL;

/** Gets the image. If image has not been downloaded yet, it returns nil. */
@property (nonatomic, retain, readonly) UIImage *image;

/** Gets the thumbnail of the image. If image has not been downloaded yet, it returns nil. */
@property (nonatomic, retain, readonly) UIImage *thumbnail;

/** Gets the index of this photo within the list of all photos. */
@property (nonatomic, assign, readonly) NSUInteger index;

/** Gets or sets the progress of the image download. */
@property (nonatomic, assign) CGFloat progress;

/** Returns YES if image loading is in progress; NO otherwise. */
@property (nonatomic, assign, readonly) BOOL isLoading;


/** Convenience method to return a new array of Photo models from an array of URL strings. */
+ (NSArray *) photosFromURLStrings: (NSArray *) urlStrings;

/** Returns the default thumbnail size. */
+ (CGSize) thumbnailSize;


/** 
 * Initializes and returns a new Photo model. 
 *
 * @param imageURLString the URL of the image
 * @param photoIndex the index of the photo within the list of all photos
 */
- (id) initWithURLString: (NSString *) imageURLString index: (NSUInteger) photoIndex;

/** 
 * Remove and release the image and thumbnail from memory cache. Image and thumbnail 
 * can be reloaded from disk later, if required. 
 */
- (void) releaseSafelyImageAndThumbnail;

@end
