//
//  ROObject.h
//  rosobjc
//
//  Created by Rachel Brindle on 6/17/13.
//  Copyright (c) 2013 Rachel Brindle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RODelegate.h"

@interface RONode : NSObject

@property (nonatomic, weak) id<RODelegate> delegate;
@property (nonatomic, strong) NSString *name;

-(id)initWithName:(NSString *)name;
-(void)shutdown:(NSString *)reason;

-(NSArray *)getPublishedTopics:(NSString *)NameSpace;

@end
