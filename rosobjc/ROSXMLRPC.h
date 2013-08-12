//
//  ROSXMLRPC.h
//  rosobjc
//
//  Created by Rachel Brindle on 6/28/13.
//  Copyright (c) 2013 Rachel Brindle. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "XMLRPC.h"

// Uses the XMLRPC (client) to interact with the master.

// Please note that this is done entirely asynchronously.
// See http://www.ros.org/wiki/ROS/Master_API for the return types.
// (specifically, they'll be (int, str, whatever))

@interface ROSXMLRPCC : NSObject <XMLRPCConnectionDelegate>
{
    NSMutableDictionary *callbacks;
}

@property (atomic, strong) NSURL *URL;

#pragma mark - Arbitrary calls.
-(void)makeCall:(NSString *)methodName WithArgs:(NSArray *)args callback:(void (^)(NSArray *))callback URL:(NSURL *)url;

#pragma mark - Register/unregister methods

-(void)registerService:(NSString *)callerID Service:(NSString *)service ServiceAPI:(NSString *)serviceAPI callback:(void(^)(NSArray *))callback;
-(void)unregisterService:(NSString *)callerID Service:(NSString *)service ServiceAPI:(NSString *)serviceAPI callback:(void(^)(NSArray *))callback;

-(void)registerSubscriber:(NSString *)callerID Topic:(NSString *)topic TopicType:(NSString *)topicType callback:(void(^)(NSArray *))callback;
-(void)unregisterSubscriber:(NSString *)callerID Topic:(NSString *)topic callback:(void(^)(NSArray *))callback;

-(void)registerPublisher:(NSString *)callerID Topic:(NSString *)topic TopicType:(NSString *)topicType callback:(void(^)(NSArray *))callback;
-(void)unregisterPublisher:(NSString *)callerID Topic:(NSString *)topic callback:(void(^)(NSArray *))callback;

#pragma mark - name service and system state

-(void)lookupNode:(NSString *)callerID Node:(NSString *)node callback:(void(^)(NSArray *))callback;

-(void)getPublishedTopics:(NSString *)callerID Subgraph:(NSString *)subgraph callback:(void(^)(NSArray *))callback;
-(void)getTopicTypes:(NSString *)callerID callback:(void(^)(NSArray *))callback;

-(void)getSystemState:(NSString *)callerID callback:(void(^)(NSArray *))callback;

-(void)getURI:(NSString *)callerID callback:(void(^)(NSArray *))callback;

-(void)lookupService:(NSString *)callerID Service:(NSString *)service callback:(void(^)(NSArray *))callback;

@end
