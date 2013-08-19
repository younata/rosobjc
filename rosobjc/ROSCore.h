//
//  ROCore.h
//  rosobjc
//
//  Created by Rachel Brindle on 6/17/13.
//  Copyright (c) 2013 Rachel Brindle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ROSNode.h"

@class HTTPServer;

@interface ROSCore : NSObject
{
    BOOL clientReady;
    BOOL shutdownFlag;
    BOOL inShutdown;
    
    NSMutableArray *rosobjects;
    NSMutableDictionary *knownMessageTypes;
    //ROSNode *node;
    
    HTTPServer *_httpServer;
}

@property (nonatomic, strong) NSString *uri;

// takes a string, outputs an array of form [address, port]
+(NSArray *)ParseRosObjcURI:(NSString *)uri;
+(ROSCore *)sharedCore;

-(BOOL)isInitialized;
-(void)setInitialized:(BOOL)inited;

-(BOOL)isShutdown;
-(BOOL)isShutdownRequested;
-(void)signalShutdown:(NSString *)reason;


-(void)registerMessageClasses:(NSArray *)classes;
-(Class)getClassForTopicType:(NSString *)type;
-(void)parseMessageFilesInDirectory:(NSString *)directory;
-(NSDictionary *)getFieldsForMessageType:(NSString *)messageType;

-(ROSNode *)createNode:(NSString *)name;
-(void)removeNode:(ROSNode *)node;
-(void)startNode:(ROSNode *)node;

-(NSArray *)respondToRPC:(NSString *)method Params:(NSArray *)params;

-(NSArray *)getPublishedTopics:(NSString *)NameSpace;

@end
