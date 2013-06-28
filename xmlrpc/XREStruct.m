//
//  XREStruct.m
//  XMLRPC
//
//  Created by znek on Wed Aug 15 2001.
//  $Id: XREStruct.m,v 1.2 2003/03/28 13:12:01 znek Exp $
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


#include "XREStruct.h"
#include "XRDefines.h"
#include "MXTextContainerElement.h"
#include "MXAutoContentContainerElement.h"


@implementation XREStruct

////////////////////////////////////////////////////
//
//	OVERRIDING FUN
//
////////////////////////////////////////////////////


- (void)addContainedElement:(MXElement *)someElement
{
    // <struct/> tags can have multiple  <member/> tags.
    // These <member/> tags consists of </name> and <value/> tags
    // in alternating order.

    // NOTE: we really do mean member, NOT kind
    if([someElement isMemberOfClass:[MXAutoContentContainerElement class]])
    {
        NSString *name = [someElement valueForAttribute:@"name"];
        XREValue *value = [someElement valueForAttribute:@"value"];
        NSMutableDictionary *kvDict;

        int _tCount = 0;

        EDLog1(XRLogXRE, @"XREStruct: scanning %@", someElement);

        if(name != nil)
            _tCount++;
        if(value != nil)
            _tCount++;
            
        if(_tCount != 2)
            [NSException raise:NSGenericException format:@"<member> tags need both <name> and <value> tags!"];
        
        kvDict = [self valueForAttribute:@"object"];
        if(kvDict == nil)
        {
            kvDict = [[[NSMutableDictionary allocWithZone:[self zone]] init] autorelease];
            [self takeValue:kvDict forAttribute:@"object"];
            [attributes removeObjectForKey:@"debris"];
        }
        [kvDict setObject:[value objectValue] forKey:name];
    }
    else
    {
        [super addContainedElement:someElement];
    }
    EDLog1(XRLogXRE, @"XREStruct: %@", [self description]);
}

- (id)emptyValue
{
    return [NSDictionary dictionary];
}

@end
