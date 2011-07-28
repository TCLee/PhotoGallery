//
//  AppDelegate.m
//  PhotoGallery
//
//  Created by Lee Tze Cheun on 7/14/11.
//  Copyright 2011 TC Lee. All rights reserved.
//

#import "AppDelegate.h"
#import "GalleryViewController.h"
#import "MBProgressHUD.h"


#pragma mark Private Interface

@interface AppDelegate ()

@property (nonatomic, retain) GalleryViewController *rootViewController;
@property (nonatomic, retain) MBProgressHUD *progressHUD;

@end


#pragma mark -

@implementation AppDelegate

@synthesize window = _window;
@synthesize progressHUD = _progressHUD;
@synthesize rootViewController = _rootViewController;


#pragma mark -
#pragma mark Application Life Cycle

- (BOOL) application: (UIApplication *) application 
    didFinishLaunchingWithOptions: (NSDictionary *) launchOptions {

    // Configure and show the window.
    _rootViewController = [[GalleryViewController alloc] initWithViewFrame: _window.bounds];        
    [self.window addSubview: self.rootViewController.view];
    [self.window makeKeyAndVisible];
    
    // Fetch and  parse the XML feed.
    _xmlFeed = [[XMLFeed alloc] initWithDelegate: self];
    [_xmlFeed fetch];
        
    return YES;
}


#pragma mark -
#pragma mark XMLFeed Delegate

- (void) xmlFeedDidStartDownload: (XMLFeed *) xmlFeed {
    // Show the progress HUD while we're downloading and parsing the XML in the background.
    self.progressHUD = [MBProgressHUD showHUDAddedTo: self.rootViewController.view animated: YES];
    self.progressHUD.labelText = NSLocalizedString(@"Loading...", @"MBProgressHUD label text.");    
}

- (void) xmlFeed: (XMLFeed *) xmlFeed didFailWithError: (NSError *) error {
    // Show error alert view.
    NSString *errorMessage = [error localizedDescription];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Error Loading XML", @"Title for alert view displayed when download or parse error occurs.")
														message: errorMessage
													   delegate: nil
											  cancelButtonTitle: NSLocalizedString(@"OK", @"OK Button")
											  otherButtonTitles: nil];
    [alertView show];
    [alertView release];    
}

- (void) xmlFeedDidFinishWithResult: (NSArray *) result {
    // Hide the progress HUD after we're done with downloading and parsing of XML.
    if (self.progressHUD) {
        [self.progressHUD hide: YES];
        self.progressHUD = nil;        
    }
    
    // Update the controller's photo data source model.
    [self.rootViewController setPhotoSource: result];
}


#pragma mark -
#pragma mark Memory Management

- (void) dealloc {
    [_window release], _window = nil;
    _xmlFeed.delegate = nil, [_xmlFeed release], _xmlFeed = nil;
    [_rootViewController release], _rootViewController = nil;
    [_progressHUD release], _progressHUD = nil;
        
    [super dealloc];
}


@end
