//
//  ROObject.h
//  rosobjc
//
//  Created by Rachel Brindle on 6/17/13.
//  Copyright (c) 2013 Rachel Brindle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ROSNodeDelegate.h"

@class ROSCore;

@interface ROSNode : NSObject
{
    NSMutableArray *publishedTopics;
    NSMutableArray *subscribedTopics;
    BOOL keepRunning;
    NSArray *protocols;
}

@property (nonatomic, weak) id<ROSNodeDelegate> delegate;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, weak) ROSCore *core;
@property (nonatomic, weak) NSString *masterURI;

-(id)initWithName:(NSString *)name;
-(void)shutdown:(NSString *)reason;

-(NSArray *)getPublishedTopics:(NSString *)NameSpace;

-(NSArray *)getBusStats:(NSString *)callerID;
-(NSArray *)getBusInfo:(NSString *)callerID;
-(NSArray *)getMasterUri:(NSString *)callerID;
-(NSArray *)shutdown:(NSString *)callerID msg:(NSString *)msg; // msg can be nil.

-(NSArray *)getSubscriptions:(NSString *)callerID;
-(NSArray *)getPublications:(NSString *)callerID;

-(NSArray *)paramUpdate:(NSString *)callerID key:(NSString *)key val:(id)value;

-(NSArray *)publisherUpdate:(NSString *)callerID topic:(NSString *)topic publishers:(NSArray *)publishers;

-(NSArray *)requestTopic:(NSString *)callerID topic:(NSString *)topic protocols:(NSArray *)protocols;

@end
