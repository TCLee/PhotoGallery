//
//  Photo.m
//  PhotoGallery
//
//  Created by Lee Tze Cheun on 7/14/11.
//  Copyright 2011 TC Lee. All rights reserved.
//

#import "Photo.h"
#import "TCFileHelper.h"
#import "TCDebug.h"
#import "ASIHTTPRequest.h"


#pragma mark Constants

// Notification events posted by the Photo model.
NSString * const PhotoDidStartLoadNotification = @"PhotoDidStartLoadNotification";
NSString * const PhotoDidFailLoadNotification = @"PhotoDidFailLoadNotification";
NSString * const PhotoDidUpdateLoadProgressNotification = @"PhotoDidUpdateLoadProgressNotification";
NSString * const PhotoDidLoadImageNotification = @"PhotoDidLoadImageNotification";
NSString * const PhotoDidLoadThumbnailNotification = @"PhotoDidLoadThumbnailNotification";


#pragma mark -
#pragma mark Private Interface

@interface Photo ()

@property (nonatomic, retain, readwrite) UIImage *image;
@property (nonatomic, retain, readwrite) UIImage *thumbnail;

@property (nonatomic, assign, readwrite) BOOL isLoading;
@property (nonatomic, assign) BOOL isLoadingImageFromCache;
@property (nonatomic, assign) BOOL isLoadingThumbnailFromCache;

- (void) resetDownload;
- (NSString *) temporaryDownloadFilePathForURL: (NSURL *) url;
- (NSString *) downloadFilePathForURL: (NSURL *) url;
- (void) downloadImage;

- (void) releaseSafelyRequest;

@end


#pragma mark -

@implementation Photo

@synthesize image = _image;
@synthesize thumbnail = _thumbnail;
@synthesize imageURL = _imageURL;
@synthesize index = _index;
@synthesize progress = _progress;
@synthesize isLoading = _loadingImageFromNetwork;
@synthesize isLoadingImageFromCache = _loadingImageFromCache;
@synthesize isLoadingThumbnailFromCache = _loadingThumbnailFromCache;


#pragma mark -
#pragma mark Debugging Methods

#ifdef DEBUG

// Returns a BOOL value as a string.
#define StringFromBOOL(b) ((b) ? @"YES" : @"NO")

// Returns a string representation of the Photo model for debugging.
- (NSString *) description {
    return [NSString stringWithFormat: 
            @"Photo Model\n"
            "{\n"
            "\tIndex = %lu\n"
            "\tImage URL = %@\n" 
            "\tProgress = %f\n" 
            "\tASIHTTPRequest = %@\n"
            "\tImage = %@ (%.1f x %.1f)\n" 
            "\tThumbnail = %@ (%.1f x %.1f)\n"
            "\tLoading Image from Network = %@\n" 
            "\tLoading Image from Cache = %@\n" 
            "\tLoading Thumbnail from Cache = %@\n"
            "}", 
            self.index, 
            [self.imageURL absoluteString],
            self.progress, 
            _request, 
            _image, _image.size.width, _image.size.height,
            _thumbnail, _thumbnail.size.width, _thumbnail.size.height,
            StringFromBOOL(self.isLoading), 
            StringFromBOOL(self.isLoadingImageFromCache), 
            StringFromBOOL(self.isLoadingThumbnailFromCache)];
}
#endif // #ifdef DEBUG


#pragma mark -
#pragma mark Class Methods

+ (NSArray *) photosFromURLStrings: (NSArray *) urlStrings {
    NSMutableArray *photos = [[NSMutableArray alloc] initWithCapacity: urlStrings.count];
    NSUInteger photoIndex = 0;
    
    for (NSString *urlString in urlStrings) {
        Photo *photo = [[Photo alloc] initWithURLString: urlString index: photoIndex++];
        [photos addObject: photo];
        [photo release], photo = nil;
    }
    return [photos autorelease];    
}

+ (CGSize) thumbnailSize {
    // Returns the default thumbnail size defined by ImageCache.
    return kThumbnailSize;
}


#pragma mark -
#pragma mark Initialize

-(id) initWithURLString: (NSString *) imageURLString index: (NSUInteger) photoIndex {
    self = [super init];
    if (self) {
        _imageURL = [[NSURL alloc] initWithString: imageURLString];
        _index = photoIndex;
    }
    return self;
}


