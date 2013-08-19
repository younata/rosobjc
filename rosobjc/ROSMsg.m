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

-(NSArray *)deserialize:(NSString *)str
{
    return nil;
}

-(NSString*)description
{
    return [_buffer description];
}

-(NSString *)md5sum
{
    return nil;
}

-(NSString *)definition
{
    return nil;
}

-(NSString *)type
{
    return nil;
}

-(NSArray *)fields
{
    return nil;
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
    return @[_buffer, _buffer];
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

/*
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
            size = s;
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
        [msgQueue addObject:[msg deserialize:q][0]];
    }
    [buffer setData:[buffer subdataWithRange:NSMakeRange(pos, [buffer length] - pos)]];
}
 */

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
    NSData *ret = nil;
    for (NSString *i in builtInTypes) {
        if ([i isEqualToString:@"bool"] || [i isEqualToString:@"uint8"]) {
            UInt8 foo = htons([data unsignedCharValue]);
            ret = [NSData dataWithBytes:&foo length:1];
        } else if ([i isEqualToString:@"int8"]) {
            int8_t foo = htons([data charValue]);
            ret = [NSData dataWithBytes:&foo length:1];
        } else if ([i isEqualToString:@"int16"]) {
            int16_t foo = htons([data shortValue]);
            ret = [NSData dataWithBytes:&foo length:2];
        } else if ([i isEqualToString:@"uint16"]) {
            UInt16 foo = htons([data unsignedShortValue]);
            ret = [NSData dataWithBytes:&foo length:2];
        } else if ([i isEqualToString:@"int32"]) {
            int32_t foo = htonl([data intValue]);
            ret = [NSData dataWithBytes:&foo length:4];
        } else if ([i isEqualToString:@"uint32"]) {
            UInt32 foo = htonl([data unsignedIntValue]);
            ret = [NSData dataWithBytes:&foo length:4];
        } else if ([i isEqualToString:@"int64"]) {
            int64_t foo = htonl([data longLongValue]);
            ret = [NSData dataWithBytes:&foo length:8];
        } else if ([i isEqualToString:@"uint64"]) {
            UInt64 foo = htonl([data unsignedLongLongValue]);
            ret = [NSData dataWithBytes:&foo length:8];
        } else if ([i isEqualToString:@"float32"]) {
            float foo = htonl([data floatValue]);
            ret = [NSData dataWithBytes:&foo length:4];
        } else if ([i isEqualToString:@"float64"]) {
            double foo = htonl([data doubleValue]);
            ret = [NSData dataWithBytes:&foo length:8];
        } else if ([i isEqualToString:@"string"]) {
            ret = [data dataUsingEncoding:NSUTF8StringEncoding];
        } else if ([i isEqualToString:@"time"] || [i isEqualToString:@"duration"]) {
            float secs = htonl([data secs]);
            float nsecs = htonl([data nsecs]);
            
            NSMutableData *d = [NSMutableData dataWithBytes:&secs length:4];
            [d appendData:[NSData dataWithBytes:&nsecs length:4]];
            ret = d;
        }
    }
    if (ret == nil)
        return ret;
    int blah = htonl([ret length]);
    NSMutableData *d = [NSMutableData dataWithBytes:&blah length:4];
    [d appendData:ret];
    
    return d;
}

NSData *serialize(id self, SEL _cmd)
{
    // get the format...
    NSArray *fields = [self fields];
    
    // built in types...
    NSArray *builtInTypes = @[@"bool", @"int8", @"uint8", @"int16", @"uint16",
                              @"int32", @"uint32", @"int64", @"uint64", @"float32",
                              @"float64", @"string", @"time", @"duration"];
    
    NSMutableData *d = [[NSMutableData alloc] init];
    for (NSArray *i in fields) {
        NSString *type = [i objectAtIndex:0];
        NSString *name = [i objectAtIndex:1];
        SEL getter = NSSelectorFromString(name);
        id foo = [self performSelector:getter];
        if ([builtInTypes containsObject:type]) {
            NSData *temp = serializeBuiltInType(foo, type);
            int l = htonl([temp length]);
            [d appendBytes:&l length:4];
            [d appendData:temp];
        } else {
            NSData *temp = [foo serialize];
            int l = htonl([temp length]);
            [d appendBytes:&l length:4];
            [d appendData:temp];
        }
    }
    return d;
}

