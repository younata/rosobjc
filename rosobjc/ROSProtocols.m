//
//  ROProtocols.m
//  rosobjc
//
//  Created by Rachel Brindle on 6/22/13.
//  Copyright (c) 2013 Rachel Brindle. All rights reserved.
//

#import "ROSProtocols.h"
#import <CommonCrypto/CommonDigest.h>

union godIntsSuck {
    uint8_t a[4];
    uint32_t b;
};

NSString *generateMD5(NSString *type)
{
    // Create byte array of unsigned chars
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    // Create 16 byte MD5 hash value, store in buffer
    CC_MD5([type UTF8String], [type length], md5Buffer);
    
    // Convert MD5 value in the buffer to NSString of hex values
    NSMutableString *output = [NSMutableString stringWithCapacity:39];
    [output appendString:@"md5sum="];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x",md5Buffer[i]];
    
    return output;
}

NSString *generateField(NSString *kind, NSString *content, int length)
{
    NSMutableString *output = [NSMutableString stringWithCapacity:length+4];
    
    union godIntsSuck foo;
    foo.b = HTONL(length);
    for (int i = 0; i < 4; i++)
        [output appendFormat:@"%c", foo.a[i]];
    
    [output appendString:[kind stringByAppendingString:@"="]];
    [output appendString:content];
    return output;
}

@implementation ROSProtocol

-(NSString *)generateConnectionHeader
{
    // 4 bytes, which tells how long the connection header is.
    // 4 bytes, defining X
    // X bytes, which is a string (not null terminated)
    //          this string is <fieldname>=<data>
    
    NSAssert(NO, @"Override generateConnectionHeader in your ROSProtocol subclass.");
    return nil;
}

@end

@implementation ROSTCP

#pragma mark - internal
// These methods should probably be done in a subclass, but whatever.
-(NSString *)generateSubscriberHeaders
{
    // message_definition
    // callerid
    // topic
    // md5sum
    // type
    
    // tcp_nodelay (optional)
    // error (optional)
    
    int mdLen = [self.messageDefinition length] + 19;
    int ciLen = [self.callerID length] + 9;
    int tLen = [self.topic length] + 6;
    int mtLen = [self.messageType length] + 5;
    int length = (5*4) + 39 + 4 + mdLen + ciLen + tLen + mtLen;
    
    int tnLen = [self.tcpNodelay length] + 16;
    int eLen = [self.error length] + 10;
    if (self.tcpNodelay != nil) {
        
        length += [self.tcpNodelay length] + 16;
    }
    if (self.error != nil) {
        length += [self.error length] + 10;
    }
    //uint8_t *ret = malloc(sizeof(uint8_t) * length);
    NSMutableString *ret = [NSMutableString stringWithCapacity:length];
    union godIntsSuck foo;
    foo.b = HTONL(length);
    for (int i = 0; i < 4; i++)
        [ret appendFormat:@"%c", foo.a[i]];
    
    [ret appendString:generateField(@"message_definition", self.messageDefinition, mdLen)];
    [ret appendString:generateField(@"callerid", self.callerID, ciLen)];
    [ret appendString:generateField(@"topic", self.topic, tLen)];
    [ret appendString:generateField(@"md5sum", generateMD5(self.messageType), 39)];
    [ret appendString:generateField(@"type", self.messageType, mtLen)];
    
    if (self.tcpNodelay != nil) {
        [ret appendString:generateField(@"tcp_nodelay", self.tcpNodelay, tnLen)];
    }
    if (self.error != nil) {
        [ret appendString:generateField(@"error", self.error, eLen)];
    }
    return ret;
}

