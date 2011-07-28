//
//  PhotoView.h
//  PhotoGallery
//
//  Created by Lee Tze Cheun on 7/15/11.
//  Copyright 2011 TC Lee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Photo.h"

/**
 * View that displays the full size photo and allows user to zoom in/out using 
 * pinch gesture or double-tap.
 *
 * This class is based on Apple's PhotoScroller and TapToZoom sample code.
 */
@interface PhotoView : UIScrollView <UIScrollViewDelegate> {

@private
    Photo *_photo;
    UIImageView *_imageView;
    UIImage *_defaultImage;    
}

/** Photo model for this view. */
@property (nonatomic, retain) Photo *photo;

/** Methods used to restore content offset and zoom scale after a rotation. */
- (CGPoint) pointToCenterAfterRotation;
- (CGFloat) scaleToRestoreAfterRotation;
- (void) restoreCenterPoint: (CGPoint) previousCenter zoomScale: (CGFloat) previousZoom;
- (void) setMaxMinZoomScalesForCurrentBounds;

@end
