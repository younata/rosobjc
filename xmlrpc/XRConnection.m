//
//  XRConnection.m
//  XMLRPC
//
//  Created by znek on Tue Aug 14 2001.
//  $Id: XRConnection.m,v 1.38 2003/04/04 02:26:17 znek Exp $
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


#include "XRConnection.h"
#include <EDCommon/EDCommon.h>
#include "XRDefines.h"
#include "XRConstants.h"
#include "XRMethodSignature.h"
#include "XRInvocationStorage.h"
#include "XRInvocation.h"
#include "XRGenericInvocation.h"
#include "XRProxy.h"
#include "XREncoder.h"
#include "XRDecoder.h"
#include "XRHTTPConnection.h"
#include "XRHTTPRequest.h"
#include "XRHTTPRequest+HTTPAuthentication.h"
#include "XRHTTPResponse.h"
#include "XRHTTPResponse+HTTPAuthentication.h"
#include "NSString+XMLExtensions.h"
#include "XREMethodCall.h"
#include "XREMethodResponse.h"
#include "XRHTTPBasicAuthenticationHandler.h"
#include "XRHTTPAuthenticationCredentials.h"

#ifdef XMLRPC_OSXSBUILD
#include "Future.h"
#endif


#define EMPTY_PROXY_HANDLE @"_"


@interface XRProxy (PrivateAPI)
- (void)_setConnectionIsInvalid;
@end

@interface XRConnection (PrivateAPI)
- (id)objectForHandle:(NSString *)handle;

- (void)receiveMessage:(NSNotification *)notification;
- (void)handleMessage:(NSData *)data socket:(NSFileHandle *)socket;
- (id)performMethod:(NSString *)selector withObjects:(NSArray *)objects credentials:(XRHTTPAuthenticationCredentials *)credentials;

- (id <NSObject, XRHTTPAuthenticationHandler>)_currentAuthHandlerForMethod:(NSString *)method;

- (BOOL)appendReceivedData:(NSData *)data socket:(NSFileHandle *)socket;
- (NSData *)cachedDataForSocket:(NSFileHandle *)socket;
- (void)removeCachedDataForSocket:(NSFileHandle *)socket;

- (void)didAcceptConnection:(NSNotification *)notification;

- (void)_startNewConnectionCheckTimer;
- (void)_stopCurrentConnectionCheckTimer;
- (void)_resetConnectionCheckTimer;
- (void)_performRemoteConnectionCheck:(NSTimer *)timer;

- (BOOL)isServer;
- (BOOL)isRunning;
- (BOOL)isValid;
- (void)_shutdown;
@end


@implementation XRConnection

/*"
 * XRConnection objects manage XML-RPC communication. XRConnection can either act as a client or as a
 * server, never as both at the same time.
 *
 * #Client
 *
 * In the first case, it establishes a connection to a URL that you have to specify and then offers you the ability
 * to perform methods (methodCalls) on the remote side. All objects involved can be usual NSObject derived
 * subclasses (or at least, objects implementing the NSObject protocol). Encoding is handled transparently and can
 * easily be extended for your special case. Note, that this is normally unnecessary and "bridging" of Objective-C
 * objects is a triggerable feature of the Mulle XMLRPC implementation.
 *
 * A very simple client could be implemented like this:
 *
 !{
     XRConnection *connection;
     id result;

     connection = [XRConnection connectionWithURL:[NSURL URLWithString:@"http://localhost:2333/RPC2"]];

     result = [connection performRemoteMethod:@"system.listMethods"];
     NSLog(@"Received: %@", result);
  }
 *
 * For a slightly more complex (but more capable) example involving proxies see the Test Client target in this project.
 *
 * #Server
 *
 * In the second case, XRConnection establishes a server connection on a local port and can register objects and
 * vend them according to the XML-RPC specs. Others can then perform methods (methodCalls) on these objects.
 * All the objects have to do is to implement the XRServing protocol which simply defines a uniform way to transform
 * the XML-RPC methodCall to an Objective-C selector. The second protocol, XRListing - which is optional - serves
 * for transparent introspection purposes. Clients can discover the methods you offer with accompanied help
 * (that you provide) how to use these methods.
 *
 * A simple server example:
 *
 !{
     NSRunLoop *loop = [NSRunLoop currentRunLoop];

     EDTCPSocket *serverSocket;
     XRConnection *connection;
     TestServer *server; \/\/ assume this exists

     serverSocket = [EDTCPSocket socket];
     [serverSocket setLocalPortNumber:2333];
     [serverSocket startListening];

     server = [[[TestServer alloc] init] autorelease];
     connection = [XRConnection connectionWithObject:server handle:@"sample" socket:serverSocket];

     \/\/ now start the connection runloop ...
     [connection runInNewThread];

     \/\/ ... and finally enter our own runLoop
     [loop run];
 }
 *
 * #{Configuring an XRConnection}
 *
 * TBD
 *
 * #{The Delegate}
 *
 * TBD
 *
 * #{Handling XRConnection Errors}
 *
 * TBD
 *
 * #{NSConnection Similarities and Differences}
 *
 * TBD
 *
 "*/


////////////////////////////////////////////////////
//
//  INVOCATION TOOLS
//
////////////////////////////////////////////////////


+ (XRInvocation *)invocationForXMLRPCMethod:(NSString *)method withXMLRPCTypes:(NSString *)types mappedToSelector:(SEL)selector atObject:(id)object
/*"
    Utility for creating XRInvocations more easily.
"*/
{
    NSMethodSignature *objcSignature;
    XRMethodSignature *xmlrpcSignature;
    XRInvocation *invocation;

    objcSignature = [object methodSignatureForSelector:selector];
    xmlrpcSignature = [XRMethodSignature signatureWithXMLRPCTypes:types objcSignature:objcSignature];
    invocation = (XRInvocation *)[XRInvocation invocationWithXMLRPCMethodSignature:xmlrpcSignature];
    [invocation setXMLRPCMethod:method];
    [invocation setSelector:selector];
    [invocation setTarget:object];
    return invocation;
}

