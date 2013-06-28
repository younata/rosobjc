//
//  XRHTTPAuthenticationHandler.h
//  XMLRPC
//
//  Created by znek on Mon Jul 08 2002.
//  $Id: XRHTTPAuthenticationHandler.h,v 1.1 2002/07/18 00:11:35 znek Exp $
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


#ifndef	__XRHTTPAuthenticationHandler_h_INCLUDE
#define	__XRHTTPAuthenticationHandler_h_INCLUDE


#import <Foundation/Foundation.h>

@class XRHTTPAuthenticationCredentials;


@protocol XRHTTPAuthenticationHandler

/*" i.e. Basic. This value should be treated case-insensitive, although it's likely to have case. "*/
- (NSString *)scheme;

- (BOOL)canAuthenticateCredentials:(XRHTTPAuthenticationCredentials *)credentials;

/*"see RFC2617 page 5, i.e. Basic realm="Wally's World" "*/
- (NSString *)challengeForAuthenticationRealm:(NSString *)realm;

/*" see RFC2617 page 5, i.e. Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ== "*/
- (NSString *)credentials;

@end

#endif	/* __XRHTTPAuthenticationHandler_h_INCLUDE */
