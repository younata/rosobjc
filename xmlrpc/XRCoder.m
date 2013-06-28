//
//  XRCoder.m
//  XMLRPC
//
//  Created by znek on Tue Aug 28 2001.
//  $Id: XRCoder.m,v 1.4 2003/04/01 17:42:20 znek Exp $
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


#include "XRCoder.h"
#include <EDCommon/EDCommon.h>


@implementation XRCoder

////////////////////////////////////////////////////
//
//  INIT & DEALLOC
//
////////////////////////////////////////////////////


- (id)initWithBuffer:(NSMutableString *)aBuffer
{
    [super init];
    if(aBuffer == nil)
    {
        [self autorelease];
        [NSException raise:NSInvalidArgumentException format:@"buffer cannot be nil"];
    }
    buffer = [aBuffer retain];
    return self;
}

- (void)dealloc
{
    [buffer release];
    [super dealloc];
}


////////////////////////////////////////////////////
//
//  ENCODING
//
////////////////////////////////////////////////////


- (void)encodeString:(NSString *)aString
{
    [self methodIsAbstract:_cmd];
}

- (void)encodeData:(NSData *)aData
{
    [self methodIsAbstract:_cmd];
}

- (void)encodeDate:(NSDate *)aDate
{
    [self methodIsAbstract:_cmd];
}

- (void)encodeDictionary:(NSDictionary *)aDictionary
{
    [self methodIsAbstract:_cmd];
}

- (void)encodeArray:(NSArray *)anArray
{
    [self methodIsAbstract:_cmd];
}

- (void)encodeNumber:(NSNumber *)aNumber
{
    [self methodIsAbstract:_cmd];
}

- (void)encodeBool:(BOOL)aBoolean
{
    [self methodIsAbstract:_cmd];
}

- (void)encodeInt:(int)anInt
{
    [self methodIsAbstract:_cmd];
}

- (void)encodeDouble:(double)aDouble
{
    [self methodIsAbstract:_cmd];
}

- (void)encodeFloat:(float)aFloat
{
    [self methodIsAbstract:_cmd];
}

- (void)encodeNullValue
{
    [self methodIsAbstract:_cmd];
}

- (void)encodeException:(NSException *)exception
{
    [self methodIsAbstract:_cmd];
}

- (void)encodeObject:(id)object
{
    [self methodIsAbstract:_cmd];
}


////////////////////////////////////////////////////
//
//  DECODING
//
////////////////////////////////////////////////////


- (id)decodeObject
{
    [self methodIsAbstract:_cmd];
    return nil; // keep compiler happy
}


@end
