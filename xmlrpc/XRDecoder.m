//
//  XRDecoder.m
//  XMLRPC
//
//  Created by znek on Tue Aug 28 2001.
//  $Id: XRDecoder.m,v 1.5 2003/06/02 00:13:38 znek Exp $
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


#include "XRDecoder.h"
#include "XRXMLParser.h"
#include "XRXMLTagProcessor.h"


@interface XRDecoder (PrivateAPI)
- (XRXMLParser *)xmlParser;
@end


@implementation XRDecoder

////////////////////////////////////////////////////
//
//   FACTORY
//
////////////////////////////////////////////////////


+ (id)decoderWithData:(NSData *)data
{
    return [[[self alloc] initForReadingWithData:data] autorelease];
}


////////////////////////////////////////////////////
//
//   INIT & DEALLOC
//
////////////////////////////////////////////////////


- (id)initForReadingWithData:(NSData *)data
{
    [super init];
    xmlContent = [data retain];
    return self;
}

- (void)dealloc
{
    [xmlContent release];
    [super dealloc];
}


////////////////////////////////////////////////////
//
//  XML PARSING
//
////////////////////////////////////////////////////


- (XRXMLParser *)xmlParser
{
    static XRXMLParser *xmlParser = nil;

    if(xmlParser == nil)
    {
        NSString *path;
        NSDictionary *definitions;
        XRXMLTagProcessor *tagProcessor;
        NSBundle *bundle;

        bundle = [NSBundle bundleForClass:NSClassFromString(@"XMLRPCFramework")];
        
        path = [bundle pathForResource:@"XMLRPCTags" ofType:@"plist"];
        if(path == nil)
            [NSException raise:NSGenericException format:@"XMLRPCTags.plist not found in XMLRPC.framework!"];
        definitions = (NSDictionary *)[[NSString stringWithContentsOfFile:path] propertyList];

        tagProcessor = [[[XRXMLTagProcessor allocWithZone:[self zone]] initWithTagDefinitions:definitions] autorelease];
        [tagProcessor setIgnoresUnknownNamespaces:YES];
        [tagProcessor setIgnoresUnknownTags:YES];
        [tagProcessor setIgnoresUnknownAttributes:YES];
        [tagProcessor setAcceptsUnknownAttributes:YES];

        xmlParser = [[XRXMLParser allocWithZone:[self zone]] initWithTagProcessor:tagProcessor];
        [xmlParser setPreservesWhitespace:YES];
    }
    return xmlParser;
}


////////////////////////////////////////////////////
//
//   DECODING
//
////////////////////////////////////////////////////


- (id)decodeObject
{
    return [[self xmlParser] parseXMLDocument:xmlContent];
}

@end