+ (XRGenericInvocation *)genericInvocationForXMLRPCMethod:(NSString *)method withXMLRPCTypes:(NSString *)types mappedToSelector:(SEL)selector atObject:(id)object
{
    XRGenericInvocation *invocation;

    invocation = [XRGenericInvocation invocationWithXMLRPCTypes:types];
    [invocation setXMLRPCMethod:method];
    [invocation setSelector:selector];
    [invocation setTarget:object];
    return invocation;
}


////////////////////////////////////////////////////
//
//  CONNECTION FACTORY
//
////////////////////////////////////////////////////


+ (XRConnection *)connectionWithObject:object handle:(NSString *)objectHandle socket:(NSFileHandle *)socket
/*"
 * Returns a connection in server mode which is associated with socket. The #rootObject of this connection is associated
 * with objectHandle, which directly refers to an XML-RPC handle.
 *
 * Although socket can be an NSFileHandle, you might want to use a subclass of NSFileHandle like
 * EDTCPSocket which provides a much richer API for socket handling.
 *
 * Note that this connection does not handle incoming connections until #runInNewThread has been called.
"*/
{
    return [[[self alloc] initWithObject:object handle:objectHandle socket:socket] autorelease];
}

+ (XRConnection *)connectionWithURL:(NSURL *)url
/*"
* Returns a connection in client mode which will use url for %methodCalls sent via #performRemoteMethod: and the variations thereof.
"*/
{
    return [[[self alloc] initWithURL:url] autorelease];
}


////////////////////////////////////////////////////
//
//  INIT & DEALLOC
//
////////////////////////////////////////////////////


- (id)init
{
    [super init];
    flags.isRunning = NO;
    // checks are expensive and require a specialized server on remote end
    // so we disable them by default
    flags.shouldPerformConnectionChecks = NO;
    connectionCheckInterval = 30.0;
    return self;
}

- (id)initWithObject:object handle:(NSString *)objectHandle socket:(NSFileHandle *)socket
/*"
 * Returns a connection in server mode which is associated with socket. The #rootObject of this connection is associated
 * with objectHandle, which directly refers to an XML-RPC handle.
 *
 * Although socket can be an NSFileHandle, you might want to use a subclass of NSFileHandle like
 * EDTCPSocket which provides a much richer API for socket handling.
 *
 * Note that this connection does not handle incoming connections until #runInNewThread has been called.
 *
 * This method is the designated initializer for server mode connections.
"*/
{
    [self init];

    handleObjectLUT = [[NSMutableDictionary allocWithZone:[self zone]] init];
    invocationStorage = [[XRInvocationStorage allocWithZone:[self zone]] init];
    methodDescriptionLUT = [[NSMutableDictionary allocWithZone:[self zone]] init];
    connDataLUT = [[NSMutableDictionary allocWithZone:[self zone]] init];
    authHandlerLUT = [[NSMutableDictionary allocWithZone:[self zone]] init];

    [self registerObject:object forHandle:objectHandle];
    serverSocket = [socket retain];
    flags.isRecursiveMulticallAllowed = NO;
    return self;
}

- (id)initWithURL:(NSURL *)url
/*"
 * Returns a connection in client mode which will use url for %methodCalls sent via #performRemoteMethod: and the variations thereof.
 *
 * This method is the designated initializer for client mode connections.
"*/
{
    [self init];
    remoteURL = [url retain];
    // if remoteURL has user/password set, we apply a HTTP basic authHandler to this connection
    if([remoteURL user] != nil)
        [self setDefaultAuthHandler:[XRHTTPBasicAuthenticationHandler authHandlerWithUser:[remoteURL user] password:[remoteURL password]]];

    proxyLUT = [[NSMutableDictionary allocWithZone:[self zone]] init];
    flags.shouldEncodeObjectsUsingNSCodingIfPossible = NO;
    flags.usesNonXMLConformantEncodingForStrings = NO;
    flags.isValid = YES;
    return self;
}


- (void)dealloc
{
    if([self isValid])
        [self invalidate];
    if([self isServer])
        [self _shutdown]; // releases serverSocket!

    [handleObjectLUT release];
    [invocationStorage release];
    [methodDescriptionLUT release];
    [connDataLUT release];
    [authHandlerLUT release];

    [defaultAuthHandler release];

    // client
    [remoteURL release];
    [remoteConnection release];
    [proxyLUT release];

    [super dealloc];
}



////////////////////////////////////////////////////
//
//  OBJECT HANDLING
//
////////////////////////////////////////////////////


- (void)registerObject:(id <NSObject, XRServing>)object forHandle:(NSString *)handle
/*"
 * Description forthcoming.
"*/
{
    NSEnumerator *iEnum;
    XRInvocation *invocation;

    if(handle == nil)
        handle = EMPTY_PROXY_HANDLE;

    // first, unregister a possible predecessor
    [self unregisterObjectForHandle:handle];

    [handleObjectLUT setObject:object forKey:handle];
    
    // cache invocations for all implemented methods
    iEnum = [[object invocationsForXMLRPC] objectEnumerator];
    while((invocation = [iEnum nextObject]) != nil)
    {
        NSString *method;
        
        method = [NSString stringWithFormat:@"%@.%@", handle, [invocation xmlrpcMethod]];
        EDLog2(XRLogObjReg, @"registering method:%@ selector:%@", method, NSStringFromSelector([invocation selector]));

        [invocationStorage registerInvocation:invocation forMethod:method];
    }
    
    // also cache method descriptions if object implements the XRListing protocol
    if([object conformsToProtocol:@protocol(XRListing)])
    {
        NSEnumerator *sEnum;
        NSString *selector;
        
        sEnum = [[(id <XRListing>)object listPublicXMLRPCMethods] objectEnumerator];
        while((selector = [sEnum nextObject]) != nil)
        {
            NSString *text = [(id <XRListing>)object descriptionForXMLRPCMethod:selector];
            if(text != nil)
            {
                NSString *method = [NSString stringWithFormat:@"%@.%@", handle, selector];
                [methodDescriptionLUT setObject:text forKey:method];
                EDLog2(XRLogObjReg, @"registering description '%@' for method:%@", text, method);
            }
        }
    }
}

