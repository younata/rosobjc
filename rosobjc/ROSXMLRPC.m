//
//  ROSXMLRPC.m
//  rosobjc
//
//  Created by Rachel Brindle on 6/28/13.
//  Copyright (c) 2013 Rachel Brindle. All rights reserved.
//

#import "ROSXMLRPC.h"
#import "ROSCore.h"

@implementation ROSXMLRPCC

#pragma mark - XMLRPCConnectionDelegate

-(void)request:(XMLRPCRequest *)request didReceiveResponse:(XMLRPCResponse *)response
{
    if (!response.isFault) {
        void (^callback)(NSArray *) = [callbacks objectForKey:request];
        callback((NSArray *)response.object);
    } else {
        NSLog(@"%@", response);
    }
    
}

-(void)request:(XMLRPCRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"Request %@ failed with error %@", request, error);
}

-(BOOL)request:(XMLRPCRequest *)request canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    // this should never be called. ROS is not a secure protocol at all.
    return YES;
}

-(void)request:(XMLRPCRequest *)request didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    // this should never be called. ROS is not a secure protocol.
}

-(void)request:(XMLRPCRequest *)request didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    // this should never be called. ROS is not a secure protocol.
}

#pragma mark - private methods

-(void)makeCall:(NSString *)methodName WithArgs:(NSArray *)args callback:(void(^)(NSArray *))callback
{
    XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithURL:_URL];
    XMLRPCConnectionManager *manager = [XMLRPCConnectionManager sharedManager];
    
    [request setMethod:methodName withParameters:args];
    
    [manager spawnConnectionWithXMLRPCRequest:request delegate:self];
    
    if (callbacks == nil)
        callbacks = [[NSMutableDictionary alloc] init];
    [callbacks setObject:callback forKey:request];
}

#pragma mark - public methods

-(void)makeCall:(NSString *)methodName WithArgs:(NSArray *)args callback:(void (^)(NSArray *))callback URL:(NSURL *)url
{
    XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithURL:url];
    XMLRPCConnectionManager *manager = [XMLRPCConnectionManager sharedManager];
    
    [request setMethod:methodName withParameters:args];
    
    [manager spawnConnectionWithXMLRPCRequest:request delegate:self];
    
    if (callbacks == nil)
        callbacks = [[NSMutableDictionary alloc] init];
    [callbacks setObject:callback forKey:request];
}

-(void)registerService:(NSString *)callerID Service:(NSString *)service ServiceAPI:(NSString *)serviceAPI callback:(void(^)(NSArray *))callback
{
    [self makeCall:@"registerService" WithArgs:@[callerID, service, serviceAPI, [[ROSCore sharedCore] uri]] callback:callback];
}

-(void)unregisterService:(NSString *)callerID Service:(NSString *)service ServiceAPI:(NSString *)serviceAPI callback:(void(^)(NSArray *))callback
{
    [self makeCall:@"unregisterService" WithArgs:@[callerID, service, serviceAPI] callback:callback];
}

-(void)registerSubscriber:(NSString *)callerID Topic:(NSString *)topic TopicType:(NSString *)topicType callback:(void(^)(NSArray *))callback
{
    [self makeCall:@"registerSubscriber" WithArgs:@[callerID, topic, topicType, [[ROSCore sharedCore] uri]] callback:callback];
}

-(void)unregisterSubscriber:(NSString *)callerID Topic:(NSString *)topic callback:(void(^)(NSArray *))callback
{
    [self makeCall:@"unregisterSubscriber" WithArgs:@[callerID, topic, [[ROSCore sharedCore] uri]] callback:callback];
}

-(void)registerPublisher:(NSString *)callerID Topic:(NSString *)topic TopicType:(NSString *)topicType callback:(void(^)(NSArray *))callback
{
    [self makeCall:@"registerPublisher" WithArgs:@[callerID, topic, topicType, [[ROSCore sharedCore] uri]] callback:callback];
}

-(void)unregisterPublisher:(NSString *)callerID Topic:(NSString *)topic callback:(void(^)(NSArray *))callback
{
    [self makeCall:@"unregisterPublisher" WithArgs:@[callerID, topic, [[ROSCore sharedCore] uri]] callback:callback];
}

-(void)lookupNode:(NSString *)callerID Node:(NSString *)node callback:(void(^)(NSArray *))callback
{
    [self makeCall:@"lookupNode" WithArgs:@[callerID, node] callback:callback];
}

-(void)getPublishedTopics:(NSString *)callerID Subgraph:(NSString *)subgraph callback:(void(^)(NSArray *))callback
{
    [self makeCall:@"getPublishedTopics" WithArgs:@[callerID, subgraph] callback:callback];
}

-(void)getTopicTypes:(NSString *)callerID callback:(void(^)(NSArray *))callback
{
    [self makeCall:@"getTopicTypes" WithArgs:@[callerID] callback:callback];
}

-(void)getSystemState:(NSString *)callerID callback:(void(^)(NSArray *))callback
{
    [self makeCall:@"getSystemState" WithArgs:@[callerID] callback:callback];
}

-(void)getURI:(NSString *)callerID callback:(void(^)(NSArray *))callback
{
    [self makeCall:@"getURI" WithArgs:@[callerID] callback:callback];
}

-(void)lookupService:(NSString *)callerID Service:(NSString *)service callback:(void(^)(NSArray *))callback
{
    [self makeCall:@"lookupService" WithArgs:@[callerID, service] callback:callback];
}

@end
