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

@interface ROSSocket : NSObject
{
    dispatch_queue_t queue;
    ROSNode *_node;
    int sockfd;
}

@property (nonatomic) short port;
@property (nonatomic) short queueLength;
@property (nonatomic) Class msgClass;
@property (nonatomic, strong) NSString *topic;

@property (nonatomic) __block BOOL run;

-(BOOL)hasConnection:(NSURL *)url;
-(void)startServerFromNode:(ROSNode *)node;
-(void)startClient:(NSURL *)url Node:(ROSNode *)node;

-(int)sendMsg:(ROSMsg *)msg;


@end
