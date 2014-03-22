//
//  ROSSocket.h
//  rosobjc
//
//  Created by Rachel Brindle on 7/21/13.
//  Copyright (c) 2013 Rachel Brindle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ROSNode.h"
#import "ROSMsg.h"

#import "GCDAsyncSocket.h"

@interface ROSSocket : NSObject <GCDAsyncSocketDelegate>
{
    dispatch_queue_t queue;
    ROSNode *_node;
    int sockfd;
    
    GCDAsyncSocket *serverSock;
    NSMutableArray *servers;
    GCDAsyncSocket *clientSock;
    
    NSMutableData *readData;
    unsigned long long dataLength;
    BOOL exchangedHeaders;
}

@property (nonatomic) uint16_t port;
@property (nonatomic) short queueLength;
@property (nonatomic) Class msgClass;
@property (nonatomic, strong) NSString *topic;
@property (nonatomic, strong) NSString *host;

@property (nonatomic) __block BOOL run;

+(BOOL)localServerAtPort:(uint16_t)port;

-(BOOL)hasConnection:(NSURL *)url;
-(void)startServerFromNode:(ROSNode *)node onAccept:(void (^)(void))onAcc;
-(void)startClient:(NSURL *)url Node:(ROSNode *)node;

-(void)shutdown;

-(NSUInteger)sendMsg:(ROSMsg *)msg;


@end
