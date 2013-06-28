//
//  XRHTTPMessage.h
//  XMLRPC
//
//  Created by znek on Tue Aug 14 2001.
//  $Id: XRHTTPMessage.h,v 1.3 2002/07/10 00:38:05 znek Exp $
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


#ifndef	__XRHTTPMessage_h_INCLUDE
#define	__XRHTTPMessage_h_INCLUDE


#import <Foundation/Foundation.h>


@interface XRHTTPMessage : NSObject
{
	NSMutableDictionary *headersLUT;
	NSString *httpVersion;
	NSStringEncoding contentEncoding;
	NSData *content;
}

- (id)initWithTransferData:(NSData *)data;

- (NSArray *)headerKeys;
- (void)setHeader:(NSString *)aHeader forKey:(NSString *)aKey;
- (void)setHeaders:(NSArray *)headers forKey:(NSString *)aKey;
- (NSArray *)headersForKey:(NSString *)aKey;
- (NSString *)headerForKey:(NSString *)aKey;

- (void)setHTTPVersion:(NSString *)aVersion;
- (NSString *)httpVersion;

- (void)setContent:(NSData *)data;
- (NSData *)content;
- (void)setContentEncoding:(NSStringEncoding)anEncoding;
- (NSStringEncoding)contentEncoding;

@end

#endif	/* __XRHTTPMessage_h_INCLUDE */
