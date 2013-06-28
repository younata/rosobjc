//
//  XRProxy.m
//  XMLRPC
//
//  Created by znek on Sun Aug 19 2001.
//  $Id: XRProxy.m,v 1.9 2003/03/28 13:12:02 znek Exp $
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


#include "XRProxy.h"
#include <EDCommon/EDCommon.h>
#import <objc/Protocol.h>
#include "XRConnection.h"
#include "XRInvocation.h"

#ifdef XMLRPC_OSXSBUILD
#include "Future.h"
#endif


@interface NSMethodSignature (PrivateAPIWeKnowExists)
+ (NSMethodSignature *)signatureWithObjCTypes:(const char *)types;
@end

@interface XRProxy (PrivateAPI)
- (void)_createSelectorMappings;
- (EDObjectPair *)_mappingForSelector:(SEL)selector;
- (BOOL)_isConnectionInvalid;
@end

@implementation XRProxy

/*"
 * XRProxy is the base class for other classes representing distant XML-RPC handles. Usually an
 * XML-RPC handle encapsulates a set of methods. As such, in an object oriented world an XML-RPC
 * handle can be understood as a controller object that can be referenced via a handle. In order to make your
 * own code more readable and maintainable you create subclasses of XRProxy that represent these
 * remote controller objects.
 *
 * XRProxy objects retain their connection until they are released. %{Please note that XRConnection objects do not
 * retain their proxies.}
 *
 * #{Subclassing}
 *
 * If you create your own subclass of XRProxy you'll mainly do that in order to create some native
 * Objective-C API which makes your own code more readable. All you then have to do is
 * to create a native Objective-C "wrapper" which covers one of the #performMethod: methods that you
 * want to use in that particular method.
 *
 * An example TestServerProxy could be defined like this:
 *
 !{
    @interface TestServerProxy : XRProxy
    {
    }
    
    - (id)doStuff:(NSArray *)args;
    
    @end
 }
 *
 * An example implementation of #doStuff: could easily be written like this:
 *
 !{
    - (id)doStuff:(NSArray *)args
    {
        return [self performMethod:@"doStuff" withObject:args];
    }
 }
 *
 * #{NSDistantObject API compatibility}
 *
 * Because XRProxy objects implement #connectionForProxy and #setProtocolForProxy: it is very easy to use
 * XRProxy objects and NSDistantObject objects in your code without much need to distinguish between them.
"*/

////////////////////////////////////////////////////
//
//   FACTORY
//
////////////////////////////////////////////////////


+ (XRProxy *)proxyOfClass:(Class)proxyClass forConnection:(XRConnection *)aConnection withHandle:(NSString *)aHandle
/*"
 * Returns an object of class proxyClass which associates itself with XML-RPC handle aHandle for XML-RPC connection aConnection.
 * If proxyClass is Nil, an instance of XRProxy will be returned.
"*/
{
    if(proxyClass == Nil)
        proxyClass = self;
    return [[[proxyClass alloc] initWithConnection:aConnection handle:aHandle] autorelease];
}


////////////////////////////////////////////////////
//
//   INIT & DEALLOC
//
////////////////////////////////////////////////////


- (id)initWithConnection:(XRConnection *)aConnection handle:(NSString *)aHandle
/*"
 * Initializes XRProxy object to retain aHandle and aConnection. During the course of the initialization
 * the XRProxy does not tell aConnection about it. Usually XRConnection objects call this method and
 * associate XRProxy objects and handles on their behalf.
 *
 * This method is the designated initializer for this class.
"*/
{
    [super init];
    
    connection = [aConnection retain];
    _isConnectionValid = YES;
    handle = [aHandle retain];
    return self;
}

- (void)dealloc
{
    [connection releaseProxy:self];
    [connection release];
    [handle release];
#if USE_SELECTOR_MAPPINGS
    [selectorMappingLUT release];
#endif
    [super dealloc];
}


////////////////////////////////////////////////////
//
//  SELECTOR/METHOD
//  MAPPING
//
////////////////////////////////////////////////////

#if USE_SELECTOR_MAPPINGS
- (void)_createSelectorMappings
{
    NSArray *_mappings;
    NSEnumerator *mEnum;
    EDObjectPair *mapping;

    _mappings = [self xmlrpcMethodMappings];
    selectorMappingLUT = [[NSMutableDictionary allocWithZone:[self zone]] initWithCapacity:[_mappings count]];
    mEnum = [_mappings objectEnumerator];
    while((mapping = [mEnum nextObject]) != nil)
    {
        NSValue *selValue;
        SEL selector;
        XRInvocation *invocation;
        
        invocation = [mapping secondObject];
        selector = [invocation selector];
        selValue = [NSValue valueWithBytes:&selector objCType:@encode(SEL)];
        [selectorMappingLUT setObject:mapping forKey:selValue];
    }
}

- (EDObjectPair *)_mappingForSelector:(SEL)selector
{
    NSValue *selValue;

    selValue = [NSValue valueWithBytes:&selector objCType:@encode(SEL)];
    return [selectorMappingLUT objectForKey:selValue];
}
#endif

////////////////////////////////////////////////////
//
//   ACCESSORS
//
////////////////////////////////////////////////////


