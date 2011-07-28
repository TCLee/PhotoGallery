//
//  XMLFeed.m
//  PhotoGallery
//
//  Created by Lee Tze Cheun on 7/15/11.
//  Copyright 2011 TC Lee. All rights reserved.
//

#import "XMLFeed.h"
#import "TCFileHelper.h"
#import "ASIHTTPRequest.h"


#pragma mark Constants

static NSString * const kImagesXML = @"http://sapphire2.adrenalin.my/application_images/image_locations.xml";
static NSString * const kImageURLsPlistFilename = @"image_urls.plist";


#pragma mark -
#pragma mark Private Interface

@interface XMLFeed ()

@property (nonatomic, readonly) NSString *imageURLsPlistFilePath;
@property (nonatomic, readonly) NSOperationQueue *parseQueue;

@end



#pragma mark -

@implementation XMLFeed

@synthesize delegate = _delegate;


#pragma mark -
#pragma mark Initialize

- (id) initWithDelegate: (id <XMLFeedDelegate>) delegate {
    self = [super init];
    if (self) {
        self.delegate = delegate;
    }
    return self;
}


#pragma mark -
#pragma mark Properties Accessors

- (NSString *) imageURLsPlistFilePath {
    if (nil == _imageURLsPlistFilePath) {        
        _imageURLsPlistFilePath = [[[TCFileHelper sharedHelper].documentsDirectory 
                                    stringByAppendingPathComponent: kImageURLsPlistFilename] 
                                   copy];
    }
    return _imageURLsPlistFilePath;
}

- (NSOperationQueue *) parseQueue {
    if (nil == _parseQueue) {
        _parseQueue = [[NSOperationQueue alloc] init];
    }
    return _parseQueue;
}


#pragma mark -
#pragma mark Fetch and Parse XML Feed

- (void) fetch {
    // Check if parsed results already exists.
    NSArray *result = [[NSArray alloc] initWithContentsOfFile: self.imageURLsPlistFilePath];
    
    if (result) {
        // If parsed result already exists, then just load it from file.
        [self.delegate xmlFeedDidFinishWithResult: result];
    } else {
        // Else, download and parse XML.              
        ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL: 
                                   [NSURL URLWithString: kImagesXML]];        
        [request setDelegate: self];
        [request startAsynchronous];        
        
        // Notify delegate that we have started download of XML feed.
        [self.delegate xmlFeedDidStartDownload: self];
    }
    
    [result release], result = nil;
}


#pragma mark -
#pragma mark ASIHTTPRequest Delegate

- (void) requestFinished: (ASIHTTPRequest *) request {
    // Create the parse operation and add it to the queue to start it asynchronously.
    ParseOperation *parseOperation = [[ParseOperation alloc] initWithData: [request responseData] 
                                                                 delegate: self];
    [self.parseQueue addOperation: parseOperation];
    [parseOperation release], parseOperation = nil;
}

- (void) requestFailed: (ASIHTTPRequest *) request {
    [self.delegate xmlFeed: self didFailWithError: [request error]];
}


#pragma mark -
#pragma mark ParseOperation Delegate

- (void) parserDidFinishParsingWithResult: (NSArray *) result {
    // Save parsed results to disk, so we can just load it from disk next time.    
    [result writeToFile: self.imageURLsPlistFilePath atomically: YES];
    
    [self.delegate xmlFeedDidFinishWithResult: result];
}

- (void) parserDidFailWithError: (NSError *) error {
    [self.delegate xmlFeed: self didFailWithError: error];
}


#pragma mark -
#pragma mark Memory Management

- (void) dealloc {
    _delegate = nil;
    [_parseQueue release], _parseQueue = nil;
    
    [super dealloc];
}

@end
