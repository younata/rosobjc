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

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSMutableDictionary *slots;

-(id)getTypes;
-(NSData *)serialize;
-(NSArray *)deserialize:(NSData *)str;

-(NSString *)md5sum;
-(NSString *)definition;
-(NSString *)type;
-(NSArray *)fields;

@end


@interface ROSHeader : NSObject

@property (nonatomic) int seq;
@property (nonatomic, strong) NSString *frameID;

@end



@interface ROSAnyMsg : ROSMsg

@end

@interface ROSTime : ROSMsg
{
    NSDate *d;
}

@property (nonatomic) float secs;
@property (nonatomic) float nsecs;

-(NSDate *)now;

@end

void serializeMessage(NSMutableData *buffer, int seq, ROSMsg *msg);
void deserializeMessages(NSMutableData *buffer, NSArray *msgQueue, ROSMsg *msgClass, int maxMsgs, int start);

NSData *serialize(id self, SEL _cmd);
NSArray *deserialize(id self, SEL _cmd, NSData *data);

@interface ROSGenMsg : NSObject

@property (nonatomic, weak) NSMutableDictionary *knownMessages; // name: class

-(NSDictionary *)GenerateMessageClass:(NSString *)classname FromFile:(NSURL *)filelocation;

@end

