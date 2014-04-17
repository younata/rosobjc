//
//  RPCResponse.m
//  rosobjc
//
//  Created by Rachel Brindle on 7/6/13.
//  Copyright (c) 2013 Rachel Brindle. All rights reserved.
//

#import "RPCResponse.h"

#import "ROSCore.h"

#import "XMLReader.h"
#import "XMLRPCDefaultEncoder.h"
#import "XMLRPCEventBasedParser.h"

NSString *NSStringTrim(NSString *str, NSCharacterSet *toTrim)
{
    NSString *a = [str stringByTrimmingCharactersInSet:toTrim];
    while (![a isEqualToString:str]) {
        str = a;
        a = [str stringByTrimmingCharactersInSet:toTrim];
    }
    return a;
}

@implementation RPCResponse
{
    NSString *responseString;
    NSMutableArray *params;
    
    NSString *methodName;
    
    NSDateFormatter *isoFormatter;
    
    BOOL done;
}

#pragma mark - HTTPResponse

-(id)initWithHeaders:(NSDictionary *)headers bodyData:(NSData *)bodyData from:(NSString *)ipAddr
{
    if ((self = [super init])) {
        if ([[ROSCore sharedCore] isIPDenied:ipAddr]) {
            _status = 403;
            responseString = @"Your authority is not recognized";
            return self;
        }
        _status = 200;
        
        isoFormatter = [[NSDateFormatter alloc] init];
        [isoFormatter setDateFormat:@"yyyyMMdd'T'HH:mm:ss"];
        
        NSString *bodyString = [[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding];
        NSArray *_params = [bodyString componentsSeparatedByString:@"<param>"];
        params = [[NSMutableArray alloc] init];
        for (int i = 1; i < [_params count]; i++) {
            NSString *j = [@"<param>" stringByAppendingString:[_params objectAtIndex:i]];
            if (i == [_params count] - 1) {
                j = [[j componentsSeparatedByString:@"</params>"] objectAtIndex:0];
            }
            NSData *d = [NSData dataWithBytes:[j UTF8String] length:[j length]];
            XMLRPCEventBasedParser *ebp = [[XMLRPCEventBasedParser alloc] initWithData:d];
            id foo = [ebp parse];
            NSAssert(foo != nil, @"[ebp parse] produced a nil object");
            [params addObject:foo];

        }
        NSDictionary *reader = [[XMLReader dictionaryForXMLData:bodyData error:nil] objectForKey:@"methodCall"];
        methodName = [[[reader objectForKey:@"methodName"] objectForKey:@"text"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        NSArray *r = [[ROSCore sharedCore] respondToRPC:methodName Params:params];
        if (r == nil) // fault.
            [self fault];
        else { // success.
            [self response:r];
        }
    }
    return self;
}

-(void)response:(NSArray *)parameters
{
    // yada yada, this is tailored for rosobjc.
    NSString *formatString = @"<?xml version=\"1.0\"?><methodResponse><params><param><value><array><data>%@</data></array></value></param></params></methodResponse>";
    NSNumber *code = [parameters objectAtIndex:0];
    NSString *msg = [parameters objectAtIndex:1];
    XMLRPCDefaultEncoder *de = [[XMLRPCDefaultEncoder alloc] init];
    NSString *two = [de performSelector:@selector(encodeObject:) withObject:[parameters objectAtIndex:2]];
    NSString *zero, *one;
    zero = [NSString stringWithFormat:@"<value><i4>%@</i4></value>", code];
    one = [NSString stringWithFormat:@"<value><string>%@</string></value>", msg];
    NSString *toAdd = [zero stringByAppendingString:one];
    toAdd = [toAdd stringByAppendingString:two];
    responseString = [[NSString alloc] initWithFormat:formatString, toAdd];
}

-(void)fault
{
    responseString = @"<?xml version=\"1.0\"?><methodResponse><fault><value><struct><member><name>faultCode</name><value><int>-1</int></value></member><member><name>faultString</name><value><string>Invalid parameters</string></value></member></struct></value></fault></methodResponse>";
}

-(UInt64)contentLength
{
    return [responseString length];
}

-(NSData *)readDataOfLength:(NSUInteger)length
{
    return [responseString dataUsingEncoding:NSUTF8StringEncoding];
}

-(BOOL)isDone
{
    return done;
}

-(NSInteger)status
{
    return _status;
}

@end
