//
//  RPCResponse.h
//  rosobjc
//
//  Created by Rachel Brindle on 7/6/13.
//  Copyright (c) 2013 Rachel Brindle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTTPResponse.h"

@interface RPCResponse : NSObject <HTTPResponse, NSXMLParserDelegate>
{
    NSInteger _status;
}

@property (nonatomic) UInt64 offset;

-(id)initWithHeaders:(NSDictionary *)headers bodyData:(NSData *)bodyData;

@end
