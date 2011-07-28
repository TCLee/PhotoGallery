//
//  ThumbnailView.h
//  PhotoGallery
//
//  Created by Lee Tze Cheun on 7/14/11.
//  Copyright 2011 TC Lee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@class Photo;


/**
 * View that displays a thumbnail image.
 */
@interface ThumbnailView : UIView {

@private
    Photo *_photo;    
    BOOL _selected;
    
    UIImageView *_imageView;
    UIProgressView *_progressView;
}

/** Photo model for this view. */
@property (nonatomic, retain) Photo *photo;

/**
 * A Boolean value that determines the selected state of the thumbnail view.
 * Thumbnail view will be rendered differently depending on its selected state.
 */
@property (nonatomic, assign) BOOL selected;

@end
