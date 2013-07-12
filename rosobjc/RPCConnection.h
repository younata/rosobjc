//
//  RPCConnection.h
//  rosobjc
//
//  Created by Rachel Brindle on 7/6/13.
//  Copyright (c) 2013 Rachel Brindle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTTPConnection.h"

@interface RPCConnection : HTTPConnection
{
    NSMutableData *requestContentBody;
}

@end
