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

@synthesize rosobjects = rosobjects;

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
    // NOTE: From the looks of it, ROS was designed to only work with
    // one node per http server. rosobjc allows the user to run
    // multiple nodes per http server, HOWEVER, no two nodes may
    // subscribe or publish to the same topics.

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

-(void)startNode:(ROSNode *)node // done automagically.
{
    // something.
}

-(NSArray *)respondToRPC:(NSString *)method Params:(NSArray *)params
{
    NSArray *ret = nil;
    if (rosobjects.count == 0) {
        return @[@(-1), @"No running nodes", @0];
    }
    NSString *cid = params[0];
    if (cid == nil)
        return nil;
    if ([method isEqualToString:@"getBusStats"]) {
        NSMutableSet *pubStats = [[NSMutableSet alloc] init];
        NSMutableSet *subStats = [[NSMutableSet alloc] init];
        NSMutableSet *serStats = [[NSMutableSet alloc] init];
        for (ROSNode *node in rosobjects) {
            NSArray *a = [node getBusStats:cid][2];
            if (a.count == 0) {
                continue;
            }
            [pubStats addObjectsFromArray:a[0]];
            [subStats addObjectsFromArray:a[1]];
            [serStats addObjectsFromArray:a[2]];
        }
        ret = @[@1, @"bus stats", @[[pubStats allObjects], [subStats allObjects], [serStats allObjects]]];
    } else if ([method isEqualToString:@"getBusInfo"]) {
        NSMutableSet *set = [[NSMutableSet alloc] init];
        for (ROSNode *node in rosobjects) {
            [set addObjectsFromArray:[node getBusStats:cid][2]];
        }
        ret = @[@1, @"bus info", [set allObjects]];
    } else if ([method isEqualToString:@"getMasterUri"]) {
        if (self.masterURI) {
            ret = @[@1, self.masterURI, self.masterURI];
        } else {
            ret = @[@0, @"master URI not set", @""];
        }
    } else if ([method isEqualToString:@"shutdown"]) {
        NSString *msg = @"";
        if ([params count] != 2)
            msg = [params objectAtIndex:1];
        [self signalShutdown:msg];
        ret = @[@0, @"shutdown", @0];
    } else if ([method isEqualToString:@"getPid"]) {
        ret = @[@0, @"", @(getpid())];
    } else if ([method isEqualToString:@"getSubscriptions"]) {
        NSMutableSet *set = [[NSMutableSet alloc] init];
        for (ROSNode *node in rosobjects) {
            [set addObjectsFromArray:[node getSubscriptions:cid][2]];
        }
        ret = @[@1, @"subscriptions", [set allObjects]];
    } else if ([method isEqualToString:@"getPublications"]) {
        NSMutableSet *set = [[NSMutableSet alloc] init];
        for (ROSNode *node in rosobjects) {
            [set addObjectsFromArray:[node getPublishedTopics:cid][2]];
        }
        ret = @[@1, @"subscriptions", [set allObjects]];
    } else if ([method isEqualToString:@"paramUpdate"]) {
        if ([params count] != 3)
            return nil;
        NSString *k = [params objectAtIndex:1];
        id val = [params objectAtIndex:2];
        for (ROSNode *node in rosobjects) {
            [node paramUpdate:cid key:k val:val];
        }
        ret = @[@1, @"", @0];
    } else if ([method isEqualToString:@"publisherUpdate"]) {
        if ([params count] != 3)
            return nil;
        NSString *t = [params objectAtIndex:1];
        NSArray *p = [params objectAtIndex:2];
        if (p.count == 0) {
            ret = @[@(-1), @"Assumed at least 1 publisher", @0];
        } else {
            for (ROSNode *node in rosobjects) {
                [node publisherUpdate:cid topic:t publishers:p];
            }
        }
        ret = @[@1, @"", @0];
    } else if ([method isEqualToString:@"requestTopic"]) {
        if ([params count] != 3)
            return nil;
        NSString *t = [params objectAtIndex:1];
        NSArray *p = [params objectAtIndex:2];
        ret = [r requestTopic:cid topic:t protocols:p];
        for (ROSNode *node in rosobjects) {
            if ([node publishesTopic:t]) {
                ret = [node requestTopic:cid topic:t protocols:p];
                if ([ret[0] integerValue] == 1) {
                    break;
                }
            }
        }
    }
    return ret;
}

-(NSArray *)getPublishedTopics:(NSString *)NameSpace
{
    NSMutableSet *set = [[NSMutableSet alloc] init];
    for (ROSNode *node in rosobjects) {
        [set addObjectsFromArray:[node getPublishedTopics:NameSpace][2]];
    }
    return [set allObjects];
}

@end