#pragma mark -
#pragma mark Properties Accesors

- (void) setProgress: (float) newProgress {
    _progress = newProgress;
        
    // Notify observers that progress property has been modified.
    [[NSNotificationCenter defaultCenter] 
         postNotificationName: PhotoDidUpdateLoadProgressNotification object: self];    
}

- (UIImage *) image {
    // If image has been cached in memory (i.e. != nil), then just return image.
    if (nil == _image) {
        // Don't load from disk cache again, if there is already a load in progress.
        if (!self.isLoadingImageFromCache) {
            // Load image from disk cache asynchronously.
            [[ImageCache sharedImageCache] loadImageForURL: self.imageURL 
                                                  delegate: self];
            self.isLoadingImageFromCache = YES;
            
            TC_DEBUG_PRINT(@"\n---[IMAGE LOADING FROM DISK CACHE]---\n%@", self);
        }        
    }
    return _image;
}

- (UIImage *) thumbnail {
    // If thumbnail has been cached in memory (i.e. != nil), then just return thumbnail.
    if (nil == _thumbnail) {
        // Don't load from disk cache again, if there is already a load in progress.
        if (!self.isLoadingThumbnailFromCache) {
            // Load thumbnail from disk cache asynchronously.
            [[ImageCache sharedImageCache] loadThumbnailForURL: self.imageURL 
                                                      delegate: self];
            self.isLoadingThumbnailFromCache = YES;
            
            TC_DEBUG_PRINT(@"\n---[THUMBNAIL LOADING FROM DISK CACHE]---\n%@", self);
        }        
    }
    return _thumbnail;
}


#pragma mark -
#pragma mark ASIHTTPRequest Delegate

// Image download has started.
- (void) requestStarted: (ASIHTTPRequest *) request {
    self.isLoading = YES;
            
    // Notify observers that Photo model has started loading image from the network.
    [[NSNotificationCenter defaultCenter] 
         postNotificationName: PhotoDidStartLoadNotification object: self];
        
    TC_DEBUG_PRINT(@"\n---[IMAGE DOWNLOAD STARTED]---\n%@", self);
}

// Image download has finished.
- (void) requestFinished: (ASIHTTPRequest *) request {
    self.isLoading = NO;
            
    // Saves the request's image response data to cache asynchronously.
    [[ImageCache sharedImageCache] saveImageForRequest: request delegate: self];    
    
    TC_DEBUG_PRINT(@"\n---[IMAGE DOWNLOAD FINISHED. SAVING IMAGE AND THUMBNAIL TO CACHE]---\n%@", self);
}

// Image download has failed.
- (void) requestFailed: (ASIHTTPRequest *) request {    
    self.isLoading = NO;        
    
    // Notify observers that Photo model has failed to load image.
    [[NSNotificationCenter defaultCenter] 
         postNotificationName: PhotoDidFailLoadNotification object: self];
    
    // Reset the download state when request has failed.
    [self resetDownload];
    
    TC_DEBUG_PRINT(@"\n---[IMAGE DOWNLOAD FAILED]---\n%@", self);
}


#pragma mark -
#pragma mark ImageCache Delegate

// Image has been loaded from cache.
- (void) imageCache: (ImageCache *) imageCache didFinishLoadingImage: (UIImage *) image {
    self.isLoadingImageFromCache = NO;    
    
    // If image is found in cache, then notify observers that image is ready.
    // Otherwise image was not found in cache, then start download of image.
    if (image) {
        self.image = image;        
        [[NSNotificationCenter defaultCenter] 
             postNotificationName: PhotoDidLoadImageNotification object: self];
        
        TC_DEBUG_PRINT(@"\n---[IMAGE LOADED FROM CACHE]---\n%@", self);
    } else {
        TC_DEBUG_PRINT(@"\n---[IMAGE NOT FOUND IN CACHE. START DOWNLOAD]---\n%@", self);        
        [self downloadImage];
    }        
}

