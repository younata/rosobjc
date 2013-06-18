//
//  ROCore.h
//  rosobjc
//
//  Created by Rachel Brindle on 6/17/13.
//  Copyright (c) 2013 Rachel Brindle. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *schema = @"rosrpc";
static NSString *master = @"master"; // reserved for master node...

@interface ROCore : NSObject
{
    BOOL clientReady;
    BOOL shutdownFlag;
    BOOL inShutdown;
    
    NSMutableArray *rosobjects;
}

@property (nonatomic, strong) NSString *uri;

// takes a string, outputs an array of form [address, port]
+(NSArray *)ParseRosObjcURI:(NSString *)uri;

-(BOOL)isInitialized;
-(BOOL)isShutdown;
-(BOOL)isShutdownRequested;

-(void)signalShutdown:(NSString *)reason;

@end
