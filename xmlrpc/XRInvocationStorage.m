//
//  XRInvocationStorage.m
//  XMLRPC
//
//  Created by znek on Fri Jun 07 2002.
//  $Id: XRInvocationStorage.m,v 1.4 2003/03/28 13:12:02 znek Exp $
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


#include "XRInvocationStorage.h"
#include <EDCommon/EDCommon.h>
#include "XRDefines.h"
#include "XRConstants.h"
#include "XRMethodSignature.h"
#include "XRInvocation.h"


@implementation XRInvocationStorage

/**
This is what the handleInvocationsLUT looks like:
 
 handle = {
     method = {
         "argTypes #1" = <invocation #1>;
         "argTypes #2" = <invocation #2>;
     }
 }
 */


////////////////////////////////////////////////////
//
//  INIT & DEALLOC
//
////////////////////////////////////////////////////


- (id)init
{
    [super init];
    handleInvocationsLUT = [[NSMutableDictionary allocWithZone:[self zone]] init];
    return self;
}

- (void)dealloc
{
    [handleInvocationsLUT release];
    [super dealloc];
}


////////////////////////////////////////////////////
//
//  HELPERS
//
////////////////////////////////////////////////////


- (EDObjectPair *)getHandleAndMethodFromUnqualifiedMethod:(NSString *)method
{
    NSRange range;

    NSAssert(method != nil, @"Method MUST NOT be *nil*!");

    range = [method rangeOfString:@"." options:NSBackwardsSearch];
    if(range.length == 0)
        return [EDObjectPair pairWithObjects:nil :method];

    return [EDObjectPair pairWithObjects:[method substringToIndex:range.location] :[method substringFromIndex:NSMaxRange(range)]];
}


////////////////////////////////////////////////////
//
//  REGISTERING
//
////////////////////////////////////////////////////


- (void)registerInvocation:(XRInvocation *)invocation forMethod:(NSString *)method
{
    EDObjectPair *handleMethodPair;
    NSString *handle, *_method, *types;
    NSMutableDictionary *signatureInvocationLUT, *methodInvocationLUT = handleInvocationsLUT;

    handleMethodPair = [self getHandleAndMethodFromUnqualifiedMethod:method];
    handle = [handleMethodPair firstObject];
    _method = [handleMethodPair secondObject];

    if(handle != nil)
    {
        methodInvocationLUT = [handleInvocationsLUT objectForKey:handle];
        if(methodInvocationLUT == nil)
        {
            methodInvocationLUT = [[[NSMutableDictionary allocWithZone:[handleInvocationsLUT zone]] init] autorelease];
            [handleInvocationsLUT setObject:methodInvocationLUT forKey:handle];
        }
    }

    signatureInvocationLUT = [methodInvocationLUT objectForKey:_method];
    if(signatureInvocationLUT == nil)
    {
        signatureInvocationLUT = [[[NSMutableDictionary allocWithZone:[methodInvocationLUT zone]] init] autorelease];
        [methodInvocationLUT setObject:signatureInvocationLUT forKey:_method];
    }

    types = [[invocation xmlrpcMethodSignature] getXRArgumentTypes];
    [signatureInvocationLUT setObject:invocation forKey:types];
    EDLog3(XRLogObjReg, @"registering invocation:%@ for method:%@ - %d signatures for this method exist", invocation, method, [signatureInvocationLUT count]);
}


////////////////////////////////////////////////////
//
//  UNREGISTERING
//
////////////////////////////////////////////////////


- (void)unregisterInvocationsForMethod:(NSString *)method
{
    EDObjectPair *handleMethodPair;
    NSString *handle, *_method;
    NSMutableDictionary *methodInvocationLUT = handleInvocationsLUT;

    handleMethodPair = [self getHandleAndMethodFromUnqualifiedMethod:method];
    handle = [handleMethodPair firstObject];
    _method = [handleMethodPair secondObject];

    if(handle != nil)
        methodInvocationLUT = [handleInvocationsLUT objectForKey:handle];
    
    EDLog1(XRLogObjReg, @"removing all invocations for method:%@", method);
    [methodInvocationLUT removeObjectForKey:_method];
}

- (void)removeInvocationsWithHandle:(NSString *)handle
{
    NSAssert(handle != nil, @"Handle MUST NOT be *nil*!");

    EDLog1(XRLogObjReg, @"removing all invocations for handle:%@", handle);
    [handleInvocationsLUT removeObjectForKey:handle];
}


////////////////////////////////////////////////////
//
//  LOOKUP
//
////////////////////////////////////////////////////


- (XRInvocation *)invocationForMethod:(NSString *)method xmlrpcArgumentTypes:(NSString *)xmlrpcTypes
{
    EDObjectPair *handleMethodPair;
    NSString *handle, *_method;
    NSDictionary *methodInvocationLUT = handleInvocationsLUT;

    handleMethodPair = [self getHandleAndMethodFromUnqualifiedMethod:method];
    handle = [handleMethodPair firstObject];
    _method = [handleMethodPair secondObject];

    if(handle != nil)
        methodInvocationLUT = [handleInvocationsLUT objectForKey:handle];

    return [[methodInvocationLUT objectForKey:_method] objectForKey:xmlrpcTypes];
}

- (NSArray *)methodSignaturesForMethod:(NSString *)method
{
    EDObjectPair *handleMethodPair;
    NSArray *invocations;
    NSString *handle, *_method;
    NSDictionary *methodInvocationLUT = handleInvocationsLUT;

    handleMethodPair = [self getHandleAndMethodFromUnqualifiedMethod:method];
    handle = [handleMethodPair firstObject];
    _method = [handleMethodPair secondObject];

    if(handle != nil)
        methodInvocationLUT = [handleInvocationsLUT objectForKey:handle];

    invocations = [[methodInvocationLUT objectForKey:_method] allValues];
    return [invocations arrayByMappingWithSelector:@selector(xmlrpcMethodSignature)];
}

@end
