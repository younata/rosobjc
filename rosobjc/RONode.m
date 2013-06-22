//
//  ROObject.m
//  rosobjc
//
//  Created by Rachel Brindle on 6/17/13.
//  Copyright (c) 2013 Rachel Brindle. All rights reserved.
//

#import "RONode.h"
#import "ROCore.h"

@interface RONode ()
{
    BOOL keepRunning;
}

@end

@interface ROCore ()
-(void)removeNode:(RONode *)node;
@end

@implementation RONode

-(id)initWithName:(NSString *)name
{
    if ((self = [super init]) != nil) {
        _name = name;
        keepRunning = YES;
    }
    return self;
}

-(void)shutdown:(NSString *)reason
{
    keepRunning = NO;
    if ([_delegate respondsToSelector:@selector(onShutdown:)])
        [_delegate onShutdown:reason];
    [_core removeNode:self];
}

-(NSArray *)getPublishedTopics:(NSString *)NameSpace
{
    if (NameSpace == nil) {
        NameSpace = @"/";
    }
    // TODO: fix
    return @[@0, @"Not Implemented", @[]];
}

-(NSArray *)getBusStats:(NSString *)callerID
{
}

@end
