//
//  XRMethodSignature.m
//  XMLRPC
//
//  Created by znek on Sat Aug 18 2001.
//  $Id: XRMethodSignature.m,v 1.7 2003/03/28 13:12:02 znek Exp $
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


#include "XRMethodSignature.h"
#include <EDCommon/EDCommon.h>

#ifdef XMLRPC_OSXSBUILD
#include "Future.h"
#endif


@interface NSNumber (PrivateAPI_WeKnowExists)
// this is private, but we need it
- (const STR)objCType;
@end


@implementation XRMethodSignature

////////////////////////////////////////////////////
//
//   HELPERS
//
////////////////////////////////////////////////////


+ (NSString *)xmlrpcTypesForObjects:(NSArray *)objects
{
    static Class arrayClass = Nil;
    static Class dictionaryClass = Nil;
    static Class dateClass = Nil;
    static Class dataClass = Nil;
    static Class numberClass = Nil;
    
    NSMutableString *types;
    int i, count;

    if(objects == nil)
        return nil;

    if(arrayClass == Nil)
        arrayClass = [NSArray class];

    if(dictionaryClass == Nil)
        dictionaryClass = [NSDictionary class];

    if(dateClass == Nil)
        dateClass = [NSDate class];

    if(dataClass == Nil)
        dataClass = [NSData class];

    if(numberClass == Nil)
        numberClass = [NSNumber class];


    count = [objects count];
    types = [NSMutableString string];

    for(i = 0; i < count; i++)
    {
        id object = [objects objectAtIndex:i];

        if([object isKindOfClass:arrayClass])
            [types appendString:@"a"]; // array
        else if([object isKindOfClass:dictionaryClass])
            [types appendString:@"S"]; // struct
        else if([object isKindOfClass:dateClass])
            [types appendString:@"t"]; // dateTime.iso8601
        else if([object isKindOfClass:dataClass])
            [types appendString:@"B"]; // base64
        else if([object isKindOfClass:numberClass])
        {
            // it's necessary to inspect the real objCType of NSNumber
            // due to the nature of its implementation
            // see XREncoder.m for a more exhaustive explanation
            char objcType = *[(NSNumber *)object objCType];

            if(objcType == _C_CHR || objcType == _C_UCHR)
                [types appendString:@"b"]; // boolean
            else if(objcType == _C_DBL)
                [types appendString:@"d"]; // double
            else if(objcType == _C_FLT)
                [types appendString:@"d"]; // double
            else
                [types appendString:@"i"]; // int
        }
        else
            [types appendString:@"s"]; // string, default for all classes (including string)
    }
    return types;
}

+ (NSString *)tagValueForXMLRPCType:(unichar)xrType
{
    if(xrType == 'i')
        return @"int";
    else if(xrType == 'b')
        return @"boolean";
    else if(xrType == 's')
        return @"string";
    else if(xrType == 'd')
        return @"double";
    else if(xrType == 't')
        return @"dateTime.iso8601";
    else if(xrType == 'B')
        return @"base64";
    else if(xrType == 'S')
        return @"struct";
    else if(xrType == 'a')
        return @"array";

    [NSException raise:NSInvalidArgumentException format:@"Unknown XML-RPC Type '%@'", [NSString stringWithCharacters:&xrType length:1]];
    return nil; // keep compiler happy
}


////////////////////////////////////////////////////
//
//   FACTORY
//
////////////////////////////////////////////////////


+ (id)signatureWithXMLRPCTypes:(NSString *)types objcSignature:(NSMethodSignature *)signature
{
    return [[[self alloc] initWithXMLRPCTypes:types objcSignature:signature] autorelease];
}


////////////////////////////////////////////////////
//
//  INIT & DEALLOC
//
////////////////////////////////////////////////////


- (id)initWithXMLRPCTypes:(NSString *)types objcSignature:(NSMethodSignature *)signature
{
    [super init];

    objcSignature = [signature retain];
    argTypes = [[NSMutableArray allocWithZone:[self zone]] initWithCapacity:[signature numberOfArguments]];
    [self setXMLRPCTypes:types];
    return self;
}

- (void)dealloc
{
    [objcSignature release];
    [argTypes release];
    [super dealloc];
}


////////////////////////////////////////////////////
//
//  XMLRPC EXTENSIONS
//
////////////////////////////////////////////////////


- (NSMethodSignature *)objcSignature
{
    return objcSignature;
}

- (void)setXMLRPCTypes:(NSString *)types
{
    static NSCharacterSet *validXRTypeSet = nil;
    EDStringScanner *scanner;
    int i, count;

    if(validXRTypeSet == nil)
        validXRTypeSet = [[NSCharacterSet characterSetWithCharactersInString:@"ibsdtBSa"] retain];

    if(objcSignature != nil)
        NSAssert2([types length] == [objcSignature numberOfArguments] - 1, @"incorrect argument count, expected %d arguments instead of %d", [objcSignature numberOfArguments] - 1, [types length]);

    scanner = [EDStringScanner scannerWithString:types];
    count = [types length];
    for(i = 0; i < count; i++)
    {
        unichar xrType;
        
        xrType = [scanner getCharacter];
        if([validXRTypeSet characterIsMember:xrType] == NO)
            [NSException raise:NSInvalidArgumentException format:@"found unknown signature '%@'", [NSString stringWithCharacters:&xrType length:1]];
        [argTypes addObject:[NSString stringWithCharacters:&xrType length:1]];
    }
    
}

- (NSString *)getXRArgumentTypes
{
    if([self numberOfArguments] == 0)
        return @"";
    return [[argTypes subarrayFromIndex:1] componentsJoinedByString:@""];
}

// this is index compatible to - (const char *)getArgumentTypeAtIndex:(unsigned)index
- (unichar)getXRArgumentTypeAtIndex:(unsigned)index
{
    if(index == 1)
        return ':'; // compatibility
    if(index > 1)
        index--;
    return [[argTypes objectAtIndex:index] characterAtIndex:0];
}

- (unichar)methodReturnType
{
    return [self getXRArgumentTypeAtIndex:0];
}

- (unsigned int)numberOfArguments
{
    return [argTypes count] + 1;
}

- (BOOL)needsObjcScalarConversionForArgumentTypeAtIndex:(unsigned)index
{
    char objcType;

    if(objcSignature == nil)
        return NO;

    objcType = *[objcSignature getArgumentTypeAtIndex:index];
    if(objcType != _C_ID)
        if(objcType != _C_VOID && index != 0)
            return YES;
    return NO;
}

@end