// Thumbnail has been loaded from cache.
- (void) imageCache: (ImageCache *) imageCache didFinishLoadingThumbnail: (UIImage *) thumbnail {
    self.isLoadingThumbnailFromCache = NO;
    
    // If thumbnail is found in cache, then notify observers that thumbnail is ready.
    // Otherwise thumbnail was not found in cache, then start download of image.
    if (thumbnail) {
        self.thumbnail = thumbnail;
        [[NSNotificationCenter defaultCenter] 
             postNotificationName: PhotoDidLoadThumbnailNotification object: self];
        
        TC_DEBUG_PRINT(@"\n---[THUMBNAIL LOADED FROM CACHE]---\n%@", self);
    } else {        
        TC_DEBUG_PRINT(@"\n---[THUMBNAIL NOT FOUND IN CACHE. START DOWNLOAD]---\n%@", self);        
        [self downloadImage];
    }
}

// Image and thumbnail has been saved to cache.
- (void) imageCache: (ImageCache *) imageCache didFinishSavingImage: (UIImage *) image thumbnail: (UIImage *) thumbnail {            
    // Cache only the thumbnail in memory for faster access.
    // Full size image will be loaded from disk cache as and when needed.
    self.thumbnail = thumbnail;
    
    // Reset the download state when image has been downloaded and saved to cache.
    [self resetDownload];
    
    TC_DEBUG_PRINT(@"\n---[IMAGE AND THUMBNAIL SAVED TO CACHE]---\n%@", self);
    
    // Notify observers that Photo model's image and thumbnail has been downloaded and 
    // saved to cache.
    [[NSNotificationCenter defaultCenter] 
         postNotificationName: PhotoDidLoadThumbnailNotification object: self];
    [[NSNotificationCenter defaultCenter] 
         postNotificationName: PhotoDidLoadImageNotification object: self];    
}


#pragma mark -
#pragma mark Private Helper Methods

// Resets the download state. 
- (void) resetDownload {
    // Cancel and release any existing request.
    [self releaseSafelyRequest];
    
    // Reset the progress.
    _progress = 0;
}

// Returns the file path for the partial download to resume previous download.
- (NSString *) temporaryDownloadFilePathForURL: (NSURL *) url {
    NSString *filename = [[url lastPathComponent] 
                          stringByAppendingPathExtension: @"download"];
    NSString *documentsDirectory = [TCFileHelper sharedHelper].documentsDirectory;    
    return [documentsDirectory stringByAppendingPathComponent: filename];                
}

// Returns the download file path for given URL.
- (NSString *) downloadFilePathForURL: (NSURL *) url {
    NSString *filename = [[url lastPathComponent] 
                          stringByAppendingPathExtension: @"original"];
    NSString *documentsDirectory = [TCFileHelper sharedHelper].documentsDirectory;
    return [documentsDirectory stringByAppendingPathComponent: filename];            
}

// Starts download of image asynchronously.
- (void) downloadImage {
    // If there's an existing request in progress, don't create and send request again.
    if (nil == _request) {        
        // Reset the download state for start of new request.
        [self resetDownload];
        
        // Create new request to download the image. 
        // Request will be added to ASIHTTPRequest's queue.
        _request = [[ASIHTTPRequest alloc] initWithURL: self.imageURL];
        [_request setDelegate: self];
        [_request setDownloadProgressDelegate: self];
        [_request setDownloadDestinationPath: [self downloadFilePathForURL: self.imageURL]];
        [_request setTemporaryFileDownloadPath: [self temporaryDownloadFilePathForURL: self.imageURL]];
        [_request setAllowResumeForFileDownloads: YES];
        [_request setShouldContinueWhenAppEntersBackground: YES];
        [_request startAsynchronous];
                
        TC_DEBUG_PRINT(@"\n---[IMAGE DOWNLOAD ADDED TO QUEUE]---\n%@", self);
    }         
}


#pragma mark -
#pragma mark Memory Management

// Removes and releases image and thumbnail from memory cache.
- (void) releaseSafelyImageAndThumbnail {
    [_image release], _image = nil;
    [_thumbnail release], _thumbnail = nil;
    
    TC_DEBUG_PRINT(@"\n---[IMAGE AND THUMBNAIL RELEASED FROM MEMORY CACHE]---\n%@", self);
}

// Cancels request and then safely releases it.
- (void) releaseSafelyRequest {
    [_request clearDelegatesAndCancel];
    [_request release], _request = nil;
}

- (void) dealloc {
    // Release image and thumbnail.
    [self releaseSafelyImageAndThumbnail];
    
    // Cancels request and then safely releases it.
    [self releaseSafelyRequest];
    
    [_imageURL release], _imageURL = nil;
    
    [super dealloc];
}


@end
