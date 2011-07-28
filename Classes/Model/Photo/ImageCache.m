//
//  ImageCache.m
//  PhotoGallery
//
//  Created by Lee Tze Cheun on 7/21/11.
//  Copyright 2011 TC Lee. All rights reserved.
//

#import "ImageCache.h"
#import "TCFileHelper.h"
#import "ASIHTTPRequest.h"
#import "UIImage+Resize.h"
#import "SynthesizeSingleton.h"


#pragma mark Constants

// Default compression quality values for photos and thumbnails.
#define PHOTO_COMPRESSION_QUALITY      0.7
#define THUMBNAIL_COMPRESSION_QUALITY  0.4

// CGSize constants representing the image and thumbnail size.
CGSize const kThumbnailSize = { .width = 100, .height = 100 };
static CGSize const kMaxPhotoSize = { .width = 2048, .height = 2048 };

// Prefix for all thumbnail filenames. (Example: Thumb_1.JPG, Thumb_2.JPG etc...)
static NSString * const kThumbnailFilenamePrefix = @"Thumb_";


#pragma mark -
#pragma mark Private Interface

@interface ImageCache ()

@property (nonatomic, readonly) NSString *cacheDirectoryPath;
@property (nonatomic, readonly) NSOperationQueue *loadQueue;
@property (nonatomic, readonly) NSOperationQueue *saveQueue;

- (NSString *) imageFilePathFromURL: (NSURL *) url;
- (NSString *) thumbnailFilePathFromURL: (NSURL *) url;

- (void) loadImageForURL: (NSURL *) url thumbnailVersion: (BOOL) thumbnailVersion delegate: (id <ImageCacheDelegate>) delegate;

@end


#pragma mark -

@implementation ImageCache


#pragma mark -
#pragma mark Singleton Design Pattern

SYNTHESIZE_SINGLETON_FOR_CLASS(ImageCache);


#pragma mark -
#pragma mark Load and Save NSOperationQueue

- (NSOperationQueue *) loadQueue {
    if (nil == _loadQueue) {        
        _loadQueue = [[NSOperationQueue alloc] init];
        [_loadQueue setMaxConcurrentOperationCount: 1];
    }
    return _loadQueue;
}

- (NSOperationQueue *) saveQueue {
    if (nil == _saveQueue) {        
        _saveQueue = [[NSOperationQueue alloc] init];
        
        // Limit the number of Save NSOperation that can run at any one time to save memory.
        // A Save NSOperation will load the downloaded image into memory (which is huge)
        // and resize the original image to create the thumbnail and scaled down image.
        [_saveQueue setMaxConcurrentOperationCount: 1];
    }
    return _saveQueue;
}


#pragma mark -
#pragma mark Image Cache File Paths

- (NSString *) cacheDirectoryPath {
    if (nil == _cacheDirectoryPath) {
        _cacheDirectoryPath = [[TCFileHelper sharedHelper].documentsDirectory copy];
    }
    return _cacheDirectoryPath;
}

- (NSString *) imageFilePathFromURL: (NSURL *) url {
    // Get the image name from the URL string.
    NSString *imageName = [url lastPathComponent];
    
    // Get the full path to the image file in the cache directory.
    return [self.cacheDirectoryPath stringByAppendingPathComponent: imageName];
}

- (NSString *) thumbnailFilePathFromURL: (NSURL *) url {
    // Get the image name from the URL string.
    NSString *imageName = [url lastPathComponent];
    
    // Create the thumbnail file name from the image name.
    NSString *thumbnailName = [kThumbnailFilenamePrefix stringByAppendingString: imageName];
    
    // Return the full path to the thumbnail file in the cache directory.
    return [self.cacheDirectoryPath stringByAppendingPathComponent: thumbnailName];
}


#pragma mark -
#pragma mark Load Image

// Notify delegate that image has been loaded from cache.
- (void) notifyDelegateDidFinishLoading: (NSDictionary *) args {
    // *** Notify delegate from the Main Thread only. ***
    assert([NSThread isMainThread]);
    
    BOOL thumbnailVersion = [[args objectForKey: @"thumbnailVersion"] boolValue];
    id <ImageCacheDelegate> delegate = [args objectForKey: @"delegate"];
    UIImage *image = [args objectForKey: @"image"];
    
    if (thumbnailVersion) {
        if ([delegate respondsToSelector: @selector(imageCache:didFinishLoadingThumbnail:)]) {
            [delegate imageCache: self didFinishLoadingThumbnail: image];
        }
    } else {
        if ([delegate respondsToSelector: @selector(imageCache:didFinishLoadingImage:)]) {
            [delegate imageCache: self didFinishLoadingImage: image];
        }
    }    
}

// This method will be called by an NSInvocationOperation and runs on a separate thread.
- (void) loadImageOperation: (NSDictionary *) args {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // Get the file path to load the image from.
    NSURL *url = [args objectForKey: @"url"];
    BOOL thumbnailVersion = [[args objectForKey: @"thumbnailVersion"] boolValue];    
    NSString *filePath = (thumbnailVersion ? 
                               [self thumbnailFilePathFromURL: url] : 
                               [self imageFilePathFromURL: url]);
    
    NSMutableDictionary *delegateArgs = [args mutableCopy];
            
    // Load image from cache. If image is nil, it means image is not found in cache.
    UIImage *image = [[UIImage alloc] initWithContentsOfFile: filePath];
    if (image) {
        [delegateArgs setObject: image forKey: @"image"];
    }
    [image release], image = nil;
    
    // Notify delegate that the image has been loaded from the cache.
    // *** We MUST called delegate on Main Thread to access UI safely! ***
    [self performSelectorOnMainThread: @selector(notifyDelegateDidFinishLoading:) withObject: delegateArgs waitUntilDone: NO];
    [delegateArgs release], delegateArgs = nil;
    
    [pool release];
}

