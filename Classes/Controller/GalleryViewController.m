//
//  GalleryViewController.m
//  PhotoGallery
//
//  Created by Lee Tze Cheun on 7/2/11.
//  Copyright 2011 TC Lee. All rights reserved.
//

#import "GalleryViewController.h"
#import "PhotoView.h"
#import "ThumbnailView.h"
#import "Photo.h"
#import "TCReachability.h"


#pragma mark Constants

// Constants for the Thumbnails View dimensions.
#define THUMBNAIL_PADDING  5.0

// Constants for the Photo View dimensions.
#define PHOTO_PADDING      10.0

// Host name to check for reachability.
static NSString * const kHostName = @"sapphire2.adrenalin.my";


#pragma mark -
#pragma mark Private Interface

@interface GalleryViewController ()

@property (nonatomic, retain) NSArray *photos;
@property (nonatomic, retain) EasyTableView *thumbnailsView;
@property (nonatomic, retain) PhotoView *photoView;

// Create the Photo Scroll View and add it as subview to given view.
- (void) createPhotoViewInView: (UIView *) view;

// Create the Thumbnails View and add it as subview to given view.
- (void) createThumbnailsViewInView: (UIView *) view;

// Reload thumbnails view's and photo view's contents.
- (void) reloadVisibleThumbnails;
- (void) reloadPhotoView;

@end


#pragma mark -

@implementation GalleryViewController

@synthesize photos = _photos;
@synthesize thumbnailsView = _thumbnailsView;
@synthesize photoView = _photoView;


#pragma mark -
#pragma mark Initialize

- (id) initWithViewFrame: (CGRect) viewFrame {
    self = [super init];
    if (self) {
        _viewFrame = viewFrame;
                
        // When our app moves to the background, free up as much memory as possible, 
        // so that there is less chance of our app being killed by iOS.
        [[NSNotificationCenter defaultCenter] 
             addObserver: self
             selector: @selector(releaseAllImages)
             name: UIApplicationDidEnterBackgroundNotification
             object: nil];
    }
    return self;
}


#pragma mark -
#pragma mark View Life Cycle

// Create the view programatically without a NIB.
- (void) loadView {
    [super loadView];
    
    // Create this controller's view.
    UIView *view = [[UIView alloc] initWithFrame: _viewFrame];
    view.backgroundColor = [UIColor blackColor];
    
    // Create the Thumbnails view and add it to this controller's view.
    [self createThumbnailsViewInView: view];
    
    // Create the Photo Scroll view and add it to this controller's view.
    [self createPhotoViewInView: view];
          
    // Set as this controller's view.
    self.view = view;
    [view release];
    view = nil;
}


#pragma mark -
#pragma mark View Controller Rotation

// Overriden to allow any orientation.
- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation {    
    return YES;
}

// Save the center point in the photo view to restore after a rotation.
// After a rotation, the photo view will re-focus on this center point.
- (void) willRotateToInterfaceOrientation: (UIInterfaceOrientation) toInterfaceOrientation duration: (NSTimeInterval) duration {
    _beforeRotationPhotoCenter = [self.photoView pointToCenterAfterRotation];    
}

// When a rotation occurs, we will need to re-adjust the zoom and content offset for 
// the photo view.
- (void) willAnimateRotationToInterfaceOrientation: (UIInterfaceOrientation) toInterfaceOrientation duration: (NSTimeInterval) duration {            
    CGFloat restoreScale = [self.photoView scaleToRestoreAfterRotation];
    [self.photoView setMaxMinZoomScalesForCurrentBounds];
    [self.photoView restoreCenterPoint: _beforeRotationPhotoCenter zoomScale: restoreScale];
    _beforeRotationPhotoCenter = CGPointZero;
}


#pragma mark -
#pragma mark Create Views

- (void) createPhotoViewInView: (UIView *) view {        
    // We need to make space for the Thumbnails view at the bottom.
    CGFloat thumbnailsViewHeight = self.thumbnailsView.bounds.size.height;
    
    // Calculate the frame of the Photo Scroll view.
    CGRect photoFrame = view.bounds;
    photoFrame.size.height -= (PHOTO_PADDING + thumbnailsViewHeight);
        
    // Create and add the Photo Scroll view to controller's view.
    PhotoView *photoView = [[PhotoView alloc] initWithFrame: photoFrame];
    self.photoView = photoView;
    [photoView release], photoView = nil;
    
    [view addSubview: self.photoView];      
}

- (void) createThumbnailsViewInView: (UIView *) view {
    // Table view and cell view sizes are calculated based on the thumbnail size.
    CGSize thumbnailSize = [Photo thumbnailSize];
    
    // Horizontal table view is placed at the bottom of the screen.    
    CGFloat tableHeight = thumbnailSize.height + (2 * THUMBNAIL_PADDING);
    CGRect tableFrame = CGRectMake(0, 
                                   view.bounds.size.height - tableHeight, 
                                   view.bounds.size.width, 
                                   tableHeight);
            
    // Create the EasyTableView object to give us the horizontal UITableView support.
    CGFloat columnWidth = thumbnailSize.width + (2 * THUMBNAIL_PADDING);
	EasyTableView *easyTableView = [[EasyTableView alloc] initWithFrame: tableFrame 
                                                        numberOfColumns: 0
                                                                ofWidth: columnWidth];
    self.thumbnailsView = easyTableView;
    [easyTableView release], easyTableView = nil;
    
	// Customize the horizontal table view's properties.
    self.thumbnailsView.delegate = self;    
    self.thumbnailsView.tableView.backgroundColor = [UIColor blackColor];        
    self.thumbnailsView.tableView.allowsSelection	= YES;
    self.thumbnailsView.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.thumbnailsView.cellBackgroundColor = [UIColor blackColor];
    self.thumbnailsView.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth);
	
    // Add the horizontal table view to the controller's view. 
	[view addSubview: self.thumbnailsView];    
}


