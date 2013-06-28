//
//  XRConnection.h
//  XMLRPC
//
//  Created by znek on Tue Aug 14 2001.
//  $Id: XRConnection.h,v 1.16 2003/04/04 02:01:54 znek Exp $
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


#ifndef	__XRConnection_h_INCLUDE
#define	__XRConnection_h_INCLUDE


#import <Foundation/Foundation.h>
#include "XRProtocols.h"
#include "XRHTTPAuthenticationHandler.h"


@class XRHTTPConnection;
@class XRHTTPAuthenticationCredentials;
@class XRProxy;
@class XRInvocationStorage;
@class XRInvocation;
@class XRGenericInvocation;


@interface XRConnection : NSObject <XRServing, XRListing>
{
    NSMutableDictionary *handleObjectLUT;
    XRInvocationStorage *invocationStorage;
    NSMutableDictionary *methodDescriptionLUT;
    NSMutableDictionary *connDataLUT;
    NSMutableDictionary *proxyLUT;
    NSMutableDictionary *authHandlerLUT;

    // Client
    NSURL *remoteURL;
    XRHTTPConnection *remoteConnection;
    NSTimeInterval connectionCheckInterval;
    NSTimer *connectionCheckTimer;

    // Server
    NSFileHandle *serverSocket;

    // NSConnection compatibility
    id rootObject; /* not retained */

    id delegate; /* not retained */

    // HTTP Connection authentication handling
    id <NSObject, XRHTTPAuthenticationHandler> defaultAuthHandler;

    struct {
        unsigned int isRunning: 1;
        unsigned int isValid: 1;
        unsigned int isRecursiveMulticallAllowed: 1;
        unsigned int shouldEncodeObjectsUsingNSCodingIfPossible: 1;
        unsigned int shouldPerformConnectionChecks: 1;
        unsigned int delegateRespondsToClassOfProxyWithHandle: 1;
        unsigned int delegateRespondsToIsConnectionAlive: 1;
        unsigned int usesNonXMLConformantEncodingForStrings: 1;
        unsigned int shouldEncodeNullValuesAsRFCDataType: 1;
        unsigned int RESERVED: 23;
    } flags;
}

/*"Utilities for creating XRInvocations easily."*/

+ (XRInvocation *)invocationForXMLRPCMethod:(NSString *)method withXMLRPCTypes:(NSString *)types mappedToSelector:(SEL)selector atObject:(id)object;
+ (XRGenericInvocation *)genericInvocationForXMLRPCMethod:(NSString *)method withXMLRPCTypes:(NSString *)types mappedToSelector:(SEL)selector atObject:(id)object;


/*"Vending"*/

+ (XRConnection *)connectionWithObject:object handle:(NSString *)objectHandle socket:(NSFileHandle *)socket;
- (id)initWithObject:object handle:(NSString *)objectHandle socket:(NSFileHandle *)socket;


/*"Connecting"*/

+ (XRConnection *)connectionWithURL:(NSURL *)url;
- (id)initWithURL:(NSURL *)url;


/*"Delegate"*/

- (void)setDelegate:(id)aDelegate;
- (id)delegate;


/*"Object registration"*/

- (void)registerObject:(id <NSObject, XRServing>)object forHandle:(NSString *)handle;
- (void)unregisterObjectForHandle:(NSString *)handle;
- (void)registerInvocation:(XRInvocation *)invocation forMethod:(NSString *)method;
- (void)unregisterInvocationsForMethod:(NSString *)method;

// This is here mainly to establish compatibility to NSConnection
- (NSArray *)remoteObjects;

// returns an autoreleased proxy
- (XRProxy *)proxyWithHandle:(NSString *)handle;

// NOTE: You normally do not need to call this method directly
- (void)releaseProxy:(XRProxy *)proxy;

// delegate can override this
- (Class)classOfProxyWithHandle:(NSString *)handle;

