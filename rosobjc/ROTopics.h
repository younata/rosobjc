//
//  ROTopic.h
//  rosobjc
//
//  Created by Rachel Brindle on 6/18/13.
//  Copyright (c) 2013 Rachel Brindle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "xmlrpc/XMLRPC.h"

#include <pthread.h>

@interface ROTopic : NSObject
{
    XMLRPCConnection *connection;
    NSString *_master;
    NSString *_method;
}
@property (nonatomic) Class msgClass;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) id type;

-(id)initWithMaster:(NSString *)master method:(NSString *)method;

-(id)getStats;
-(id)getStatsInfo;
-(void)close;

@end

@interface ROSubscriber : ROTopic
{
    void (^callback)(id);
}

-(void)setOnTopicRcvd:(void(^)(id))block;
-(void)spin;

@end

@interface ROPublisher : ROTopic

-(void)publish:(id)msg;

@end

typedef enum {
    RORegistrationSub = 0,
    RORegistrationPub = 1
} RORegistration;

@interface ROTopicManager : NSObject
{
    NSMutableDictionary *pubs;
    NSMutableDictionary *subs;
    NSMutableSet *topics;
    pthread_mutex_t lock;
    BOOL closed;
}

-(NSArray *)getPubSubInfo;
-(NSArray *)getPubSubStats;

-(void)closeAll;

#pragma mark - Internal methods
-(void)add:(ROTopic *)ps map:(NSMutableDictionary *)map regType:(RORegistration)regType;
-(void)recalculateTopics;
-(void)remove:(ROTopic *)ps map:(NSMutableDictionary *)map regType:(RORegistration)regType;

-(ROTopic *)getImplementation:(NSString *)resolvedName regType(RORegistration)regType;
-(ROTopic *)getPubImpl:(NSString *)resolvedName;
-(ROTopic *)getSubImpl:(NSString *)resolvedName;
-(BOOL)hasSubscription:(NSString *)resolvedName;
-(BOOL)hasPublication:(NSString *)resolvedName;
-(NSArray *)getTopics;

@end
