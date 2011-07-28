//
//  PhotoView.m
//  PhotoGallery
//
//  Created by Lee Tze Cheun on 6/26/11.
//  Copyright 2011 TC Lee. All rights reserved.
//

#import "PhotoView.h"


#pragma mark Private Inteface

@interface PhotoView ()

@property (nonatomic, retain) UIImageView *imageView;
@property (nonatomic, readonly) UIImage *defaultImage;

- (CGPoint) maximumContentOffset;
- (CGRect) zoomRectForScale: (float) scale withCenter: (CGPoint) center;
- (void) addDoubleTapGesture;
- (void) displayImage: (UIImage *) image;

- (void) registerAsObserverForPhotoModel: (Photo *) photo;
- (void) unregisterAsObserverForPhotoModel: (Photo *) photo;

@end


#pragma mark -

@implementation PhotoView

@synthesize imageView = _imageView;
@synthesize photo = _photo;


#pragma mark -
#pragma mark Properties Accessors

// Gets the default placeholder image when there is no image to display.
- (UIImage *) defaultImage {
    if (nil == _defaultImage) {
        _defaultImage = [[UIImage imageNamed: @"photoDefault.png"] retain];
    }
    return _defaultImage;
}

- (void) setPhoto: (Photo *) newPhoto {
    if (_photo != newPhoto) {
        // Remove ourselves as observer from the old Photo model.        
        [self unregisterAsObserverForPhotoModel: _photo];
        
        // Update the view's backing model to the new Photo model.
        [_photo release];
        _photo = [newPhoto retain];
        
        if (nil == _photo) { return; }
        
        // Register ourselves as observer to the new Photo model.
        [self registerAsObserverForPhotoModel: _photo];
                  
        // Display the image on the zoom-enabled photo view.
        [self displayImage: _photo.image];
    }
}


#pragma mark -
#pragma mark Register/Unregister as Photo Model's Observer

// Register ourselves as observer to the given Photo model.
- (void) registerAsObserverForPhotoModel: (Photo *) photo {    
    NSDictionary *notifications = [[NSDictionary alloc] initWithObjectsAndKeys: 
                                   [NSValue valueWithPointer: @selector(photoDidFailLoad:)], PhotoDidFailLoadNotification,                                    
                                   [NSValue valueWithPointer: @selector(photoDidLoadImage:)], PhotoDidLoadImageNotification, nil];
    
    for (NSString *notificationName in notifications) {
        [[NSNotificationCenter defaultCenter] addObserver: self 
                                                 selector: [[notifications objectForKey: notificationName] pointerValue] 
                                                     name: notificationName 
                                                   object: photo];
    }
    
    [notifications release], notifications = nil;        
}

// Unregister ourselves as observer to the given Photo model.
- (void) unregisterAsObserverForPhotoModel: (Photo *) photo {
    NSArray *notificationNames = [[NSArray alloc] initWithObjects:  
                                  PhotoDidFailLoadNotification, 
                                  PhotoDidLoadImageNotification, nil];
    
    for (NSString *notificationName in notificationNames) {
        [[NSNotificationCenter defaultCenter] removeObserver: self 
                                                        name: notificationName 
                                                      object: photo];
    }
    
    [notificationNames release], notificationNames = nil;
}


#pragma mark -
#pragma mark Photo Model Notifications

// Photo model has failed to load image.
- (void) photoDidFailLoad: (NSNotification *) notification {
    [self displayImage: nil];
}

// Photo model has finished loading image.
- (void) photoDidLoadImage: (NSNotification *) notification {
    Photo *photo = [notification object];
    [self displayImage: photo.image];
}


#pragma mark -
#pragma mark Override UIView Methods

- (id) initWithFrame: (CGRect) frame {   
    self = [super initWithFrame: frame];
    if (self) {
        self.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        self.showsVerticalScrollIndicator = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.bouncesZoom = YES;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.delegate = self;                   
    }
    return self;
}

/** 
 * Override layoutSubviews method to center image within the scroll view. 
 * The method layoutSubviews is where we want to place the centering code because
 * it's called each time the scroll view is scrolled or zoomed.
 */