- (void)unregisterObjectForHandle:(NSString *)handle
{
    NSEnumerator *kEnum;
    NSString *key;
    NSString *handlePrefix;

    if(handle == nil)
        handle = EMPTY_PROXY_HANDLE;

    [handleObjectLUT removeObjectForKey:handle];
    
    handlePrefix = [NSString stringWithFormat:@"%@.", handle];

    [invocationStorage removeInvocationsWithHandle:handle];

    // cannot simply get keyEnumerator because we're deleting keys
    // as we enumerate on them ... thus we make a copy to be sure.
    kEnum = [[[[methodDescriptionLUT allKeys] copy] autorelease] objectEnumerator];
    while((key = [kEnum nextObject]) != nil)
    {
        if([key hasPrefix:handlePrefix])
            [methodDescriptionLUT removeObjectForKey:key];
    }
}

- (void)registerInvocation:(XRInvocation *)invocation forMethod:(NSString *)method
{
    [invocationStorage registerInvocation:invocation forMethod:method];
}

- (void)unregisterInvocationsForMethod:(NSString *)method
{
    [invocationStorage unregisterInvocationsForMethod:method];
}

- (id <NSObject, XRServing>)objectForHandle:(NSString *)handle
{
    if(handle == nil)
        handle = EMPTY_PROXY_HANDLE;

    return [handleObjectLUT objectForKey:handle];
}

- (id)rootObject
{
    return rootObject;
}

- (void)setRootObject:(id)anObject
{
    rootObject = anObject;
}


////////////////////////////////////////////////////
//
//  PROXY HANDLING
//
////////////////////////////////////////////////////


- (XRProxy *)proxyWithHandle:(NSString *)handle
{
    Class proxyClass;
    XRProxy *proxy;

    NSAssert([self isServer] == NO, @"only client connections can return proxies");

    proxyClass = [self classOfProxyWithHandle:handle];
    proxy = [XRProxy proxyOfClass:proxyClass forConnection:self withHandle:handle];

    if(handle == nil)
        handle = EMPTY_PROXY_HANDLE;

    [proxyLUT setObject:[NSValue valueWithNonretainedObject:proxy] forKey:handle];
    return proxy;
}

- (void)releaseProxy:(XRProxy *)proxy
{
    NSString *handle = [proxy handle];

    if(handle == nil)
        handle = EMPTY_PROXY_HANDLE;

    [proxyLUT removeObjectForKey:handle];
}

- (Class)classOfProxyWithHandle:(NSString *)handle
{
    if(flags.delegateRespondsToClassOfProxyWithHandle)
        return [delegate classOfProxyWithHandle:handle forConnection:self];
    return [XRProxy class];
}

- (NSArray *)remoteObjects
{
    NSMutableArray *proxyObjects;
    NSEnumerator *pEnum;
    NSValue *proxyValue;

    proxyObjects = [NSMutableArray array];

    pEnum = [proxyLUT objectEnumerator];
    while((proxyValue = [pEnum nextObject]) != nil)
    {
        XRProxy *aProxy = [proxyValue nonretainedObjectValue];
        [proxyObjects addObject:aProxy];
    }
    return proxyObjects;
}


////////////////////////////////////////////////////
//
//  AUTHENTICATION
//
////////////////////////////////////////////////////


- (void)setDefaultAuthHandler:(id <NSObject, XRHTTPAuthenticationHandler>)authHandler
{
    [authHandler retain];
    [defaultAuthHandler release];
    defaultAuthHandler = authHandler;
}

- (id <NSObject, XRHTTPAuthenticationHandler>)defaultAuthHandler
{
#warning * ZNeK: How about a delegate plug here?
    return defaultAuthHandler;
}

- (void)setAuthHandler:(id <NSObject, XRHTTPAuthenticationHandler>)authHandler forMethod:(NSString *)method
{
    NSAssert(method != nil, @"Method MUST NOT be nil!");

    if(authHandler != nil)
        [authHandlerLUT setObject:authHandler forKey:method];
    else
        [authHandlerLUT removeObjectForKey:method];
}

- (id <NSObject, XRHTTPAuthenticationHandler>)authHandlerForMethod:(NSString *)method
{
    id <NSObject, XRHTTPAuthenticationHandler> authHandler;

    authHandler = [authHandlerLUT objectForKey:method];
    if(authHandler == nil)
    {
        // is there an authHandler set for the whole handle?
        EDObjectPair *handleMethodPair = [invocationStorage getHandleAndMethodFromUnqualifiedMethod:method];
        authHandler = [authHandlerLUT objectForKey:[handleMethodPair firstObject]];
    }
    return authHandler;
}


- (id <NSObject, XRHTTPAuthenticationHandler>)_currentAuthHandlerForMethod:(NSString *)method
{
    id authHandler;

    authHandler = [self authHandlerForMethod:method];
    if(authHandler == nil)
        authHandler = [self defaultAuthHandler];

    return authHandler;
}


////////////////////////////////////////////////////
//
//  REMOTE
//  MESSAGING
//
////////////////////////////////////////////////////


- (id)performRemoteMethod:(NSString *)method
{
    return [self performRemoteMethod:method withObjects:[NSArray array]];
}

- (id)performRemoteMethod:(NSString *)method withObject:(id)object
{
    if(object == nil)
        object = [NSNull null];
    return [self performRemoteMethod:method withObjects:[NSArray arrayWithObject:object]];
}

