//
//  XREncoder.m
//  XMLRPC
//
//  Created by znek on Tue Aug 28 2001.
//  $Id: XREncoder.m,v 1.14 2003/04/04 02:26:17 znek Exp $
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


#include "XREncoder.h"
#include <EDMessage/EDMessage.h>
#include "XRProtocols.h"
#include "XRConstants.h"
#include "NSString+XMLExtensions.h"
#ifdef sun
#import <iso/limits_iso.h> // UINT_MAX (Solaris 2.8)
// #import <sys/types.h> // UINT_MAX (Solaris < 2.8)
#endif

@interface NSNumber (PrivateAPI_WeKnowExists)
// this is private, but we need it
- (const STR)objCType;
@end


@implementation XREncoder

static NSDictionary *xmlEntityMapping = nil;
static NSDictionary *nonXMLConformantEntityMapping = nil;

////////////////////////////////////////////////////
//
//   FACTORY
//
////////////////////////////////////////////////////


+ (id)encoderWithBuffer:(NSMutableString *)aBuffer
{
    return [[[self alloc] initForWritingWithBuffer:aBuffer] autorelease];
}


////////////////////////////////////////////////////
//
//   INIT & DEALLOC
//
////////////////////////////////////////////////////


- (id)initForWritingWithBuffer:(NSMutableString *)aBuffer
{
    [super initWithBuffer:aBuffer];

    if(xmlEntityMapping == nil)
    {
        NSString *path;

        path = [[NSBundle bundleForClass:NSClassFromString(@"XMLRPCFramework")] pathForResource:@"String2XMLEntity" ofType:@"plist"];
        NSAssert(path != nil, @"Unable to load String2XMLEntity.plist");

        xmlEntityMapping = [[[NSString stringWithData:[NSData dataWithContentsOfFile:path] encoding:NSUTF8StringEncoding] propertyList] retain];

        path = [[NSBundle bundleForClass:NSClassFromString(@"XMLRPCFramework")] pathForResource:@"String2Entity" ofType:@"plist"];
        NSAssert(path != nil, @"Unable to load String2Entity.plist");

        nonXMLConformantEntityMapping = [[[NSString stringWithData:[NSData dataWithContentsOfFile:path] encoding:NSUTF8StringEncoding] propertyList] retain];
    }
    
    flags.encodeUsingNSCodingIfPossible = NO;
    flags.encodeNullValueAsRFCDataType = NO;
    flags.useNonXMLConformantEncodingForStrings = NO;
    return self;
}


////////////////////////////////////////////////////
//
//  CODING SPECIALS
//
////////////////////////////////////////////////////


- (void)setEncodesObjectsUsingNSCodingIfPossible:(BOOL)yn
{
    flags.encodeUsingNSCodingIfPossible = yn;
}

- (void)setEncodesNullValuesAsRFCDataType:(BOOL)yn
{
    flags.encodeNullValueAsRFCDataType = yn;
}

- (void)setUsesNonXMLConformantEncodingForStrings:(BOOL)yn;
{
    flags.useNonXMLConformantEncodingForStrings = yn;
}


////////////////////////////////////////////////////
//
//  CODING TYPES
//
////////////////////////////////////////////////////


- (void)encodeString:(NSString *)aString
{
    [buffer appendFormat:@"<string>%@</string>", [aString stringByEncodingEntities:flags.useNonXMLConformantEncodingForStrings ? nonXMLConformantEntityMapping : xmlEntityMapping]];
}

- (void)encodeData:(NSData *)aData
{
    NSString *base64Representation = [NSString stringWithData:[aData encodeBase64WithLineLength:UINT_MAX - 3 andNewlineAtEnd:NO] encoding:NSASCIIStringEncoding];
    [buffer appendFormat:@"<base64>%@</base64>", base64Representation];
}

- (void)encodeDate:(NSDate *)aDate
{
    NSString *iso8601Representation = [aDate descriptionWithCalendarFormat:@"%Y%m%dT%H:%M:%S" timeZone:nil locale:nil];
    [buffer appendFormat:@"<dateTime.iso8601>%@</dateTime.iso8601>", iso8601Representation];
}

- (void)encodeDictionary:(NSDictionary *)aDictionary
{
    NSEnumerator *kEnum = [aDictionary keyEnumerator];
    NSString *key;

    [buffer appendString:@"<struct>"];
    while((key = [kEnum nextObject]) != nil)
    {
        NSAssert([key isKindOfClass:[NSString class]], @"Cannot encode keys which are no strings as that would violate the specs. See http://www.xmlrpc.com/spec for details.");
        [buffer appendString:@"<member><name>"];
        [buffer appendString:[key stringByEncodingEntities:xmlEntityMapping]];
        [buffer appendString:@"</name><value>"];
        [self encodeObject:[aDictionary objectForKey:key]];
        [buffer appendString:@"</value></member>"];
    }
    [buffer appendString:@"</struct>"];
}

