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
        
        dataLength = 0;
        
        queue = dispatch_queue_create([NSStringFromClass([self class]) UTF8String], 0);
    }
    return self;
}

-(BOOL)hasConnection:(NSURL *)url
{
    return NO;
}

-(NSData *)generatePublisherHeader
{
    ROSMsg *a = [[_msgClass alloc] init];
    NSString *md5sum = [@"md5sum=" stringByAppendingString:[a md5sum]];
    int i = (int)[md5sum length];
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
    int i = [ret1 length];
    [ret appendBytes:&i length:4];
    [ret appendData:ret1];
    
    return ret;
}

#pragma mark - GCDAsyncSocketDelegate

-(void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    if (gcdSockets == nil) {
        gcdSockets = [[NSMutableArray alloc] init];
    }
    [gcdSockets addObject:newSocket];
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
        [self handleServerData:sock];
    }
    
    if (i > dataLength) {
        [self socket:sock didReadData:[data subdataWithRange:NSMakeRange(dataLength, i-dataLength)] withTag:tag];
    }
}

#pragma mark - Methods

-(void)handleServerData:(GCDAsyncSocket *)socket
{
    NSData *s = [readData copy];
    if (!exchangedHeaders) {
        NSMutableDictionary *headers = [[NSMutableDictionary alloc] init];
        while ([s length] != 0) {
            int len = *(int*)[[s subdataWithRange:NSMakeRange(0, 4)] bytes];
            s = [s subdataWithRange:NSMakeRange(0, 4)];
            NSString *t = [[NSString alloc] initWithData:[s subdataWithRange:NSMakeRange(0, len)] encoding:NSUTF8StringEncoding];
            NSArray *a = [t componentsSeparatedByString:@"="];
            if ([a count] == 1)
                break;
            [headers setObject:a[1] forKey:a[0]];
            s = [s subdataWithRange:NSMakeRange(4, [s length] - len)];
        }
        // construct a respanse...
        // lookup the md5sum for this...
        
        [socket writeData:[self generatePublisherHeader] withTimeout:-1 tag:0];
        exchangedHeaders = YES;
    } else {
        ROSMsg *foo = [[_msgClass alloc] init];
        [foo deserialize:s];
        [_node recvMsg:foo Topic:_topic];
    }
}