- (id)performRemoteMethod:(NSString *)method withObject:(id)firstObject withObject:(id)secondObject
{
    if(firstObject == nil)
        firstObject = [NSNull null];
    if(secondObject == nil)
        secondObject = [NSNull null];
    return [self performRemoteMethod:method withObjects:[NSArray arrayWithObjects:firstObject, secondObject, nil]];
}

// this might raise if the remote side returns a fault
- (id)performRemoteMethod:(NSString *)method withObjects:(NSArray *)objects
{
    XRHTTPRequest *request;
    XRHTTPResponse *response;
    NSData *xmlRequest;
    NSData *xmlResponse;
    id <NSObject, XRHTTPAuthenticationHandler> authHandler;

    NSAssert([self isServer] == NO, @"Attempt to performRemoteMethod:withObjects: on server connection");

    xmlRequest = [self xmlRequestForPerformRemoteMethod:method withObjects:objects];
    EDLog1(XRLogMessage, @"xmlRequest = %@", [NSString stringWithData:xmlRequest encoding:NSUTF8StringEncoding]);
    request = [XRHTTPRequest requestWithMethod:@"POST" uri:[remoteURL path] != nil ? [remoteURL path] : @"/" httpVersion:@"HTTP/1.0" headers:nil content:xmlRequest];

    authHandler = [self _currentAuthHandlerForMethod:method];
    if(authHandler != nil)
        [request setAuthenticationCredentials:authHandler];

    NS_DURING

        if(remoteConnection == nil)
        {
            remoteConnection = [[XRHTTPConnection connectionWithHost:[remoteURL host] port:[remoteURL port] != nil ? [[remoteURL port] intValue] : 80] retain];
            [remoteConnection setSendTimeout:10.0];
            [remoteConnection setReceiveTimeout:10.0];
        }
        if([remoteConnection sendRequest:request] == NO)
            [NSException raise:NSGenericException format:@"Could not send request to %@", [remoteURL description]];
    
        response = [remoteConnection readResponse];

        // We need to check for HTTP errors now
        if([response status] != 200)
        {
            NSMutableDictionary *userInfo = nil;
            NSException *exception;
            NSString *reason;
            
            // Is it an authorization problem?
            if([response status] == 401)
            {
                NSString *realm = [[response headersForKey:@"www-authenticate"] firstObject];
                if(realm != nil)
                {
                    userInfo = [NSMutableDictionary dictionary];
                    [userInfo setObject:realm forKey:XRAuthenticationRealmKey];
                }

                reason = [NSString stringWithFormat:@"Authentication required for %@", (realm != nil) ? realm : @"\"unknown\" (no authentication realm found)"];
                exception = [[[NSException alloc] initWithName:XRAuthorizationRequiredException reason:reason userInfo:userInfo] autorelease];
                [exception raise];
            }
            else
            {
                NSString *reasonPhrase = [response reasonPhrase];

                if(reasonPhrase != nil)
                    reason = [NSString stringWithFormat:@"%d %@", [response status], reasonPhrase];
                else
                    reason = [NSString stringWithFormat:@"%d", [response status]];

                userInfo = [NSMutableDictionary dictionary];
                [userInfo setObject:[NSNumber numberWithInt:[response status]] forKey:XRHTTPErrorCodeKey];
                if(reasonPhrase != nil)
                    [userInfo setObject:reasonPhrase forKey:XRHTTPErrorStringKey];

                exception = [[[NSException alloc] initWithName:XRHTTPException reason:reason userInfo:userInfo] autorelease];
                [exception raise];
            }
        }
            
        if(flags.shouldPerformConnectionChecks)
            [self _resetConnectionCheckTimer];

        xmlResponse = [response content];
        if(xmlResponse == nil)
            [NSException raise:NSFileHandleOperationException format:@"Received empty response!"];

    NS_HANDLER

        // Connection level related failures require us
        // to invalidate the connection
        [self invalidate];
        [localException raise];

    NS_ENDHANDLER

    return [self resultForXMLResponse:xmlResponse];
}

- (NSData *)xmlRequestForPerformRemoteMethod:(NSString *)method withObjects:(NSArray *)objects
{
    NSMutableString *xmlRequest;
    XREncoder *coder;
    NSEnumerator *pEnum;
    id parameter;
    
    xmlRequest = [NSMutableString string];
    coder = [XREncoder encoderWithBuffer:xmlRequest];
    [coder setEncodesObjectsUsingNSCodingIfPossible:flags.shouldEncodeObjectsUsingNSCodingIfPossible];
    [coder setEncodesNullValuesAsRFCDataType:flags.shouldEncodeNullValuesAsRFCDataType];
    [coder setUsesNonXMLConformantEncodingForStrings:flags.usesNonXMLConformantEncodingForStrings];

    [xmlRequest appendString:@"<?xml version=\"1.0\"?>\n<methodCall><methodName>"];
    [xmlRequest appendString:method];
    [xmlRequest appendString:@"</methodName><params>"];
    
    pEnum = [objects objectEnumerator];
    while((parameter = [pEnum nextObject]) != nil)
    {
        [xmlRequest appendString:@"<param><value>"];
        [coder encodeObject:parameter];
        [xmlRequest appendString:@"</value></param>"];
    }
    
    [xmlRequest appendString:@"</params></methodCall>"];
    return [xmlRequest dataUsingEncoding:NSUTF8StringEncoding];
}

- (id)resultForXMLResponse:(NSData *)xmlResponse
{
    XREMethodResponse *methodResponse;
    XRDecoder *decoder;
    id result = nil;

    // use the XRDecoder to decode the request
    decoder = [XRDecoder decoderWithData:xmlResponse];
    methodResponse = [decoder decodeObject];

    EDLog1(XRLogXML, @"** parsed response tree:\n%@", methodResponse);

    if([methodResponse hasFault])
    {
        [[NSException exceptionWithName:XRRemoteException reason:[[methodResponse fault] objectForKey:@"faultString"] userInfo:[methodResponse fault]] raise];
    }
    else
    {
        result = [methodResponse objectValue];
#warning * ZNeK: configurable return value for *nil* could be nice to have 
        if(result == [NSNull null])
            result = @"";
    }
    return result;
}


