//
//  ThumbnailView.m
//  PhotoGallery
//
//  Created by Lee Tze Cheun on 7/14/11.
//  Copyright 2011 TC Lee. All rights reserved.
//

#import "ThumbnailView.h"
#import "Photo.h"


#pragma mark Constants

// Padding for the UIProgressView.
#define PROGRESS_VIEW_PADDING 8

// Selected and unselected opacity for UIImageView.
#define SELECTED_OPACITY    1.0
#define UNSELECTED_OPACITY  0.35


#pragma mark -
#pragma mark Private Interface

@interface ThumbnailView ()

@property (nonatomic, retain) UIImageView *imageView;
@property (nonatomic, retain) UIProgressView *progressView;

- (void) createImageView;
- (void) createProgressView;

- (void) registerAsObserverForPhotoModel: (Photo *) photo;
- (void) unregisterAsObserverForPhotoModel: (Photo *) photo;

@end


#pragma mark -

@implementation ThumbnailView

@synthesize photo = _photo;
@synthesize selected = _selected;
@synthesize imageView = _imageView;
@synthesize progressView = _progressView;


#pragma mark -
#pragma mark Initialize and Create Views

- (id) initWithFrame: (CGRect) frame {    
    self = [super initWithFrame:frame];    
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        
        // Create and add the image view  as subview to this view.
        [self createImageView];        
        
        // Create and add the progress view  as subview to this view.
        // Progress view will be placed on top of the image view.
        [self createProgressView];
        
        // Set view's state to unselected initially.
        self.selected = NO;
    }
    return self;
}

- (void) createProgressView {
    // Progress view's height is set depending on the UIProgressViewStyle used.
    _progressView = [[UIProgressView alloc] initWithProgressViewStyle: 
                     UIProgressViewStyleDefault];
    
    // Progress view is hidden. It's visible only when download begins.
    self.progressView.hidden = YES;
        
    // Position the progress view at the bottom of the view with some padding on each side.
    CGFloat progressBarHeight = self.progressView.frame.size.height;
    self.progressView.frame = CGRectMake(self.bounds.origin.x + PROGRESS_VIEW_PADDING, 
                                         self.bounds.size.height - (progressBarHeight + PROGRESS_VIEW_PADDING), 
                                         self.bounds.size.width - (2.0 * PROGRESS_VIEW_PADDING), 
                                         progressBarHeight);
    
    [self addSubview: self.progressView];
}

- (void) createImageView {
    // Create and add the image view to display the thumbnail.
    _imageView = [[UIImageView alloc] initWithFrame: self.bounds];
    self.imageView.contentMode = UIViewContentModeCenter;
    self.imageView.clipsToBounds = YES;
    [self addSubview: self.imageView];    
}


#pragma mark -
#pragma mark Selected/Unselected State

- (void) setSelected: (BOOL) newSelected {
    _selected = newSelected;     
    if (_selected) {
        // Draw view as selected.
        self.imageView.alpha = SELECTED_OPACITY;
        self.layer.borderColor = [[UIColor whiteColor] CGColor];
        self.layer.borderWidth = 2.0;        
    } else {
        // Draw view as unselected.
        self.imageView.alpha = UNSELECTED_OPACITY;
        self.layer.borderColor = [[UIColor darkGrayColor] CGColor];
        self.layer.borderWidth = 1.0;
    }
}


#pragma mark -
#pragma mark Photo Model

- (void) setPhoto: (Photo *) newPhoto {
    if (_photo != newPhoto) {
        // Remove ourselves as observer from the old Photo model.        
        [self unregisterAsObserverForPhotoModel: _photo];
        
        // Update the view's backing model to the new Photo model.
        [_photo release], _photo = nil;
        _photo = [newPhoto retain];
        
        if (nil == _photo) { return; }
                                
        // Register ourselves as observer to the new Photo model.
        [self registerAsObserverForPhotoModel: _photo];
        
        // Display thumbnail on image view.
        self.imageView.image = _photo.thumbnail;
                                        
        // Only show progress bar, if there's a download in progress.
        self.progressView.hidden = (!_photo.isLoading);
        self.progressView.progress = _photo.progress;
    }
}


#pragma mark -
#pragma mark Register/Unregister as Photo Model's Observer

// Register ourselves as observer to the given Photo model.
- (void) registerAsObserverForPhotoModel: (Photo *) photo {    
    NSDictionary *notifications = [[NSDictionary alloc] initWithObjectsAndKeys: 
                                   [NSValue valueWithPointer: @selector(photoDidStartLoad:)], PhotoDidStartLoadNotification, 
                                   [NSValue valueWithPointer: @selector(photoDidUpdateLoadProgress:)], PhotoDidUpdateLoadProgressNotification, 
                                   [NSValue valueWithPointer: @selector(photoDidFailLoad:)], PhotoDidFailLoadNotification,                                    
                                   [NSValue valueWithPointer: @selector(photoDidLoadThumbnail:)], PhotoDidLoadThumbnailNotification, nil];

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
                                  PhotoDidStartLoadNotification, 
                                  PhotoDidFailLoadNotification, 
                                  PhotoDidUpdateLoadProgressNotification, 
                                  PhotoDidLoadThumbnailNotification, nil];
    
    for (NSString *notificationName in notificationNames) {
        [[NSNotificationCenter defaultCenter] removeObserver: self 
                                                        name: notificationName 
                                                      object: photo];
    }
    
    [notificationNames release], notificationNames = nil;
}


#pragma mark -
#pragma mark Photo Model Notifications

// Photo model has started loading the image. Make our progress view visible.
- (void) photoDidStartLoad: (NSNotification *) notification {    
    self.progressView.hidden = NO;
}

// Photo model has updated its load progress. Update our progress view accordingly.
- (void) photoDidUpdateLoadProgress: (NSNotification *) notification {
    Photo *photo = [notification object];      
    self.progressView.progress = photo.progress;    
}

// Photo model failed to load image.
- (void) photoDidFailLoad: (NSNotification *) notification {
    self.progressView.hidden = YES;
    self.progressView.progress = 0;
}

// Photo model has finished loading thumbnail.
- (void) photoDidLoadThumbnail: (NSNotification *) notification {
    Photo *photo = [notification object];
    self.imageView.image = photo.thumbnail;
    
    // Fade in animation for image view.
    self.imageView.alpha = 0.0;
    [UIView animateWithDuration: 0.5 
                          delay: 0.0 
                        options: UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction
         animations: ^ {
             self.imageView.alpha = (self.selected ? SELECTED_OPACITY : UNSELECTED_OPACITY);
         } 
         completion: NULL
     ];
            
    self.progressView.hidden = YES;
    self.progressView.progress = 0;
}


#pragma mark -
#pragma mark Memory Management

- (void) dealloc {
    // Unregister ourselves as observer from all notifications (not just Photo model).
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    [_photo release], _photo = nil;
    [_imageView release], _imageView = nil;
    [_progressView release], _progressView = nil;
    [super dealloc];
}

@end
