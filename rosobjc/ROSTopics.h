//
//  ROTopic.h
//  rosobjc
//
//  Created by Rachel Brindle on 6/18/13.
//  Copyright (c) 2013 Rachel Brindle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ROSXMLRPC.h"

#include <pthread.h>

@interface ROSTopic : NSObject
{
    NSString *_master; // master URI
    
    ROSXMLRPCC *masterClient;
}
@property (nonatomic) Class msgClass; // returns messages of this type.
@property (nonatomic, strong) NSString *name; // topic name.
@property (nonatomic, strong) NSString *method;
@property (nonatomic, strong) id type;

-(id)initWithMaster:(NSString *)master method:(NSString *)method;

-(id)getStats;
-(id)getStatsInfo;
-(void)close;
-(BOOL)hasConnection:(NSString *)URI;

@end

@interface ROSSubscriber : ROSTopic
{
    void (^callback)(id);
}

-(void)setOnTopicRcvd:(void(^)(id))block;
-(void)spin;

@end

@interface ROSPublisher : ROSTopic

-(void)publish:(id)msg;

@end

typedef enum {
    RORegistrationSub = 0,
    RORegistrationPub = 1
} RORegistration;

@interface ROSTopicManager : NSObject
{
    NSMutableDictionary *pubs;
    NSMutableDictionary *subs;
    NSMutableSet *topics;
    pthread_mutex_t lock;
    BOOL closed;
}

+(ROSTopicManager *)sharedTopicManager;

-(NSArray *)getPubSubInfo;
-(NSArray *)getPubSubStats;

-(void)closeAll;

#pragma mark - Internal methods
-(void)add:(ROSTopic *)ps map:(NSMutableDictionary *)map regType:(RORegistration)regType;
-(void)recalculateTopics;
-(void)remove:(ROSTopic *)ps map:(NSMutableDictionary *)map regType:(RORegistration)regType;

-(ROSTopic *)getImplementation:(NSString *)resolvedName regType:(RORegistration)regType;
-(ROSTopic *)getPubImpl:(NSString *)resolvedName;
-(ROSTopic *)getSubImpl:(NSString *)resolvedName;
-(BOOL)hasSubscription:(NSString *)resolvedName;
-(BOOL)hasPublication:(NSString *)resolvedName;
-(NSArray *)getSubscriptions;
-(NSArray *)getPublications;
-(NSArray *)getTopics;


@end
