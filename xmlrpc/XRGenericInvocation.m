//
//  XRGenericInvocation.m
//  UNIXServer
//
//  Created by znek on Thu Apr 11 2002.
//  $Id: XRGenericInvocation.m,v 1.4 2003/03/28 13:12:01 znek Exp $
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
//  at http://www.mulle-kybernetik.com/software/UNIXServer
//
//  THIS IS EXPERIMENTAL SOFTWARE AND IT IS KNOWN TO HAVE BUGS, SOME OF WHICH MAY HAVE
//  SERIOUS CONSEQUENCES. THE COPYRIGHT HOLDER ALLOWS FREE USE OF THIS SOFTWARE IN ITS
//  "AS IS" CONDITION. THE COPYRIGHT HOLDER DISCLAIMS ANY LIABILITY OF ANY KIND FOR ANY
//  DAMAGES WHATSOEVER RESULTING DIRECTLY OR INDIRECTLY FROM THE USE OF THIS SOFTWARE
//  OR OF ANY DERIVATIVE WORK.
//---------------------------------------------------------------------------------------


#include "XRGenericInvocation.h"


@implementation XRGenericInvocation

static NSMethodSignature *genericSignature = nil;


////////////////////////////////////////////////////
//
//  FACTORY
//
////////////////////////////////////////////////////


+ (id)invocationWithXMLRPCTypes:(NSString *)types
{
    return [[[self alloc] initWithXMLRPCTypes:types] autorelease];
}


////////////////////////////////////////////////////
//
//  INIT & DEALLOC
//
////////////////////////////////////////////////////


- (id)initWithXMLRPCTypes:(NSString *)types
{
    [super init];

    if(genericSignature == nil)
        genericSignature = [[self methodSignatureForSelector:@selector(performMethod:withArguments:)] retain];

    xmlrpcMethodSignature = [[XRMethodSignature signatureWithXMLRPCTypes:types objcSignature:nil] retain];
    invocation = [[NSInvocation invocationWithMethodSignature:genericSignature] retain];
    
    return self;
}

- (id)initWithXMLRPCMethodSignature:(XRMethodSignature *)aSignature
{
    [NSException raise:NSInvalidArgumentException format:@"Cannot use -(id)initWithXMLRPCMethodSignature:(XRMethodSignature *)aSignature !!! Use -(id)initWithXMLRPCTypes:(NSString *)types instead!"];
    return self; // keep compiler happy
}

- (void)dealloc
{
    [invocation release];
    [xmlrpcMethodSignature release];
    [xmlrpcMethod release];
    [super dealloc];
}


////////////////////////////////////////////////////
//
//  ACCESSORS
//
////////////////////////////////////////////////////


- (void)setArguments:(NSArray *)arguments
{
    NSString *xmlrpcArgumentTypes;

    // argument count checking
    if(([[self xmlrpcMethodSignature] numberOfArguments] - 2) != [arguments count])
        [NSException raise:NSInvalidArgumentException format:@"Wrong number of arguments! Expected %d, instead got %d", [[self xmlrpcMethodSignature] numberOfArguments] - 2, [arguments count]];

    // type checking
    xmlrpcArgumentTypes = [XRMethodSignature xmlrpcTypesForObjects:arguments];
    if([[[self xmlrpcMethodSignature] getXRArgumentTypes] isEqualToString:xmlrpcArgumentTypes] == NO)
        [NSException raise:NSInvalidArgumentException format:@"Argument types do not match expected signature! Expected '%@', instead got '%@'.", [[self xmlrpcMethodSignature] getXRArgumentTypes], xmlrpcArgumentTypes];

    // now set the arguments
    [invocation setArgument:&xmlrpcMethod atIndex:2];
    [invocation setArgument:&arguments atIndex:3];
}

- (void)setTarget:(id)target
{
    if([self selector] != NULL)
    {
        NSMethodSignature *objcSignature = [target methodSignatureForSelector:[self selector]];
        if([objcSignature isEqual:genericSignature] == NO)
            [NSException raise:NSInvalidArgumentException format:@"Target %@ has no valid methodSignature for selector %@!", target, NSStringFromSelector([self selector])];
    }
    [invocation setTarget:target];
}


- (void)setSelector:(SEL)selector
{
    if([self target] != nil)
    {
        NSMethodSignature *objcSignature = [[self target] methodSignatureForSelector:selector];
        if([objcSignature isEqual:genericSignature] == NO)
            [NSException raise:NSInvalidArgumentException format:@"Target %@ has no valid methodSignature for selector %@!", [self target], NSStringFromSelector(selector)];
    }
    [invocation setSelector:selector];
}


////////////////////////////////////////////////////
//
//  METHOD SIGNATURE
//
////////////////////////////////////////////////////


// generic invocation signature
- (id)performMethod:(NSString *)method withArguments:(NSArray *)arguments
{
    return nil;
}

@end
