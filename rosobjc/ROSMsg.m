//
//  ROMsg.m
//  rosobjc
//
//  Created by Rachel Brindle on 6/18/13.
//  Copyright (c) 2013 Rachel Brindle. All rights reserved.
//

#import "ROSMsg.h"
#import <objc/runtime.h>

#import "ROSCore.h"

@interface ROSMsg ()
{
    
}

@end

@implementation ROSMsg

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

-(NSArray *)decodeData:(NSString *)str
{
    return nil;
}

-(NSString*)description
{
    return [_buffer description];
}

@end

@interface ROSAnyMsg ()
{
    NSString *md5sum;
    id type;
    BOOL hasHeader;
    NSString *fullText;
    
}

@end

@implementation ROSAnyMsg

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

-(NSArray *)deserialize:(NSData *)str
{
    _buffer = str;
    return @[_buffer, @""];
}

-(NSString *)description
{
    return [NSString stringWithUTF8String:[_buffer bytes]];
}

@end

@implementation ROSTime

-(NSDate *)now
{
    return [NSDate date];
}

@end

void serializeMessage(NSMutableData *buffer, int seq, ROSMsg *msg)
{
    NSRange r = NSMakeRange(4, [buffer length]-4);
    if ([[msg.slots allKeys] containsObject:@"header"]) {
        ROSHeader *header = [msg.slots objectForKey:@"header"];
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
    NSCAssert1(![msg isKindOfClass:[ROSMsg class]], @"%p is not a subclass of ROMsg", msgClass);
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
        [msgQueue addObject:[[msg deserialize:q] firstObject]];
    }
    [buffer setData:[buffer subdataWithRange:NSMakeRange(pos, [buffer length] - pos)]];
}

#pragma mark - autogenerating classes

id getObject(id self, SEL _cmd)
{
    NSString *cmd = [[NSString alloc] initWithUTF8String:sel_getName(_cmd)];
    
    return [self valueForKey:[@"_" stringByAppendingString:cmd]];
}

void setObject(id self, SEL _cmd, id obj)
{
    NSString *cmd = [[NSString alloc] initWithUTF8String:sel_getName(_cmd)];
    
    // cmd is of form setValue:...
    NSString *iv = [[cmd substringWithRange:NSMakeRange(3, [cmd length] - 4)] lowercaseString];
    
    [self setValue:obj forKey:[@"_" stringByAppendingString:iv]];
}

/*
 bool
 int8
 uint8
 int16
 uint16
 int32
 uint32
 int64
 uint64
 float32
 float64
 string
 time
 duration
 */

NSData *serializeBuiltInType(id data, NSString *type)
{
    NSArray *builtInTypes = @[@"bool", @"int8", @"uint8", @"int16", @"uint16",
                              @"int32", @"uint32", @"int64", @"uint64", @"float32",
                              @"float64", @"string", @"time", @"duration"];
    for (NSString *i in builtInTypes) {
        if ([i isEqualToString:@"bool"] || [i isEqualToString:@"uint8"]) {
            UInt8 foo = htons([data unsignedCharValue]);
            return [NSData dataWithBytes:&foo length:1];
        } else if ([i isEqualToString:@"int8"]) {
            int8_t foo = htons([data charValue]);
            return [NSData dataWithBytes:&foo length:1];
        } else if ([i isEqualToString:@"int16"]) {
            int16_t foo = htons([data shortValue]);
            return [NSData dataWithBytes:&foo length:2];
        } else if ([i isEqualToString:@"uint16"]) {
            UInt16 foo = htons([data unsignedShortValue]);
            return [NSData dataWithBytes:&foo length:2];
        } else if ([i isEqualToString:@"int32"]) {
            int32_t foo = htonl([data intValue]);
            return [NSData dataWithBytes:&foo length:4];
        } else if ([i isEqualToString:@"uint32"]) {
            UInt32 foo = htonl([data unsignedIntValue]);
            return [NSData dataWithBytes:&foo length:4];
        } else if ([i isEqualToString:@"int64"]) {
            int64_t foo = htonl([data longLongValue]);
            return [NSData dataWithBytes:&foo length:8];
        } else if ([i isEqualToString:@"uint64"]) {
            UInt64 foo = htonl([data unsignedLongLongValue]);
            return [NSData dataWithBytes:&foo length:8];
        } else if ([i isEqualToString:@"float32"]) {
            float foo = htonl([data floatValue]);
            return [NSData dataWithBytes:&foo length:4];
        } else if ([i isEqualToString:@"float64"]) {
            double foo = htonl([data doubleValue]);
            return [NSData dataWithBytes:&foo length:8];
        } else if ([i isEqualToString:@"string"]) {
            return [data dataUsingEncoding:NSUTF8StringEncoding];
        } else if ([i isEqualToString:@"time"] || [i isEqualToString:@"duration"]) {
            float secs = htonl([data secs]);
            float nsecs = htonl([data nsecs]);
            
            NSMutableData *d = [NSMutableData dataWithBytes:&secs length:4];
            [d appendData:[NSData dataWithBytes:&nsecs length:4]];
            return d;
        }
    }
    return nil;
}