NSArray *deserialize(id self, SEL _cmd, NSData *data)
{
    // get the format...
    NSArray *fields = [self fields];
    
    // built in types...
    NSArray *builtInTypes = @[@"bool", @"int8", @"uint8", @"int16", @"uint16",
                              @"int32", @"uint32", @"int64", @"uint64", @"float32",
                              @"float64", @"string", @"time", @"duration"];

    
    NSData *d = data;
    for (NSArray *i in fields) {
        NSString *type = [i objectAtIndex:0];
        NSString *name = [i objectAtIndex:1];
        SEL setter = NSSelectorFromString([NSString stringWithFormat:@"set%@:", [name capitalizedString]]);
        NSString *def = nil;
        if ([i count] > 2)
            def = [i lastObject];
        
        if ([builtInTypes containsObject:type]) {
            int l = 0;
            [d getBytes:&l length:4];
            if ([d length] == 0)
                break;
            d = [d subdataWithRange:NSMakeRange(4, [d length] - 4)];
            if ([type isEqualToString:@"bool"]) {
                UInt8 foo;
                [d getBytes:&foo length:l];
                [self performSelector:setter withObject:@(foo)];
                d = [d subdataWithRange:NSMakeRange(l, [d length] - l)];
            } else if ([type isEqualToString:@"int8"]) {
                int8_t foo;
                [d getBytes:&foo length:l];
                [self performSelector:setter withObject:@(foo)];
                d = [d subdataWithRange:NSMakeRange(l, [d length] - l)];
            } else if ([type isEqualToString:@"uint8"]) {
                UInt8 foo;
                [d getBytes:&foo length:l];
                [self performSelector:setter withObject:@(foo)];
                d = [d subdataWithRange:NSMakeRange(l, [d length] - l)];
            } else if ([type isEqualToString:@"int16"]) {
                int16_t foo;
                [d getBytes:&foo length:l];
                foo = foo;
                [self performSelector:setter withObject:@(foo)];
                d = [d subdataWithRange:NSMakeRange(l, [d length] - l)];
            } else if ([type isEqualToString:@"uint16"]) {
                UInt16 foo;
                [d getBytes:&foo length:l];
                foo = foo;
                [self performSelector:setter withObject:@(foo)];
                d = [d subdataWithRange:NSMakeRange(l, [d length] - l)];
            } else if ([type isEqualToString:@"int32"]) {
                int32_t foo;
                [d getBytes:&foo length:l];
                foo = foo;
                [self performSelector:setter withObject:@(foo)];
                d = [d subdataWithRange:NSMakeRange(l, [d length] - l)];
            } else if ([type isEqualToString:@"uint32"]) {
                UInt32 foo;
                [d getBytes:&foo length:l];
                foo = foo;
                [self performSelector:setter withObject:@(foo)];
                d = [d subdataWithRange:NSMakeRange(l, [d length] - l)];
            } else if ([type isEqualToString:@"int64"]) {
                int64_t foo;
                [d getBytes:&foo length:l];
                foo = foo;
                [self performSelector:setter withObject:@(foo)];
                d = [d subdataWithRange:NSMakeRange(l, [d length] - l)];
            } else if ([type isEqualToString:@"uint64"]) {
                UInt64 foo;
                [d getBytes:&foo length:l];
                foo = foo;
                [self performSelector:setter withObject:@(foo)];
                d = [d subdataWithRange:NSMakeRange(l, [d length] - l)];
            } else if ([type isEqualToString:@"float32"]) {
                float foo;
                [d getBytes:&foo length:l];
                foo = foo;
                [self performSelector:setter withObject:@(foo)];
                d = [d subdataWithRange:NSMakeRange(l, [d length] - l)];
            } else if ([type isEqualToString:@"float64"]) {
                double foo;
                [d getBytes:&foo length:l];
                foo = foo;
                [self performSelector:setter withObject:@(foo)];
                d = [d subdataWithRange:NSMakeRange(l, [d length] - l)];
            } else if ([type isEqualToString:@"string"]) {
                NSString *s = [[NSString alloc] initWithData:[d subdataWithRange:NSMakeRange(0, l)] encoding:NSUTF8StringEncoding];
                d = [d subdataWithRange:NSMakeRange(l, [d length] - l)];
                [self performSelector:setter withObject:s];
            } else if ([type isEqualToString:@"time"] || [type isEqualToString:@"duration"]) {
                // Oh, I hope this works...
                float secs;
                float nsecs;
                [d getBytes:&secs length:4];
                d = [d subdataWithRange:NSMakeRange(4, [d length] - 4)];
                [d getBytes:&nsecs length:4];
                d = [d subdataWithRange:NSMakeRange(4, [d length] - 4)];
                secs = secs;
                nsecs = nsecs;
                ROSTime *t = [[ROSTime alloc] init];
                t.secs = secs;
                t.nsecs = nsecs;
                [self performSelector:setter withObject:t];
            }
        } else {
            Class a = NSClassFromString(type);
            ROSMsg *foo = [[a alloc] init];
            NSArray *b = nil;
            b = [foo deserialize:d];
            d = [b lastObject];
            [self performSelector:setter withObject:[b objectAtIndex:0]];
        }
    }
    return @[self, d];
}

