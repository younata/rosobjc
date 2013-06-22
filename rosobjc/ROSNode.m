//
//  ROObject.m
//  rosobjc
//
//  Created by Rachel Brindle on 6/17/13.
//  Copyright (c) 2013 Rachel Brindle. All rights reserved.
//

#import "ROSNode.h"
#import "ROSCore.h"
#import "ROSTopics.h"

@implementation ROSNode

// in rospy, this is actually the ROSHandler class.
// because we're NOT doing the master part of the
// master/slave api (mostly for speed, if someone wants
// to contribute code that works for master, go ahead.
// I personally have no idea how to implement it, without
// depending on ROS to be installed elsewhere.

-(id)initWithName:(NSString *)name
{
    if ((self = [super init]) != nil) {
        _name = name;
        [self commonInit];
    }
    return self;
}

#pragma mark - Internal

-(void)commonInit
{
    keepRunning = YES;
    protocols = @[@"TCPROS"];
    publishedTopics = [[NSMutableArray alloc] init];
    subscribedTopics = [[NSMutableArray alloc] init];
}

#pragma mark - Public

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
    NSArray *foo = [[ROSTopicManager sharedTopicManager] getPubSubStats];
    return @[@1, @"", [foo arrayByAddingObject:@[]]];
}

-(NSArray *)getBusInfo:(NSString *)callerID
{
    return @[@1, @"bus info", [[ROSTopicManager sharedTopicManager] getPubSubInfo]];
}

-(NSArray *)getMasterUri:(NSString *)callerID
{
    if (self.masterURI != nil) {
        return @[@1, self.masterURI, self.masterURI];
    }
    return @[@0, @"master URI not set", @""];
}

-(NSArray *)shutdown:(NSString *)callerID msg:(NSString *)msg
{
    return nil;
}

-(NSArray *)getSubscriptions:(NSString *)callerID
{
    return @[@1, @"subscriptions", [[ROSTopicManager sharedTopicManager] getSubscriptions]];
}

-(NSArray *)getPublications:(NSString *)callerID
{
    return @[@1, @"publications", [[ROSTopicManager sharedTopicManager] getPublications]];
}

#pragma mark - internal
-(NSArray *)connectTopic:(NSString*)topic uri:(NSString *)URI
{
    ROTopic *t = [[ROSTopicManager sharedTopicManager] getSubImpl:topic];
    if (t == nil)
        return @[@(-1), [NSString stringWithFormat:@"No subscriber for topic [%@]", topic], @0];
    else if ([t hasConnection:URI])
        return @[@1, [NSString stringWithFormat:@"connectTopic:(%@: subscriber already connected to publisher", topic], @0];
    //[protocols addObject:@"TCPROS"]; Not yet implemented.
    // FIXME: better way of doing the above.
    if ([protocols count] == 0) {
        return @[@0, @"ERROR: no available protocol handlers", @0];
    }
    // actually connect.
#error implement RONode connectTopic
    return nil;
}

#pragma mark - public

-(NSArray *)paramUpdate:(NSString *)callerID key:(NSString *)key val:(id)value
{
#error implement param server cache, then uncomment below.
    /*
     if (getParamServerCache().update(key, value))
        return @[@1, @"", @0];
     return @[@(-1), @"not subscribed", @0];
     */
    return nil;
}

-(NSArray *)publisherUpdate:(NSString *)callerID topic:(NSString *)topic publishers:(NSArray *)publishers
{
    for (NSString *uri in publishers) {
#error Implement publisherUpdate
    }
}

-(NSArray *)requestTopic:(NSString *)callerID topic:(NSString *)topic protocols:(NSArray *)_protocols
{
    if (![[ROTopicManager sharedTopicManager] hasPublication:topic])
        return @[@(-1), [NSString stringWithFormat:@"Not a publisher of %@", topic], @[]];
#error implement protocols...
    NSAssert([_protocols containsObject:@"TCPROS"], @"Only supported protocol is tcpros");
    //return [[_protocols objectAtIndex:0] initPublisher];
    return @[@0, @"no supported protocol implementations", @[]];
}

@end
  
  
  
  
