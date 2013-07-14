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

-(void)respondToRPC:(NSString *)method Params:(NSArray *)params
{
    
}

-(NSArray *)getPublishedTopics:(NSString *)NameSpace
{
    NSArray *t = [[self getMaster] getPublishedTopics:NameSpace];
    NSAssert1([[t objectAtIndex:0] intValue] == 1, @"unable to get published topics: %@", [t objectAtIndex:1]);
    return ([t objectAtIndex:2]);
}

@end