- (void) layoutSubviews {
    [super layoutSubviews];
    
    /* Center the image as it becomes smaller than the size of the screen. */
    
    CGSize scrollViewSize = self.bounds.size;
    CGRect imageFrame = self.imageView.frame;
    
    // Center image horizontally within the scroll view.
    if (imageFrame.size.width < scrollViewSize.width) {
        imageFrame.origin.x = (scrollViewSize.width - imageFrame.size.width) / 2;
    } else {
        imageFrame.origin.x = 0;
    }
    
    // Center image vertically within the scroll view.
    if (imageFrame.size.height < scrollViewSize.height) {
        imageFrame.origin.y = (scrollViewSize.height - imageFrame.size.height) / 2;
    } else {
        imageFrame.origin.y = 0;
    }
        
    // Update the image view's frame to be centered within scroll view.   
    self.imageView.frame = imageFrame;
}


#pragma mark -
#pragma mark Configure UIScrollView to Display Image

- (void) displayImage: (UIImage *) image {
    // Use default placeholder image, if no image provided (nil).
    BOOL useDefaultImage = (nil == image);
    if (useDefaultImage) {
        image = self.defaultImage;
    }
    
    // Remove previous image view if any.
    [self.imageView removeFromSuperview];
    self.imageView = nil;
    
    // Reset zoom scale to default before doing any further calculations.
    self.zoomScale = 1.0;
            
    // Create a new UIImageView for the new image.
    _imageView = [[UIImageView alloc] initWithImage: image];
    [self addSubview: self.imageView];
        
    // Configure the scroll view's zoom settings.
    self.contentSize = image.size;
    [self setMaxMinZoomScalesForCurrentBounds];
    self.zoomScale = self.minimumZoomScale;            
    
    // Add double tap to zoom gesture. 
    // If we're using default placeholder image, don't need double tap gesture.
    if (!useDefaultImage) {        
        self.imageView.userInteractionEnabled = YES;
        [self addDoubleTapGesture];
    }    
}

- (void) setMaxMinZoomScalesForCurrentBounds {
    CGSize scrollViewSize = self.bounds.size;
    CGSize imageSize = self.imageView.bounds.size;    
        
    // Scale to fit the image's width within the scroll view.    
    CGFloat widthScale = scrollViewSize.width / imageSize.width;
    
    // Scale to fit the image's height within the scroll view.
    CGFloat heightScale = scrollViewSize.height / imageSize.height;        
    
    // Use the minimum of width or height scale to fit image within scroll view perfectly.    
    CGFloat minZoomScale = MIN(widthScale, heightScale);    
    
    // On high resolution screens we have double the pixel density, so we will 
    // be seeing every pixel if we limit the maximum zoom scale to 0.5.
    CGFloat maxZoomScale = 1.0 / [UIScreen mainScreen].scale; 
    
    // If the image is smaller than the screen, we don't want to force it to be zoomed in.
    minZoomScale = MIN(minZoomScale, maxZoomScale);

    self.maximumZoomScale = maxZoomScale;
    self.minimumZoomScale = minZoomScale;    
}


#pragma mark -
#pragma mark Double Tap to Zoom

- (void) addDoubleTapGesture {
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] 
                                          initWithTarget: self action: @selector(handleDoubleTap:)];
    [tapGesture setNumberOfTapsRequired: 2];
    [self.imageView addGestureRecognizer: tapGesture];
    [tapGesture release], tapGesture = nil;
}

// Double tap zooms in on the point where the user tapped.
- (void) handleDoubleTap: (UIGestureRecognizer *) gesture {
    // If image is zoomed out, double tap will zoom in. Vice versa.
    float scale = (self.zoomScale > self.minimumZoomScale ? 
                   self.minimumZoomScale : self.maximumZoomScale);               
    
    CGRect zoomRect = [self zoomRectForScale: scale 
                                  withCenter: [gesture locationInView: gesture.view]];
    [self zoomToRect: zoomRect animated: YES];
}


