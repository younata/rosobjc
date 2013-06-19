//
//  ROObject.h
//  rosobjc
//
//  Created by Rachel Brindle on 6/17/13.
//  Copyright (c) 2013 Rachel Brindle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RONodeDelegate.h"

@class ROCore;

@interface RONode : NSObject
{
    NSMutableArray *publishedTopics;
    NSMutableArray *subscribedTopics;
}

@property (nonatomic, weak) id<RONodeDelegate> delegate;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, weak) ROCore *core;
@property (nonatomic, weak) NSString *masterURI;

-(id)initWithName:(NSString *)name;
-(void)shutdown:(NSString *)reason;

-(NSArray *)getPublishedTopics:(NSString *)NameSpace;

@end