#pragma mark - autogenerating classes

// TODO: get this working better.
// This is probably a more robust way than having a script auto-generate classes.
// However, that script works much better for nearly all cases than this.

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

@implementation ROSGenMsg

-(NSDictionary *)GenerateMessageClass:(NSString *)classname FromFile:(NSURL *)filelocation
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
        NSString *type = [parts objectAtIndex:0];
        if (![builtInTypes containsObject:type] && [[_knownMessages objectForKey:type] firstObject] == nil)
            return nil;
        NSString *a = [parts objectAtIndex:1];
        NSArray *b = [a componentsSeparatedByString:@"="];
        NSString *tn = [b objectAtIndex:0];
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
        NSString *type = [i objectAtIndex:0];
        NSString *name = [i objectAtIndex:1];
        NSString *def = nil;
        if ([fields count] > 2)
            def = [i lastObject];
        NSAssert1([builtInTypes containsObject:type] || [[_knownMessages objectForKey:type] firstObject] != nil, @"Unknown type name %@", type);
        // we do check this earlier, this is just a later check to make sure it works.
        
        Class tc;
        if ([builtInTypes containsObject:type]) {
            if ([type isEqualToString:@"string"]) {
                tc = [NSString class];
            } else if ([type isEqualToString:@"time"] || [type isEqualToString:@"duration"]) {
                tc = [ROSTime class];
            } else {
                tc = [NSNumber class];
            }
        } else {
            tc = [[_knownMessages objectForKey:type] firstObject];
        }
        id foo = [[tc alloc] init];
        class_addIvar(ret, [[@"_" stringByAppendingString:name] UTF8String], sizeof(foo), log2(sizeof(foo)), @encode(id));
        class_addMethod(ret, NSSelectorFromString(name), (IMP)getObject, "@@:");
        class_addMethod(ret, NSSelectorFromString([NSString stringWithFormat:@"set%@:", [name capitalizedString]]), (IMP)setObject, "v@:@");
        foo = nil;
    }
    
    class_replaceMethod(ret, NSSelectorFromString(@"deserialize:"), (IMP)deserialize, "@@:@");
    class_replaceMethod(ret, NSSelectorFromString(@"serialize"), (IMP)serialize, "@@:");
    
    objc_registerClassPair(ret);
    
    // calculate md5sum, calculate the type, message_definition...
    NSString *md5sum = @"";
    NSString *type = @"";
    NSString *definition = @"";
    
    return @{@"message": ret, @"fields": fields, @"md5sum": md5sum, @"type": type, @"definition": definition};
}

@end