- (void)encodeArray:(NSArray *)anArray
{
    NSEnumerator *oEnum = [anArray objectEnumerator];
    id object;

    [buffer appendString:@"<array><data>"];
    while((object = [oEnum nextObject]) != nil)
    {
        [buffer appendString:@"<value>"];
        [self encodeObject:object];
        [buffer appendString:@"</value>"];
    }
    [buffer appendString:@"</data></array>"];
}

- (void)encodeNumber:(NSNumber *)number
{
    // We have to find out what the original format is this number has been initialized with.
    // According to the specs at http://www.xmlrpc.com/spec we have to support the following types:
    // <i4> or <int>, four-byte signed integer, -12
    // <boolean>, 0 (false) or 1 (true), 1
    // <double>, double-precision signed floating point number, -12.214
    
    // ... and here's the deal:
    // NSNumber is a class cluster. Fair enough, the Foundation (and GNUstep)
    // engineers left a trace as to what the original type (Objective-C type) of the
    // represented value is.

    char objcType = *[number objCType];

    if(objcType == _C_CHR || objcType == _C_UCHR) // presumably BOOL ...
        [self encodeBool:[number boolValue]];
    else if(objcType == _C_DBL)
        [self encodeDouble:[number doubleValue]];
    else if(objcType == _C_FLT)
        [self encodeFloat:[number floatValue]];
    else
        [self encodeInt:[number intValue]];
}

- (void)encodeBool:(BOOL)aBoolean
{
    [buffer appendFormat:@"<boolean>%d</boolean>", aBoolean == NO ? 0 : 1];
}

- (void)encodeDouble:(double)aDouble
{
    [buffer appendFormat:@"<double>%.16f</double>", aDouble];
}

- (void)encodeFloat:(float)aFloat
{
    [buffer appendFormat:@"<double>%.8g</double>", aFloat];
}

- (void)encodeInt:(int)anInt
{
    [buffer appendFormat:@"<int>%d</int>", anInt];
}

- (void)encodeNullValue
{
    if(flags.encodeNullValueAsRFCDataType)
        [buffer appendFormat:@"<nil/>"];
    else
        [self encodeString:@""];
}

- (void)encodeException:(NSException *)exception
{
    NSMutableDictionary *fault;
    int _errCode = XRUnspecifiedErrorCode;
    NSString *faultString = [exception reason];
    NSString *_ex = [exception name];
    NSDictionary *userInfo;

//    [buffer appendString:@"<fault>\n<value>"];

    // we can use pointers here to speed things up
    if(_ex == XRDoesNotRecognizeSelectorException)
        _errCode = XRDoesNotRecognizeSelectorErrorCode;
    else if(_ex == XRInvalidArgumentsException)
        _errCode = XRInvalidArgumentsErrorCode;
    else if(_ex == EDMLParserException)
        _errCode = XRXMLParserErrorCode;

    // check if somebody else is providing a richer error description
    userInfo = [exception userInfo];
    if(userInfo != nil)
    {
        NSNumber *remoteErrorCode;
        NSString *remoteFaultString;

        remoteErrorCode = [userInfo objectForKey:XRRemoteErrorCodeKey];
        if(remoteErrorCode != nil)
            _errCode = [remoteErrorCode intValue];

        remoteFaultString = [userInfo objectForKey:XRRemoteErrorStringKey];
        if(remoteFaultString != nil)
            faultString = remoteFaultString;
    }

    // construct a fault
    fault = [NSMutableDictionary dictionaryWithCapacity:2];
    [fault setObject:[faultString stringByEncodingEntities:xmlEntityMapping] forKey:@"faultString"];
    [fault setObject:[NSNumber numberWithInt:_errCode] forKey:@"faultCode"];

    [self encodeDictionary:fault];

//    [buffer appendString:@"</value>\n</fault>"];
}


- (void)encodeObject:(id)object
{
    if(object == nil)
    {
        [self encodeNullValue];
    }
    else if([object conformsToProtocol:@protocol(XRCoding)])
    {
        [object encodeWithXMLRPCCoder:self];
    }
    else
    {
        if(flags.encodeUsingNSCodingIfPossible)
        {
            if([object conformsToProtocol:@protocol(NSCoding)])
            {
                // if we can serialize ourselves we'd like to do so
                // we also leave a note for the other side that we're in fact a serialized
                // Objective-C object
    
                NSData *serializedObject = [NSArchiver archivedDataWithRootObject:object];
                NSString *base64Representation = [NSString stringWithData:[serializedObject encodeBase64WithLineLength:INT_MAX - 3 andNewlineAtEnd:NO] encoding:NSASCIIStringEncoding];
                [buffer appendString:[NSString stringWithFormat:@"<base64 xr:objc-type=\"%@\">%@</base64>", NSStringFromClass([object class]), base64Representation]];
                return; // we're done
            }
        }
        // fall back to coding the description of the object
        [self encodeString:[object description]];
    }
}

@end
