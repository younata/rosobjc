//
//  XRHTTPMessage.m
//  XMLRPC
//
//  Created by znek on Tue Aug 14 2001.
//  $Id: XRHTTPMessage.m,v 1.8 2003/03/28 13:12:02 znek Exp $
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


#include "XRHTTPMessage.h"
#include <EDMessage/EDMessage.h>


@implementation XRHTTPMessage

////////////////////////////////////////////////////
//
//  INIT & DEALLOC
//
////////////////////////////////////////////////////


- (id)init
{
    [super init];

    headersLUT = [[NSMutableDictionary allocWithZone:[self zone]] init];
    [self setHTTPVersion:@"HTTP/1.0"];
    [self setContentEncoding:NSUTF8StringEncoding];
    [self setHeader:@"text/xml" forKey:@"Content-Type"];

	return self;
}

- (id)initWithTransferData:(NSData *)data
{
    EDMessagePart *messagePart;
    NSEnumerator *hEnum;
    NSString *headerField;
    NSStringEncoding encoding;

    [super init];

    headersLUT = [[NSMutableDictionary allocWithZone:[self zone]] init];
    messagePart = [[EDMessagePart allocWithZone:[self zone]] initWithTransferData:data fallbackStringEncoding:NSUTF8StringEncoding];
    
    hEnum = [[messagePart headerFields] objectEnumerator];
    while((headerField = [[hEnum nextObject] firstObject]) != nil)
    {
        NSMutableArray *headers;
        id header;

        header = [[messagePart decoderForHeaderField:headerField] fieldBody];
        headers = [headersLUT objectForStringKeyCaseInsensitive:headerField];
        if(headers == nil)
            headers = [[[NSMutableArray allocWithZone:[headersLUT zone]] initWithCapacity:1] autorelease];
        [headers addObject:header];
        [headersLUT setObject:headers forKey:headerField];
    }
    
    [self setContent:[messagePart contentData]];
    
    // The charset used for the content is attached to the content-type as a parameter. This looks like e.g.
    // content-type: text/xml; charset=iso-8859-1

    encoding = NSUTF8StringEncoding; // fallback

    if([[[messagePart contentType] firstObject] isEqualToString:@"text"])
    {
        NSString *charset = [[messagePart contentTypeParameters] objectForKey:@"charset"];
        if((charset != nil) && ([NSString stringEncodingForMIMEEncoding:charset] != 0))
            encoding = [NSString stringEncodingForMIMEEncoding:charset];
    }

    [self setContentEncoding:encoding];
    
    return self;
}

- (void)dealloc
{
    [headersLUT release];
    [content release];
    [super dealloc];
}


////////////////////////////////////////////////////
//
//  ACCESSORS
//
////////////////////////////////////////////////////


- (NSArray *)headerKeys
{
    return [[headersLUT keyEnumerator] allObjects];
}

- (void)setHeader:(NSString *)aHeader forKey:(NSString *)aKey
{
    [headersLUT setObject:[NSMutableArray arrayWithObject:aHeader] forKey:aKey];
}

- (void)setHeaders:(NSArray *)headers forKey:(NSString *)aKey
{
    [headersLUT setObject:[NSMutableArray arrayWithArray:headers] forKey:aKey];
}

- (NSArray *)headersForKey:(NSString *)aKey
{
    return [headersLUT objectForStringKeyCaseInsensitive:aKey];
}

- (NSString *)headerForKey:(NSString *)aKey
{
    return [[self headersForKey:aKey] firstObject];
}


- (void)setHTTPVersion:(NSString *)aVersion
{
    [aVersion retain];
    [httpVersion release];
    httpVersion = aVersion;
}

- (NSString *)httpVersion
{
    return httpVersion;
}

- (void)setContent:(NSData *)data
{
    [data retain];
    [content release];
    content = data;
    if([data length] > 0)
        [self setHeader:[NSString stringWithFormat:@"%d", [data length]] forKey:@"Content-Length"];
    else
        [headersLUT removeObjectForKey:@"Content-Length"];
}

- (NSData *)content
{
    return content;
}

- (void)setContentEncoding:(NSStringEncoding)anEncoding
{
    contentEncoding = anEncoding;
}

- (NSStringEncoding)contentEncoding
{
    return contentEncoding;
}

@end
