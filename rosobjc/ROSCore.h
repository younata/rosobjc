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

static NSString *schema = @"rosrpc";
static NSString *master = @"master"; // reserved for master node...

@interface ROSCore : NSObject
{
    BOOL clientReady;
    BOOL shutdownFlag;
    BOOL inShutdown;
    
    NSMutableArray *rosobjects;
    
    HTTPServer *_httpServer;
}

@property (nonatomic, strong, readonly) NSString *uri;

// takes a string, outputs an array of form [address, port]
+(NSArray *)ParseRosObjcURI:(NSString *)uri;
+(ROSCore *)sharedCore;

-(BOOL)isInitialized;
-(BOOL)isShutdown;
-(BOOL)isShutdownRequested;
-(void)signalShutdown:(NSString *)reason;

-(ROSNode *)getMaster;
-(ROSNode *)createNode:(NSString *)name;
-(void)removeNode:(ROSNode *)node;
-(void)startNode:(ROSNode *)node;

-(void)respondToRPC:(NSString *)method Params:(NSArray *)params;

-(NSArray *)getPublishedTopics:(NSString *)NameSpace;

@end
