//
//  ROTopic.m
//  rosobjc
//
//  Created by Rachel Brindle on 6/18/13.
//  Copyright (c) 2013 Rachel Brindle. All rights reserved.
//

#import "ROTopics.h"
#import "ROMsg.h"

@implementation ROTopic

-(void)setMsgClass:(Class)msgClass
{
    id foo = [[msgClass alloc] init];
    NSAssert1([foo isKindOfClass:[ROMsg class]], @"%p is not a subclass of ROMsg", msgClass);
    _msgClass = msgClass;
}

@end

@implementation ROSubscriber

-(void)setOnTopicRcvd:(void (^)(id))block
{
    callback = block;
}

-(void)onTopicRcvd
{
    
}

@end

@implementation ROPublisher

-(void)publish:(id)msg
{
    
}

@end
