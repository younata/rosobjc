//
//  ROCore.m
//  rosobjc
//
//  Created by Rachel Brindle on 6/17/13.
//  Copyright (c) 2013 Rachel Brindle. All rights reserved.
//

#import "ROSCore.h"

#import "HTTPServer.h"
#import "RPCConnection.h"

@interface ROSCore () {
    ROSNode *masterProxy;
}
-(void)setInitialized:(BOOL)inited;
@end

static ROSCore *roscoreSingleton = nil;

@implementation ROSCore

+(NSArray *)ParseRosObjcURI:(NSString *)uri
{
    NSAssert1([uri hasPrefix:schema], @"Invalid protocol for ROS service URL: %@", uri);
    uri = [uri substringFromIndex:[schema length]];
    NSString *destLoc = nil;
    NSInteger destPort;
    NSAssert1([uri rangeOfString:@"/"].location != NSNotFound, @"Invalid protocol for ROS service URL: %@", uri);
    destLoc = [uri substringToIndex:[uri rangeOfString:@"/"].location];
    NSAssert1([uri rangeOfString:@":"].location != NSNotFound, @"Invalid protocol for ROS service URL: %@", uri);
    destPort = [[uri substringFromIndex:[uri rangeOfString:@":"].location+1] integerValue];
    return @[destLoc, @(destPort)];
}

+(ROSCore *)sharedCore
{
    if (roscoreSingleton == nil)
        [ROSCore initialize];
    return roscoreSingleton;
}

+(void)initialize
{
    if (roscoreSingleton == nil) {
        roscoreSingleton = [[ROSCore alloc] initSingleton];
    }
}

-(id)init
{
    return nil;
}

-(id)initSingleton
{
    if ((self = [super init]) != nil) {
        clientReady = NO;
        shutdownFlag = NO;
        inShutdown = NO;
        rosobjects = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)setUri:(NSString *)uri
{
    [ROSCore ParseRosObjcURI:uri];
    _uri = uri;
}

-(BOOL)isInitialized
{
    return clientReady;
}

-(void)setInitialized:(BOOL)inited
{
    clientReady = inited;
    
    [_httpServer setConnectionClass:[RPCConnection class]];
    [_httpServer setPort:8080];
    
    // Enable Bonjour
    [_httpServer setType:@"_http._tcp."];
    
    // Set document root
    [_httpServer setDocumentRoot:[@"~/Documents/Sites" stringByExpandingTildeInPath]];
    
    // Start XMLRPC server
    NSError* error = nil;
    if (![_httpServer start:&error]) {
        NSLog(@"Error starting HTTP Server: %@", error);
    }
    
    shutdownFlag = NO;
    inShutdown = NO;
}

-(BOOL)isShutdown
{
    return shutdownFlag;
}

-(BOOL)isShutdownRequested
{
    return inShutdown;
}

-(void)signalShutdown:(NSString *)reason
{
    if (inShutdown || shutdownFlag)
        return;
    inShutdown = YES;
    for (ROSNode *node in rosobjects) {
        [node shutdown:reason];
    }
    rosobjects = nil;
    
    [_httpServer stop];
    _httpServer = nil;
    
    shutdownFlag = YES;
}

-(void)removeNode:(ROSNode *)node
{
    [rosobjects removeObject:node];
}

-(ROSNode *)getMaster
{
    if (masterProxy == nil) {
        
    }
    return masterProxy;
}

-(ROSNode *)createNode:(NSString *)name
{
    // NOTE: this is something that we should fix.
    // It doesn't scale to run multiple httpservers
    // if we want to run more than one node.
    
    // Unfortunately, it would take a core ROS change to fix this.
    if ([rosobjects count] != 0) {
        return nil;
    }
    for (ROSNode *node in rosobjects) {
        if ([node.name isEqualToString:name])
            return nil;
    }
    ROSNode *ret = [[ROSNode alloc] initWithName:name];
    ret.core = self;
    ret.masterURI = _uri;
    [rosobjects addObject:ret];
    return ret;
}

-(void)startNode:(ROSNode *)node
{
    // something.
}

-(NSArray *)respondToRPC:(NSString *)method Params:(NSArray *)params
{
    NSArray *ret = nil;
    ROSNode *r = [rosobjects firstObject];
    if (r == nil)
        return nil;
    NSString *cid = [params firstObject];
    if (cid == nil)
        return nil;
    if ([method isEqualToString:@"getBusStats"]) {
        ret = [r getBusStats:cid];
    } else if ([method isEqualToString:@"getBusInfo"]) {
        ret = [r getBusInfo:cid];
    } else if ([method isEqualToString:@"getMasterUri"]) {
        ret = [r getMasterUri:cid];
    } else if ([method isEqualToString:@"shutdown"]) {
        NSString *msg = @"";
        if ([params count] != 2)
            msg = [params objectAtIndex:1];
        [self signalShutdown:msg];
    } else if ([method isEqualToString:@"getPid"]) {
        ret = @[@0, @"", @(getpid())];
    } else if ([method isEqualToString:@"getSubscriptions"]) {
        ret = [r getSubscriptions:cid];
    } else if ([method isEqualToString:@"getPublications"]) {
        ret = [r getPublications:cid];
    } else if ([method isEqualToString:@"paramUpdate"]) {
        if ([params count] != 3)
            return nil;
        NSString *k = [params objectAtIndex:1];
        id val = [params objectAtIndex:2];
        ret = [r paramUpdate:cid key:k val:val];
    } else if ([method isEqualToString:@"publisherUpdate"]) {
        if ([params count] != 3)
            return nil;
        NSString *t = [params objectAtIndex:1];
        NSArray *p = [params objectAtIndex:2];
        ret = [r publisherUpdate:cid topic:t publishers:p];
    } else if ([method isEqualToString:@"requestTopic"]) {
        if ([params count] != 3)
            return nil;
        NSString *t = [params objectAtIndex:1];
        NSArray *p = [params objectAtIndex:2];
        ret = [r requestTopic:cid topic:t protocols:p];
    }
    return ret;
}

-(NSArray *)getPublishedTopics:(NSString *)NameSpace
{
    NSArray *t = [[self getMaster] getPublishedTopics:NameSpace];
    NSAssert1([[t objectAtIndex:0] intValue] == 1, @"unable to get published topics: %@", [t objectAtIndex:1]);
    return ([t objectAtIndex:2]);
}

@end
