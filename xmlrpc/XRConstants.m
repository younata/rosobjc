//
//  XRConstants.m
//  XMLRPC
//
//  Created by znek on Wed Aug 15 2001.
//  $Id: XRConstants.m,v 1.7 2003/03/28 13:12:01 znek Exp $
//
//  Copyright (c) 2001 by Marcus M�ller <znek@mulle-kybernetik.com>.
//  All rights reserved.
//
//  Permission to use, copy, modify and distribute this software and its documentation
//  is hereby granted under the terms of the GNU Lesser General Public License, version 2.1
//  as published by the Free Software Foundation, provided that both the copyright notice
//  and this permission notice appear in all copies of the software, derivative works or
//  modified versions, and any portions thereof, and that both notices appear in supporting
//  documentation, and that credit is given to Marcus M�ller in all documents and publicity
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


#include "XRConstants.h"

NSString *XRConnectionDidDieNotification = @"XRConnectionDidDieNotification";

NSString *XRAuthorizationRequiredException = @"XRAuthorizationRequiredException";
NSString *XRDoesNotRecognizeSelectorException = @"XRDoesNotRecognizeSelectorException";
NSString *XRInvalidArgumentsException = @"XRInvalidArgumentsException";
NSString *XRRemoteException = @"XRRemoteException";
NSString *XRHTTPException = @"XRHTTPException";

NSString *XRRemoteErrorCodeKey = @"XRRemoteErrorCode";
NSString *XRRemoteErrorStringKey = @"XRRemoteErrorString";
NSString *XRAuthenticationHandlerKey = @"XRAuthHandler";
NSString *XRAuthenticationRealmKey = @"XRAuthenticationRealm";
NSString *XRHTTPErrorCodeKey = @"XRHTTPErrorCode";
NSString *XRHTTPErrorStringKey = @"XRHTTPErrorString";


const int XRUnspecifiedErrorCode = -32000;
const int XRDoesNotRecognizeSelectorErrorCode = -32601;
const int XRInvalidArgumentsErrorCode = -32602;
const int XRXMLParserErrorCode = -32700;