-(NSString *)generatePublisherHeaders
{
    // md5sum
    // type
    
    // callerid (optional)
    // latching (optional)
    // error (optional)
    
    int mtLen = [self.messageType length] + 5;
    
    int ciLen = [self.callerID length] + 13;
    int laLen = [self.latching length] + 13;
    int eLen = [self.error length] + 10;
    
    int length = mtLen + (2*4) + 39 + 4;
    if (ciLen > 13)
        length += ciLen;
    if (laLen > 13)
        length += laLen;
    if (eLen > 10)
        length += eLen;
    
    NSMutableString *ret = [NSMutableString stringWithCapacity:length];
    union godIntsSuck foo;
    foo.b = HTONL(length);
    for (int i = 0; i < 4; i++)
        [ret appendFormat:@"%c", foo.a[i]];
    
    //[ret appendString:generateField(@"callerid", self.callerID, ciLen)];
    [ret appendString:generateField(@"md5sum", generateMD5(self.messageType), 39)];
    [ret appendString:generateField(@"type", self.messageType, mtLen)];
    
    if (self.callerID != nil) {
        [ret appendString:generateField(@"callerid", self.callerID, ciLen)];
    }
    if (self.latching != nil) {
        [ret appendString:generateField(@"latching", self.latching, laLen)];
    }
    if (self.error != nil) {
        [ret appendString:generateField(@"error", self.error, eLen)];
    }
    return ret;
}

-(NSString *)generateServiceHeaders
{
    // THIS IS RESPONSE.
    
    // callerid

    // error (optional)
    
    int ciLen = [self.callerID length] + 9;
    int eLen = [self.error length] + 10;
    int length = ciLen + 8;
    if (eLen > 6)
        length += eLen;
    
    NSMutableString *ret = [NSMutableString stringWithCapacity:length];
    union godIntsSuck foo;
    foo.b = HTONL(length);
    for (int i = 0; i < 4; i++)
        [ret appendFormat:@"%c", foo.a[i]];
    
    [ret appendString:generateField(@"callerid", self.callerID, ciLen)];
    if (self.error != nil) {
        [ret appendString:generateField(@"error", self.error, eLen)];
    }
    return ret;
}

-(NSString *)generateServiceClientHeaders
{
    // callerid
    // service
    // md5sum
    // type
    
    // persistent (optional)
    // error (optional)
    
    int ciLen = [self.callerID length] + 9;
    int sLen = [self.service length] + 8;
    int mtLen = [self.messageType length] + 5;
    
    int pLen = [self.persistant length] + 15;
    int eLen = [self.error length] + 10;
    
    int length = ciLen + sLen + mtLen + (4 * 4) + 39 + 4;
    if (pLen > 15)
        length += pLen;
    if (eLen > 10)
        length += eLen;
    
    NSMutableString *ret = [NSMutableString stringWithCapacity:length];
    union godIntsSuck foo;
    foo.b = HTONL(length);
    for (int i = 0; i < 4; i++)
        [ret appendFormat:@"%c", foo.a[i]];
    
    [ret appendString:generateField(@"callerid", self.callerID, ciLen)];
    [ret appendString:generateField(@"service", self.service, sLen)];
    [ret appendString:generateField(@"md5sum", generateMD5(self.messageType), 39)];
    [ret appendString:generateField(@"type", self.messageType, mtLen)];

    if (self.persistant != nil) {
        [ret appendString:generateField(@"persistant", self.persistant, pLen)];
    }
    if (self.error != nil) {
        [ret appendString:generateField(@"error", self.error, eLen)];
    }
    return ret;
}

-(NSString *)generateConnectionHeader
{
    // there has got to be better ways of implementing each of the below methods...
    switch (_connectionType) {
        case ROSTCPSubscriber:
            return [self generateSubscriberHeaders];
            break;
        case ROSTCPPublisher:
            return [self generatePublisherHeaders];
            break;
        case ROSTCPService:
            return [self generateServiceHeaders];
            break;
        case ROSTCPServiceClient:
            return [self generateServiceClientHeaders];
            break;
    }
    return nil;
}

@end

@implementation ROSUDP

-(id)init
{
    NSAssert(NO, @"UDPROS for rosobjc is not yet implemented.");
    return nil;
}

@end