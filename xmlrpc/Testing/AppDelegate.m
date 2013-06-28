//
//  AppDelegate.m
//  XMLRPC
//
//  Created by znek on Sun Aug 26 2001.
//  $Id: AppDelegate.m,v 1.2 2003/03/28 13:12:08 znek Exp $
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


#include "AppDelegate.h"
#include <EDCommon/EDCommon.h>
#include <XMLRPC/XMLRPC.h>
#include "TestController.h"
#include "TestServerProxy.h"


@implementation AppDelegate

- (void)setup
{
    NSString *serverURL;
    
    EDLogMask = (XRLogWarning | XRLogInfo | XRLogDebug | XRLogMessage | XRLogConnection);

    serverURL = @"http://localhost:2333/RPC2";
//    serverURL = @"http://orbital:2333/RPC2";
//    serverURL = @"http://xmlrpc-c.sourceforge.net/api/sample.php";
    
    controller = [[TestController alloc] init];

    connection = [[XRConnection connectionWithURL:[NSURL URLWithString:serverURL]] retain];
    [connection setDelegate:controller];
    proxy = (TestServerProxy *)[connection proxyWithHandle:@"sample"];
    [proxy retain];

    [connection setConnectionCheckInterval:5.0];
    [connection setShouldPerformConnectionChecks:YES];

    EDLog1(XRLogDebug, @"Connection: %@", connection);
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    [self setup];
}

- (IBAction)performTest:(id)sender
{
    id result;

    result = [proxy doStuff:[NSArray arrayWithObjects:@"1", [NSNumber numberWithInt:2], nil]];
    EDLog1(XRLogDebug, @"Received: %@", result);

}

@end
