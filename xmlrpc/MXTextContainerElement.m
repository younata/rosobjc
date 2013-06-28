//---------------------------------------------------------------------------------------
// created as MXTextContainerElement.m by znek on Sun 29-Oct-2000
// $Id: MXTextContainerElement.m,v 1.4 2003/03/28 13:12:01 znek Exp $
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


#include "MXTextContainerElement.h"
#include "MXStringElement.h"


@interface MXTextContainerElement (PrivateCaching)
- (void)_cacheText;
@end


@implementation MXTextContainerElement

////////////////////////////////////////////////////
//
//	DEALLOC
//
////////////////////////////////////////////////////


- (void)dealloc
{
    [text release];
    [super dealloc];
}


////////////////////////////////////////////////////
//
//	CACHING
//
////////////////////////////////////////////////////


- (void)setContainedElements:(NSArray *)someElements
{
    [super setContainedElements:someElements];
    [self _cacheText];
}


////////////////////////////////////////////////////
//
//	ACCESSORS
//
////////////////////////////////////////////////////


- (NSString *)text
{
    if(text == nil)
        [self _cacheText];
    return text;
}


- (void)_cacheText
{
    NSEnumerator *cEnum;
    MXStringElement *element;
    
    text = [[NSMutableString allocWithZone:[self zone]] init];
    cEnum = [containedElements objectEnumerator];
    while((element = [cEnum nextObject]) != nil)
        [element appendToString:text];

    //  [text removeSurroundingWhitespace];
}


////////////////////////////////////////////////////
//
//	DEBUGGING
//
////////////////////////////////////////////////////


- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ 0x%x: text=\"%@\">", NSStringFromClass([self class]), self, [self text]];
}

@end
