//
//  TCReachability.h
//  PhotoGallery
//
//  Created by Lee Tze Cheun on 7/26/11.
//  Copyright 2011 TC Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Reachability;


#pragma mark Constants

/** Posted when Reachability status returns ReachableViaWiFi or ReachableViaWWAN. */
extern NSString * const TCReachabilityDidBecomeReachable;

/** Posted when Reachability staus returns NotReachable. */
extern NSString * const TCReachabilityDidBecomeUnreachable;


#pragma mark -

/**
 * TCReachability is a facade around the Reachability class to provide
 * a simpler API for checking network reachability.
 *
 * Based on Apple's Reachability sample code.
 */
@interface TCReachability : NSObject {

@private
    Reachability *_hostReach;
}

/** Gets the shared singleton instance. */
+ (id) sharedTCReachability;

/** Starts reachability check with given host name. Observers will be notified 
    when reachability status has changed. */
- (void) startReachabilityCheckWithHostName: (NSString *) hostName;

@end
