//
//  ROTopic.m
//  rosobjc
//
//  Created by Rachel Brindle on 6/18/13.
//  Copyright (c) 2013 Rachel Brindle. All rights reserved.
//

#import "ROSTopics.h"
#import "ROSMsg.h"

@implementation ROSTopic

-(id)initWithMaster:(NSString *)master method:(NSString *)method
{
    if ((self = [super init]) != nil) {
        _master = master;
        _method = method;
        masterClient = [[ROSXMLRPCC alloc] init];
        masterClient.URL = [NSURL URLWithString:_master];
    }
    return self;
}

-(void)setMsgClass:(Class)msgClass
{
    id foo = [[msgClass alloc] init];
    NSAssert1([foo isKindOfClass:[ROSMsg class]], @"%p is not a subclass of ROSMsg", msgClass);
    _msgClass = msgClass;
}

-(id)getStats
{
    return nil;
}

-(id)getStatsInfo
{
    return nil;
}

-(void)close
{
    // subscriber/publisher should implement this.
}

-(BOOL)hasConnection:(NSString *)URI
{
    return NO;
}

@end



@implementation ROSSubscriber

-(void)spin
{
    //XMLRPCConnectionManager *manager = [XMLRPCConnectionManager sharedManager];
    //NSString *s =
    [masterClient registerSubscriber:[self method] Topic:[self name] TopicType:[[[self msgClass] alloc] name] callback:^(NSArray *foo){
        ;
    }];
}

-(void)setOnTopicRcvd:(void (^)(id))block
{
    callback = block;
}

-(void)onTopicRcvd
{
    
}

@end



@implementation ROSPublisher

-(void)publish:(id)msg
{
    
}

@end

ROSTopicManager *topicManager;

@implementation ROSTopicManager

+(void)initialize
{
    static BOOL initialized = NO;
    if (!initialized) {
        initialized = YES;
        topicManager = [[ROSTopicManager alloc] init];
    }
}

+(ROSTopicManager *)sharedTopicManager
{
    return topicManager;
}

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

-(void)lock
{
    pthread_mutex_lock(&lock);
}

-(void)unlock
{
    pthread_mutex_unlock(&lock);
}

-(NSArray *)pubsAndSubs
{
    return [[pubs allValues] arrayByAddingObjectsFromArray:[subs allValues]];
}

-(NSArray *)getPubSubInfo
{
    [self lock];
    NSMutableArray *ret = [[NSMutableArray alloc] init];
    for (ROSTopic *s in [self pubsAndSubs]) {
        [ret addObject:[s getStatsInfo]];
    }
    [self unlock];
    return ret;
}

-(NSArray *)getPubSubStats
{
    [self lock];
    NSMutableArray *pubInfo = [[NSMutableArray alloc] initWithCapacity:[pubs count]];
    for (ROSTopic *s in [pubs allValues]) {
        [pubInfo addObject:[s getStats]];
    }
    NSMutableArray *subInfo = [[NSMutableArray alloc] initWithCapacity:[subs count]];
    for (ROSTopic *s in [subs allValues]) {
        [subInfo addObject:[s getStats]];
    }
    [self unlock];
    return @[pubInfo, subInfo];
}

-(void)closeAll
{
    closed = YES;
    [self lock];
    for (ROSTopic *t in [self pubsAndSubs]) {
        [t close];
    }
    [pubs removeAllObjects];
    [subs removeAllObjects];
    [self unlock];
}

-(void)add:(ROSTopic *)ps map:(NSMutableDictionary *)map regType:(RORegistration)regType
{
    NSString *resolvedName = [ps name];
    [self lock];
    
    [map setObject:ps forKey:resolvedName];
    [topics addObject:resolvedName];
    // get_registration_listeners().notify_added(resolvedName, ps.type, reg_type);
    
    [self unlock];
}

-(void)recalculateTopics
{
    NSArray *foo = [self pubsAndSubs];
    topics = [[NSMutableSet alloc] initWithCapacity:[foo count]];
    for (ROSTopic *t in foo) {
        [topics addObject:t.name];
    }
}

-(void)remove:(ROSTopic *)ps map:(NSMutableDictionary *)map regType:(RORegistration)regType
{
    NSString *resolvedName = [ps name];
    [self lock];
    [map removeObjectForKey:resolvedName];
    [self recalculateTopics];
    // get_registration_listeners().notify_removed(resolvedName, ps.type, reg_type);

    [self unlock];
}

-(ROSTopic *)getImplementation:(NSString *)resolvedName regType:(RORegistration)regType
{
    NSMutableDictionary *a;
    if (regType == RORegistrationPub)
        a = pubs;
    else if (regType == RORegistrationSub)
        a = subs;
    else
        NSAssert1(NO, @"Invalid reg type %d", regType);
    return [a objectForKey:resolvedName];
}

-(ROSTopic *)getPubImpl:(NSString *)resolvedName
{
    return [pubs objectForKey:resolvedName];
}

-(ROSTopic *)getSubImpl:(NSString *)resolvedName
{
    return [subs objectForKey:resolvedName];
}

-(BOOL)hasSubscription:(NSString *)resolvedName
{
    return [subs.allKeys containsObject:resolvedName];
}

-(BOOL)hasPublication:(NSString *)resolvedName
{
    return [pubs.allKeys containsObject:resolvedName];
}

-(NSArray *)getTopics
{
    return [topics allObjects];
}

-(NSArray *)getList:(NSDictionary *)dict
{
    NSMutableArray *ret = [[NSMutableArray alloc] init];
    for (NSString *k in [dict allKeys]) {
        [ret addObject:@[k, [[dict objectForKey:k] type]]];
    }
    return ret;
}

-(NSArray *)getSubscriptions
{
    return [self getList:subs];
}

-(NSArray *)getPublications
{
    return [self getList:pubs];
}

@end