-(void)startServerFromNode:(ROSNode *)node
{
    _node = node;
    _run = YES;
    exchangedHeaders = NO;
    GCDAsyncSocket *a = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:queue];
    [a acceptOnPort:_port error:nil];
    
    /*
    struct addrinfo hints, *servinfo, *p;
    struct sockaddr_storage their_addr; // connector's address information
    int yes=1;
    int rv;
    _run = YES;
    
    memset(&hints, 0, sizeof hints);
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = AI_PASSIVE; // use my IP
    
    if ((rv = getaddrinfo(NULL, [[@(_port) stringValue] UTF8String], &hints, &servinfo)) != 0) {
        fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(rv));
        return;
    }
    
    for(p = servinfo; p != NULL; p = p->ai_next) {
        if ((sockfd = socket(p->ai_family, p->ai_socktype,
                             p->ai_protocol)) == -1) {
            perror("server: socket");
            continue;
        }
        
        if (setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &yes,
                       sizeof(int)) == -1) {
            perror("setsockopt");
            exit(1);
        }
        
        if (bind(sockfd, p->ai_addr, p->ai_addrlen) == -1) {
            close(sockfd);
            perror("server: bind");
            continue;
        }
        
        break;
    }
    
    if (p == NULL)  {
        fprintf(stderr, "server: failed to bind\n");
        return;
    }
    
    freeaddrinfo(servinfo);
    
    if (listen(sockfd, _queueLength) == -1) {
        perror("listen");
        exit(1);
    }
    
    NSData *(^readMsg)(void) = ^NSData *(void) {
        char shortBuf[4];
        int foo = (int)recv(sockfd, shortBuf, 4, 0);
        char *s = malloc(foo+1);
        int justSent = 0, totalSent = 0;
        while (YES) {
            justSent = (int)recv(sockfd, s+totalSent, foo-totalSent, 0);
            totalSent += justSent;
            if (foo == totalSent) { break; }
        }
        return [NSData dataWithBytes:s length:foo];
    };
    
    dispatch_async(queue, ^{
        while(_run) {  // main accept() loop
            socklen_t sin_size = sizeof(their_addr);
            int new_fd = accept(sockfd, (struct sockaddr *)&their_addr, &sin_size);
            if (new_fd == -1) {
                perror("accept");
                continue;
            }
            char s_[INET6_ADDRSTRLEN];
            
            inet_ntop(their_addr.ss_family,
                      &(((struct sockaddr_in*)&their_addr)->sin_addr),
                      s_, sizeof(s_));
            
            NSData *d = readMsg(); // This is the connection header.
            d = [d subdataWithRange:NSMakeRange(4, [d length] - 4)];
            NSData *s = [d copy];
            NSMutableDictionary *headers = [[NSMutableDictionary alloc] init];
            while ([s length] != 0) {
                int len = *(int*)[[s subdataWithRange:NSMakeRange(0, 4)] bytes];
                s = [s subdataWithRange:NSMakeRange(0, 4)];
                NSString *t = [[NSString alloc] initWithData:[s subdataWithRange:NSMakeRange(0, len)] encoding:NSUTF8StringEncoding];
                NSArray *a = [t componentsSeparatedByString:@"="];
                if ([a count] == 1)
                    break;
                [headers setObject:a[1] forKey:a[0]];
                s = [s subdataWithRange:NSMakeRange(4, [s length] - len)];
            }
            // construct a respanse...
            // lookup the md5sum for this...
            
            [self sendData:[self generatePublisherHeader]];
            
            d = s = nil;
            
            dispatch_async(queue, ^{
                while (_run) {
                    NSData *d = readMsg();
                    ROSMsg *foo = [[_msgClass alloc] init];
                    [foo deserialize:d];
                    [_node recvMsg:foo Topic:_topic];
                    // I HIGHLY doubt this is used, though...
                }
            });
        }
    });
     */
}

void prettyPrintHeader(NSData *data)
{
    NSData *d = data;
    while ([d length] > 1) {
        int i;
        [d getBytes:&i range:NSMakeRange(0, 4)];
        char *s = malloc(i);
        [d getBytes:s range:NSMakeRange(4, i)];
        NSString *str = [[NSString alloc] initWithBytes:s length:i encoding:NSUTF8StringEncoding];
        printf("%s\n", [str UTF8String]);
        free(s);
        d = [d subdataWithRange:NSMakeRange(4+i, [d length] - (4+i))];
    }
}

+(BOOL)localServerAtPort:(short)port
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
    
    NSData *(^readMsg)(void) = ^NSData *(void) {
        int i;
        int foo = (int)recv(sockfd, &i, 4, 0);
        foo = i;
        char *s = malloc(foo+1);
        int justSent = 0, totalSent = 0;
        while (YES) {
            justSent = (int)recv(sockfd, s+totalSent, foo-totalSent, 0);
            totalSent += justSent;
            if (foo == totalSent) { break; }
        }
        return [NSData dataWithBytes:s length:foo];
    };
    
    NSData *toSend = [self generateSubscriberHeader];
    //prettyPrintHeader(toSend);
    [self sendData:toSend];
    readMsg(); // TODO: Actually check that the message types are valid.
    //prettyPrintHeader(argle);
    
    dispatch_async(queue, ^{
        while (_run) {
            NSData *d = readMsg();
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
    int foo = (int)[d length], justSent = 0, totalSent = 0;
    const void *data = [d bytes];
    while (YES) {
        justSent = (int)send(sockfd, data+totalSent, foo-totalSent, 0);
        totalSent += justSent;
        if (foo == totalSent) { break; }
    }
    return totalSent;
}

-(int)sendMsg:(ROSMsg *)msg
{
    if (!gcdSockets || [gcdSockets count] == 0)
        return 0;
    NSData *d = [msg serialize];
    [gcdSockets[0] writeData:d withTimeout:-1 tag:0];
    return [d length];
}

@end