////////////////////////////////////////////////////
//
//  LOCAL
//  MESSAGING
//
////////////////////////////////////////////////////


// server mode
// get everything from the data in order to process the selector with args
// send response back to the socket

- (void)handleMessage:(NSData *)data socket:(NSFileHandle *)senderSocket
{
    XRHTTPRequest *request;
    XRHTTPResponse *response;
    NSData *xmlRequest;
    NSData *xmlResponse;
    
    request = [XRHTTPRequest requestWithTransferData:data];
    xmlRequest = [request content];
    EDLog1(XRLogMessage, @"xmlRequest = %@", [NSString stringWithData:xmlRequest encoding:NSUTF8StringEncoding]);

    NS_DURING

        // this incorporates performing selectors and stuff
        // it can also require authorization in which case we have to intercept certain exceptions
        xmlResponse = [self xmlResponseForXMLMessage:xmlRequest credentials:[request authenticationCredentials]];
        // encapsulate response in a HTTP transportable object
        response = [XRHTTPResponse responseWithContent:xmlResponse];

    NS_HANDLER

        id authHandler;

        // create an empty response
        response = [XRHTTPResponse responseWithContent:[NSData data]];
        // retrieve the authHandler and apply it to the response
        authHandler = [[localException userInfo] objectForKey:XRAuthenticationHandlerKey];
        if(authHandler != nil)
        {
            NSString *realm = [[localException userInfo] objectForKey:XRAuthenticationRealmKey];
            [response setAuthenticationRequest:authHandler forRealm:realm];
        }
        else
        {
            [response setStatus:500]; // internal server error
            [response setReasonPhrase:@"Internal server error"];
        }
        
    NS_ENDHANDLER
 
    [senderSocket writeData:[response transferData]];
    
    // disallow further sends and receives
    [senderSocket shutdown];
}

// server mode
// get everything from the data in order to process the selector with args
// send response back to the socket

- (NSData *)xmlResponseForXMLMessage:(NSData *)xmlRequest credentials:(XRHTTPAuthenticationCredentials *)credentials
{
    NSData *xmlResponse = nil;
    NSMutableString *xmlContent;
    XREncoder *coder;
    
    xmlContent = [NSMutableString stringWithString:@"<?xml version=\"1.0\"?>\n<methodResponse>"];
    coder = [XREncoder encoderWithBuffer:xmlContent];
    [coder setEncodesObjectsUsingNSCodingIfPossible:flags.shouldEncodeObjectsUsingNSCodingIfPossible];
    [coder setEncodesNullValuesAsRFCDataType:flags.shouldEncodeNullValuesAsRFCDataType];
    [coder setUsesNonXMLConformantEncodingForStrings:flags.usesNonXMLConformantEncodingForStrings];

    NS_DURING

        XRDecoder *decoder;
        XREMethodCall *methodCall;
        id result;
        
        // use the XRDecoder to decode the request
        decoder = [XRDecoder decoderWithData:xmlRequest];
        methodCall = [decoder decodeObject];

        EDLog1(XRLogXML, @"** parsed request tree:\n%@", methodCall);

        result = [self performMethod:[methodCall selector] withObjects:[methodCall parameters] credentials:credentials];
        
        [xmlContent appendString:@"<params>"];
        
        if(result != nil)
        {
            [xmlContent appendString:@"<param><value>"];
            [coder encodeObject:result];
            [xmlContent appendString:@"</value></param>"];
        }
        [xmlContent appendString:@"</params>"];

    NS_HANDLER

        if([localException name] == XRAuthorizationRequiredException)
            [localException raise]; // re-raise

        EDLog2(XRLogMessage, @"Caught %@ exception while performingMessage: %@", [localException name], [localException reason]);

        [xmlContent appendString:@"<fault><value>"];
        [coder encodeObject:localException];
        [xmlContent appendString:@"</value></fault>"];

    NS_ENDHANDLER
		
    [xmlContent appendString:@"</methodResponse>"];
    EDLog1(XRLogMessage, @"Assembled response:\n%@", xmlContent);
    xmlResponse = [xmlContent dataUsingEncoding:NSUTF8StringEncoding];
    return xmlResponse;
}


// this might raise if the request is buggy
- (id)performMethod:(NSString *)method withObjects:(NSArray *)objects credentials:(XRHTTPAuthenticationCredentials *)credentials
{
    id <NSObject, XRHTTPAuthenticationHandler> authHandler;
    XRInvocation *invocation;
    id result;

    NSAssert([self isServer], @"Attempt to performMethod:withObjects: on client connection!");

    authHandler = [self _currentAuthHandlerForMethod:method];
    if(authHandler != nil)
    {
        if(credentials == nil || [authHandler canAuthenticateCredentials:credentials] == NO)
        {
            NSException *exception;
            NSDictionary *userInfo;
            NSString *reason;

            reason = [NSString stringWithFormat:@"Authorization required for method '%@'.", method];
            userInfo = [NSDictionary dictionaryWithObjectsAndKeys:authHandler, XRAuthenticationHandlerKey, method, XRAuthenticationRealmKey, nil];
            exception = [[NSException alloc] initWithName:XRAuthorizationRequiredException reason:reason userInfo:userInfo];
            [exception raise];
        }
    }
    
    invocation = [invocationStorage invocationForMethod:method xmlrpcArgumentTypes:[XRMethodSignature xmlrpcTypesForObjects:objects]];
    if(invocation == nil)
    {
        if([[invocationStorage methodSignaturesForMethod:method] count] == 0)
        {
            [NSException raise:XRDoesNotRecognizeSelectorException format:@"Method '%@' not defined!", method];
        }
        else
        {
            NSArray *signatures;

            signatures = [[invocationStorage methodSignaturesForMethod:method] arrayByMappingWithSelector:@selector(getXRArgumentTypes)];
            [NSException raise:XRInvalidArgumentsException format:@"Invalid argument types for method '%@'! Received arguments have signature of '%@' but method instead has these signatures: '%@'.", method, [XRMethodSignature xmlrpcTypesForObjects:objects], [signatures componentsJoinedByString:@", "]];
        }
    }

    NS_DURING
        [invocation setArguments:objects];
    NS_HANDLER
        [NSException raise:XRInvalidArgumentsException format:[localException reason]];
    NS_ENDHANDLER

    [invocation invoke];
    result = [invocation returnValue];
    return result;
}


