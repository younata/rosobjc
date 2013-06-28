//
//  XRNull.m
//  XMLRPC
//
//  Created by znek on Mon 24-Sep-2001.
//  $Id: XRNull.m,v 1.1 2001/10/01 03:12:17 znek Exp $
//
//  Copyright (c) 2001 by Marcus MŸller <znek@mulle-kybernetik.com>.
//  All rights reserved.
//
//  Permission to use, copy, modify and distribute this software and its documentation
//  is hereby granted under the terms of the GNU Lesser General Public License, version 2.1
//  as published by the Free Software Foundation, provided that both the copyright notice
//  and this permission notice appear in all copies of the software, derivative works or
//  modified versions, and any portions thereof, and that both notices appear in supporting
//  documentation, and that credit is given to Marcus MŸller in all documents and publicity
//  pertaining to direct or indirect use of this code or its derivatives.
//
//  This is free software; you can redistribute and/or modify it under
//  the terms of the GNU Lesser General Public License, version 2.1 as published by the Free
//  Software Foundation. Further information can be found on the project's web pages
//  at http://www.mulle-kybernetik.com/software/XMLRPC
//
//  THIS IS EXPERIMENTAL SOFTWARE AND IT IS KNOWN TO HAVE BUGS, SOME OF WHICH MAY HAVE
//  SERIOUS CONSEQUENCES. THE COPYRIGHT HOLDER ALLOWS FREE USE OF THIS SOFTWARE IN ITS
//  "AS IS" CONDITION. THE COPYRIGHT HOLDER DISCLAIMS ANY LIABILITY OF ANY KIND FOR ANY
//  DAMAGES WHATSOEVER RESULTING DIRECTLY OR INDIRECTLY FROM THE USE OF THIS SOFTWARE
//  OR OF ANY DERIVATIVE WORK.
//---------------------------------------------------------------------------------------


#import "XRNull.h"


@implementation XRNull

////////////////////////////////////////////////////
//
//  FACTORY
//
////////////////////////////////////////////////////


+ (XRNull *)null;
{
    static id sharedInstance = nil;

    if(sharedInstance == nil)
        sharedInstance = [[[self class] alloc] init];
    return sharedInstance;
}


////////////////////////////////////////////////////
//
//  RETAIN/RELEASE
//
////////////////////////////////////////////////////


- (id)retain
{
    return self;
}

- (oneway void)release
{
    // nothing to do
}

- (id)autorelease
{
    return self;
}

- (void)dealloc
{
    [NSException raise:NSInternalInconsistencyException format:@"%@ may not be called!", NSStringFromSelector(_cmd)];
}


////////////////////////////////////////////////////
//
//  COMMON PROTOCOLS
//
////////////////////////////////////////////////////


- (id)copy;
{
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    // nothing to do
}

@end
