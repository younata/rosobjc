//
//  ROProtocols.m
//  rosobjc
//
//  Created by Rachel Brindle on 6/22/13.
//  Copyright (c) 2013 Rachel Brindle. All rights reserved.
//

#import "ROSProtocols.h"
#import <CommonCrypto/CommonDigest.h>

const uint8_t *generateMD5(uint8_t *type, uint32_t length)
{
    // Create byte array of unsigned chars
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    // Create 16 byte MD5 hash value, store in buffer
    CC_MD5(type, length, md5Buffer);
    
    // Convert MD5 value in the buffer to NSString of hex values
    NSMutableString *output = [NSMutableString stringWithCapacity:39];
    [output appendString:@"md5sum="];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x",md5Buffer[i]];
    
    return (const uint8_t *)[output UTF8String];
}

@implementation ROSProtocol

-(uint8_t *)generateConnectionHeader
{
    // 4 bytes, which tells how long the connection header is.
    // 4 bytes, defining X
    // X bytes, which is a string (not null terminated)
    //          this string is <fieldname>=<data>
    
    NSAssert(NO, @"Override generateConnectionHeader in your ROSProtocol subclass.");
    return NULL;
}

@end

@implementation ROSTCP

#pragma mark - internal
// These methods should probably be done in a subclass, but whatever.
-(uint8_t *)generateSubscriberHeaders
{
    // message_definition
    // callerid
    // topic
    // md5sum
    // type
    
    // tcp_nodelay (optional)
    // error (optional)
    
    
}

-(uint8_t *)generatePublisherHeaders
{
    // md5sum
    // type
    
    // callerid (optional)
    // latching (optional)
    // error (optional)
}

-(uint8_t *)generateServiceHeaders
{
    // callerid

    // error (optional)
}

-(uint8_t *)generateServiceClientHeaders
{
    // callerid
    // service
    // md5sum
    // type
    
    // persistent (optional)
    // error (optional)
}

-(uint8_t *)generateConnectionHeader
{
    
}

@end

@implementation ROSUDP

-(id)init
{
    NSAssert(NO, @"UDPROS for rosobjc is not yet implemented.");
    return nil;
}

@end