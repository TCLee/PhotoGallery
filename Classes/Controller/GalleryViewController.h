//
//  GalleryViewController.h
//  PhotoGallery
//
//  Created by Lee Tze Cheun on 7/2/11.
//  Copyright 2011 TC Lee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#import "EasyTableView.h"

@class PhotoView;

/**
 * Controller for the photo and thumbnails view.
 */
@interface GalleryViewController : UIViewController <EasyTableViewDelegate> {

@private    
    // Photo data source model for the views.
    NSArray *_photos;
                                
    // Horizontal table view that holds all the thumbnails view.
    EasyTableView *_thumbnailsView;
    
    // View to display the full size photo and allows user to zoom in/out.
    PhotoView *_photoView; 
    
    // Since we're building the view programmatically, we'll need to
    // know the controller's view size and position.
    CGRect _viewFrame;
    
    // Center point on the photo to refocus on after a rotation occurs.
    CGPoint _beforeRotationPhotoCenter;    
}

/**
 * Initialize a new controller with a view's frame set to specified frame rect.
 */
- (id) initWithViewFrame: (CGRect) viewFrame;

/**
 * Updates the photos data source model.
 */
- (void) setPhotoSource: (NSArray *) imageURLs;

@end
