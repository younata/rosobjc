//
//  parsertest_main.m
//  XMLRPC
//
//  Created by znek on Fri Feb 01 2002.
//  $Id: parsertest_main.m,v 1.2 2003/03/28 13:12:09 znek Exp $
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
#include "TestServer.h"


int main(int argc, const char *argv[])
{

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *xmlPath = @"/tmp/example.xml";
    XRConnection *connection;
    TestServer *server;
    NSData *xmlResponse;
    id result;

    EDLogMask = (XRLogWarning | XRLogInfo | XRLogDebug | XRLogMessage | XRLogXML | XRLogXRE);

    server = [[[TestServer alloc] init] autorelease];
    connection = [XRConnection connectionWithObject:server handle:@"test" socket:nil];
    xmlResponse = [NSData dataWithContentsOfFile:xmlPath];

    result = [connection resultForXMLResponse:xmlResponse];
    NSLog(@"result = %@", result);

    [pool release];
    exit(0); // insure the process exit status is 0
    return 0; // keep compiler happy
}