- (void) loadImageForURL: (NSURL *) url thumbnailVersion: (BOOL) thumbnailVersion delegate: (id <ImageCacheDelegate>) delegate {
    // Create the dictionary that stores the arguments we will pass to the 
    // NSInvocationOperation's method.
    NSMutableDictionary *args = [[NSMutableDictionary alloc] init];
    [args setObject: url forKey: @"url"];
    [args setObject: [NSNumber numberWithBool: thumbnailVersion] forKey: @"thumbnailVersion"];
    [args setObject: delegate forKey: @"delegate"];
    
    // Create the load operation and add it to queue to run it asynchronously.
    // The args will be retained by the NSInvocationOperation.
    NSInvocationOperation *loadOperation = [[NSInvocationOperation alloc] 
                                            initWithTarget: self 
                                            selector: @selector(loadImageOperation:) 
                                            object: args];
    [self.loadQueue addOperation: loadOperation];
    
    [args release], args = nil;
    [loadOperation release], loadOperation = nil;     
}

- (void) loadImageForURL: (NSURL *) url delegate: (id <ImageCacheDelegate>) delegate {
    [self loadImageForURL: url thumbnailVersion: NO delegate: delegate];
}

- (void) loadThumbnailForURL: (NSURL *) url delegate: (id <ImageCacheDelegate>) delegate {
    [self loadImageForURL: url thumbnailVersion: YES delegate: delegate];
}


#pragma mark -
#pragma mark Save Image

// Notify delegate that image and thumbnail has been saved.
- (void) notifyDelegateDidFinishSaving: (NSDictionary *) args {
    // *** Notify delegate from the Main Thread only. ***
    assert([NSThread isMainThread]);
    
    id <ImageCacheDelegate> delegate = [args objectForKey: @"delegate"];
    UIImage *image = [args objectForKey: @"image"];
    UIImage *thumbnail = [args objectForKey: @"thumbnail"];
    
    if ([delegate respondsToSelector: @selector(imageCache:didFinishSavingImage:thumbnail:)]) {
        [delegate imageCache: self didFinishSavingImage: image thumbnail: thumbnail];
    }    
}

// This method will be called by an NSInvocationOperation and runs on a separate thread.
- (void) saveImageOperation: (NSDictionary *) args {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // 1. Load the downloaded image from disk.
    ASIHTTPRequest *request = [args objectForKey: @"request"];    
    NSURL *imageURL = [request originalURL];
    UIImage *originalImage = [[UIImage alloc] initWithContentsOfFile: 
                              [request downloadDestinationPath]];  
    
    // 2. Save thumbnail version of original image to disk cache.
    UIImage *thumbnail = [originalImage thumbnailImage: kThumbnailSize.width
                                     transparentBorder: 0 
                                          cornerRadius: 0 
                                  interpolationQuality: kCGInterpolationDefault];
    [UIImageJPEGRepresentation(thumbnail, THUMBNAIL_COMPRESSION_QUALITY) 
         writeToFile: [self thumbnailFilePathFromURL: imageURL] 
          atomically: YES]; 
    
    // 3. Save scaled down version of original image to disk cache.
    UIImage *image = [originalImage resizedImageWithContentMode: UIViewContentModeScaleAspectFit
                                                         bounds: kMaxPhotoSize
                                           interpolationQuality: kCGInterpolationDefault];    
    [UIImageJPEGRepresentation(image, PHOTO_COMPRESSION_QUALITY) 
         writeToFile: [self imageFilePathFromURL: imageURL] 
          atomically: YES];
                        
    // Release the original image from memory.
    [originalImage release], originalImage = nil;
    
    // 4. Remove the downloaded image from disk. Don't need it anymore.
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    [fileManager removeItemAtPath: [request downloadDestinationPath] error: nil];
    [fileManager release], fileManager = nil;
            
    // 5. Notify delegate that the image and thumbnail has been saved to cache.    
    NSMutableDictionary *delegateArgs = [args mutableCopy];
    [delegateArgs setObject: image forKey: @"image"];
    [delegateArgs setObject: thumbnail forKey: @"thumbnail"];
    
    // *** We MUST call delegate on Main Thread to access UI safely! ***
    [self performSelectorOnMainThread: @selector(notifyDelegateDidFinishSaving:) 
                           withObject: delegateArgs waitUntilDone: NO];
    
    [delegateArgs release], delegateArgs = nil;
    
    [pool release];
}

- (void) saveImageForRequest: (ASIHTTPRequest *) request delegate: (id <ImageCacheDelegate>) delegate{
    // Create the dictionary that stores the arguments we will pass to the 
    // NSInvocationOperation's method.
    NSMutableDictionary *args = [[NSMutableDictionary alloc] init];
    [args setObject: request forKey: @"request"];
    [args setObject: delegate forKey: @"delegate"];
    
    // Create the save operation and add it to queue to run it asynchronously.
    // The args will be retained by the NSInvocationOperation.
    NSInvocationOperation *saveOperation = [[NSInvocationOperation alloc] 
                                            initWithTarget: self 
                                            selector: @selector(saveImageOperation:) 
                                            object: args];
    [self.saveQueue addOperation: saveOperation];
        
    [args release], args = nil;
    [saveOperation release], saveOperation = nil;
}


#pragma mark -
#pragma mark Memory Management

- (void) dealloc {
    [_cacheDirectoryPath release], _cacheDirectoryPath = nil;
    [_loadQueue release], _loadQueue = nil;
    [_saveQueue release], _saveQueue = nil;
    [super dealloc];
}

@end
