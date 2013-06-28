//
//  xrcall_main.m
//  XRCommand
//
//  Created by znek on Wed Jul 17 2002.
//  $Id: xrcall_main.m,v 1.3 2003/03/28 13:12:09 znek Exp $
//
//  Copyright (c) 2001 by Marcus MŸller <znek@mulle-kybernetik.com>.
//  All rights reserved.
//
//  Permission to use, copy, modify and distribute this software and its documentation
//  is hereby granted under the terms of the GNU General Public License, version 2
//  as published by the Free Software Foundation, provided that both the copyright notice
//  and this permission notice appear in all copies of the software, derivative works or
//  modified versions, and any portions thereof, and that both notices appear in supporting
//  documentation, and that credit is given to Marcus MŸller in all documents and publicity
//  pertaining to direct or indirect use of this code or its derivatives.
//
//  This is free software; you can redistribute and/or modify it under
//  the terms of the GNU General Public License, version 2 as published by the Free
//  Software Foundation. Further information can be found on the project's web pages
//  at http://www.mulle-kybernetik.com/software/XRCommand
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


void usage(NSString *reason)
{
    [reason fprintf:[NSFileHandle fileHandleWithStandardError]];
    [@"\nUsage: xrcall URL COMMAND [PARAMETERS]\n\nExample: xrcall http://user:pwd@somehost.org/RPC2 add '(2, 2)'\n" fprintf:[NSFileHandle fileHandleWithStandardError]];
    exit(1);
}


int main(int argc, const char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSArray * args;
    NSString *serverURL;
    NSString *method;
    NSMutableArray *objects = nil;
    XRConnection *connection;
    id result;
    int i;

//    EDLogMask = (XRLogWarning | XRLogInfo | XRLogDebug | XRLogConnection | XRLogMessage | XRLogXML | XRLogXRE | XRLogObjReg);
    EDLogMask = 0x0;

    if(argc < 2)
        usage(@"Invalid number of arguments!");

    args = [[NSProcessInfo processInfo] arguments];
    serverURL = [args objectAtIndex:1];
    method = [args objectAtIndex:2];


    if(argc >= 3)
    {
        objects = [NSMutableArray array];

        for(i = 3; i < argc; i++)
        {
            id object;

            NS_DURING

                object = [[args objectAtIndex:i] propertyList];

            NS_HANDLER

                object = [args objectAtIndex:i];

            NS_ENDHANDLER

            if(object == nil)
                object = [NSNull null];
            [objects addObject:object];
        }
    }

    connection = [XRConnection connectionWithURL:[NSURL URLWithString:serverURL]];

    NS_DURING

        if(objects != nil)
            result = [connection performRemoteMethod:method withObjects:objects];
        else
            result = [connection performRemoteMethod:method];

        [[result description] printf];

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
