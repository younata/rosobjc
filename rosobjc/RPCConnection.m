//
//  RPCConnection.m
//  rosobjc
//
//  Created by Rachel Brindle on 7/6/13.
//  Copyright (c) 2013 Rachel Brindle. All rights reserved.
//

#import "RPCConnection.h"
#import "HTTPMessage.h"
#import "RPCResponse.h"

@implementation RPCConnection

-(BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path
{
    return [method isEqualToString:@"POST"];
}

-(BOOL)expectsRequestBodyFromMethod:(NSString *)method atPath:(NSString *)path
{
    return YES;
}

-(void)prepareForBodyWithSize:(UInt64)contentLength
{
    requestContentBody = [[NSMutableData alloc] initWithCapacity:(NSUInteger)contentLength];
}

-(void)processBodyData:(NSData *)postDataChunk
{
    [requestContentBody appendData:postDataChunk];
}

-(void)finishResponse
{
    requestContentBody = nil;
    [super finishResponse];
}

-(id<HTTPResponse>)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
    if ([method isEqualToString:@"POST"])
        return [[RPCResponse alloc] initWithHeaders:[request allHeaderFields] bodyData:requestContentBody];
    return nil;
}

@end
