//
//  TCReachability.m
//  PhotoGallery
//
//  Created by Lee Tze Cheun on 7/26/11.
//  Copyright 2011 TC Lee. All rights reserved.
//

#import "TCReachability.h"
#import "Reachability.h"
#import "SynthesizeSingleton.h"

#pragma mark Constants

NSString * const TCReachabilityDidBecomeReachable = @"TCReachabilityDidBecomeReachable";
NSString * const TCReachabilityDidBecomeUnreachable = @"TCReachabilityDidBecomeUnreachable";


#pragma mark Private Interface

@interface TCReachability ()

@property (nonatomic, retain) Reachability *hostReach;

- (void) checkReachabilityStatus: (Reachability *) currentReachability;

@end


#pragma mark -

@implementation TCReachability

@synthesize hostReach = _hostReach;

#pragma mark -
#pragma mark Singleton Design Pattern

SYNTHESIZE_SINGLETON_FOR_CLASS(TCReachability);


#pragma mark -
#pragma mark Public Methods API

- (void) startReachabilityCheckWithHostName: (NSString *) hostName {
    // Observe the kNetworkReachabilityChangedNotification. When that notification is posted, the
    // method "reachabilityChanged" will be called. 
    [[NSNotificationCenter defaultCenter] 
         addObserver: self 
         selector: @selector(reachabilityChanged:) 
         name: kReachabilityChangedNotification 
         object: nil];
    
    // Check if remote server is available.
    self.hostReach = [[Reachability reachabilityWithHostName: hostName] retain];
	[self.hostReach startNotifier];    
}


#pragma mark -
#pragma mark Reachability Notification

// Called by Reachability whenever status changes.
- (void) reachabilityChanged: (NSNotification *) notification {
	Reachability* currentReachability = [notification object];
    NSParameterAssert([currentReachability isKindOfClass: [Reachability class]]);
    [self checkReachabilityStatus: currentReachability];
}

// Helper method to check status of current Reachability object.
- (void) checkReachabilityStatus: (Reachability *) currentReachability {
    NetworkStatus networkStatus = [currentReachability currentReachabilityStatus];
    
    switch (networkStatus) {
        case NotReachable: {            
            // Notify observers that connection has become unavailable.
            [[NSNotificationCenter defaultCenter] 
                 postNotificationName: TCReachabilityDidBecomeUnreachable object: self];            
            break;
        }
            
        case ReachableViaWiFi:
        case ReachableViaWWAN: {            
            // Notify observers that connection has become available.
            [[NSNotificationCenter defaultCenter] 
                 postNotificationName: TCReachabilityDidBecomeReachable object: self];
            break;
        }
    }    
}


#pragma mark -
#pragma mark Memory Management

- (void) dealloc {
    [_hostReach release], _hostReach = nil;
    [super dealloc];
}

@end
