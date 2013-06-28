//
//  Objects+XRCoding.m
//  XMLRPC
//
//  Created by znek on Tue Aug 28 2001.
//  $Id: Objects+XRCoding.m,v 1.5 2003/04/04 02:01:54 znek Exp $
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


#include <XMLRPC/XMLRPC.h>

#ifdef XMLRPC_OSXSBUILD
#include "Future.h"
#endif


@interface NSString (XRCoding) <XRCoding>
@end

@implementation NSString (XRCoding)

- (void)encodeWithXMLRPCCoder:(XRCoder *)aCoder
{
    [aCoder encodeString:self];
}

- (id)initWithXMLRPCCoder:(XRCoder *)aDecoder
{
    [self autorelease];
    return [aDecoder decodeObject];
}

@end


@interface NSData (XRCoding) <XRCoding>
@end

@implementation NSData (XRCoding)

- (void)encodeWithXMLRPCCoder:(XRCoder *)aCoder
{
    [aCoder encodeData:self];
}

- (id)initWithXMLRPCCoder:(XRCoder *)aDecoder
{
    [self autorelease];
    return [aDecoder decodeObject];
}

@end


@interface NSDate (XRCoding) <XRCoding>
@end

@implementation NSDate (XRCoding)

- (void)encodeWithXMLRPCCoder:(XRCoder *)aCoder
{
    [aCoder encodeDate:self];
}

- (id)initWithXMLRPCCoder:(XRCoder *)aDecoder
{
    [self autorelease];
    return [aDecoder decodeObject];
}

@end


@interface NSNumber (XRCoding) <XRCoding>
@end

@implementation NSNumber (XRCoding)

- (void)encodeWithXMLRPCCoder:(XRCoder *)aCoder
{
    [aCoder encodeNumber:self];
}

- (id)initWithXMLRPCCoder:(XRCoder *)aDecoder
{
    [self autorelease];
    return [aDecoder decodeObject];
}

@end


@interface NSDictionary (XRCoding) <XRCoding>
@end

@implementation NSDictionary (XRCoding)

- (void)encodeWithXMLRPCCoder:(XRCoder *)aCoder
{
    [aCoder encodeDictionary:self];
}

- (id)initWithXMLRPCCoder:(XRCoder *)aDecoder
{
    [self autorelease];
    return [aDecoder decodeObject];
}

@end


@interface NSArray (XRCoding) <XRCoding>
@end

@implementation NSArray (XRCoding)

- (void)encodeWithXMLRPCCoder:(XRCoder *)aCoder
{
    [aCoder encodeArray:self];
}

- (id)initWithXMLRPCCoder:(XRCoder *)aDecoder
{
    [self autorelease];
    return [aDecoder decodeObject];
}

@end


@interface NSNull (XRCoding) <XRCoding>
@end

@implementation NSNull (XRCoding)

- (void)encodeWithXMLRPCCoder:(XRCoder *)aCoder
{
    [aCoder encodeNullValue];
}

- (id)initWithXMLRPCCoder:(XRCoder *)aDecoder
{
    [self autorelease];
    return [aDecoder decodeObject];
}

@end


@interface NSException (XRCoding) <XRCoding>
@end

@implementation NSException (XRCoding)

- (void)encodeWithXMLRPCCoder:(XRCoder *)aCoder
{
    [aCoder encodeException:self];
}

- (id)initWithXMLRPCCoder:(XRCoder *)aDecoder
{
    [self autorelease];
    return [aDecoder decodeObject];
}

@end
