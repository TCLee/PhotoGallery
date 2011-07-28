//
//  PhotoGalleryAppDelegate.h
//  PhotoGallery
//
//  Created by Lee Tze Cheun on 7/14/11.
//  Copyright 2011 TC Lee. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "XMLFeed.h"

@class MBProgressHUD;
@class GalleryViewController;


/**
 * Delegate for the application.
 * Starts the download of the XML data in the background and 
 * parses the images URL from the XML file.
 */
@interface AppDelegate : NSObject <UIApplicationDelegate, XMLFeedDelegate> {
    
@private
    // Application's main window.
    UIWindow *_window;
    
    XMLFeed *_xmlFeed;
        
    // Progress HUD shown to user when we're downloading and parsing the XML 
    // in the background.
    MBProgressHUD *_progressHUD;
        
    // Controller for the photo and thumbnails view.
    GalleryViewController *_rootViewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@end

