//
//  ROCore.m
//  rosobjc
//
//  Created by Rachel Brindle on 6/17/13.
//  Copyright (c) 2013 Rachel Brindle. All rights reserved.
//

#import "ROSCore.h"

@interface ROSCore () {
    ROSNode *masterProxy;
}
-(void)setInitialized:(BOOL)inited;
@end

//static ROCore *rocoreSingleton = nil;

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

-(id)init
{
    return nil;
}

-(id)initWithMasterURI:(NSString *)uri
{
    if ((self = [super init]) != nil) {
        clientReady = NO;
        shutdownFlag = NO;
        inShutdown = NO;
        rosobjects = [[NSMutableArray alloc] init];
        [ROSCore ParseRosObjcURI:uri];
        _uri = uri;
    }
    return self;
}


-(BOOL)isInitialized
{
    return clientReady;
}

-(void)setInitialized:(BOOL)inited
{
    clientReady = inited;
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

-(NSArray *)getPublishedTopics:(NSString *)NameSpace
{
    NSArray *t = [[self getMaster] getPublishedTopics:NameSpace];
    NSAssert1([[t objectAtIndex:0] intValue] == 1, @"unable to get published topics: %@", [t objectAtIndex:1]);
    return ([t objectAtIndex:2]);
}

@end
