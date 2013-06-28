//
//  XRHTTPResponse.m
//  XMLRPC
//
//  Created by znek on Tue Aug 14 2001.
//  $Id: XRHTTPResponse.m,v 1.7 2003/03/28 13:12:02 znek Exp $
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


#include "XRHTTPResponse.h"
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


@implementation XRHTTPResponse

////////////////////////////////////////////////////
//
//   FACTORY
//
////////////////////////////////////////////////////


// sending
+ (id)responseWithContent:(NSData *)data
{
    return [[[self alloc] initWithContent:data] autorelease];
}

// receiving
+ (id)responseWithTransferData:(NSData *)data
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
    static NSDictionary *_locale = nil;
    static NSString *serverName = nil;

    NSCalendarDate *now;

    [super init];

    if(serverName == nil)
        serverName = [[NSString alloc] initWithFormat:@"Mulle XMLRPC/%g [%@] (http://www.mulle-kybernetik.com/software/XMLRPC)", XMLRPCVersionNumber,  [[NSProcessInfo processInfo] operatingSystemName]];
    
    if(_locale == nil)
        _locale = [[@"{NSShortMonthNameArray = (Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec);NSShortWeekDayNameArray = (Sun, Mon, Tue, Wed, Thu, Fri, Sat);}" propertyList] retain];

    status = 200; // OK
    [self setReasonPhrase:@"OK"];

    now = NOW;
    [now setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    [self setHeader:[now descriptionWithCalendarFormat:@"%a, %d %b %Y %H:%M:%S %Z" locale:_locale] forKey:@"Date"];
    [self setHeader:serverName forKey:@"Server"];

    return self;
}

- (id)initWithContent:(NSData *)data
{
    [self init];
    [self setContent:data];
    return self;
}

- (id)initWithTransferData:(NSData *)data
{
    const char *pstart, *p, *pmax;
    int plen;
    NSString *responseLine;
    NSArray *responseLineComponents;
    NSData *message;

    // i.e. HTTP/1.1 200 OK

    // scan into data until first \r\n found.
    pstart = [data bytes];
    p = pstart;
    pmax = p + [data length];
    
    while((p < pmax) && (iscrlf(*p) == NO))
        p += 1;
    if(p == pmax)
        [NSException raise:NSGenericException format:@"Data is not an HTTP response! :: %@", [NSString stringWithData:data encoding:NSASCIIStringEncoding]];
    
    p += 2; // skip \r\n
    plen = p - pstart;
    
    responseLine = [NSString stringWithData:[data subdataWithRange:NSMakeRange(0, plen - 2)] encoding:NSASCIIStringEncoding];
    responseLineComponents = [responseLine componentsSeparatedByString:@" "];
    
    message = [data subdataWithRange:NSMakeRange(plen, [data length] - plen)];
    // call super's implementation which fully understands headers and contentData
    [super initWithTransferData:message];

    [self setHTTPVersion:[responseLineComponents objectAtIndex:0]];
    status = [[responseLineComponents objectAtIndex:1] intValue];
    if([responseLineComponents count] > 2)
        [self setReasonPhrase:[[responseLineComponents subarrayFromIndex:2] componentsJoinedByString:@" "]];

    return self;
}


////////////////////////////////////////////////////
//
//  ACCESSORS
//
////////////////////////////////////////////////////


- (void)setStatus:(unsigned int)anInt
{
    status = anInt;
}

- (unsigned int)status
{
	return status;
}


- (void)setReasonPhrase:(NSString *)value
{
    [value retain];
    [reasonPhrase release];
    reasonPhrase = value;
}


- (NSString *)reasonPhrase
{
    return reasonPhrase;
}


// this doesn't really belong here, as the "transferData"
// - the understanding of it - is directly associated with
// the underlying transport scheme.
// Implementing it here means limiting it to our view.
// But then again, we're really not trying to be as generalistic
// as possible, so to me it's perfectly acceptable.

- (NSData *)transferData
{
    NSMutableString *response;
    NSEnumerator *hEnum;
    NSString *key;
    response = [NSMutableString string];
    
    [response appendString:[self httpVersion]];
    [response appendFormat:@" %d %@\r\n", [self status], [self reasonPhrase]];
    
    hEnum = [headersLUT keyEnumerator];
    while((key = [hEnum nextObject]) != nil)
    {
        NSEnumerator *vEnum = [[self headersForKey:key] objectEnumerator];
        NSString *value;
        
        while((value = [vEnum nextObject]) != nil)
        {
            [response appendString:key];
            [response appendString:@": "];
            [response appendString:value];
            [response appendString:@"\r\n"];
        }
    }
    [response appendString:@"\r\n"];
    [response appendString:[NSString stringWithData:[self content] encoding:[self contentEncoding]]];
    return [response dataUsingEncoding:[self contentEncoding]];
}


@end
