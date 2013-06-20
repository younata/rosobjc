//
//  ROTopic.m
//  rosobjc
//
//  Created by Rachel Brindle on 6/18/13.
//  Copyright (c) 2013 Rachel Brindle. All rights reserved.
//

#import "ROTopics.h"
#import "ROMsg.h"

@implementation ROTopic

-(id)initWithMaster:(NSString *)master method:(NSString *)method
{
    if ((self = [super init]) != nil) {
        _master = master;
        _method = method;
    }
    return self;
}

-(void)setMsgClass:(Class)msgClass
{
    id foo = [[msgClass alloc] init];
    NSAssert1([foo isKindOfClass:[ROMsg class]], @"%p is not a subclass of ROMsg", msgClass);
    _msgClass = msgClass;
}

@end



@implementation ROSubscriber

-(void)spin
{
    //XMLRPCConnectionManager *manager = [XMLRPCConnectionManager sharedManager];
    //NSString *s =
}

-(void)setOnTopicRcvd:(void (^)(id))block
{
    callback = block;
}

-(void)onTopicRcvd
{
    
}

@end



@implementation ROPublisher

-(void)publish:(id)msg
{
    
}

@end


@implementation ROTopicManager

-(id)init
{
    if ((self = [super init]) != nil) {
        pubs = [[NSMutableDictionary alloc] init];
        subs = [[NSMutableDictionary alloc] init];
        topics = [[NSMutableSet alloc] init];
        pthread_mutex_init(&lock, NULL);
        closed = NO;
    }
    return self;
}

-(NSArray *)pubsAndSubs
{
    return [[pubs allValues] arrayByAddingObjectsFromArray:[subs allValues]];
}

-(NSArray *)getPubSubInfo
{
    pthread_mutex_lock(&lock);
    NSMutableArray *ret = [[NSMutableArray alloc] init];
    for (ROTopic *s in [self pubsAndSubs]) {
        [ret addObject:[s getStatsInfo]];
    }
    pthread_mutex_unlock(&lock);
    return ret;
}

-(NSArray *)getPubSubStats
{
    pthread_mutex_lock(&lock);
    NSMutableArray *pubInfo = [[NSMutableArray alloc] initWithCapacity:[pubs count]];
    for (ROTopic *s in [pubs allValues]) {
        [pubInfo addObject:[s getStats]];
    }
    NSMutableArray *subInfo = [[NSMutableArray alloc] initWithCapacity:[subs count]];
    for (ROTopic *s in [subs allValues]) {
        [subInfo addObject:[s getStats]];
    }
    pthread_mutex_unlock(&lock);
    return @[pubInfo, subInfo];
}

-(void)closeAll
{
    closed = YES;
    pthread_mutex_lock(&lock);
    for (ROTopic *t in [self pubsAndSubs]) {
        [t close];
    }
    [pubs removeAllObjects];
    [subs removeAllObjects];
    pthread_mutex_unlock(&lock);
}

@end









