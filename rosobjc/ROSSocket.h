//
//  ROSSocket.h
//  rosobjc
//
//  Created by Rachel Brindle on 7/21/13.
//  Copyright (c) 2013 Rachel Brindle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ROSSocket : NSObject
{
    dispatch_queue_t queue;
}

@property (nonatomic) short port;
@property (nonatomic) short queueLength;

@property (nonatomic) __block BOOL run;

-(void)startServer;
-(void)startClient:(NSURL *)url;


@end
