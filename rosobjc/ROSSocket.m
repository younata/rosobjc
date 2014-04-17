//
//  ROSSocket.m
//  rosobjc
//
//  Created by Rachel Brindle on 7/21/13.
//  Copyright (c) 2013 Rachel Brindle. All rights reserved.
//

#import "ROSSocket.h"

#import "ROSCore.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <sys/wait.h>

#import "GCDAsyncSocket.h"

#define MAXDATASIZE 1024

@implementation ROSSocket

-(id)init
{
    if ((self = [super init])) {
        _queueLength = 512;
        _port = 1234;
        _run = YES;
        
        servers = [[NSMutableArray alloc] init];
        
        dataLength = 0;
    }
    return self;
}

-(void)createQueue
{
    NSString *qs = [[NSStringFromClass([self class]) stringByAppendingString:_topic] stringByAppendingString:NSStringFromClass(_msgClass)];
    queue = dispatch_queue_create([qs UTF8String], 0);
}

-(BOOL)hasConnection:(NSURL *)url
{
    return NO;
}

-(NSData *)generatePublisherHeader
{
    ROSMsg *a = [[_msgClass alloc] init];
    NSString *md5sum = [@"md5sum=" stringByAppendingString:[a md5sum]];
    NSInteger i = [md5sum length];
    BOOL NSStringPreservesEndingZero = NO;
    NSData *d = [md5sum dataUsingEncoding:NSUTF8StringEncoding];
    if ([d length] != 39) {
        NSStringPreservesEndingZero = YES;
        i--;
        d = [d subdataWithRange:NSMakeRange(0, i)];
    }
    NSMutableData *da = [[NSMutableData alloc] initWithBytes:&i length:4];
    [da appendData:d];
    NSString *type = [@"type=" stringByAppendingString:[a type]];
    d = [type dataUsingEncoding:NSUTF8StringEncoding];
    if (NSStringPreservesEndingZero) {
        i = [type length] -1;
        d = [d subdataWithRange:NSMakeRange(0, [d length] -1)];
    } else {
        i = [type length];
    }
    [da appendBytes:&i length:4];
    [da appendData:d];
    i = [da length];
    NSMutableData *data = [NSMutableData dataWithBytes:&i length:4];
    [data appendData:da];
    
    return data;
}

-(NSData *)generateSubscriberHeader
{
    ROSMsg *a = [[_msgClass alloc] init];
    NSString *md5sum = [@"md5sum=" stringByAppendingString:[a md5sum]];
    NSString *type = [@"type=" stringByAppendingString:[a type]];
    NSString *callerid = [@"callerid=" stringByAppendingString:_node.name];
    NSString *topic = [@"topic=" stringByAppendingString:[self topic]];
    NSString *message_definition = [@"message_definition=" stringByAppendingString:[a definition]];
    
    NSMutableData *ret = [[NSMutableData alloc] init];
    NSMutableData *ret1 = [[NSMutableData alloc] init];
    
    int l;
    l = (int)[md5sum length];
    BOOL NSStringPreservesEndingZero = NO;
    NSData *d = [md5sum dataUsingEncoding:NSUTF8StringEncoding];
    if ([d length] != 39) {
        NSStringPreservesEndingZero = YES;
        l--;
    }
    
    for (NSString *s in @[md5sum, type, callerid, topic, message_definition]) {
        l = (int)[s length];
        if (NSStringPreservesEndingZero) {
            l--;
        }
        [ret1 appendBytes:&l length:4];
        [ret1 appendData:[[s dataUsingEncoding:NSUTF8StringEncoding] subdataWithRange:NSMakeRange(0, l)]];
    }
    NSUInteger i = [ret1 length];
    [ret appendBytes:&i length:4];
    [ret appendData:ret1];
    
    return ret;
}

#pragma mark - GCDAsyncSocketDelegate

-(void)socketDidConfigureForListening:(GCDAsyncSocket *)sock
{
    ;
}

