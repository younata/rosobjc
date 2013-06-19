//
//  ROMsg.m
//  rosobjc
//
//  Created by Rachel Brindle on 6/18/13.
//  Copyright (c) 2013 Rachel Brindle. All rights reserved.
//

#import "ROMsg.h"

@interface ROMsg ()
{
    
}

@end

@implementation ROMsg

-(id)init
{
    if ((self = [super init]) != nil) {
        _slots = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(id)getTypes
{
    return nil;
}

-(NSData *)serialize
{
    return nil;
}

-(id)deserialize:(NSString *)str
{
    return nil;
}

-(NSString*)description
{
    return [_buffer description];
}

@end

@interface ROAnyMsg ()
{
    NSString *md5sum;
    id type;
    BOOL hasHeader;
    NSString *fullText;
    
}

@end

@implementation ROAnyMsg

-(id)init
{
    if ((self = [super init]) != nil) {
        hasHeader = NO;
        fullText = @"";
    }
    return self;
}

-(NSData *)serialize
{
    return _buffer;
}

-(id)deserialize:(NSData *)str
{
    _buffer = str;
    return self;
}

-(NSString *)description
{
    return [NSString stringWithUTF8String:[_buffer bytes]];
}

@end

void serializeMessage(NSMutableData *buffer, int seq, ROMsg *msg)
{
    NSRange r = NSMakeRange(4, [buffer length]-4);
    if ([[msg.slots allKeys] containsObject:@"header"]) {
        ROHeader *header = [msg.slots objectForKey:@"header"];
        header.seq = seq;
        if (header.frameID == nil)
            header.frameID = @"0";
    }
    // write: little indian, unsigned ints...
    NSData *d2 = [msg serialize];
    uint32_t foo = htonl([d2 length]);
    char *h = (char *)&foo;
    NSData *d1 = [NSData dataWithBytes:h length:4];
    [buffer replaceBytesInRange:NSMakeRange(0, 4) withBytes:[d1 bytes]];
    [buffer replaceBytesInRange:r withBytes:[d2 bytes]];
}

void deserializeMessages(NSMutableData *buffer, NSMutableArray *msgQueue, Class msgClass, int maxMsgs, int start)
{
    id msg = [[msgClass alloc] init];
    NSCAssert1(![msg isKindOfClass:[ROMsg class]], @"%p is not a subclass of ROMsg", msgClass);
    int pos = 0;
    int len = [buffer length];
    if (len < 4)
        return;
    int size = -1;
    NSMutableArray *buffs = [[NSMutableArray alloc] init];
    while ((size < 0 && len >= 4) || (size > -1 && len >= size)) {
        if (size < 0 && len >= 4) {
            char foo[4];
            [buffer getBytes:foo range:NSMakeRange(pos, 4)];
            uint32_t s;
            s = (uint32_t)*foo;
            size = NTOHL(s);
            len -= 4;
        }
        if (size > -1 && len >= size) {
            NSData *d = [buffer subdataWithRange:NSMakeRange(pos+4, size)];
            [buffs addObject:d];
            pos += size+4;
            len -= size;
            size = -1;
            if (maxMsgs > 0 && [buffs count] >= maxMsgs)
                break;
        }
    }
    for (NSData *q in buffs) {
        [msgQueue addObject:[msg deserialize:q]];
    }
    [buffer setData:[buffer subdataWithRange:NSMakeRange(pos, [buffer length] - pos)]];
}














