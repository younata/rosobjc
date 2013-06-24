//
//  ROProtocols.h
//  rosobjc
//
//  Created by Rachel Brindle on 6/22/13.
//  Copyright (c) 2013 Rachel Brindle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ROSProtocol : NSObject

@property (nonatomic, strong) NSString *msgType;

-(uint8_t *)generateConnectionHeader;

@end

enum ROSTCPConnectionType {
    ROSTCPSubscriber = 0,
    ROSTCPPublisher = 1,
    ROSTCPService = 2,
    ROSTCPServiceClient = 3,
};

// Implements TCPROS
@interface ROSTCP : ROProtocol

@property (nonatomic) ROSTCPConnectionType connectionType;

@end

@interface ROSUDP : ROProtocol

@end