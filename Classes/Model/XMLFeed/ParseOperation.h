//
//  ParseOperation.h
//  PhotoGallery
//
//  Created by Lee Tze Cheun on 7/14/11.
//  Copyright 2011 TC Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ParseOperationDelegate;


/**
 * NSOperation subclass used to perform the XML parsing of the image URLs.
 * Parsing of the XML is performed on another thread to avoid blocking the UI.
 */
@interface ParseOperation : NSOperation <NSXMLParserDelegate> {

@private
    // Delegate object to be notified of parser's status.
    id <ParseOperationDelegate> _delegate;
    
    // XML data to parse.
    NSData *_xmlData;
    
    // List of image URL strings.
    NSMutableArray *_imageURLStringList;
    
    // Currently parsed image URL string entry.
    NSMutableString *_currentImageURLString;
    
    // We're only interested in the <image> element's content.
    BOOL _isImageURLElement;    
}

/** 
 * Initialize parse operation with the XML data and delegate object to be notified of 
 * parsing status. 
 */
- (id) initWithData: (NSData *) data delegate: (id <ParseOperationDelegate>) delegate;

@end


/**
 * Protocol for parser to communicate with its delegate.
 */
@protocol ParseOperationDelegate

/** Called when parser has finished parsing the XML. */
- (void) parserDidFinishParsingWithResult: (NSArray *) result;

/** Called when parser has encountered an error. */
- (void) parserDidFailWithError: (NSError *) error;

@end