-(void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    if ([[ROSCore sharedCore] isIPDenied:[newSocket connectedHost]]) {
        [newSocket writeData:[@"403 Authority not recognized" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
        [newSocket disconnectAfterWriting];
    } else {
        [servers addObject:newSocket];
        NSLog(@"Received connection from %@ on port %d", [newSocket connectedHost], [newSocket connectedPort]);
        [newSocket readDataWithTimeout:-1 tag:0];
    }
}

-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    if (dataLength == 0) {
        readData = [[NSMutableData alloc] init];
        [data getBytes:&dataLength length:4];
        data = [data subdataWithRange:NSMakeRange(4, [data length] - 4)];
    }
    unsigned long long i = [data length];
    if (i > dataLength) {
        [readData appendData:[data subdataWithRange:NSMakeRange(0, dataLength)]];
    } else {
        [readData appendData:[data subdataWithRange:NSMakeRange(0, i)]];
    }
    
    if (i >= dataLength) {
        [self handleServerDataFrom:sock];
        dataLength = 0;
    }
    
    if (i > dataLength) {
        [self socket:sock didReadData:[data subdataWithRange:NSMakeRange(dataLength, i-dataLength)] withTag:tag];
    } else {
        [sock readDataWithTimeout:-1 tag:0];
    }
}

-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    NSLog(@"Socket disconnected with error: %@", err);
}

#pragma mark - Methods

void prettyPrintHeader(NSData *data)
{
    NSData *d = data;//[data subdataWithRange:NSMakeRange(4, [data length] - 4)];
    while ([d length] > 4) {
        int len = 0;
        unsigned char shortBuf[4];
        [d getBytes:shortBuf range:NSMakeRange(0, 4)];
        for (int j = 0; j < 4; j++)
            len += (shortBuf[j]&0xff) << (24-(j*8));
        char *s = malloc(len);
        [d getBytes:s range:NSMakeRange(4, len)];
        for (int i = 0; i < len; i++) {
            printf("%02x:", s[i]);
        }
        printf("\n");
        NSString *str = [[NSString alloc] initWithBytes:s length:len encoding:NSUTF8StringEncoding];
        if (str != nil)
            printf("%s\n", [str UTF8String]);
        free(s);
        s = NULL;
        d = [d subdataWithRange:NSMakeRange(4+len, [d length] - (4+len))];
    }
}

-(void)handleServerDataFrom:(GCDAsyncSocket *)sock
{
    NSData *s = [readData copy];
    unsigned int len = [self handleReadMsg:s];
    if ([s length] < len)
        return;
    if (!exchangedHeaders) {
        NSMutableDictionary *headers = [[NSMutableDictionary alloc] init];
        NSData *d = [s copy];
        while ([d length] != 0) {
            unsigned int l = [self handleReadMsg:d];
            NSAssert(l <= [d length], @"l is longer than data");
            NSData *sd = [s subdataWithRange:NSMakeRange(0, l)];
            NSString *t = [[NSString alloc] initWithData:sd encoding:NSUTF8StringEncoding];
            NSAssert(t != nil, @"t is nil");
            NSArray *a = [t componentsSeparatedByString:@"="];
            if ([a count] < 2)
                break; // TODO: fixme.
            NSAssert([a count] != 1, @"components separated... returned only one object, expected 2");
            [headers setObject:a[1] forKey:a[0]];
            d = [d subdataWithRange:NSMakeRange(4+l, [d length] - (l + 4))];
        }
        // construct a respanse...
        // lookup the md5sum for this...
        
        [sock writeData:[self generatePublisherHeader] withTimeout:-1 tag:0];
        exchangedHeaders = YES;
    } else {
        ROSMsg *foo = [[_msgClass alloc] init];
        [foo deserialize:s];
        [_node recvMsg:foo Topic:_topic];
    }
}

-(unsigned int)handleReadMsg:(NSData *)input
{
    unsigned char *c = (unsigned char *)[input bytes];
    unsigned int len = 0;
    for (int i = 0; i < 4; i++)
        len += (c[i]&0xFF) << ((i*8));
    return len;
}

-(NSData *)readMsg
{
    // this is the way rospy works.
    unsigned char *c = malloc(4096);
    size_t r = 0;
    if ((r = recv(sockfd, c, 4096, 0)) == -1) {
        perror("readMsg");
        [self shutdown];
        return nil;
    }
    NSData *ret = [NSData dataWithBytes:c length:r];
    free(c);
    return ret;
};

