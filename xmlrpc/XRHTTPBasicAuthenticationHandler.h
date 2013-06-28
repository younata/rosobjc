//
//  XRHTTPBasicAuthenticationHandler.h
//  XMLRPC
//
//  Created by znek on Mon Jul 08 2002.
//  $Id: XRHTTPBasicAuthenticationHandler.h,v 1.2 2003/03/28 13:12:02 znek Exp $
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


#ifndef	__XRHTTPBasicAuthenticationHandler_h_INCLUDE
#define	__XRHTTPBasicAuthenticationHandler_h_INCLUDE


#import <Foundation/Foundation.h>
#include "XRHTTPAuthenticationHandler.h"


@interface XRHTTPBasicAuthenticationHandler : NSObject <XRHTTPAuthenticationHandler>
{
    NSString *authenticationBlurb;
}

+ (id)authHandlerWithUser:(NSString *)user password:(NSString *)password;
- (id)initWithUser:(NSString *)user password:(NSString *)password;

@end

#endif	/* __XRHTTPBasicAuthenticationHandler_h_INCLUDE */
