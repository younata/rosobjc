//
//  TestServer.m
//  XMLRPC
//
//  Created by znek on Tue Aug 14 2001.
//  $Id: TestServer.m,v 1.7 2003/03/28 13:12:08 znek Exp $
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


#include "TestServer.h"
#include <EDCommon/EDCommon.h>
#include <XMLRPC/XMLRPC.h>


@implementation TestServer

////////////////////////////////////////////////////
//
//	XRServing Protocol
//
////////////////////////////////////////////////////


- (NSArray *)invocationsForXMLRPC
{
    NSMutableArray *invocations;
    
    invocations = [NSMutableArray array];
    
    [invocations addObject:[XRConnection invocationForXMLRPCMethod:@"doStuff" withXMLRPCTypes:@"sa" mappedToSelector:@selector(doStuff:) atObject:self]];
    [invocations addObject:[XRConnection invocationForXMLRPCMethod:@"testIfTrue" withXMLRPCTypes:@"bb" mappedToSelector:@selector(testIfTrue:) atObject:self]];
    
    return invocations;
}


////////////////////////////////////////////////////
//
//	XRListing Protocol
//
////////////////////////////////////////////////////


- (NSArray *)listPublicXMLRPCMethods
{
    return [NSArray arrayWithObjects:@"doStuff", @"testIfTrue", nil];
}

- (NSString *)descriptionForXMLRPCMethod:(NSString *)selector;
{
    if([selector isEqualToString:@"doStuff"])
        return @"Silly test method.";
    else if([selector isEqualToString:@"testIfTrue"])
        return @"Tests if the given argument is a boolean with value true. Returns either true or false.";
    return nil;
}


////////////////////////////////////////////////////
//
//	ACCESSORS
//
////////////////////////////////////////////////////


- (id)doStuff:(NSArray *)args
{
    EDLog1(XRLogDebug, @"TestServer.doStuff: received args = %@", args);
//    return [NSNumber numberWithInt:23];
    return self;
}

#if 0
- (NSNumber *)testIfTrue:(NSNumber *)candidate
{
    EDLog1(XRLogDebug, @"TestServer.testIfTrue: received candidate = %@", candidate);
    
    if([candidate isKindOfClass:[NSNumber class]])
        return [NSNumber numberWithBool:[candidate boolValue] == YES];
    return [NSNumber numberWithBool:NO];
}
#else
- (BOOL)testIfTrue:(BOOL)candidate
{
    EDLog1(XRLogDebug, @"TestServer.testIfTrue: received candidate = %d", candidate);
    return candidate != NO;
}
#endif

@end
