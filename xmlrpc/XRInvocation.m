//
//  XRInvocation.m
//  XMLRPC
//
//  Created by znek on Sat Aug 18 2001.
//  $Id: XRInvocation.m,v 1.8 2003/03/28 13:12:02 znek Exp $
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


#include "XRInvocation.h"
#include <EDCommon/EDCommon.h>
#include "XRMethodSignature.h"

#ifdef XMLRPC_OSXSBUILD
#include "Future.h"
#endif


@implementation XRInvocation

////////////////////////////////////////////////////
//
//  FACTORY
//
////////////////////////////////////////////////////


+ (id)invocationWithXMLRPCMethodSignature:(XRMethodSignature *)aSignature
{
    return [[[self alloc] initWithXMLRPCMethodSignature:aSignature] autorelease];
}


////////////////////////////////////////////////////
//
//  INIT & DEALLOC
//
////////////////////////////////////////////////////


- (id)initWithXMLRPCMethodSignature:(XRMethodSignature *)aSignature
{
    NSMethodSignature *objcSignature;

    [super init];

    xmlrpcMethodSignature = [aSignature retain];
    objcSignature = [xmlrpcMethodSignature objcSignature];
    invocation = [[NSInvocation invocationWithMethodSignature:objcSignature] retain];

    if(0)
    {
        int i, argc;

        // now perform some checks ...
        if(*[objcSignature methodReturnType] != '@' && *[objcSignature methodReturnType] != 'v')
            [NSException raise:NSInvalidArgumentException format:@"Objective-C mappings are currently not allowed to return scalar types! This will be addressed in a future release."];

        argc = [objcSignature numberOfArguments];
        for(i = 2; i < argc; i++)
        {
            if(*[objcSignature getArgumentTypeAtIndex:i] != '@')
                [NSException raise:NSInvalidArgumentException format:@"ObjC mappings are currently not allowed to include scalar types! This will be addressed in a future release."];
        }
    }
    
    return self;
}

- (void)dealloc
{
    [invocation release];
    [xmlrpcMethodSignature release];
    [xmlrpcMethod release];
    [super dealloc];
}


////////////////////////////////////////////////////
//
//  ACCESSORS
//
////////////////////////////////////////////////////


- (XRMethodSignature *)xmlrpcMethodSignature
{
    return xmlrpcMethodSignature;
}

- (NSMethodSignature *)methodSignature
{
    return [invocation methodSignature];
}

- (id)target
{
    return [invocation target];
}

- (void)setTarget:(id)target
{
    [invocation setTarget:target];
}

- (SEL)selector
{
    return [invocation selector];
}

- (void)setSelector:(SEL)selector
{
    [invocation setSelector:selector];
}

- (void)setXMLRPCMethod:(NSString *)aMethod
{
    [aMethod retain];
    [xmlrpcMethod release];
    xmlrpcMethod = aMethod;
}

- (NSString *)xmlrpcMethod
{
    return xmlrpcMethod;
}

- (void)setArguments:(NSArray *)arguments
{
    NSMethodSignature *objcSignature;
    NSString *xmlrpcArgumentTypes;
    int argc, i;

    // argument count checking
    objcSignature = [invocation methodSignature];
    if([objcSignature numberOfArguments] - 2 != [arguments count])
        [NSException raise:NSInvalidArgumentException format:@"Selector '%@' expected %d arguments but instead received %d!", NSStringFromSelector([self selector]), [objcSignature numberOfArguments] - 2, [arguments count]];

    // type checking
    xmlrpcArgumentTypes = [XRMethodSignature xmlrpcTypesForObjects:arguments];
    if([[[self xmlrpcMethodSignature] getXRArgumentTypes] isEqualToString:xmlrpcArgumentTypes] == NO)
        [NSException raise:NSInvalidArgumentException format:@"Argument types do not match expected signature! Expected '%@', instead got '%@'.", [[self xmlrpcMethodSignature] getXRArgumentTypes], xmlrpcArgumentTypes];

    // now set the arguments
    argc = [objcSignature numberOfArguments] - 2;
    for(i = 0; i < argc; i++)
    {
        id argument;
        char objcType;

        objcType = *[objcSignature getArgumentTypeAtIndex:i + 2];
        argument = [arguments objectAtIndex:i];
        // filter placeholders
        if(argument == [NSNull null])
            argument = nil;

        if(objcType == _C_ID) // object
        {
            [invocation setArgument:&argument atIndex:i + 2];
        }
        else if(objcType == _C_CHR || objcType == _C_UCHR) // although this is also char it is presumably BOOL
        {
            BOOL value = [(NSNumber *)argument boolValue];
            [invocation setArgument:&value atIndex:i + 2];
        }
        else if(objcType == _C_INT)
        {
            int value = [(NSNumber *)argument intValue];
            [invocation setArgument:&value atIndex:i + 2];
        }
        else if(objcType == _C_UINT)
        {
            unsigned int value = [(NSNumber *)argument unsignedIntValue];
            [invocation setArgument:&value atIndex:i + 2];
        }
        else if(objcType == _C_FLT)
        {
            float value = [(NSNumber *)argument floatValue];
            [invocation setArgument:&value atIndex:i + 2];
        }
        else if(objcType == _C_DBL)
        {
            double value = [(NSNumber *)argument doubleValue];
            [invocation setArgument:&value atIndex:i + 2];
        }
        else if(objcType == _C_LNG)
        {
            long value = [(NSNumber *)argument longValue];
            [invocation setArgument:&value atIndex:i + 2];
        }
        else if(objcType == _C_ULNG)
        {
            unsigned long value = [(NSNumber *)argument unsignedLongValue];
            [invocation setArgument:&value atIndex:i + 2];
        }
        else if(objcType == _C_SHT)
        {
            short value = [(NSNumber *)argument shortValue];
            [invocation setArgument:&value atIndex:i + 2];
        }
        else if(objcType == _C_USHT)
        {
            unsigned short value = [(NSNumber *)argument unsignedShortValue];
            [invocation setArgument:&value atIndex:i + 2];
        }
        else
        {
            unichar xmlrpcArgumentType = [xmlrpcMethodSignature getXRArgumentTypeAtIndex:i + 2];
            [NSException raise:NSInvalidArgumentException format:@"Cannot coerce argument of XML-RPC type '%@' into Objective-C scalar type '%c'!", [NSString stringWithCharacters:&xmlrpcArgumentType length:1], objcType];
        }
    }
}

