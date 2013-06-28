//
//  XRConstants.h
//  XMLRPC
//
//  Created by znek on Wed Aug 15 2001.
//  $Id: XRConstants.h,v 1.7 2003/01/03 16:15:23 znek Exp $
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


#ifndef	__XRConstants_h_INCLUDE
#define	__XRConstants_h_INCLUDE


#import <Foundation/Foundation.h>


extern NSString *XRConnectionDidDieNotification;

extern NSString *XRAuthorizationRequiredException;
extern NSString *XRDoesNotRecognizeSelectorException;
extern NSString *XRInvalidArgumentsException;
extern NSString *XRRemoteException;
extern NSString *XRHTTPException;

extern NSString *XRRemoteErrorCodeKey;
extern NSString *XRRemoteErrorStringKey;
extern NSString *XRAuthenticationHandlerKey;
extern NSString *XRAuthenticationRealmKey;
extern NSString *XRHTTPErrorCodeKey;
extern NSString *XRHTTPErrorStringKey;

/*
 Specification for Fault Code Interoperability, version 20010516
 http://xmlrpc-epi.sourceforge.net/specs/rfc.fault_codes.php

 -32700 ---> parse error. not well formed
 -32701 ---> parse error. unsupported encoding
 -32702 ---> parse error. invalid character for encoding
 -32600 ---> server error. invalid xml-rpc. not conforming to spec.
 -32601 ---> server error. requested method not found
 -32602 ---> server error. invalid method parameters
 -32603 ---> server error. internal xml-rpc error
 -32500 ---> application error
 -32400 ---> system error
 -32300 ---> transport error

 In addition, the range -32099 .. -32000, inclusive is reserved for implementation defined server errors. Server errors which do not cleanly map to a specific error defined by this spec should be assigned to a number in this range. This leaves the remainder of the space available for application defined errors.
 */

extern const int XRUnspecifiedErrorCode; // -32000
extern const int XRDoesNotRecognizeSelectorErrorCode; // -32601
extern const int XRInvalidArgumentsErrorCode; // -32602
extern const int XRXMLParserErrorCode; // -32700

#endif	/* __XRConstants_h_INCLUDE */
