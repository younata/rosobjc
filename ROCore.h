//
//  ROCore.h
//  rosobjc
//
//  Created by Rachel Brindle on 6/17/13.
//  Copyright (c) 2013 Rachel Brindle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RONode.h"
#import "xmlrpc/XMLRPC.h"

static NSString *schema = @"rosrpc";
static NSString *master = @"master"; // reserved for master node...

@interface ROCore : NSObject
{
    BOOL clientReady;
    BOOL shutdownFlag;
    BOOL inShutdown;
    
    NSMutableArray *rosobjects;
}

@property (nonatomic, strong, readonly) NSString *uri;

// takes a string, outputs an array of form [address, port]
+(NSArray *)ParseRosObjcURI:(NSString *)uri;
//+(ROCore *)sharedCore;

-(BOOL)isInitialized;
-(BOOL)isShutdown;
-(BOOL)isShutdownRequested;
-(void)signalShutdown:(NSString *)reason;

-(id)initWithMasterURI:(NSString *)uri;

-(RONode *)getMaster;
-(RONode *)createNode:(NSString *)name;
-(void)removeNode:(RONode *)node;
-(void)startNode:(RONode *)node;

-(NSArray *)getPublishedTopics:(NSString *)NameSpace;

@end
