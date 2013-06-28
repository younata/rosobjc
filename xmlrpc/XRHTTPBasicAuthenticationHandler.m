//
//  XRHTTPBasicAuthenticationHandler.m
//  XMLRPC
//
//  Created by znek on Mon Jul 08 2002.
//  $Id: XRHTTPBasicAuthenticationHandler.m,v 1.3 2003/03/28 13:12:02 znek Exp $
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


#include "XRHTTPBasicAuthenticationHandler.h"
#include <EDMessage/EDMessage.h>
#include "XRDefines.h"
#include "XRHTTPAuthenticationCredentials.h"

#ifdef sun
#import <iso/limits_iso.h> // UINT_MAX (Solaris 2.8)
// #import <sys/types.h> // UINT_MAX (Solaris < 2.8)
#endif


@implementation XRHTTPBasicAuthenticationHandler

////////////////////////////////////////////////////
//
//  FACTORY
//
////////////////////////////////////////////////////


+ (id)authHandlerWithUser:(NSString *)user password:(NSString *)password
{
    return [[[self alloc] initWithUser:user password:password] autorelease];
}


////////////////////////////////////////////////////
//
//  INIT & DEALLOC
//
////////////////////////////////////////////////////


- (id)initWithUser:(NSString *)user password:(NSString *)password
{
    NSString *authenticationPlainText;
    NSData *authenticationData;

    [super init];

    authenticationPlainText = [NSString stringWithFormat:@"%@:%@", user, (password != nil) ? password : @""];
    // HTTP headers are ISO-8859-1 by default, see RFC2616, p. 16.
    authenticationData = [authenticationPlainText dataUsingEncoding:NSISOLatin1StringEncoding];
    authenticationBlurb = [[NSString stringWithData:[authenticationData encodeBase64WithLineLength:UINT_MAX - 3 andNewlineAtEnd:NO] encoding:NSASCIIStringEncoding] retain];
    return self;
}

- (void)dealloc
{
    [authenticationBlurb release];
    [super dealloc];
}


////////////////////////////////////////////////////
//
//  XRHTTPAuthenticationHandler
//  Protocol
//
////////////////////////////////////////////////////


- (NSString *)scheme
{
    return @"basic";
}

- (BOOL)canAuthenticateCredentials:(XRHTTPAuthenticationCredentials *)credentials
{
    if([[credentials scheme] isEqualToString:[self scheme]] == NO)
    {
        EDLog2(XRLogDebug, @"Couldn't authenticate request, because scheme \"%@\" does not match expected scheme \"%@\"", [credentials scheme], [self scheme]);
        return NO;
    }
    if([[credentials rawResponse] isEqualToString:authenticationBlurb] == NO)
    {
        EDLog(XRLogDebug, @"Couldn't authenticate request, because user/password combo incorrect.");
        return NO;
    }
    return YES;
}

- (NSString *)challengeForAuthenticationRealm:(NSString *)realm
{
    return [NSString stringWithFormat:@"Basic realm=\"%@\"", realm];
}

- (NSString *)credentials
{
    return [NSString stringWithFormat:@"Basic %@", authenticationBlurb];
}


////////////////////////////////////////////////////
//
//  DEBUGGING
//
////////////////////////////////////////////////////


- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ 0x%x: %@ %@>", NSStringFromClass(isa), self, [self scheme], authenticationBlurb != nil ? authenticationBlurb : @""];
}

@end