#pragma mark -
#pragma mark EasyTableView Delegate Methods (Thumbnails View)

//  Return the number of cells (columns in our case) for EasyTableView.
- (NSUInteger) numberOfCellsForEasyTableView: (EasyTableView *) easyTableView {
    return self.photos.count;
}

// Create the view for the EasyTableView's cell.
- (UIView *) easyTableView: (EasyTableView *) easyTableView viewForRect: (CGRect) rect {
    CGRect thumbnailFrame = rect;
    thumbnailFrame.origin.x += THUMBNAIL_PADDING;
    thumbnailFrame.origin.y += THUMBNAIL_PADDING;
    thumbnailFrame.size.width -= (THUMBNAIL_PADDING * 2.0);
    thumbnailFrame.size.height -= (THUMBNAIL_PADDING * 2.0);    
        
    ThumbnailView *thumbnailView = [[[ThumbnailView alloc] initWithFrame: thumbnailFrame] 
                                    autorelease];    
    return thumbnailView;        
}

// Populates EasyTableView's cell at index with data from the data source.
- (void) easyTableView: (EasyTableView *) easyTableView setDataForView: (UIView *) view 
              forIndex: (NSUInteger) index {
                
    ThumbnailView *thumbnailView = (ThumbnailView *) view;
    thumbnailView.photo = [self.photos objectAtIndex: index];
                        
    // "selectedIndexPath" can be nil, so we need to test for that condition.
	BOOL isSelected = (easyTableView.selectedIndexPath) ? 
                      (easyTableView.selectedIndexPath.row == index) : NO;
    thumbnailView.selected = isSelected;         
}

// Tracks the selected thumbnail.
- (void) easyTableView: (EasyTableView *) easyTableView selectedView: (UIView *) selectedView 
               atIndex: (NSUInteger) index deselectedView: (UIView *) deselectedView {
    
    // Set selected state of currently selected thumbnail image view.
    ThumbnailView *selectedThumbnailView = (ThumbnailView *) selectedView;
    selectedThumbnailView.selected = YES;            
    
    // Deselect the previous thumbnail image view (if any).
    if (deselectedView) {
        ThumbnailView *deselectedThumbnailView = (ThumbnailView *) deselectedView;
        deselectedThumbnailView.selected = NO;                        
    }    

    // Display selected Photo model on the photo view.
    self.photoView.photo = [self.photos objectAtIndex: index];
}


#pragma mark -
#pragma mark Photos Data Source

- (void) setPhotoSource: (NSArray *) imageURLs {
    self.photos = [Photo photosFromURLStrings: imageURLs];
    
    // Start checking for network reachability.
    [[TCReachability sharedTCReachability] startReachabilityCheckWithHostName: kHostName];    
    [[NSNotificationCenter defaultCenter] 
         addObserver: self 
         selector: @selector(TCReachabilityDidBecomeReachable:) 
         name: TCReachabilityDidBecomeReachable 
         object: nil];
    
    // Reload the thumbnails table view.
    [self.thumbnailsView.tableView reloadData];
        
    // Select the first thumbnail initially.
    [self.thumbnailsView selectCellAtIndex: 0 animated: YES];    
}


#pragma mark -
#pragma mark TCReachability Notifications

- (void) TCReachabilityDidBecomeReachable: (NSNotification *) notification {    
    // Reload all visible thumbnails and photo view.
    [self reloadVisibleThumbnails];    
    [self reloadPhotoView];
}

- (void) reloadVisibleThumbnails {
    NSArray *thumbnailViews = [self.thumbnailsView visibleViews];
    for (ThumbnailView *thumbnailView in thumbnailViews) {
        // Photo model's thumbnail property getter will start download, 
        // if image is not available.
        [thumbnailView.photo thumbnail];
    }
}

- (void) reloadPhotoView {
    // Photo model's image property getter will start download, if image is not available.
    [self.photoView.photo image];
}


#pragma mark -
#pragma mark Memory Management

// Remove and release all images from cache. It can be reloaded later from disk.
- (void) releaseAllImages {
    [self.photos makeObjectsPerformSelector: @selector(releaseSafelyImageAndThumbnail)];
}

- (void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.    
    [self releaseAllImages];
}

- (void) viewDidUnload {
    [super viewDidUnload];
    self.photoView = nil;
    self.thumbnailsView = nil;
}

- (void) dealloc {
    // Remove ourselves as observer from the UIApplication notifications.
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    [_photos release], _photos = nil;
    [_photoView release], _photoView = nil;
    [_thumbnailsView release], _thumbnailsView = nil;
    
    [super dealloc];
}

@end
