//
//  ROTopic.h
//  rosobjc
//
//  Created by Rachel Brindle on 6/18/13.
//  Copyright (c) 2013 Rachel Brindle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ROTopic : NSObject

@property (nonatomic) Class msgClass;

@end

@interface ROSubscriber : ROTopic
{
    void (^callback)(id);
}

-(void)setOnTopicRcvd:(void(^)(id))block;

@end

@interface ROPublisher : ROTopic

-(void)publish:(id)msg;

@end
