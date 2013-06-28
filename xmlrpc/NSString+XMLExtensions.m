//---------------------------------------------------------------------------------------
// created as NSString+Extensions.m by znek on Sat 03-Mar-2001
// $Id: NSString+XMLExtensions.m,v 1.8 2003/04/04 02:01:54 znek Exp $
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


#include <EDCommon/EDCommon.h>
#include "NSString+XMLExtensions.h"


@implementation NSString (XRExtensions)

/*
- (NSString *)stringByDecodingEntityEncoding
{
    static NSDictionary *replaceLUT = nil;
    NSMutableString *decodedString = nil;
    NSString *decodedEntity;
    NSRange range;
    int i, entityStartPos, prevLocation = 0, count = [self length];
    unichar stopChar = '&';


    if(replaceLUT == nil)
    {
        NSString *path;
        path = [[NSBundle bundleForClass:NSClassFromString(@"XMLRPCFramework")] pathForResource:@"Entity2String" ofType:@"plist"];
        NSAssert(path != nil, @"Unable to load Entity2String.plist");
        replaceLUT = [[[NSString stringWithData:[NSData dataWithContentsOfFile:path] encoding:NSUTF8StringEncoding] propertyList] retain];
    }


    for(i = 0, entityStartPos = 0; i < count; i++)
    {
        if([self characterAtIndex:i] == stopChar)
        {
            if(stopChar == '&')
            {
                entityStartPos = i;
                stopChar = ';';
            }
            else
            {
                stopChar = '&';

                range.location = entityStartPos + 1;
                range.length = i - range.location;

                if((decodedEntity = [replaceLUT objectForKey:[self substringWithRange:range]]) != nil)
                {
                    if(decodedString == nil)
                        decodedString = [NSMutableString string];

                    range.location = prevLocation;
                    range.length = entityStartPos - range.location;
                    if(range.length > 0)
                        [decodedString appendString:[self substringWithRange:range]];
                    [decodedString appendString:decodedEntity];
                    prevLocation = i + 1;
                }
            }
        }
    }
    if(decodedString == nil)
        return self;

    [decodedString appendString:[self substringFromIndex:prevLocation]];
    return decodedString;
}
*/

- (NSString *)stringByEncodingEntities:(NSDictionary *)mapping
{
    NSMutableString *encodedString;
    EDStringScanner *scanner;

    NSAssert(mapping != nil, @"The mapping MUST NOT be nil!");

    encodedString = [[[NSMutableString alloc] init] autorelease];
    scanner = [EDStringScanner scannerWithString:self];
    while([scanner peekCharacter] != EDStringScannerEndOfDataCharacter)
    {
        unichar nextChar;
        NSString *entityString;
        nextChar = [scanner getCharacter];
        if((entityString = [mapping objectForKey:[NSString stringWithCharacters:&nextChar length:1]]) != nil)
            [encodedString appendString:entityString];
        else
            [encodedString appendString:[NSString stringWithCharacters:&nextChar length:1]];
    }
    return encodedString;
}

@end