#if USE_SELECTOR_MAPPINGS
- (NSArray *)xmlrpcMethodMappings
/*"
 * %{Only available if framework was compiled with #{-DUSE_SELECTOR_MAPPINGS=1}.
 * This code has turned out not to work as well as expected
 * and will be removed in a future version of this framework.}
"*/
{
    return [NSArray array];
}
#endif

- (NSString *)handle
/*"
 * Returns the XML-RPC handle this object was associated with during initialization.
"*/
{
    return handle;
}


//-------------------------------------
// NSDistantObject compatibility
//-------------------------------------


- (XRConnection *)connectionForProxy
/*"
 * Returns the connection object this proxy is associated with.
"*/
{
    return connection;
}

- (void)setProtocolForProxy:(Protocol *)aProtocol
/*"
 * Compatibility method for retaining API compatibility with NSDistantObject objects. Currently this implementation
 * does nothing.
"*/
{
#if USE_SELECTOR_MAPPINGS
    protocol = aProtocol;
    [selectorMappingLUT release]; // just in case
    [self _createSelectorMappings];
#endif
}


//-------------------------------------
// XRConnection stuff
//-------------------------------------


- (void)_setConnectionIsInvalid
{
    _isConnectionValid = NO;
}

- (BOOL)_isConnectionInvalid
{
    return _isConnectionValid == NO;
}


////////////////////////////////////////////////////
//
//   PERFORMING METHODS
//
////////////////////////////////////////////////////


- (id)performMethod:(NSString *)method
/*"
 * Cover method for subclassers which performs the remote method on this object's connection. Returns
 * whatever the remote method invocation is supposed to return.
* The method SHOULD NOT contain the remote handle, as this is automatically prepended.
 *
 * In case of a remote exception or other error this method
 * will raise an appropriate exception. For a list of possible exceptions and accompanied %userInfo keys
 * please consult the following list:
 *
 * TBD
 *
"*/
{
    return [self performMethod:method withObjects:[NSArray array]];
}

- (id)performMethod:(NSString *)method withObject:(id)object
/*"
 * Returns the result of performing method with an argument of object. For a more detailed discussion see #performMethod:.
"*/
{
    if(object == nil)
        object = [NSNull null];
    return [self performMethod:method withObjects:[NSArray arrayWithObject:object]];
}

- (id)performMethod:(NSString *)method withObject:(id)firstObject withObject:(id)secondObject
/*"
 * Returns the result of performing method with firstObject and secondObject as its arguments.
 * For a more detailed discussion see #performMethod:.
"*/
{
    if(firstObject == nil)
        firstObject = [NSNull null];
    if(secondObject == nil)
        secondObject = [NSNull null];
    return [self performMethod:method withObjects:[NSArray arrayWithObjects:firstObject, secondObject, nil]];
}

- (id)performMethod:(NSString *)method withObjects:(NSArray *)objects
/*"
 * Returns the result of performing method with an arbitrary number of arguments represented in the objects NSArray.
 * The number of arguments given MUST match the number of arguments expected by method. If you need to provide
 * a nil value as an argument value you can do so by inserting an instance of NSNull at the appropriate index.
 * All arguments of type NSNull will automatically be transformed into nil objects.
 *
 * For a more detailed discussion see #performMethod:.
"*/
{
    NSString *_method;
    NSString *_handle;

    NSAssert([self _isConnectionInvalid] == NO, @"** connection is invalid");
    _handle = [self handle];

    if(_handle != nil)
        _method = [NSString stringWithFormat:@"%@.%@", [self handle], method];
    else
        _method = method;

    return [[self connectionForProxy] performRemoteMethod:_method withObjects:objects];
}


////////////////////////////////////////////////////
//
//   FORWARDING
//
////////////////////////////////////////////////////


#if USE_SELECTOR_MAPPINGS
- (void)forwardInvocation:(NSInvocation *)invocation
{
    NSString *method;
    EDObjectPair *mapping;
    NSMethodSignature *objcSignature;
    id result;

    NSAssert1([self _isConnectionInvalid] == NO, @"** Connection of proxy %@ is invalid", [self description]);

    mapping = [self _mappingForSelector:[invocation selector]];
    if(mapping == nil)
        [self doesNotRecognizeSelector:[invocation selector]];

    method = [mapping firstObject];
    objcSignature = [[mapping secondObject] methodSignature];

#warning !! check type and stuff

    result = [connection performRemoteMethod:method withObjects:nil];
#warning Now morph the return value into that kind of data the invocation expects
    
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    NSMethodSignature *objcSignature;

    if((objcSignature = [super methodSignatureForSelector:aSelector]) != nil)
        return objcSignature;
        
    // we have to ask our protocol for a method signature
    if(protocol != nil)
    {
        const char	*types = NULL;
        struct objc_method_description* methodDescription;
        
        methodDescription = [protocol descriptionForInstanceMethod:aSelector];
        if(methodDescription == NULL)
            methodDescription = [protocol descriptionForClassMethod:aSelector];

        if(methodDescription != NULL)
            types = methodDescription->types;
        objcSignature = [NSMethodSignature signatureWithObjCTypes:types];
    }
    return objcSignature;
}


- (BOOL)respondsToSelector:(SEL)aSelector
{
    if([super respondsToSelector:aSelector] == YES)
        return YES;
    return [self _mappingForSelector:aSelector] != nil;
}
#endif

@end
