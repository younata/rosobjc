//
//  functionaltests_main.m
//  XMLRPC
//
//  Created by znek on Tue Aug 14 2001.
//  $Id: functionaltests_main.m,v 1.4 2003/03/28 13:12:09 znek Exp $
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


#import <Foundation/Foundation.h>
#include <EDCommon/EDCommon.h>
#include <XMLRPC/XMLRPC.h>
#include <XMLRPC/NSCalendarDate+ISO8601.h>


int main(int argc, const char *argv[])
{
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    XREncoder *coder;
    NSMutableString *coderBuffer;

    NSString *string;
    NSDate *date;
    NSNumber *number;
    NSData *data;
    NSArray *array;
    NSDictionary *dictionary;
    id object;

    coderBuffer = [NSMutableString string];
    coder = [XREncoder encoderWithBuffer:coderBuffer];

    string = @"GŸten Tag! <> haha";
    date = [NSDate date];
    data = [string dataUsingEncoding:NSUTF8StringEncoding];
    object = [NSURL URLWithString:@"http://www.mulle-kybernetik.com"];
    array = [NSArray arrayWithObjects:string, object, date, nil];
    dictionary = [NSDictionary dictionaryWithObjectsAndKeys:date, @"date", string, @"string", object, @"url", nil];

    EDLogMask = 0xffff;
    EDLog(XRLogDebug, @"=== TESTING BASE DATATYPES ===");

    EDLog(XRLogDebug, @"Expecting: G\\U00fcten Tag! &lt;&gt; haha");
    [coder encodeString:string];
    EDLog1(XRLogDebug, @"string = %@", coderBuffer);
    [coderBuffer deleteCharactersInRange:NSMakeRange(0, [coderBuffer length])];

    EDLog(XRLogDebug, @"Expecting: <dateTime.iso8601>...</dateTime.iso8601>");
    [coder encodeDate:date];
    EDLog1(XRLogDebug, @"date = %@", coderBuffer);
    [coderBuffer deleteCharactersInRange:NSMakeRange(0, [coderBuffer length])];

    EDLog(XRLogDebug, @"Expecting: <base64>R8O8dGVuIFRhZyEgPD4gaGFoYQ==</base64>");
    [coder encodeData:data];
    EDLog1(XRLogDebug, @"data = %@", coderBuffer);
    [coderBuffer deleteCharactersInRange:NSMakeRange(0, [coderBuffer length])];


    EDLog(XRLogDebug, @"Expecting: <array>...</array>");
    [coder encodeArray:array];
    EDLog1(XRLogDebug, @"array = %@", coderBuffer);
    [coderBuffer deleteCharactersInRange:NSMakeRange(0, [coderBuffer length])];


    EDLog(XRLogDebug, @"Expecting: <struct>...</struct>");
    [coder encodeDictionary:dictionary];
    EDLog1(XRLogDebug, @"dictionary = %@", coderBuffer);
    [coderBuffer deleteCharactersInRange:NSMakeRange(0, [coderBuffer length])];


    EDLog(XRLogDebug, @"=== TESTING TRANSPARENT OBJECT ENCODING ===");

    EDLog(XRLogDebug, @"Expecting: <string>http://www.mulle-kybernetik.com</string>");
    [coder encodeObject:object];
    EDLog1(XRLogDebug, @"object = %@", coderBuffer);
    [coderBuffer deleteCharactersInRange:NSMakeRange(0, [coderBuffer length])];

    [coder setEncodesObjectsUsingNSCodingIfPossible:YES];

    EDLog(XRLogDebug, @"Expecting: <base64 xr:objc-type=\"NSURL\">BAt0eXBlZHN0cmVhbYED6IQBQISEhAVOU1VSTACEhAhOU09iamVjdACFhAFjAJKEhIQITlNTdHJpbmcBlIQBKx9odHRwOi8vd3d3Lm11bGxlLWt5YmVybmV0aWsuY29thoY=</base64>");
    [coder encodeObject:object];
    EDLog1(XRLogDebug, @"object = %@", coderBuffer);
    [coderBuffer deleteCharactersInRange:NSMakeRange(0, [coderBuffer length])];


    EDLog(XRLogDebug, @"=== TESTING DATE ENCODING ===");
    date = [NSCalendarDate dateWithISO8601Representation:@"19980717T14:08:55"];

    EDLog(XRLogDebug, @"Expecting: <dateTime.iso8601>19980717T16:08:55</dateTime.iso8601>");
    [coder encodeDate:date];
    EDLog1(XRLogDebug, @"reference date = %@", coderBuffer);
    [coderBuffer deleteCharactersInRange:NSMakeRange(0, [coderBuffer length])];


    EDLog(XRLogDebug, @"=== TESTING TRANSPARENT NUMBER ENCODINGS ===");
    number = [NSNumber numberWithInt:-3];
    [coder encodeNumber:number];
    EDLog(XRLogDebug, @"Expecting: <int>-3</int>");
    EDLog1(XRLogDebug, @"number = %@", coderBuffer);
    [coderBuffer deleteCharactersInRange:NSMakeRange(0, [coderBuffer length])];

    number = [NSNumber numberWithBool:YES];
    [coder encodeNumber:number];
    EDLog(XRLogDebug, @"Expecting: <boolean>1</boolean>");
    EDLog1(XRLogDebug, @"number = %@", coderBuffer);
    [coderBuffer deleteCharactersInRange:NSMakeRange(0, [coderBuffer length])];

    number = [NSNumber numberWithDouble:123.456789];
    [coder encodeNumber:number];
    EDLog(XRLogDebug, @"Expecting: <double>123.456789</double>");
    EDLog1(XRLogDebug, @"number = %@", coderBuffer);
    [coderBuffer deleteCharactersInRange:NSMakeRange(0, [coderBuffer length])];

    [pool release];
    exit(0); // insure the process exit status is 0
    return 0; // keep compiler happy
}
