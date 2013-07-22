//
//  ROProtocols.h
//  rosobjc
//
//  Created by Rachel Brindle on 6/22/13.
//  Copyright (c) 2013 Rachel Brindle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ROSProtocol : NSObject

@property (nonatomic, strong) NSString *messageDefinition;
@property (nonatomic, strong) NSString *topic;
@property (nonatomic, strong) NSString *messageType;
@property (nonatomic, strong) NSString *callerID;
@property (nonatomic, strong) NSString *service;
@property (nonatomic, strong) NSString *tcpNodelay;
@property (nonatomic, strong) NSString *error;
@property (nonatomic, strong) NSString *latching;
@property (nonatomic, strong) NSString *persistant;

-(NSString *)generateConnectionHeader;

@end

enum ROSTCPConnectionType {
    ROSTCPSubscriber = 0,
    ROSTCPPublisher = 1,
    ROSTCPService = 2,
    ROSTCPServiceClient = 3,
};

// Implements TCPROS
@interface ROSTCP : ROSProtocol

@property (nonatomic) enum ROSTCPConnectionType connectionType;

@end

// Implements UDPROS
@interface ROSUDP : ROSProtocol

@end