//
//  ROObject.m
//  rosobjc
//
//  Created by Rachel Brindle on 6/17/13.
//  Copyright (c) 2013 Rachel Brindle. All rights reserved.
//

#import "ROSNode.h"
#import "ROSCore.h"

#import "ROSMsg.h"
#import "ROSXMLRPC.h"

#import "ROSSocket.h"

@implementation ROSNode

-(id)initWithName:(NSString *)name
{
    if ((self = [super init]) != nil) {
        _name = name;
        [self commonInit];
    }
    return self;
}

#pragma mark - Internal

-(void)commonInit
{
    keepRunning = YES;
    protocols = @[@"TCPROS"];
    publishedTopics = [[NSMutableDictionary alloc] init];
    subscribedTopics = [[NSMutableDictionary alloc] init];
    
    clients = [[NSMutableArray alloc] init];
    servers = [[NSMutableArray alloc] init];
    
    masterClient = [[ROSXMLRPCC alloc] init];
}

-(void)setMasterURI:(NSString *)masterURI
{
    _masterURI = masterURI;
    masterClient.URL = [NSURL URLWithString:_masterURI];
}

#pragma mark - Public

-(void)shutdown:(NSString *)reason
{
    keepRunning = NO;
    if (_delegate != nil && [_delegate respondsToSelector:@selector(onShutdown:)])
        [_delegate onShutdown:reason];
    for (ROSSocket *s in [servers arrayByAddingObjectsFromArray:clients]) {
        [s shutdown];
    }
    [clients removeAllObjects];
    [servers removeAllObjects];
    [_core removeNode:self];
}

#pragma mark - Most used by the developer.
-(void)subscribe:(NSString *)topic callback:(void (^)(ROSMsg *))block
{
    if (![topic hasPrefix:@"/"]) {
        topic = [@"/" stringByAppendingString:topic];
    }
    [masterClient getTopicTypes:[self name] callback:^(NSArray *res) {
        NSString *type = @"";
        for (NSArray *i in [res lastObject]) {
            NSString *tname = i[0];
            NSString *ttype = [i lastObject];
            if ([tname isEqualToString:topic]) {
                type = ttype;
                break;
            }
        }
        if (!topicTypes) {
            topicTypes = [[NSMutableDictionary alloc] init];
        }
        [topicTypes setObject:type forKey:topic];
        [masterClient registerSubscriber:[self name] Topic:topic TopicType:type callback:^(NSArray *foo){
            NSArray *subs = [foo lastObject];
            for (NSString *i in subs) {
                [self connectTopic:topic uri:i type:type Server:NO];
            }
        }];
    }];
    if ([subscribedTopics objectForKey:topic] == nil) {
        NSMutableArray *foo = [[NSMutableArray alloc] init];
        [foo addObject:block];
        [subscribedTopics setObject:foo forKey:topic];
    } else {
        NSMutableArray *foo = [subscribedTopics objectForKey:topic];
        [foo addObject:block];
    }
}

-(void)advertize:(NSString *)topic msgType:(NSString *)msgName
{
    if (![topic hasPrefix:@"/"]) {
        topic = [@"/" stringByAppendingString:topic];
    }
    if ([[ROSCore sharedCore] getClassForMessageType:msgName] == nil)
        return;
    if ([publishedTopics objectForKey:topic] != nil) {
        return;
    }
    [publishedTopics setObject:msgName forKey:topic];
    if (!topicTypes) {
        topicTypes = [[NSMutableDictionary alloc] init];
    }
    [topicTypes setObject:msgName forKey:topic];
    [masterClient registerPublisher:[self name] Topic:topic TopicType:msgName callback:^(NSArray *res){
        // res is an array of things already subscribing to this.
        NSLog(@"%@", res);
        NSArray *subs = [res lastObject];
        for (NSString *i in subs) {
            break;
            [self requestTopic:nil topic:topic protocols:nil];
            //[self connectTopic:topic uri:i type:msgName Server:YES];
        }
    }];
    
}

-(void)recvMsg:(ROSMsg *)msg Topic:(NSString *)topic
{
    NSArray *foo = [subscribedTopics objectForKey:topic];
    for (void (^cb)(ROSMsg *) in foo) {
        if (cb == nil)
            continue;
        cb(msg);
    }
}

-(BOOL)publishMsg:(ROSMsg *)msg Topic:(NSString *)topic
{
    ROSSocket *s = nil;
    for (ROSSocket *soc in servers) {
        if ([soc.topic isEqualToString:topic]) {
            s = soc;
            [s sendMsg:msg];
            break;
        }
    }
    if (s == nil)
        return NO;
    return YES;
}

-(void)stopPublishingTopic:(NSString *)topic
{
    NSMutableArray *foo = [[NSMutableArray alloc] init];
    for (ROSSocket *soc in servers) {
        if (soc.topic == topic) {
            [soc shutdown];
        }
    }
    for (ROSSocket *soc in foo) {
        [servers removeObject:soc];
    }
}

-(void)unSubscribeFromTopic:(NSString *)topic
{
    for (ROSSocket *soc in clients) {
        if (soc.topic == topic){
            [soc shutdown];
        }
    }
    [subscribedTopics removeObjectForKey:topic];
}

