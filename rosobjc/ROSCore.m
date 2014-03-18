//
//  ROCore.m
//  rosobjc
//
//  Created by Rachel Brindle on 6/17/13.
//  Copyright (c) 2013 Rachel Brindle. All rights reserved.
//

#import "ROSCore.h"

#import "ROSXMLRPC.h"

#import "HTTPServer.h"
#import "RPCConnection.h"
#import "ROSMsg.h"
#import "ROSSocket.h"

@interface ROSCore () {
    ROSNode *masterProxy;
}
-(void)setInitialized:(BOOL)inited;
@end

@implementation ROSCore

+(NSArray *)ParseRosObjcURI:(NSString *)uri
{
    //NSAssert1([uri hasPrefix:schema], @"Invalid protocol for ROS service URL: %@", uri);
    //uri = [uri substringFromIndex:[schema length]];
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
    static ROSCore *ret;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        ret = [[ROSCore alloc] init];
    });
    return ret;
}

-(id)init
{
    if ((self = [super init]) != nil) {
        clientReady = NO;
        shutdownFlag = NO;
        inShutdown = NO;
        knownMessageTypes = [[NSMutableDictionary alloc] init];
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
    if (clientReady == inited)
        return;
    if (inited) {
        clientReady = inited;
        
        _httpServer = [[HTTPServer alloc] init];
        
        [_httpServer setConnectionClass:[RPCConnection class]];
        _rpcPort = 8080;
        
        while ([ROSSocket localServerAtPort:_rpcPort]) {
            _rpcPort++;
        }
        [_httpServer setPort:_rpcPort];
        NSString *hostname = [[NSProcessInfo processInfo] hostName];
        NSString *uri = [NSString stringWithFormat:@"http://%@:%u", hostname, _rpcPort];
        [self setUri:uri];
        
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
    [rosobjects removeAllObjects];
    
    [_httpServer stop];
    _httpServer = nil;
    
    shutdownFlag = YES;
}

-(void)removeNode:(ROSNode *)node
{
    [rosobjects removeObject:node];
}

-(void)registerMessageClasses:(NSArray *)classes
{
    for (Class c in classes) {
        NSString *type = [(ROSMsg *)[[c alloc] init] type];
        [knownMessageTypes setObject:c forKey:type];
    }
}

-(Class)getClassForMessageType:(NSString *)type
{
    return [knownMessageTypes objectForKey:type];
}

-(NSArray *)getKnownMessageTypes
{
    return knownMessageTypes.allKeys;
}

-(void)parseMessageFilesInDirectory:(NSString *)directory
{
    NSAssert(NO, @"Do not call [ROSCore parseMessageFilesInDirectory]");
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory error:nil];
    ROSGenMsg *gm = [[ROSGenMsg alloc] init];
    gm.knownMessages = knownMessageTypes;
    for (NSString *i in files) {
        if (![[i pathExtension] isEqualToString:@"msg"]) {
            continue;
        }
        NSString *classname = [i stringByDeletingPathExtension];
        if ([[knownMessageTypes allKeys] containsObject:classname]) {
            continue;
        }
        [knownMessageTypes setObject:[gm GenerateMessageClass:classname FromFile:[NSURL URLWithString:i]] forKey:classname];
    }
}

-(NSArray *)getFieldsForMessageType:(NSString *)messageType
{
    return [knownMessageTypes objectForKey:messageType];
}

-(ROSNode *)createNode:(NSString *)name
{
    // NOTE: this is something that we should fix.
    // It doesn't scale to run multiple httpservers
    // if we want to run more than one node.
    
    // Unfortunately, it would take a core ROS change to fix this.
    if ([rosobjects count] != 0) {
        return [rosobjects objectAtIndex:0];
    }
    for (ROSNode *node in rosobjects) {
        if ([node.name isEqualToString:name])
            return nil;
    }
    ROSNode *ret = [[ROSNode alloc] initWithName:name];
    ret.core = self;
    ret.masterURI = _masterURI;
    [rosobjects addObject:ret];
    return ret;
}

-(ROSNode *)getFirstNode
{
    if ([rosobjects count] == 0)
        return nil;
    return [rosobjects objectAtIndex:0];
}

-(void)startNode:(ROSNode *)node
{
    // something.
}

-(NSArray *)respondToRPC:(NSString *)method Params:(NSArray *)params
{
    NSArray *ret = nil;
    ROSNode *r = rosobjects[0];
    if (r == nil)
        return nil;
    NSString *cid = params[0];
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
    NSArray *t = [rosobjects[0] getPublishedTopics:NameSpace];
    NSAssert1([[t objectAtIndex:0] intValue] == 1, @"unable to get published topics: %@", [t objectAtIndex:1]);
    return ([t objectAtIndex:2]);
}

@end
