//
//  XRHTTPConnection.m
//  XMLRPC
//
//  Created by znek on Wed Aug 15 2001.
//  $Id: XRHTTPConnection.m,v 1.12 2003/05/07 11:04:34 znek Exp $
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


#include "XRHTTPConnection.h"
#include <EDCommon/EDCommon.h>
#include "XRHTTPRequest.h"
#include "XRHTTPResponse.h"


@interface XRHTTPConnection (PrivateAPI)
- (BOOL)_connect;
- (void)_disconnect;
@end


@implementation XRHTTPConnection

////////////////////////////////////////////////////
//
//  FACTORY
//
////////////////////////////////////////////////////


+ (id)connectionWithHost:(NSString*)aHost port:(unsigned int)aPortNumber
{
    return [[[self alloc] initWithHost:aHost onPort:aPortNumber] autorelease];
}


////////////////////////////////////////////////////
//
//  INIT & DEALLOC
//
////////////////////////////////////////////////////


- (id)initWithHost:(NSString *)aHost onPort:(unsigned int)aPortNumber
{
    [self init];
    hostName = [aHost retain];
    port = aPortNumber;
    sendTimeout = 10.0;
    receiveTimeout = 10.0;
    return self;
}

- (void)dealloc
{
    if([self isConnected])
        [self _disconnect]; // will release socket
    [hostName release];
    [super dealloc];
}


////////////////////////////////////////////////////
//
//  CONNECTING
//
////////////////////////////////////////////////////


- (BOOL)_connect
{
    if([self isConnected])
        [self _disconnect];

    socket = [[EDTCPSocket allocWithZone:[self zone]] init];
    [socket setSendTimeout:[self sendTimeout]];
    [socket setReceiveTimeout:[self receiveTimeout]];
    [socket connectToHost:[NSHost hostWithNameOrAddress:hostName] port:port];
    return [self isConnected];
}

- (void)_disconnect
{
    NSAssert([self isConnected] == YES, @"already disconnected");

    [socket closeFile];
    [socket release];
    socket = nil;
}

- (BOOL)sendRequest:(XRHTTPRequest *)request
{
    NSMutableString *requestString;
    NSEnumerator *hEnum;
    NSString *headerKey;

    if([self isConnected] == NO)
        if([self _connect] == NO)
            return NO;

    requestString = [NSMutableString string];

    // i.e. POST /RPC2 HTTP/1.0
    [requestString appendString:[request method]];
    [requestString appendString:@" "];
    [requestString appendString:[request uri]];
    [requestString appendString:@" "];
    [requestString appendString:[request httpVersion]];
    [requestString appendString:@"\r\n"];

    // strictly speaking, only HTTP/1.1 requires it
    [request setHeader:port == 80 ? hostName : [NSString stringWithFormat:@"%@:%d", hostName, port] forKey:@"host"];

    hEnum = [[request headerKeys] objectEnumerator];
    while((headerKey = [hEnum nextObject]) != nil)
    {
        NSEnumerator *fEnum;
        NSString *fieldValue;
        
        fEnum = [[request headersForKey:headerKey] objectEnumerator];
        while((fieldValue = [fEnum nextObject]) != nil)
        {
            [requestString appendString:headerKey];
            [requestString appendString:@": "];
            [requestString appendString:fieldValue];
            [requestString appendString:@"\r\n"];
        }
    }

    [requestString appendString:@"\r\n"];
    // flush the first part
    // don't know if it's wiser to set the contentEncoding as header encoding or assume UTF8 or whatever?
    [socket writeData:[requestString dataUsingEncoding:[request contentEncoding]]];
    
    // now send the real content
    if([request content] != nil)
        [socket writeData:[request content]];

    return [self isConnected];
}

- (XRHTTPResponse *)readResponse
{
    NSData *responseData;

    responseData = [socket readDataToEndOfFile];
    if([self keepAliveEnabled] == NO)
        [self _disconnect];
    return [XRHTTPResponse responseWithTransferData:responseData];
}


////////////////////////////////////////////////////
//
//  CONNECTION
//  PROPERTIES
//
////////////////////////////////////////////////////


- (BOOL)isConnected
{
    if(socket == nil)
        return NO;
    return [socket isConnected];
}

- (void)setKeepAliveEnabled:(BOOL)yn
{
	flags.shouldKeepAlive = yn;
}

- (BOOL)keepAliveEnabled
{
	return flags.shouldKeepAlive;
}

- (void)setSendTimeout:(NSTimeInterval)timeout
{
    sendTimeout = timeout;
    if([self isConnected])
        [socket setSendTimeout:sendTimeout];
}

- (NSTimeInterval)sendTimeout
{
    return sendTimeout;
}

- (void)setReceiveTimeout:(NSTimeInterval)timeout
{
    receiveTimeout = timeout;
    if([self isConnected])
        [socket setReceiveTimeout:receiveTimeout];
}

- (NSTimeInterval)receiveTimeout
{
    return receiveTimeout;
}


@end