// NOTE: XML-RPC connections do not really have a rootObject, because
// everything is based on 'handles'. If you integrate XML-RPC as a
// transparent replacement for NSConnections into a program
// you might find these methods useful.

- (id)rootObject;
// NOTE: The given object will not be retained!
- (void)setRootObject:(id)anObject;


/*"Authentication"*/

- (void)setDefaultAuthHandler:(id <NSObject, XRHTTPAuthenticationHandler>)authHandler;
- (id <NSObject, XRHTTPAuthenticationHandler>)defaultAuthHandler;

- (void)setAuthHandler:(id <NSObject, XRHTTPAuthenticationHandler>)authHandler forMethod:(NSString *)method;
- (id <NSObject, XRHTTPAuthenticationHandler>)authHandlerForMethod:(NSString *)method;


/*"Sending messages over the wire"*/

// These do work only if connection is acting as a client
- (id)performRemoteMethod:(NSString *)method;
- (id)performRemoteMethod:(NSString *)method withObject:(id)object;
- (id)performRemoteMethod:(NSString *)method withObject:(id)firstObject withObject:(id)secondObject;
- (id)performRemoteMethod:(NSString *)method withObjects:(NSArray *)objects;
// these are our public entry into XML processing of remote messages
// NOTE: Use these methods as a public entry into this XML-RPC implementation if you handle
// the HTTP transport on your own
- (NSData *)xmlRequestForPerformRemoteMethod:(NSString *)method withObjects:(NSArray *)objects;
- (id)resultForXMLResponse:(NSData *)xmlResponse;


/*"Performing messages on objects handled by us"*/

// NOTE: Use this method as a public entry into this XML-RPC implementation if you handle
// the HTTP transport on your own
- (NSData *)xmlResponseForXMLMessage:(NSData *)xmlRequest credentials:(XRHTTPAuthenticationCredentials *)credentials;


/*"Connection runloop"*/

// Connections that serve as a server (vending objects) have to be run in order to work
- (void)runInNewThread;
// this will raise if connection is not in running state
- (void)stop;
// will post a XRConnectionDidDieNotification and release all proxies
- (void)invalidate;


/*"Connection options"*/

// This triggers whether a specific methodCall should be delivered to
// the remote end every 'connectionCheckInterval' seconds. This enables
// us to take notice of a connection death within the granularity defined
// by 'connectionCheckInterval' seconds.
// default is NO
- (void)setShouldPerformConnectionChecks:(BOOL)yn;
// The interval in question, s.a.
- (void)setConnectionCheckInterval:(NSTimeInterval)interval;


// Decide, whether 'multicall' methodCalls can be placed inside a 'multicall'
// methodCall (which could possibly lead to an endless recursion)
// default is NO
- (void)setAllowsRecursiveMulticall:(BOOL)yn;

// Decide, whether objects not implementing the XRCoding protocol
// but capable of NSCoding should be sent as NSCoded base64 streams
// rather than as strings
// default is NO
- (void)setShouldEncodeObjectsUsingNSCodingIfPossible:(BOOL)yn;

// Implements an RFC to allow sending of nil values as native datatypes.
// default is NO
- (void)setEncodesNullValuesAsRFCDataType:(BOOL)yn;

// The spec says, multiple times BTW, that XML-RPC is XML conformant.
// However, there's an appendix which states that only '<' and '&' characters need
// to be entity-encoded - which clearly violates the XML spec.
// Bad enough, some server implementors take that seriously and cannot handle
// proper XML data. If you encounter such a server you have to use this flag.
// default is NO
- (void)setUsesNonXMLConformantEncodingForStrings:(BOOL)yn;

@end


@interface NSObject (XRConnectionDelegate)
- (Class)classOfProxyWithHandle:(NSString *)handle forConnection:(XRConnection *)connection;
- (BOOL)isConnectionAlive:(XRConnection *)connection;
@end

#endif	/* __XRConnection_h_INCLUDE */
