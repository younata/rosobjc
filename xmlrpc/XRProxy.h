//
//  XRProxy.h
//  XMLRPC
//
//  Created by znek on Sun Aug 19 2001.
//  $Id: XRProxy.h,v 1.5 2002/04/09 01:00:42 znek Exp $
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


#ifndef	__XRProxy_h_INCLUDE
#define	__XRProxy_h_INCLUDE


#import <Foundation/Foundation.h>

@class XRConnection;


#define USE_SELECTOR_MAPPINGS 0


@interface XRProxy : NSObject
{
    XRConnection *connection;
    BOOL _isConnectionValid;
    Protocol *protocol;
    NSString *handle;
#if USE_SELECTOR_MAPPINGS
    NSMutableDictionary *selectorMappingLUT;
#endif
}

/*"Proxy Factory"*/

+ (XRProxy *)proxyOfClass:(Class)proxyClass forConnection:(XRConnection *)aConnection withHandle:(NSString *)aHandle;

// Subclassers have to do their initialization work here
- (id)initWithConnection:(XRConnection *)aConnection handle:(NSString *)aHandle;

#if USE_SELECTOR_MAPPINGS
/*"Only available if framework has been compiled with -DUSE_SELECTOR_MAPPINGS=1"*/
// Subclassers have to override this. See XRConnection's method
// + (EDObjectPair *)mappingForXMLRPCMethod:(NSString *)method toSelector:(SEL)selector atObject:(id)object withXMLRPCTypes:(NSString *)types;
// for details
/** TypeInfo EDObjectPair */
- (NSArray *)xmlrpcMethodMappings;
#endif

/*"XML-RPC Handle"*/

- (NSString *)handle;


/*"NSDistantObject compatibility"*/

- (XRConnection *)connectionForProxy;
- (void)setProtocolForProxy:(Protocol *)proto;


/*"Subclasser helper API"*/

// API for subclassers. Use it in your wrapper methods.
// Each of these methods can raise exceptions, for local or remote reasons
- (id)performMethod:(NSString *)method;
- (id)performMethod:(NSString *)method withObject:(id)object;
- (id)performMethod:(NSString *)method withObject:(id)firstObject withObject:(id)secondObject;
- (id)performMethod:(NSString *)method withObjects:(NSArray *)objects;

@end

#endif	/* __XRProxy_h_INCLUDE */
