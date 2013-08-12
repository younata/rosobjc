//
//  ROSUDP.m
//  rosobjc
//
//  Created by Rachel Brindle on 8/11/13.
//  Copyright (c) 2013 Rachel Brindle. All rights reserved.
//

#import "ROSUDP.h"

@implementation ROSUDP

-(BOOL)hasConnection:(NSURL *)url
{
    return NO; // UDP is a connectionless protocol...
}

-(void)startServerFromNode:(ROSNode *)node
{
    _node = node;
}

-(void)startClient:(NSURL *)url Node:(ROSNode *)node
{
    _node = node;
}

-(int)sendMsg:(ROSMsg *)msg
{
    return 0;
}

@end
