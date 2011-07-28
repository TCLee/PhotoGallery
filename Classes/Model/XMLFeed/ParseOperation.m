//
//  ParseOperation.m
//  PhotoGallery
//
//  Created by Lee Tze Cheun on 7/14/11.
//  Copyright 2011 TC Lee. All rights reserved.
//

#import "ParseOperation.h"


#pragma mark Private Interface

@interface ParseOperation ()

@property (nonatomic, assign) id <ParseOperationDelegate> delegate;
@property (nonatomic, retain) NSData *xmlData;
@property (nonatomic, retain) NSMutableArray *imageURLStringList;
@property (nonatomic, retain) NSMutableString *currentImageURLString;

@end


#pragma mark -

@implementation ParseOperation

@synthesize delegate = _delegate;
@synthesize xmlData = _xmlData;
@synthesize imageURLStringList = _imageURLStringList;
@synthesize currentImageURLString = _currentImageURLString;

#pragma mark -
#pragma mark Initialize

- (id) initWithData: (NSData *) data delegate:(id <ParseOperationDelegate>) delegate {
    self = [super init];
    if (self) {
        self.xmlData = data;
        self.delegate = delegate;        
    }
    return self;
}


#pragma mark -
#pragma mark Override NSOperation Methods

/** This operation's main task is to parse the XML. */
- (void) main {
    // Create an autorelease pool for this background thread.
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // Create the array to hold all the image URLs parsed from the XML.
    self.imageURLStringList = [NSMutableArray array];
    
    // Create the XML parser to parse given XML data.
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData: self.xmlData];
    [parser setDelegate: self];
    [parser parse];
    
    // Notify the delegate that the parser has finished parsing the XML file.
    // *** MUST call delegate method from Main Thread, so that it can access the UI safely.
    [self performSelectorOnMainThread: @selector(notifyParserDidFinishParsingWithResult:) 
                           withObject: self.imageURLStringList 
                        waitUntilDone: NO];
        
    // Release the parser.
    [parser release];
    parser = nil;
    
    // Release the objects used during parsing.
    self.imageURLStringList = nil;
    self.currentImageURLString = nil;

    [pool release];
}


#pragma mark -
#pragma mark Notify Delegate from Main Thread

// Notify the delegate that the parsing has completed successfully.
- (void) notifyParserDidFinishParsingWithResult: (NSArray *) imageURLList {    
    assert([NSThread isMainThread]);
    
    [self.delegate parserDidFinishParsingWithResult: imageURLList];
}

// Notify the delegate that a parser error has occured.
- (void) notifyParserDidFailWithError: (NSError *) error {    
    assert([NSThread isMainThread]);
        
    [self.delegate parserDidFailWithError: error];
}


#pragma mark -
#pragma mark NSXMLParser Delegate Methods

// Reduce potential parsing errors by using string constants declared in a single place.
static NSString * const kElementNameImage = @"image";


- (void) parser: (NSXMLParser *) parser didStartElement: (NSString *) elementName 
   namespaceURI: (NSString *) namespaceURI qualifiedName: (NSString *) qName 
     attributes: (NSDictionary *) attributeDict {
    
    // Start tag of image element: <image>
    if ([elementName isEqualToString: kElementNameImage]) {
        // Create a new mutable string to store the image URL.
        self.currentImageURLString = [NSMutableString string];
        _isImageURLElement = YES;
    }
}

- (void) parser: (NSXMLParser *) parser foundCharacters: (NSString *) string {
    // We're only interested in the <image> element.
    if (_isImageURLElement) {
        [self.currentImageURLString appendString: string];
    }    
}

- (void) parser: (NSXMLParser *) parser didEndElement: (NSString *) elementName 
   namespaceURI: (NSString *) namespaceURI qualifiedName: (NSString *) qName {
    
    // Closing tag of image element: </image>
    if ([elementName isEqualToString: kElementNameImage]) {
        // Add the completed image URL to the list.
        [self.imageURLStringList addObject: self.currentImageURLString];
        
        // Array will retain the image URL. So, we can release ours.
        self.currentImageURLString = nil;
    }
    
    // Reset the <image> element found flag.
    _isImageURLElement = NO;
}

- (void) parser: (NSXMLParser *) parser parseErrorOccurred: (NSError *) error {
    
    // Notify delegate that a parser error has occured.
    // *** MUST call delegate method from Main Thread, so that it can access the UI safely.
    [self performSelectorOnMainThread: @selector(notifyParserDidFailWithError:) 
                           withObject: error 
                        waitUntilDone: NO];
}


#pragma mark -
#pragma mark Memory Management

- (void) dealloc {    
    self.xmlData = nil;
    self.imageURLStringList = nil;    
    self.currentImageURLString = nil;
    
    [super dealloc];
}

@end
