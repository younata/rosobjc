//
//  RODelegate.h
//  rosobjc
//
//  Created by Rachel Brindle on 6/17/13.
//  Copyright (c) 2013 Rachel Brindle. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RONodeDelegate <NSObject>

@optional
-(void)onShutdown:(NSString *)reason;

@end
