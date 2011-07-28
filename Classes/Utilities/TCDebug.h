/*
 *  TCDebug.h
 *  PhotoGallery
 *
 *  Created by Lee Tze Cheun on 7/25/11.
 *  Copyright 2011 TC Lee. All rights reserved.
 *
 */

/**
 * The macro below will only function when the DEBUG preprocessor macro is specified!
 * This macro code is extracted from Three20's TTDebug.h
 *
 * Usage: TC_DEBUG_PRINT(@"formatted log text %d %f", param1, param2);
 *
 * Print the given formatted text to the log.
 */
#ifdef DEBUG
    #define TC_DEBUG_PRINT(xx, ...)  NSLog(@"%s(%d): " xx, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
    #define TC_DEBUG_PRINT(xx, ...)  ((void)0)  // no-op
#endif // #ifdef DEBUG