NSData *serialize(id self, SEL _cmd)
{
    // get the format...
    NSArray *fields = [[ROSCore sharedCore] getFieldsForMessageType:[self classNameForClass:[self class]]];
    
    // built in types...
    NSArray *builtInTypes = @[@"bool", @"int8", @"uint8", @"int16", @"uint16",
                              @"int32", @"uint32", @"int64", @"uint64", @"float32",
                              @"float64", @"string", @"time", @"duration"];
    
    NSMutableData *d = [[NSMutableData alloc] init];
    for (NSArray *i in fields) {
        NSString *type = [i firstObject];
        NSString *name = [i objectAtIndex:1];
        id foo = [self valueForKey:[@"_" stringByAppendingString:name]];
        //NSString *def = nil;
        if ([i count] > 2)
            continue;
            //def = [i lastObject];
        // I, actually, am not sure if constants are transmitted or not. They shouldn't be, but I'll look it up later.
        if ([builtInTypes containsObject:type]) {
            [d appendData:serializeBuiltInType(foo, type)];
        } else {
            [d appendData:[foo serialize]];
        }
    }
    return d;
}

NSArray *deserialize(id self, SEL _cmd, NSData *data)
{
    // get the format...
    NSArray *fields = [[ROSCore sharedCore] getFieldsForMessageType:[self classNameForClass:[self class]]];
    
    // built in types...
    NSArray *builtInTypes = @[@"bool", @"int8", @"uint8", @"int16", @"uint16",
                              @"int32", @"uint32", @"int64", @"uint64", @"float32",
                              @"float64", @"string", @"time", @"duration"];

    
    NSData *d = data;
    for (NSArray *i in fields) {
        NSString *type = [i firstObject];
        NSString *name = [i objectAtIndex:1];
        NSString *def = nil;
        if ([i count] > 2)
            def = [i lastObject];
        
        if ([builtInTypes containsObject:type]) {
            for (NSString *i in builtInTypes) {
                if ([i isEqualToString:@"bool"]) {
                    UInt8 foo;
                    [d getBytes:&foo length:1];
                    [self setObject:@(foo) forKey:[@"_" stringByAppendingString:name]];
                    d = [d subdataWithRange:NSMakeRange(1, [d length] - 1)];
                } else if ([i isEqualToString:@"int8"]) {
                    int8_t foo;
                    [d getBytes:&foo length:1];
                    [self setObject:@(foo) forKey:[@"_" stringByAppendingString:name]];
                    d = [d subdataWithRange:NSMakeRange(1, [d length] - 1)];
                } else if ([i isEqualToString:@"uint8"]) {
                    UInt8 foo;
                    [d getBytes:&foo length:1];
                    [self setObject:@(foo) forKey:[@"_" stringByAppendingString:name]];
                    d = [d subdataWithRange:NSMakeRange(1, [d length] - 1)];
                } else if ([i isEqualToString:@"int16"]) {
                    int16_t foo;
                    [d getBytes:&foo length:2];
                    foo = ntohs(foo);
                    [self setObject:@(foo) forKey:[@"_" stringByAppendingString:name]];
                    d = [d subdataWithRange:NSMakeRange(2, [d length] - 2)];
                } else if ([i isEqualToString:@"uint16"]) {
                    UInt16 foo;
                    [d getBytes:&foo length:2];
                    foo = ntohs(foo);
                    [self setObject:@(foo) forKey:[@"_" stringByAppendingString:name]];
                    d = [d subdataWithRange:NSMakeRange(2, [d length] - 2)];
                } else if ([i isEqualToString:@"int32"]) {
                    int32_t foo;
                    [d getBytes:&foo length:4];
                    foo = ntohl(foo);
                    [self setObject:@(foo) forKey:[@"_" stringByAppendingString:name]];
                    d = [d subdataWithRange:NSMakeRange(4, [d length] - 4)];
                } else if ([i isEqualToString:@"uint32"]) {
                    UInt32 foo;
                    [d getBytes:&foo length:4];
                    foo = ntohl(foo);
                    [self setObject:@(foo) forKey:[@"_" stringByAppendingString:name]];
                    d = [d subdataWithRange:NSMakeRange(4, [d length] - 4)];
                } else if ([i isEqualToString:@"int64"]) {
                    int64_t foo;
                    [d getBytes:&foo length:8];
                    foo = ntohl(foo);
                    [self setObject:@(foo) forKey:[@"_" stringByAppendingString:name]];
                    d = [d subdataWithRange:NSMakeRange(8, [d length] - 8)];
                } else if ([i isEqualToString:@"uint64"]) {
                    UInt64 foo;
                    [d getBytes:&foo length:8];
                    foo = ntohl(foo);
                    [self setObject:@(foo) forKey:[@"_" stringByAppendingString:name]];
                    d = [d subdataWithRange:NSMakeRange(8, [d length] - 8)];
                } else if ([i isEqualToString:@"float32"]) {
                    float foo;
                    [d getBytes:&foo length:4];
                    foo = ntohl(foo);
                    [self setObject:@(foo) forKey:[@"_" stringByAppendingString:name]];
                    d = [d subdataWithRange:NSMakeRange(4, [d length] - 4)];
                } else if ([i isEqualToString:@"float64"]) {
                    double foo;
                    [d getBytes:&foo length:8];
                    foo = ntohl(foo);
                    [self setObject:@(foo) forKey:[@"_" stringByAppendingString:name]];
                    d = [d subdataWithRange:NSMakeRange(8, [d length] - 8)];
                } else if ([i isEqualToString:@"string"]) {
                    NSMutableString *s = [[NSMutableString alloc] init];
                    char foo;
                    do {
                        [d getBytes:&foo length:1];
                        [s appendFormat:@"%c", foo];
                        d = [d subdataWithRange:NSMakeRange(1, [d length] - 1)];
                    } while (foo != 0);
                    [self setObject:[NSString stringWithString:s] forKey:[@"_" stringByAppendingString:name]];
                } else if ([i isEqualToString:@"time"] || [i isEqualToString:@"duration"]) {
                    float secs;
                    float nsecs;
                    [d getBytes:&secs length:4];
                    d = [d subdataWithRange:NSMakeRange(4, [d length] - 4)];
                    [d getBytes:&nsecs length:4];
                    d = [d subdataWithRange:NSMakeRange(4, [d length] - 4)];
                    secs = ntohl(secs);
                    nsecs = ntohl(nsecs);
                    ROSTime *t = [[ROSTime alloc] init];
                    t.secs = secs;
                    t.nsecs = nsecs;
                    [self setObject:t forKey:[@"_" stringByAppendingString:name]];
                }
            }
        } else {
            Class a = NSClassFromString(type);
            id foo = [[a alloc] init];
            SEL blah = NSSelectorFromString(@"decodeData:");
            NSArray *b = nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            if ([foo respondsToSelector:blah])
                b = [foo performSelector:blah withObject:d];
#pragma clang diagnostic pop
            d = [b lastObject];
            [self setObject:[b firstObject] forKey:[@"_" stringByAppendingString:name]];
        }
    }
    return @[self, d];
}

