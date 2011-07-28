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
#import "ASIDownloadCache.h"


#pragma mark Constants

static NSString * const kImagesXML = @"http://sapphire2.adrenalin.my/application_images/image_locations.xml";


#pragma mark -
#pragma mark Private Interface

@interface XMLFeed ()

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

- (NSOperationQueue *) parseQueue {
    if (nil == _parseQueue) {
        _parseQueue = [[NSOperationQueue alloc] init];
    }
    return _parseQueue;
}


#pragma mark -
#pragma mark Fetch and Parse XML Feed

- (void) fetch {
    NSURL *url = [[NSURL alloc] initWithString: kImagesXML];
    ASIHTTPRequest *request = [[ASIHTTPRequest alloc] initWithURL: url];
    
    // Cache this request so that we don't have to redownload the XML data
    // again, if it's not modified.
    [request setDownloadCache: [ASIDownloadCache sharedCache]];
    [request setCacheStoragePolicy: ASICachePermanentlyCacheStoragePolicy];
    
    [request setDelegate: self];
    [request startAsynchronous];
    
    [url release], url = nil;
    [request release], request = nil;
}


#pragma mark -
#pragma mark ASIHTTPRequest Delegate

- (void) requestStarted: (ASIHTTPRequest *) request {
    [self.delegate xmlFeedDidStartDownload: self];    
}

- (void) requestFinished: (ASIHTTPRequest *) request {
    ParseOperation *parseOperation = [[ParseOperation alloc] 
                                      initWithData: [request responseData] 
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
    [self.delegate xmlFeed: self didFinishWithResult: result];
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