- (void)invoke
{
    [invocation invoke];
}

- (void)invokeWithTarget:(id)target
{
    [invocation invokeWithTarget:target];
}

- (id)returnValue
{
    char objcReturnType;
    unichar returnType;

    objcReturnType = *[[invocation methodSignature] methodReturnType];
    returnType = [[self xmlrpcMethodSignature] methodReturnType];

    // because XML-RPC allows no void return value, we need to provide
    // a default empty return value
    if(objcReturnType == 'v')
    {
        // return value depends on signature, even if we're void because XML-RPC doesn't give a damn!
        if(returnType == 's')
            return @"";
        else if(returnType == 'i')
            return [NSNumber numberWithInt:0];
        else if(returnType == 'b')
            return [NSNumber numberWithBool:YES];
        else if(returnType == 'd')
            return [NSNumber numberWithDouble:0.0];
        else if(returnType == 't')
            return [NSDate date];
        else if(returnType == 'B')
            return [NSData data];
        else if(returnType == 'S')
            return [NSDictionary dictionary];
        else if(returnType == 'a')
            return [NSArray array];
        return @""; // the default
    }


    if(objcReturnType == _C_ID) // object
    {
        id result;
        [invocation getReturnValue:&result];
        return result;
    }
    else if(objcReturnType == _C_CHR || objcReturnType == _C_UCHR) // BOOL ...
    {
        BOOL result;
        [invocation getReturnValue:&result];
        return [NSNumber numberWithBool:result];
    }
    else if(objcReturnType == _C_INT)
    {
        int result;
        [invocation getReturnValue:&result];
        return [NSNumber numberWithInt:result];
    }
    else if(objcReturnType == _C_UINT) 
    {
        unsigned int result;
        [invocation getReturnValue:&result];
        return [NSNumber numberWithUnsignedInt:result];
    }
    else if(objcReturnType == _C_FLT)
    {
        float result;
        [invocation getReturnValue:&result];
        return [NSNumber numberWithFloat:result];
    }
    else if(objcReturnType == _C_DBL)
    {
        double result;
        [invocation getReturnValue:&result];
        return [NSNumber numberWithDouble:result];
    }
    else if(objcReturnType == _C_SHT)
    {
        short result;
        [invocation getReturnValue:&result];
        return [NSNumber numberWithShort:result];
    }
    else if(objcReturnType == _C_USHT)
    {
        unsigned short result;
        [invocation getReturnValue:&result];
        return [NSNumber numberWithUnsignedShort:result];
    }
    else if(objcReturnType == _C_LNG)
    {
        long result;
        [invocation getReturnValue:&result];
        return [NSNumber numberWithLong:result];
    }
    else if(objcReturnType == _C_ULNG)
    {
        unsigned long result;
        [invocation getReturnValue:&result];
        return [NSNumber numberWithUnsignedLong:result];
    }
    else
    {
        unichar xmlrpcReturnType = [xmlrpcMethodSignature getXRArgumentTypeAtIndex:0];
        [NSException raise:NSInvalidArgumentException format:@"Cannot coerce Objective-C scalar type '%c' into XML-RPC type '%@'!", objcReturnType, [NSString stringWithCharacters:&xmlrpcReturnType length:1]];
    }
    return nil; // keep compiler happy
}

@end