//------------------
//  XRServing
//  Protocol
//------------------


- (NSArray *)invocationsForXMLRPC
{
    NSMutableArray *invocations;
    
    invocations = [NSMutableArray array];
    [invocations addObject:[XRConnection invocationForXMLRPCMethod:@"listMethods" withXMLRPCTypes:@"a" mappedToSelector:@selector(_listAllPublicMethods) atObject:self]];
    [invocations addObject:[XRConnection invocationForXMLRPCMethod:@"methodHelp" withXMLRPCTypes:@"ss" mappedToSelector:@selector(_methodHelp:) atObject:self]];
    [invocations addObject:[XRConnection invocationForXMLRPCMethod:@"methodSignature"  withXMLRPCTypes:@"as" mappedToSelector:@selector(_methodSignature:) atObject:self]];
    [invocations addObject:[XRConnection invocationForXMLRPCMethod:@"multicall" withXMLRPCTypes:@"aa" mappedToSelector:@selector(_multicall:) atObject:self]];
    [invocations addObject:[XRConnection invocationForXMLRPCMethod:@"isAlive" withXMLRPCTypes:@"b" mappedToSelector:@selector(_isAlive) atObject:self]];
    return invocations;
}


//------------------
//  SERVER
//  XMLRPC
//  METHODS
//------------------


- (NSArray *)_listAllPublicMethods
{
    NSMutableArray *selectors = [NSMutableArray array];
    NSEnumerator *hEnum = [handleObjectLUT keyEnumerator];
    NSString *handle;
    
    while((handle = [hEnum nextObject]) != nil)
    {
        id <NSObject, XRServing> object;
        object = [self objectForHandle:handle];
        
        if([object conformsToProtocol:@protocol(XRListing)])
        {
            NSEnumerator *selEnum;
            NSString *selector;

            if([handle isEqualToString:EMPTY_PROXY_HANDLE])
                handle = nil;

            selEnum = [[(id <XRListing>)object listPublicXMLRPCMethods] objectEnumerator];
            while((selector = [selEnum nextObject]) != nil)
            {
                if(handle != nil)
                    [selectors addObject:[NSString stringWithFormat:@"%@.%@", handle, selector]];
                else
                    [selectors addObject:selector];
            }
        }
    }
    return selectors;
}

- (NSString *)_methodHelp:(NSString *)method
{
    NSString *text = [methodDescriptionLUT objectForKey:method];
    if(text == nil)
        text = @"";
    return text;
}

// Multicall RFC: http://www.xmlrpc.com/discuss/msgReader$1208
- (NSArray *)_multicall:(NSArray *)boxcar
{
    NSEnumerator *mcrEnum = [boxcar objectEnumerator];
    NSDictionary *methodCallRequest;
    NSMutableArray *results = [NSMutableArray array];

    while((methodCallRequest = [mcrEnum nextObject]) != nil)
    {
        NSString *method = [methodCallRequest objectForKey:@"methodName"];
        NSArray *parameters = [methodCallRequest objectForKey:@"params"];
        id result;

        NS_DURING

            if(method == nil || parameters == nil)
                [NSException raise:NSGenericException format:@"Malformed system.multicall request, missing method and/or parameters"];

            if([parameters isKindOfClass:[NSArray class]] == NO)
                [NSException raise:NSGenericException format:@"Malformed system.multicall request, 'params' attribute must be an array"];

            if(flags.isRecursiveMulticallAllowed == NO)
                if([method isEqualToString:@"system.multicall"])
                    [NSException raise:NSInvalidArgumentException format:@"Recursive system.multicall forbidden"];

            // NOTE: We don't have any clue as to what the credentials are right now, because our decoupled API
            // doesn't leave a trace as to what the HTTP request might have looked like.
            // On the one hand, we might have been able to derive a correct authorization from the initial HTTP request,
            // but on the other hand there might be all sorts of different schemes required for any of the methods in
            // the boxcar.
            // My conclusion is to leave the whole issue as is, because there's no trivial solution to the problem.
            // Authorization is probably not manageable with multicall.

            result = [self performMethod:method withObjects:parameters credentials:nil];
            if(result == nil)
                result = [NSNull null];
            result = [NSArray arrayWithObject:result]; // see RFC

        NS_HANDLER

            result = localException;

        NS_ENDHANDLER
        
        [results addObject:result];
    }
    return results;
}

- (id)_methodSignature:(NSString *)method
{
    NSArray *signatures;
    NSEnumerator *sEnum;
    XRMethodSignature *signature;
    NSMutableArray *_signatures;

    signatures = [invocationStorage methodSignaturesForMethod:method];
    if(signatures == nil || [signatures count] == 0)
        return @"no signature found";

    _signatures = [NSMutableArray array];
    sEnum = [signatures objectEnumerator];
    while((signature = [sEnum nextObject]) != nil)
    {
        NSMutableArray *types = [[[NSMutableArray allocWithZone:[self zone]] initWithCapacity:[signature numberOfArguments] - 1] autorelease];
        int i, argc = [signature numberOfArguments];

        for(i = 0; i < argc; i++)
        {
            if(i != 1)
            {
                unichar xrType = [signature getXRArgumentTypeAtIndex:i];
                [types addObject:[XRMethodSignature tagValueForXMLRPCType:xrType]];
            }
        }
        [_signatures addObject:types];
    }
    return _signatures;
}