-(void)startServerFromNode:(ROSNode *)node onAccept:(void (^)(void))onAcc
{
    _node = node;
    _run = YES;
    
    //onSocketAccept = onAcc;
    [self createQueue];
    
    serverSock = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:queue];
    NSError *error = nil;
    if (![serverSock acceptOnPort:_port error:&error]) {
        NSLog(@"Error setting up server: %@", error);
    }
    
    return;
}

+(BOOL)localServerAtPort:(uint16_t)port
{
    int sockfd;
    
    BOOL ret = YES;
    
    const char *host = "127.0.0.1";

    // loop through all the results and connect to the first we can
    sockfd = socket(PF_INET, SOCK_STREAM, 0);
    if (sockfd == -1)
        return NO;
    
    struct sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    addr.sin_addr.s_addr = inet_addr(host);
    memset(addr.sin_zero, '\0', sizeof(addr.sin_zero));
    
    if (connect(sockfd, (struct sockaddr *)&addr, sizeof(addr)) == -1) {
        if (errno == ECONNREFUSED) {
            ret = NO;
        }
    }
    
    close(sockfd);
    
    return ret;
}

-(void)startClient:(NSURL *)url Node:(ROSNode *)node
{
    _node = node;
    _host = [url host];
    
    [self createQueue];
    
    struct addrinfo hints, *servinfo, *p;
    int rv;
    char s[INET6_ADDRSTRLEN];
    
    _port = (unsigned short)[[url port] unsignedShortValue];
    const char *host = [[url host] UTF8String];
    
    memset(&hints, 0, sizeof hints);
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    
    if ((rv = getaddrinfo(host, [[@(_port) stringValue] UTF8String], &hints, &servinfo)) != 0) {
        fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(rv));
        return;
    }
    
    // loop through all the results and connect to the first we can
    for(p = servinfo; p != NULL; p = p->ai_next) {
        if ((sockfd = socket(p->ai_family, p->ai_socktype,
                             p->ai_protocol)) == -1) {
            perror("client: socket");
            continue;
        }
        
        if (connect(sockfd, p->ai_addr, p->ai_addrlen) == -1) {
            close(sockfd);
            perror("client: connect");
            continue;
        }
        break;
    }
    
    if (p == NULL) {
        fprintf(stderr, "client: failed to connect\n");
        return;
    }
    
    inet_ntop(p->ai_family, &(((struct sockaddr_in*)p->ai_addr)->sin_addr),
              s, sizeof s);
    
    freeaddrinfo(servinfo); // all done with this structure
     
    NSData *toSend = [self generateSubscriberHeader];
    //prettyPrintHeader(toSend);
    if ([self sendData:toSend] <= 0) {
        perror("sendmsg");
    }
    [self readMsg]; // TODO: Actually check that the message types are valid.
    //prettyPrintHeader(argle);
    
    dispatch_async(queue, ^{
        while (_run) {
            NSData *d = [self readMsg];
            //prettyPrintHeader(d);
            ROSMsg *foo = [[_msgClass alloc] init];
            [foo deserialize:d];
            [_node recvMsg:foo Topic:_topic];
        }
    });
}

-(void)shutdown
{
    _run = NO;
    close(sockfd);
}

-(int)sendData:(NSData *)d
{
    if (sockfd <= 0)
        return 0;
    int foo = (int)[d length], justSent = 0, totalSent = 0;
    const void *data = [d bytes];
    while (YES) {
        justSent = (int)send(sockfd, data+totalSent, foo-totalSent, 0);
        if (justSent <= 0) {
            perror("sendData");
            [self shutdown];
            return -1;
        }
        totalSent += justSent;
        if (foo == totalSent) { break; }
    }
    return totalSent;
}

-(NSUInteger)sendMsg:(ROSMsg *)msg
{
    if (sockfd < 0 || !_run) {
        return -1;
    }
    if ([servers count] == 0)
        return [self sendData:[msg serialize]];
    NSData *d = [msg serialize];
    for (GCDAsyncSocket *s in servers)
        [s writeData:d withTimeout:-1 tag:0];
    return [d length];
}

@end