@implementation ROSGenMsg

-(NSArray *)GenerateMessageClass:(NSString *)classname FromFile:(NSURL *)filelocation
{
    if (_knownMessages == nil) {
        return nil;
    }
    
    NSArray *builtInTypes = @[@"bool", @"int8", @"uint8", @"int16", @"uint16",
                              @"int32", @"uint32", @"int64", @"uint64", @"float32",
                              @"float64", @"string", @"time", @"duration"];

    
    NSString *str = [NSString stringWithContentsOfURL:filelocation encoding:NSUTF8StringEncoding error:nil];
    if (str == nil) {
        return nil;
    }
    
    NSMutableArray *fields = [[NSMutableArray alloc] init];
    
    // read the file... then go through fields... bleh.
    NSArray *lines = [str componentsSeparatedByString:@"\n"];
    for (NSString *i in lines) {
        // check for comment
        NSString *nc = [[str componentsSeparatedByString:@"#"] objectAtIndex:0];
        NSArray *parts = [nc componentsSeparatedByString:@" "];
        if ([parts count] < 2)
            continue;
        NSString *type = [parts firstObject];
        if (![builtInTypes containsObject:type] && [[_knownMessages objectForKey:type] firstObject] == nil)
            return nil;
        NSString *a = [parts objectAtIndex:1];
        NSArray *b = [a componentsSeparatedByString:@"="];
        NSString *tn = [b firstObject];
        NSString *def = nil;
        if ([b count] > 1) {
            def = [b objectAtIndex:1];
            [fields addObject:@[type, tn, def]];
        } else {
            [fields addObject:@[type, tn]];
        }
    }
    
    // Run away, run far away.
    Class ret = objc_allocateClassPair([ROSMsg class], [classname UTF8String], 0);
    for (NSArray *i in fields) {
        NSString *type = [i firstObject];
        NSString *name = [i objectAtIndex:1];
        NSString *def = nil;
        if ([fields count] > 2)
            def = [i lastObject];
        Class tc = [[_knownMessages objectForKey:type] firstObject];
        NSAssert1(tc != nil, @"Unknown type name %@", type);
        // we do check this earlier, this is just a later check to make sure shit works.
        id foo = [[tc alloc] init];
        class_addIvar(ret, [[@"_" stringByAppendingString:name] UTF8String], sizeof(foo), log2(sizeof(foo)), @encode(id));
        class_addMethod(ret, NSSelectorFromString(name), (IMP)getObject, "@@:");
        class_addMethod(ret, NSSelectorFromString([NSString stringWithFormat:@"set%@:", [name capitalizedString]]), (IMP)setObject, "v@:@");
        foo = nil;
    }
    
    class_replaceMethod(ret, NSSelectorFromString(@"deserialize:"), (IMP)deserialize, "@@:@");
    class_replaceMethod(ret, NSSelectorFromString(@"serialize"), (IMP)serialize, "@@:");
    
    objc_registerClassPair(ret);
    
    return @[ret, fields];
}

@end