- (NSNumber *)_isAlive
{
    return [NSNumber numberWithBool:[self isRunning]];
}



//------------------
//  XRListing
//  Protocol
//------------------


- (NSArray *)listPublicXMLRPCMethods
{
    return [NSArray arrayWithObjects:@"listMethods", @"methodHelp", @"methodSignature", @"isAlive", @"multicall", nil];
}

- (NSString *)descriptionForXMLRPCMethod:(NSString *)selector;
{
    if([selector isEqualToString:@"listMethods"])
        return @"This method lists all the methods that the XML-RPC server knows how to dispatch.";
    else if([selector isEqualToString:@"methodHelp"])
        return @"Returns help text if defined for the method passed, otherwise returns an empty string.";
    else if([selector isEqualToString:@"methodSignature"])
        return @"Returns an array of known signatures (an array of arrays) for the method name passed. If no signatures are known, returns a none-array (test for type != array to detect missing signature).";
    else if([selector isEqualToString:@"isAlive"])
        return @"Test method for clients to see whether the server is still responsive/reachable.";
    else if([selector isEqualToString:@"multicall"])
        return @"Implementation of multicall RFC, see http://www.xmlrpc.com/discuss/msgReader$1208.";
    return nil;
}


////////////////////////////////////////////////////
//
//  BACKGROUND COMMS
//
////////////////////////////////////////////////////


- (void)didAcceptConnection:(NSNotification *)notification
{
    NSFileHandle *socket;
    
    socket = [[notification userInfo] objectForKey:NSFileHandleNotificationFileHandleItem];
    EDLog1(XRLogConnection, @"didAcceptConnection on socket %@, registering for reads", socket);
    [DNC addObserver:self selector:@selector(receiveMessage:) name:NSFileHandleReadCompletionNotification object:socket];
    [socket retain]; // retain the socket, we need it later on
    [socket readInBackgroundAndNotify];
    
    // we're running asynchronously here and somebody might have changed our state
    if([self isRunning])
        [serverSocket acceptConnectionInBackgroundAndNotify];
}

- (void)receiveMessage:(NSNotification *)notification
{
    NSFileHandle *senderSocket;
    NSData *rawRequest;
    
    senderSocket = [notification object];

    rawRequest = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];

    EDLog2(XRLogConnection, @"receiveMessage:%@ socket:%@", rawRequest, senderSocket);

    // Test if the rawRequest is empty. If this is true it means that the remote
    // side closed the connection
    
    if([rawRequest length] == 0)
    {
        EDLog1(XRLogConnection, @"Remote side closed the socket %@, dumping data.", senderSocket);
        [DNC removeObserver:self name:NSFileHandleReadCompletionNotification object:senderSocket];
        [self removeCachedDataForSocket:senderSocket];
        [senderSocket release]; // release the socket, the remote end's gone
        return;
    }

    // Now dispatch the things
    // push things on a queue (they might be incomplete)
    // if we know the request is complete, we can safely remove ourselves as observers
    // and finally answer the request

    if([self appendReceivedData:rawRequest socket:senderSocket])
    {
        [DNC removeObserver:self name:NSFileHandleReadCompletionNotification object:senderSocket];
        rawRequest = [self cachedDataForSocket:senderSocket];
        [self handleMessage:rawRequest socket:senderSocket];
        [self removeCachedDataForSocket:senderSocket];
        [senderSocket release]; // release the socket, since we won't receive any notifications from now on anyways
    }
    else
    {
        // continue reading until we think we're done
        [senderSocket readInBackgroundAndNotify];
    }
}


//------------------
// HELPERS
//------------------


// also signals completeness of data
- (BOOL)appendReceivedData:(NSData *)data socket:(NSFileHandle *)socket
{
    NSMutableData *_cachedData;
    NSNumber *cacheKey;
    NSString *_cachedDataString;

    cacheKey = [NSNumber numberWithInt:[socket fileDescriptor]];
    _cachedData = [connDataLUT objectForKey:cacheKey];
    if(_cachedData == nil)
    {
        _cachedData = [NSMutableData dataWithData:data];
        [connDataLUT setObject:_cachedData forKey:cacheKey];
    }
    else
    {
        [_cachedData appendData:data];
    }

// We assume the encoding is UTF-8, because scanning is pretty expensive.
    _cachedDataString = [NSString stringWithData:_cachedData encoding:NSUTF8StringEncoding];
    return [_cachedDataString rangeOfString:@"</methodCall>" options:NSBackwardsSearch].length > 0;
}

- (NSData *)cachedDataForSocket:(NSFileHandle *)socket
{
    return [connDataLUT objectForKey:[NSNumber numberWithInt:[socket fileDescriptor]]];
}

- (void)removeCachedDataForSocket:(NSFileHandle *)socket
{
    [connDataLUT removeObjectForKey:[NSNumber numberWithInt:[socket fileDescriptor]]];
}


////////////////////////////////////////////////////
//
//  RUNLOOP
//
////////////////////////////////////////////////////


- (void)runInNewThread
{
    NSAssert([self isServer], @"Attempt to run a client connection as server!");
    NSAssert([self isRunning] == NO, @"Attempt to start connection server which is already running!");
    
    EDLog1(XRLogDebug, @"connection %@ entering server mode", self);
    flags.isRunning = YES; // this can be cancelled by a stop operation
    
    [self registerObject:self forHandle:@"system"]; // careful, possible retain cycle
    
    [DNC addObserver:self selector:@selector(didAcceptConnection:) name:NSFileHandleConnectionAcceptedNotification object:serverSocket];
    
    [serverSocket acceptConnectionInBackgroundAndNotify];
}

