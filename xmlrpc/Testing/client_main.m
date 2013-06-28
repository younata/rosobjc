//
//  client_main.m
//  XMLRPC
//
//  Created by znek on Mon Aug 13 2001.
//  $Id: client_main.m,v 1.13 2003/03/28 13:12:09 znek Exp $
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
#include "TestController.h"
#include "TestServerProxy.h"


int main(int argc, const char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *serverURL;
    XRConnection *connection;
    TestController *controller;

    EDLogMask = (XRLogWarning | XRLogInfo | XRLogDebug | XRLogConnection | XRLogMessage | XRLogXML | XRLogXRE | XRLogObjReg);
//    EDLogMask = XRLogDebug;
//    EDLogMask = 0x0;

    serverURL = @"http://znek:secret@localhost:2333/RPC2";
//    serverURL = @"http://xmlrpc-c.sourceforge.net/api/sample.php";
    
    controller = [[[TestController alloc] init] autorelease];
    connection = [XRConnection connectionWithURL:[NSURL URLWithString:serverURL]];

    [connection setDelegate:controller];

    NS_DURING
        
        if(0)
        {
            [connection setConnectionCheckInterval:5.0];
            [connection setShouldPerformConnectionChecks:YES];
        }
    
        if(0)
        {
            EDLog1(XRLogDebug, @"Connection: %@", connection);
        }
    
        if(0)
        {
            NSMutableArray *calls = [NSMutableArray array];
            NSString *call;
            NSArray *result;

            call = @"{ methodName = \"sample.doStuff\" ; params = ( ( \"a\", \"b\" ) ); }";
            [calls addObject:[call propertyList]];
            call = @"{ methodName = \"sample.xdoStuff\" ; params = ( ( \"a\", \"b\" ) ); }";
            [calls addObject:[call propertyList]];
            call = @"{ methodName = \"sample.doStuff\" ; params = ( ( \"a\", \"b\" ) ); }";
            [calls addObject:[call propertyList]];
    
            result = [connection performRemoteMethod:@"system.multicall" withObject:calls];
            EDLog1(XRLogDebug, @"Result: %@", result);
        }
    
        if(0)
        {
            NSArray *result;
    
            result = [connection performRemoteMethod:@"system.listMethods"];
            EDLog1(XRLogDebug, @"Result: %@", result);
        }
    
        if(0)
        {
            id object;
            NSArray *result;

            object = [@"( { foo = \"bar\"; baz = ( \"a\", \"b\", 100 ); }, x)" propertyList];
            result = [connection performRemoteMethod:@"sample.doStuff" withObject:object];
            EDLog1(XRLogDebug, @"Result: %@", result);
        }
        
        if(1)
        {
            TestServerProxy *proxy;
            int result, i;
    
            proxy = (TestServerProxy *)[connection proxyWithHandle:@"sample"];
            for(i = 0; i < 300; i++)
            {
                result = [proxy testIfTrue:YES];
                EDLog2(XRLogDebug, @"Message:%i Received:%d", i, result);
            }
        }

    NS_HANDLER

        NSDictionary *userInfo;
        NSString *error;
        NSString *errReason;
        int exitCode;

        errReason = [localException reason];
        exitCode = 1;

        if((userInfo = [localException userInfo]) != nil)
        {
            id value;

            value  = [userInfo objectForKey:XRRemoteErrorStringKey];
            if(value != nil)
                errReason = value;
            value  = [userInfo objectForKey:XRRemoteErrorCodeKey];
            if(value != nil)
                exitCode = [value intValue];
        }

        error = [NSString stringWithFormat:@"%@: %@\n", [localException name], errReason];
        [error fprintf:[NSFileHandle fileHandleWithStandardError]];
        exit(exitCode);
        
    NS_ENDHANDLER

    [pool release];
    exit(0); // insure the process exit status is 0
    return 0; // keep compiler happy
}