#pragma mark - internal
-(NSArray *)connectTopic:(NSString*)topic uri:(NSString *)URI type:(NSString *)topicType Server:(BOOL)isServer
{
    // actually connect.
    NSURL *u = [NSURL URLWithString:URI]; // wait.
    
    NSString *tcpros = @"TCPROS";
    
    ROSXMLRPCC *xrc = [[ROSXMLRPCC alloc] init];
    xrc.URL = u;
    if (!isServer) {
        [xrc makeCall:@"requestTopic" WithArgs:@[self.name, topic, @[@[@"TCPROS"]]] callback:^(NSArray *res){;
            if ([res[2] count] == 0) {
                // problem.
                NSLog(@"Unable to subscribe to %@", topic);
                NSLog(@"Recieved %@", res);
                //[masterClient unregisterSubscriber:self.name Topic:topic callback:^(NSArray *a){;}];
                return;
            }
            
            NSLog(@"%@", res);
            
            NSArray *a = res[2];
            if ([a[0] isEqualToString:tcpros]) {
                NSString *hostname = a[1];
                NSNumber *port = a[2];
                NSURL *ur = [NSURL URLWithString:[NSString stringWithFormat:@"//%@:%@", hostname, port]];
                ROSSocket *s = [[ROSSocket alloc] init];
                s.topic = topic;
                s.msgClass = [[ROSCore sharedCore] getClassForMessageType:topicType];
                [s startClient:ur Node:self];
                [clients addObject:s];
            }
        } URL:u];
    } else {
        NSLog(@"uh... problem?");
        /*
         [s startServerFromNode:self];
         [servers addObject:s];
         */
    }
    return @[@1, [NSString stringWithFormat:@"Connected to %@", topic], @0];
}

#pragma mark - Slave API
-(NSArray *)getPublishedTopics:(NSString *)NameSpace
{
    if (NameSpace == nil) {
        NameSpace = @"/";
    }
    NSMutableArray *ret = [[NSMutableArray alloc] init];
    for (NSString *t in publishedTopics.allKeys) {
        if ([t hasPrefix:NameSpace])
            [ret addObject:t];
    }
    return @[@1, @"published topics", ret];
}

-(NSArray *)getBusStats:(NSString *)callerID
{
    //NSArray *foo = [[ROSTopicManager sharedTopicManager] getPubSubStats];
    return @[@1, @"", [@[] arrayByAddingObject:@[]]];
}

-(NSArray *)getBusInfo:(NSString *)callerID
{
    return @[@1, @"bus info", @[]];//[[ROSTopicManager sharedTopicManager] getPubSubInfo]];
}

-(NSArray *)getMasterUri:(NSString *)callerID
{
    if (self.masterURI != nil) {
        return @[@1, self.masterURI, self.masterURI];
    }
    return @[@0, @"master URI not set", @""];
}

-(NSArray *)shutdown:(NSString *)callerID msg:(NSString *)msg
{
    for (ROSSocket *s in [servers arrayByAddingObjectsFromArray:clients]) {
        [s shutdown];
    }
    for (NSString *p in publishedTopics.allKeys) {
        ;
    }
    for (NSString *s in subscribedTopics.allKeys) {
        ;
    }
    return nil;
}

-(NSArray *)getSubscriptions:(NSString *)callerID
{
    return @[@1, @"subscriptions", [subscribedTopics allKeys]];
}

-(NSArray *)getPublications:(NSString *)callerID
{
    return @[@1, @"publications", publishedTopics.allKeys];
}

#pragma mark - public

-(NSArray *)paramUpdate:(NSString *)callerID key:(NSString *)key val:(id)value
{
    if ([params objectForKey:key] != nil) {
        [params setObject:value forKey:key];
        return @[@1, @"", @0];
    }
    return @[@(-1), @"not subscribed", @0];
}

-(NSArray *)publisherUpdate:(NSString *)callerID topic:(NSString *)topic publishers:(NSArray *)publishers
{
    if ([publishers count] != 0) {
        return nil;
    }
    NSString *topicType = [topicTypes objectForKey:topic];
    if (!topicType) {
        return nil;
    }
    NSMutableArray *knownHosts = [[NSMutableArray alloc] init];
    for (ROSSocket *soc in clients) {
        [knownHosts addObject:soc.host];
    }
    for (NSString *uri in publishers) {
        NSURL *u = [NSURL URLWithString:uri];
        NSString *h = [u host];
        if (![knownHosts containsObject:h]) {
            [self connectTopic:topic uri:uri type:topicType Server:NO];
            [knownHosts addObject:h];
        }
    }
    return nil;
}

-(NSArray *)requestTopic:(NSString *)callerID topic:(NSString *)topic protocols:(NSArray *)_protocols
{
    if (![topic hasPrefix:@"/"]) {
        topic = [@"/" stringByAppendingString:topic];
    }
    if ([publishedTopics objectForKey:topic] == nil) {
        return @[@0, [NSString stringWithFormat:@"Not a publisher of %@", topic], @[]];
    }
    BOOL found = NO;
    if (_protocols == nil || _protocols.count == 0) {
        found = YES;
    }
    for (NSArray *i in _protocols) {
        if ([[i objectAtIndex:0] isEqualToString:@"TCPROS"]) {
            found = YES;
            break;
        }
    }
    if (!found)
        return @[@0, @"No protocol match made", @[]];

    ROSSocket *s = [[ROSSocket alloc] init];
    s.topic = topic;
    s.msgClass = [[ROSCore sharedCore] getClassForMessageType:[publishedTopics objectForKey:topic]];
    unsigned short port = 9000;
    while ([ROSSocket localServerAtPort:port]) {
        port++;
    }
    s.port = port;
    [s startServerFromNode:self];
    [servers addObject:s];
    
    NSString *hn = [[NSProcessInfo processInfo] hostName];
    NSArray *ret = @[@1, [NSString stringWithFormat:@"ready on %@:%u", hn, s.port], @[@"TCPROS", hn, @(s.port)]];
    NSLog(@"%@", ret);
    
    return ret;
}

@end
  
  
  
  
