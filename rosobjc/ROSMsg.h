//
//  ROMsg.h
//  rosobjc
//
//  Created by Rachel Brindle on 6/18/13.
//  Copyright (c) 2013 Rachel Brindle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ROSMsg : NSObject
{
    NSData *_buffer;
}

@property (nonatomic, strong) NSMutableDictionary *slots;

-(id)getTypes;
-(NSData *)serialize;
-(id)deserialize:(NSData *)str;

@end



@interface ROSHeader : NSObject

@property (nonatomic) int seq;
@property (nonatomic, strong) NSString *frameID;

@end



@interface ROSAnyMsg : ROMsg

@end

void serializeMessage(NSMutableData *buffer, int seq, ROMsg *msg);
void deserializeMessages(NSMutableData *buffer, NSArray *msgQueue, ROMsg *msgClass, int maxMsgs, int start);