- (void)stop
{
    NSAssert([self isServer], @"Attempt to stop a client connection which cannot be run!");
    NSAssert([self isRunning], @"Attempt to stop a connection which is not running!");

    [DNC removeObserver:self name:NSFileHandleConnectionAcceptedNotification object:serverSocket];
    [self unregisterObjectForHandle:@"system"];
    flags.isRunning = NO;
    EDLog1(XRLogDebug, @"connection %@ leaving server mode", self);
}

- (void)invalidate
{
    NSEnumerator *pEnum;
    NSValue *proxyValue;

    NSAssert([self isValid], @"Attempt to invalidate an already invalidated connection!");

    EDLog1(XRLogConnection, @"Connection %@ will be invalidated now.", self);
    if(flags.shouldPerformConnectionChecks)
        [self _stopCurrentConnectionCheckTimer];

    // post XRConnectionDidDieNotification
    [DNC postNotificationName:XRConnectionDidDieNotification object:self];

    // invalidate all proxies
    pEnum = [proxyLUT objectEnumerator];
    while((proxyValue = [pEnum nextObject]) != nil)
    {
        XRProxy *aProxy = [proxyValue nonretainedObjectValue];
        [aProxy _setConnectionIsInvalid];
    }
}


////////////////////////////////////////////////////
//
//  CONNECTION
//  EXTENSIONS
//
////////////////////////////////////////////////////


- (void)_startNewConnectionCheckTimer
{
    connectionCheckTimer = [[NSTimer scheduledTimerWithTimeInterval:connectionCheckInterval target:self selector:@selector(_performRemoteConnectionCheck:) userInfo:nil repeats:NO] retain];
}

- (void)_stopCurrentConnectionCheckTimer
{
    [connectionCheckTimer invalidate];
    [connectionCheckTimer release];
    connectionCheckTimer = nil;
}

- (void)_resetConnectionCheckTimer
{
    [self _stopCurrentConnectionCheckTimer];
    [self _startNewConnectionCheckTimer];
}

- (void)_performRemoteConnectionCheck:(NSTimer *)timer
{
    NS_DURING
    
        BOOL isAlive;
        
        EDLog1(XRLogConnection, @"_performRemoteConnectionCheck: for connection %@", self);
        if(flags.delegateRespondsToIsConnectionAlive)
            isAlive = [delegate isConnectionAlive:self];
        else
            isAlive = [[self performRemoteMethod:@"system.isAlive"] boolValue];
        if(isAlive == NO)
            [NSException raise:NSGenericException format:@"remote end claims isAlive == NO"];

    NS_HANDLER

        EDLog3(XRLogConnection, @"_performRemoteConnectionCheck: for connection %@ failed, %@:%@", self, [localException name], [localException reason]);
        if([self isValid])
            [self invalidate];

    NS_ENDHANDLER
}


- (void)setShouldPerformConnectionChecks:(BOOL)yn
{
    flags.shouldPerformConnectionChecks = yn;
    if(yn)
        [self _startNewConnectionCheckTimer];
    else
        [self _stopCurrentConnectionCheckTimer];
}

- (void)setConnectionCheckInterval:(NSTimeInterval)interval
{
    connectionCheckInterval = interval;
}


////////////////////////////////////////////////////
//
//  PRIVATE API
//
////////////////////////////////////////////////////


- (BOOL)isServer
{
    return remoteURL == nil;
}

- (BOOL)isRunning
{
    return flags.isRunning;
}

- (BOOL)isValid
{
    return flags.isValid;
}

- (void)_shutdown
{
    if([self isRunning])
        [self stop];
    [serverSocket shutdown];
    [serverSocket closeFile];
    [serverSocket release];
    serverSocket = nil;
}


////////////////////////////////////////////////////
//
//  DELEGATE
//
////////////////////////////////////////////////////


- (void)setDelegate:(id)aDelegate
{
    delegate = aDelegate;

    // check delegate's capabilities
    flags.delegateRespondsToClassOfProxyWithHandle = [delegate respondsToSelector:@selector(classOfProxyWithHandle:forConnection:)];
    flags.delegateRespondsToIsConnectionAlive = [delegate respondsToSelector:@selector(isConnectionAlive:)];
}

- (id)delegate
{
    return delegate;
}


////////////////////////////////////////////////////
//
//  MISC ATTRIBUTES
//
////////////////////////////////////////////////////


- (void)setAllowsRecursiveMulticall:(BOOL)yn
{
    flags.isRecursiveMulticallAllowed = yn;
}

- (void)setShouldEncodeObjectsUsingNSCodingIfPossible:(BOOL)yn
{
    flags.shouldEncodeObjectsUsingNSCodingIfPossible = yn;
}

- (void)setEncodesNullValuesAsRFCDataType:(BOOL)yn
{
    flags.shouldEncodeNullValuesAsRFCDataType = yn;
}

- (void)setUsesNonXMLConformantEncodingForStrings:(BOOL)yn
{
    flags.usesNonXMLConformantEncodingForStrings = yn;
}


////////////////////////////////////////////////////
//
//  DEBUGGING
//
////////////////////////////////////////////////////


- (NSString *)description
{
    NSMutableString *desc = [[[NSMutableString allocWithZone:[self zone]] init] autorelease];
    NSString *port;

    [desc appendFormat:@"<%@ 0x%x:", NSStringFromClass(isa), self];
    if([serverSocket isKindOfClass:[EDIPSocket class]])
        port = [NSString stringWithFormat:@"%d", [(EDIPSocket *)serverSocket localPort]];
    else
        port = @"N/A";

    if([self isServer])
        [desc appendFormat:@" SERVER (PORT=%@ MODE=%@)", port, [self isRunning] ? @"running" : @"stopped"];
    else
        [desc appendFormat:@" URL=%@%@", [remoteURL description], flags.shouldPerformConnectionChecks ? [NSString stringWithFormat:@" (performs connection check every %g seconds)", connectionCheckInterval] : @""];
    [desc appendString:@">"];
    return desc;
}

@end
