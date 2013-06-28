//
//  XRMethodSignature.h
//  XMLRPC
//
//  Created by znek on Sat Aug 18 2001.
//  $Id: XRMethodSignature.h,v 1.5 2002/06/08 00:05:11 znek Exp $
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


#ifndef	__XRMethodSignature_h_INCLUDE
#define	__XRMethodSignature_h_INCLUDE


#import <Foundation/Foundation.h>


@interface XRMethodSignature : NSObject
{
    NSMethodSignature *objcSignature;
    NSMutableArray *argTypes;
}

// valid XMLRPC types:
// i : int (i4)
// b : boolean
// s : string
// d : double
// t : dateTime.iso8601
// B : base64
// S : struct
// a : array

// HELPERS

// Returns a string containing the XMLRPC types (s.a.) for the given objects in their respective order.
// Please note that this method assumes a type of 's' for anything that cannot be natively transferred via XML-RPC. 
+ (NSString *)xmlrpcTypesForObjects:(NSArray *)objects;
// Returns the tag value (that is, on a protocol level) for the given type, i.e. 'dateTime.iso8601' for a type of 't'.
+ (NSString *)tagValueForXMLRPCType:(unichar)xrType;


// The types string consists of the return type (first character) followed
// by the arguments' types in the order they appear in the Objective-C selector
+ (id)signatureWithXMLRPCTypes:(NSString *)types objcSignature:(NSMethodSignature *)signature;
- (id)initWithXMLRPCTypes:(NSString *)types objcSignature:(NSMethodSignature *)signature;

- (NSMethodSignature *)objcSignature;

- (void)setXMLRPCTypes:(NSString *)types;
- (NSString *)getXRArgumentTypes;

// this is index compatible to NSMethodSignature's - (const char *)getArgumentTypeAtIndex:(unsigned)index
- (unichar)getXRArgumentTypeAtIndex:(unsigned)index;

- (unichar)methodReturnType;
- (unsigned int)numberOfArguments;

- (BOOL)needsObjcScalarConversionForArgumentTypeAtIndex:(unsigned)index;

@end

#endif	/* __XRMethodSignature_h_INCLUDE */
