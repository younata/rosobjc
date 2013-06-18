//
//  ROCore.m
//  rosobjc
//
//  Created by Rachel Brindle on 6/17/13.
//  Copyright (c) 2013 Rachel Brindle. All rights reserved.
//

#import "ROCore.h"

@interface ROCore ()
-(void)setInitialized:(BOOL)inited;

@end

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

-(id)init
{
    if ((self = [super init]) != nil) {
        clientReady = NO;
        shutdownFlag = NO;
        inShutdown = NO;
        rosobjects = [[NSMutableArray alloc] init];
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
    for (id rosobject in rosobjects) {
        [rosobject shutdown];
    }
    [rosobjects removeAllObjects];
    rosobjects = nil;
}

@end