- (CGRect) zoomRectForScale: (float) scale withCenter: (CGPoint) center {
    CGSize scrollViewSize = self.frame.size;
    
    // Calculate the width and height of the zoom rectangle.
    // As the zoom scale decreases, so more content is visible, the size of the rect grows.
    CGRect zoomRect = CGRectZero;    
    zoomRect.size.width = scrollViewSize.width / scale;
    zoomRect.size.height = scrollViewSize.height / scale;
    
    // Calculate the x and y position of the zoom rectangle.
    zoomRect.origin.x = center.x - (zoomRect.size.width / 2.0);
    zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0);
    
    return zoomRect;
}


#pragma mark -
#pragma mark UIScrollViewDelegate

// Return the UIImageView that we want zooming for.
- (UIView *) viewForZoomingInScrollView: (UIScrollView *) scrollView {
    return self.imageView;
}


#pragma mark -
#pragma mark Handle View Rotation

// Returns the center point in image coordinate space to try to restore after a rotation. 
- (CGPoint) pointToCenterAfterRotation {    
    // Get the center point in the scroll view's bounds.
    CGPoint scrollViewCenter = CGPointMake(CGRectGetMidX(self.bounds), 
                                           CGRectGetMidY(self.bounds));
    
    // Convert that center point to image's coordinate space.
    return [self convertPoint: scrollViewCenter toView: self.imageView];            
}

// Returns the zoom scale to attempt to restore after a rotation.
- (CGFloat) scaleToRestoreAfterRotation {
    CGFloat contentScale = self.zoomScale;    
    
    // If we're at the minimum zoom scale, preserve that by returning 0.
    // It will be converted to the minimum allowable scale when the zoom scale is restored.
    if (contentScale <= self.minimumZoomScale + FLT_EPSILON) {
        contentScale = 0;
    }    
    
    return contentScale;
}

// Returns the maximum content offset allowed for current content size.
- (CGPoint) maximumContentOffset {
    CGSize contentSize = self.contentSize;
    CGSize viewportSize = self.bounds.size;
    
    // Content Offset = Content Size - Viewport Size
    // Content Offset should never be negative.
    CGFloat maxOffsetX = MAX(0, contentSize.width - viewportSize.width);
    CGFloat maxOffsetY = MAX(0, contentSize.height - viewportSize.height);        
    
    return CGPointMake(maxOffsetX, maxOffsetY);            
}

// Adjusts current content offset and zoom scale to try to restore the previous zoom 
// scale and center.
- (void) restoreCenterPoint: (CGPoint) previousCenter zoomScale: (CGFloat) previousZoom {
    // Step 1: Restore zoom scale, first making sure it is within the allowable range.
    // (i.e. minimumZoomScale <= previousZoom <= maximumZoomScale)
    self.zoomScale = MIN(self.maximumZoomScale, MAX(self.minimumZoomScale, previousZoom));
 
    // Step 2: Restore center point, first making sure it is within the allowable range.
    
    // 2-A: Convert the center point back to our own coordinate space.
    CGPoint scrollViewCenter = [self convertPoint: previousCenter fromView: self.imageView];    

    // 2-B: Calculate the content offset that would move us to that center point.
    CGPoint offset = CGPointMake(scrollViewCenter.x - (self.bounds.size.width / 2.0), 
                                 scrollViewCenter.y - (self.bounds.size.height / 2.0));    
    
    // 2-C: Restore offset, adjusted to be within the allowable range.
    // (i.e. minOffset <= offset <= maxOffset)
    CGPoint maxOffset = [self maximumContentOffset];
    CGPoint minOffset = CGPointZero;
    offset.x = MAX(minOffset.x, MIN(maxOffset.x, offset.x));
    offset.y = MAX(minOffset.y, MIN(maxOffset.y, offset.y));
    self.contentOffset = offset;
}


#pragma mark -
#pragma mark Memory Management

- (void) dealloc {
    // Unregister ourselves as observer from all notifications (not just Photo model).
    [[NSNotificationCenter defaultCenter] removeObserver: self];

    [_photo release], _photo = nil;
    [_imageView release], _imageView = nil;
    [_defaultImage release], _defaultImage = nil;
        
    [super dealloc];
}

@end
