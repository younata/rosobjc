//
//  RPCResponse.m
//  rosobjc
//
//  Created by Rachel Brindle on 7/6/13.
//  Copyright (c) 2013 Rachel Brindle. All rights reserved.
//

#import "RPCResponse.h"

#import "ROSCore.h"

@implementation RPCResponse
{
    NSString *responseString;
    NSXMLParser *parser;
    NSMutableArray *params;
    NSMutableArray *structs;
    
    NSString *memberName;
    
    id workingObject;
    
    NSMutableString *currentElementValue;
    NSString *methodName;
    
    int currentStructIndex;
    
    NSDateFormatter *isoFormatter;
    
    BOOL done;
}

#pragma mark - HTTPResponse

-(id)initWithHeaders:(NSDictionary *)headers bodyData:(NSData *)bodyData
{
    if ((self = [super init])) {
        _status = 200;
        
        params = [[NSMutableArray alloc] init];
        structs = [[NSMutableArray alloc] init];
        
        workingObject = params;
        currentStructIndex = -1;
        
        done = NO;
        isoFormatter = [[NSDateFormatter alloc] init];
        [isoFormatter setDateFormat:@"yyyyMMdd'T'HH:mm:ss"];
        
        parser = [[NSXMLParser alloc] initWithData:bodyData];
        // this is a very brittle implementation. It would be a good idea
        // if someone more experienced than myself at implementing this
        // were to take a look at it.
                
        [parser setDelegate:self];
        if ([parser parse]) {
            NSArray *r = [[ROSCore sharedCore] respondToRPC:methodName Params:params];
            if (r == nil) // fault.
                [self fault];
            else {// success.
                // haha... I need to actually do a response...
            }
        } else {
            
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
    id otherValue = [parameters objectAtIndex:2];
    NSString *zero, *one, *two;
    zero = [NSString stringWithFormat:@"<value><i4>%@</i4></value>", code];
    one = [NSString stringWithFormat:@"<value><string>%@</string></value>", msg];
#error implement response.
    if ([otherValue isKindOfClass:nil])
        ;
    two = [NSString stringWithFormat:@""];
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
    return nil;
}

-(BOOL)isDone
{
    return done;
}

-(NSInteger)status
{
    return _status;
}

#pragma mark - NSXMLParserDelegate

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if ([[elementName lowercaseString] isEqualToString:@"methodname"]) {
        
    }
    else if ([[elementName lowercaseString] isEqualToString:@"struct"]) {
        currentStructIndex++;
        workingObject = [[NSMutableDictionary alloc] init];
        [structs addObject:workingObject];
    }
    else if ([elementName isEqualToString:@"array"]) {
        currentStructIndex++;
        workingObject = [[NSMutableArray alloc] init];
        [structs addObject:workingObject];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (!currentElementValue) {
        currentElementValue = [[NSMutableString alloc] initWithString:string];
    } else {
        [currentElementValue appendString:string];
    }
}

-(BOOL)isStruct
{
    if ([workingObject isKindOfClass:[NSMutableArray class]]) {
        return YES;
    }
    return NO;
}

-(void)addObject:(id<NSCopying>)object
{
    if ([self isStruct]) {
        NSMutableDictionary *foo = (NSMutableDictionary *)workingObject;
        foo[memberName] = object;
        memberName = nil;
    } else {
        [((NSMutableArray *)workingObject) addObject:object];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI  qualifiedName:(NSString *)qName
{
    if ([[elementName lowercaseString] isEqualToString:@"methodname"]) {
        methodName = [NSString stringWithString:currentElementValue];
    } else if ([elementName isEqualToString:@"param"]) {
    } // primitive param types...
    else if ([elementName isEqualToString:@"i4"] || [elementName isEqualToString:@"int"]) {
        [self addObject:@([currentElementValue integerValue])];
    } else if ([elementName isEqualToString:@"boolean"]) {
        [self addObject:@([currentElementValue boolValue])];
    } else if ([elementName isEqualToString:@"string"]) {
        [self addObject:[NSString stringWithString:currentElementValue]];
    } else if ([elementName isEqualToString:@"double"]) {
        [self addObject:@([currentElementValue doubleValue])];
    } else if ([elementName isEqualToString:@"dateTime.iso8601"]) {
        [self addObject:[isoFormatter dateFromString:currentElementValue]];
    } else if ([elementName isEqualToString:@"base64"]) {
        [self addObject:[NSString stringWithString:currentElementValue]];
    } // structs...
    else if ([elementName isEqualToString:@"struct"]) {
        [params addObject:structs[currentStructIndex]];
        [structs removeLastObject];
        currentStructIndex--;
        if (currentStructIndex == -1)
            workingObject = params;
        else
            workingObject = [structs lastObject];
    } else if ([elementName isEqualToString:@"name"]) {
        memberName = [NSString stringWithString:currentElementValue];
    } // arrays...
    else if ([elementName isEqualToString:@"array"]) {
        [params addObject:structs[currentStructIndex]];
        [structs removeLastObject];
        currentStructIndex--;
        if (currentStructIndex == -1)
            workingObject = params;
        else
            workingObject = [structs lastObject];
    }
    
    currentElementValue = nil;
}

-(void)parserDidEndDocument:(NSXMLParser *)parser
{
    done = YES;
}

@end
