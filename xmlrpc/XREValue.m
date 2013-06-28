//
//  XREValue.m
//  XMLRPC
//
//  Created by znek on Wed Aug 15 2001.
//  $Id: XREValue.m,v 1.8 2003/03/28 13:12:01 znek Exp $
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


#include "XREValue.h"
#include <EDMessage/EDMessage.h>
#include "MXTextContainerElement.h"
#include "MXStringElement.h"
#include "XRDefines.h"
#include "NSCalendarDate+ISO8601.h"

#ifdef XMLRPC_OSXSBUILD
#include "Future.h"
#endif


@implementation XREValue

////////////////////////////////////////////////////
//
//	OVERRIDING FUN
//
////////////////////////////////////////////////////


- (void)addContainedElement:(MXElement *)someElement
{
    if([someElement isKindOfClass:[MXTextContainerElement class]])
    {
        MXTextContainerElement *wrapperElement = (MXTextContainerElement *)someElement;
        NSString *wrapperType = [wrapperElement valueForAttribute:@"key"];
        id object = nil;

        EDLog2(XRLogXRE, @"XREValue: scanning element %@ of type %@", wrapperElement, wrapperType);

        if([wrapperType isEqualToString:@"string"])
            object = [wrapperElement text];
        else if([wrapperType isEqualToString:@"int"])
            object = [NSNumber numberWithInt:[[wrapperElement text] intValue]];
        else if([wrapperType isEqualToString:@"boolean"])
            object = [NSNumber numberWithBool:(BOOL)[[wrapperElement text] intValue]];
        else if([wrapperType isEqualToString:@"dateTime.iso8601"])
            object = [NSCalendarDate dateWithISO8601Representation:[wrapperElement text]];
        else if([wrapperType isEqualToString:@"double"])
        {
            NSScanner *scanner;
            double doubleValue;

            scanner = [NSScanner scannerWithString:[wrapperElement text]];
            [scanner scanDouble:&doubleValue];
            object = [NSNumber numberWithDouble:doubleValue];
        }
        else if([wrapperType isEqualToString:@"base64"])
        {
            NSData *data;
            
            data = [[wrapperElement text] dataUsingEncoding:NSASCIIStringEncoding];
            object = [data decodeBase64];

            // if wrapper has an objc-type attached we deserialize the object!
            if([wrapperElement valueForAttribute:@"xr:objc-type"] != nil)
                object = [NSUnarchiver unarchiveObjectWithData:object];
        }
        else
            [NSException raise:NSGenericException format:@"Cannot wrap object of type '%@' with textual representation '%@'!", wrapperType, [wrapperElement text]];

        [self takeValue:object forAttribute:@"object"];
        [attributes removeObjectForKey:@"debris"]; // discard unnecessary debris
    }
    else if([someElement isKindOfClass:[XREValue class]])
    {
        id object = [(XREValue *)someElement objectValue];
        [self takeValue:object forAttribute:@"object"];
        [attributes removeObjectForKey:@"debris"]; // discard unnecessary debris
    }
    else if([someElement isKindOfClass:[MXStringElement class]])
    {
        // collect all debris which makes up a string which doesn't consist of whitespace only
        // this makes sense only if we don't already have an object attached
        // NOTE: This whole thing is pretty annoying, but we have to stick to the specs

        if([self valueForAttribute:@"object"] == nil)
        {
            NSMutableString *debris;
            
            debris = [self valueForAttribute:@"debris"];
            if(debris == nil)
            {
                debris = [NSMutableString string];
                [self takeValue:debris forAttribute:@"debris"];
            }
            [(MXStringElement *)someElement appendToString:debris];
        }
    }
    else
    {
        [super addContainedElement:someElement];
    }
    EDLog1(XRLogXRE, @"XREValue: %@", [self description]);
}


////////////////////////////////////////////////////
//
//	ACCESSORS
//
////////////////////////////////////////////////////


- (id)emptyValue
{
#warning * ZNeK: this is in accordance with the specs
    return @"";
}

- (id)objectValue
{
    id object;

    object = [self valueForAttribute:@"object"];
    if(object != nil)
        return object;
    object = [self valueForAttribute:@"debris"];
    if(object != nil)
        return object;
    return [self emptyValue];
}


////////////////////////////////////////////////////
//
//	DEBUGGING
//
////////////////////////////////////////////////////


- (NSString *)description
{
  return [NSString stringWithFormat:@"<%@ 0x%x: object=\"%@\" objectClass=\"%@\">", NSStringFromClass([self class]), self, [self objectValue], NSStringFromClass([[self objectValue] class])];
}

@end
