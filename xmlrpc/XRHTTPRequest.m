//
//  XRHTTPRequest.m
//  XMLRPC
//
//  Created by znek on Wed Aug 15 2001.
//  $Id: XRHTTPRequest.m,v 1.4 2003/03/28 13:12:02 znek Exp $
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


#include "XRHTTPRequest.h"
#include <EDCommon/EDCommon.h>
#include "XRDefines.h"


//---------------------------------------------------------------------------------------
//	Constants
//---------------------------------------------------------------------------------------

#define LF ((char)'\x0A')
#define CR ((char)'\x0D')

//---------------------------------------------------------------------------------------
//	Macros
//---------------------------------------------------------------------------------------

static __inline__ BOOL iscrlf(char c)
{
    return (c == CR) || (c == LF);
}


@implementation XRHTTPRequest

////////////////////////////////////////////////////
//
//   FACTORY
//
////////////////////////////////////////////////////


+ (id)requestWithMethod:(NSString *)aMethod uri:(NSString *)aURI httpVersion:(NSString *)anHTTPVersion headers:(NSDictionary *)someHeaders content:(NSData *)aContent;
{
    return [[[self alloc] initWithMethod:aMethod uri:aURI httpVersion:anHTTPVersion headers:someHeaders content:aContent] autorelease];
}

+ (id)requestWithTransferData:(NSData *)data
{
    return [[[self alloc] initWithTransferData:data] autorelease];
}


////////////////////////////////////////////////////
//
//  INIT & DEALLOC
//
////////////////////////////////////////////////////


// delivered by build system
XMLRPC_EXTERN double XMLRPCVersionNumber;

- (id)init
{
    static NSString *userAgentName = nil;

    [super init];

    if(userAgentName == nil)
        userAgentName = [[NSString alloc] initWithFormat:@"Mulle XMLRPC/%g [%@] (http://www.mulle-kybernetik.com/software/XMLRPC)", XMLRPCVersionNumber,  [[NSProcessInfo processInfo] operatingSystemName]];

    [self setHeader:userAgentName forKey:@"User-Agent"];
    return self;
}

- (id)initWithMethod:(NSString *)aMethod uri:(NSString *)aURI httpVersion:(NSString *)anHTTPVersion headers:(NSDictionary *)someHeaders content:(NSData *)aContent
{
    NSEnumerator *hEnum;
    NSString *headerKey;

    [self init];

    NSAssert(aMethod != nil, @"method must not be nil");
    NSAssert(aURI != nil, @"uri must not be nil");

    method = [aMethod retain];
    uri = [aURI retain];
    
    if(anHTTPVersion != nil)
        [self setHTTPVersion:anHTTPVersion];
    
    if(aContent != nil)
        [self setContent:aContent];

    if(someHeaders != nil)
    {
        // headers
        hEnum = [someHeaders keyEnumerator];
        while((headerKey = [hEnum nextObject]) != nil)
        {
            id value;
            
            value = [someHeaders objectForKey:headerKey];
            if([value isKindOfClass:[NSArray class]])
                [self setHeaders:value forKey:headerKey];
            else
                [self setHeader:value forKey:headerKey];
        }
    }
    return self;
}

- (id)initWithTransferData:(NSData *)data
{
    const char *pstart, *p, *pmax;
    int plen;
    NSString *requestLine;
    NSArray *requestLineComponents;
    NSData *message;
    
    // scan into data until first \r\n found.
    pstart = [data bytes];
    p = pstart;
    pmax = p + [data length];
    
    while((p < pmax) && (iscrlf(*p) == NO))
        p += 1;
    if(p == pmax)
        [NSException raise:NSGenericException format:@"Data is not an HTTP request!"];
    
    p += 2; // skip \r\n
    plen = p - pstart;
    
    requestLine = [NSString stringWithData:[data subdataWithRange:NSMakeRange(0, plen - 2)] encoding:NSASCIIStringEncoding];
    requestLineComponents = [requestLine componentsSeparatedByString:@" "];
    
    message = [data subdataWithRange:NSMakeRange(plen, [data length] - plen)];
    // call super's implementation which fully understands headers and contentData
    [super initWithTransferData:message];

    // now set the properties which we found out before
    method = [[requestLineComponents objectAtIndex:0] retain];
    uri = [[requestLineComponents objectAtIndex:1] retain];
    [self setHTTPVersion:[requestLineComponents objectAtIndex:2]];
    
    return self;
}

- (void)dealloc
{
    [method release];
    [uri release];
    [super dealloc];
}


////////////////////////////////////////////////////
//
//  ACCESSORS
//
////////////////////////////////////////////////////


- (NSString *)method
{
	return method;
}

- (NSString *)uri
{
	return uri;
}

@end
