//
//  XREMethodCall.m
//  XMLRPC
//
//  Created by znek on Wed Aug 15 2001.
//  $Id: XREMethodCall.m,v 1.3 2003/03/28 13:12:01 znek Exp $
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


#include "XREMethodCall.h"
#include "MXContainerElement.h"
#include "XREValue.h"
#include "XRDefines.h"


@implementation XREMethodCall

////////////////////////////////////////////////////
//
//	OVERRIDING FUN
//
////////////////////////////////////////////////////


- (void)addContainedElement:(MXElement *)someElement
{
    // methodCall tags receive two tags.
    // One is the <methodName/>, the other the <params/> tag.
    // A <params/> tag, however, may contain multiple <param/> tags.
    // The <param/> tags consist of a <value/> tag, which is an XREValue
    // in our implementation

    // NOTE: we really do mean member, NOT kind
    if([someElement isMemberOfClass:[MXContainerElement class]])
    {
        NSMutableArray *params;
        NSEnumerator *paramsEnum;
        MXContainerElement *paramElement;

        params = [[[NSMutableArray allocWithZone:[self zone]] initWithCapacity:[[(MXContainerElement *)someElement containedElements] count]] autorelease];
        paramsEnum = [[(MXContainerElement *)someElement containedElements] objectEnumerator];
        
        while((paramElement = [paramsEnum nextObject]) != nil)
        {
            if([paramElement isMemberOfClass:[MXContainerElement class]])
            {
                NSEnumerator *subpEnum = [[paramElement containedElements] objectEnumerator];
                XREValue *valueElement;
                
                while((valueElement = [subpEnum nextObject]) != nil)
                {
                    if([valueElement isKindOfClass:[XREValue class]])
                    {
                        [params addObject:[valueElement objectValue]];
 //                       EDLog1(XRLogXRE, @"XREMethodCall: added real parameter: %@", valueElement);
                    }
                }
            }
        }
        [self takeValue:params forAttribute:@"params"];
    }
    else
    {
        [super addContainedElement:someElement];
    }
}


////////////////////////////////////////////////////
//
//	ACCESSORS
//
////////////////////////////////////////////////////


- (NSString *)selector
{
    return [self valueForAttribute:@"methodName"];
}

- (NSArray *)parameters
{
    return [self valueForAttribute:@"params"];
}


////////////////////////////////////////////////////
//
//	DEBUGGING
//
////////////////////////////////////////////////////


- (NSString *)description
{
  return [NSString stringWithFormat:@"<%@ 0x%x: selector=\"%@\" parameters=\"%@\">", NSStringFromClass([self class]), self, [self selector], [self parameters]];
}

@end
