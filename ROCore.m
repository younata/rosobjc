//
//  ROCore.m
//  rosobjc
//
//  Created by Rachel Brindle on 6/17/13.
//  Copyright (c) 2013 Rachel Brindle. All rights reserved.
//

#import "ROCore.h"

@interface ROCore () {
    RONode *masterProxy;
}
-(void)setInitialized:(BOOL)inited;
@end

//static ROCore *rocoreSingleton = nil;

@implementation ROCore

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

/*
+(ROCore *)sharedCore
{
    if (rocoreSingleton == nil)
        [ROCore initialize];
    return rocoreSingleton;
}


+(void)initialize
{
    static BOOL initialized = NO;
    if(!initialized)
    {
        initialized = YES;
        rocoreSingleton = [[ROCore alloc] init];
    }
}
*/

-(id)init
{
    return nil;
    /*
    if (rocoreSingleton != nil)
        return nil;
    if ((self = [super init]) != nil) {
        clientReady = NO;
        shutdownFlag = NO;
        inShutdown = NO;
        rosobjects = [[NSMutableArray alloc] init];
    }
    return self;
     */
}

-(id)initWithMasterURI:(NSString *)uri
{
    if ((self = [super init]) != nil) {
        clientReady = NO;
        shutdownFlag = NO;
        inShutdown = NO;
        rosobjects = [[NSMutableArray alloc] init];
        [ROCore ParseRosObjcURI:uri];
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
    for (RONode *node in rosobjects) {
        [node shutdown:reason];
    }
    rosobjects = nil;
}

-(void)removeNode:(RONode *)node
{
    [rosobjects removeObject:node];
}

-(RONode *)getMaster
{
    if (masterProxy == nil) {
        
    }
    return masterProxy;
}

-(RONode *)createNode:(NSString *)name
{
    for (RONode *node in rosobjects) {
        if ([node.name isEqualToString:name])
            return nil;
    }
    RONode *ret = [[RONode alloc] initWithName:name];
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
