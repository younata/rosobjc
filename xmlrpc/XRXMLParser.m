//
//  XRXMLParser.m
//  XMLRPC
//
//  Created by znek on Tue Aug 14 2001.
//  $Id: XRXMLParser.m,v 1.12 2003/06/02 00:13:38 znek Exp $
//
//  Copyright (c) 2001 by Marcus MŸller <znek@mulle-kybernetik.com>.
//  All rights reserved.
//
//  Permission to use, copy, modify and distribute this software and its documentation
//  is hereby granted under the terms of the GNU Lesser General Public License, version 2.1
//  as published by the Free Software Foundation, provided that both the copyright notice
//  and this permission notice appear in all copies of the software, derivative works or
//  modified versions, and any portions thereof, and that both notices appear in supporting
//  documentation, and that credit is given to Marcus MŸller in all documents and publicity
//  pertaining to direct or indirect use of this code or its derivatives.
//
//  This is free software; you can redistribute and/or modify it under
//  the terms of the GNU Lesser General Public License, version 2.1 as published by the Free
//  Software Foundation. Further information can be found on the project's web pages
//  at http://www.mulle-kybernetik.com/software/XMLRPC
//
//  THIS IS EXPERIMENTAL SOFTWARE AND IT IS KNOWN TO HAVE BUGS, SOME OF WHICH MAY HAVE
//  SERIOUS CONSEQUENCES. THE COPYRIGHT HOLDER ALLOWS FREE USE OF THIS SOFTWARE IN ITS
//  "AS IS" CONDITION. THE COPYRIGHT HOLDER DISCLAIMS ANY LIABILITY OF ANY KIND FOR ANY
//  DAMAGES WHATSOEVER RESULTING DIRECTLY OR INDIRECTLY FROM THE USE OF THIS SOFTWARE
//  OR OF ANY DERIVATIVE WORK.
//---------------------------------------------------------------------------------------


#include "XRXMLParser.h"

//
//  UNFORTUNATELY we need some private definitions from the EDMLParser in order to
//  fullfill a very dubious demand in the XML-RPC spec. The XML-RPC specification requires
//  us to NOT ENCODE all special characters that the XML specification clearly requires.
//  This means that we also have to be able to parse non XML conformant data. I cannot simply
//  put this demand into the EDMLParser for obvious reasons. Instead I simply override the
//  appropriate methods.
//

#define EDML_MAX_ENTITY_LENGTH 50

enum
{
    EDMLPTextMode,
    EDMLPSpaceMode,
    EDMLPTagMode,
    EDMLPProcInstrMode,
    EDMLPCommentMode,
    EDMLPCommentBracketMode,
    EDMLPCDATAMode
};

enum
{
    EDMLPT_STRING = 1,
    EDMLPT_SPACE = 2,
    EDMLPT_LT = 3,
    EDMLPT_GT = 4,
    EDMLPT_SLASH = 5,
    EDMLPT_EQ =  6,
    EDMLPT_TSTRING =  7,
    EDMLPT_TATTR =  8,
    EDMLPT_TATTRLIST =  9,
    EDMLPT_STAG = 10,
    EDMLPT_ETAG = 11,
    EDMLPT_ELEMENT = 12,
    EDMLPT_LIST = 13
};

@interface EDMLToken : NSObject
{
    int 		type;
    id			value;
}

+ (EDMLToken *)tokenWithType:(int)aType;
- (id)initWithType:(int)aType;
- (int)type;
- (void)setValue:(id)aValue;
- (id)value;

@end


@interface EDMLParser (PrivateAPI)
+ (void)_initializeCharacterSets;
@end


@implementation XRXMLParser

EDCOMMON_EXTERN EDBitmapCharset *textCharset, *spaceCharset, *attrStopCharset;

/*"
  XRXMLParser is a simple extension to the EDMLParser, basically changing an aspect
  of the parser's behavior due to an extension in the XML-RPC spec.
"*/


////////////////////////////////////////////////////
//
//  CLASS INITIALIZATION
//
////////////////////////////////////////////////////


+ (void)initialize
{
#ifdef GNU_RUNTIME
    // The GNU runtime doesn't handle this automatically as the NeXT runtime does
    [super initialize];
#endif
    [self _initializeCharacterSets];
}


////////////////////////////////////////////////////
//
//  CHARACTER SETS
//
////////////////////////////////////////////////////


+ (void)_initializeCharacterSets
{
    [super _initializeCharacterSets];
    textCharset = EDBitmapCharsetFromCharacterSet([self textCharacterSet]);
}

// because of a 'clever extension' to the XML-RPC specs we need to modify this set to also include
// '>' characters that otherwise would need to be quoted (as stated by the XML specs)
+ (NSCharacterSet *)textCharacterSet
{
    NSMutableCharacterSet	*tempCharset;

    tempCharset = [[[NSCharacterSet illegalCharacterSet] mutableCopy] autorelease];
    [tempCharset addCharactersInString:@"<&"];
    [tempCharset formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [tempCharset invert];
    return tempCharset;
}


////////////////////////////////////////////////////
//
//  LEXER
//
////////////////////////////////////////////////////


static __inline__ unichar *nextchar(unichar *charp, BOOL raiseOnEnd)
{
    charp += 1;
    if((raiseOnEnd == YES) && (*charp == (unichar)0))
        [NSException raise:EDMLParserException format:@"Unexpected end of source."];
    return charp;
}


static NSString *readentity(unichar *charp, NSDictionary *entityTable, int *len)
{
    NSString 	*entity;
    unichar		*start, c;

    NSCAssert((*charp == '&'), @"readentity called with charp not pointing to an & char.");
    charp = nextchar(charp, YES);
    start = charp;
    while((*charp != ';') && ((charp - start) < EDML_MAX_ENTITY_LENGTH))
        charp = nextchar(charp, YES);

    if(*start == '#')
    { // convert using unicode char code
        if((*(start + 1) == 'x') || (*(start + 1) == 'X'))
            c = [[NSString stringWithCharacters:(start + 2) length:(charp - (start + 2))] intValueForHex];
        else
            c = [[NSString stringWithCharacters:(start + 1) length:(charp - (start + 1))] intValue];
        entity = (c > 0) ? [NSString stringWithCharacters:&c length:1] : nil;
    }
    else if(entityTable != nil)
    { // convert using entity table
        entity = [entityTable objectForKey:[NSString stringWithCharacters:start length:(charp - start)]];
    }
    else
    {
        entity = nil;
    }

    charp = nextchar(charp, NO);
    if(charp - start >= EDML_MAX_ENTITY_LENGTH)
        [NSException raise:EDMLParserException format:@"Found invalid entity '%@'", [NSString stringWithCharacters:(start - 1) length:(charp - start + 1)]];

    if(entity == nil)
        entity = [NSString stringWithCharacters:(start - 1) length:(charp - start + 1)];

    *len = (charp - start + 1);

    return entity;
}


static NSString *readquotedstring(unichar *charp, NSDictionary *entityTable, int *len)
{
    NSMutableString	*string;
    unichar			*start, *chunkstart, endchar;
    int				entitylen;

    endchar = *charp;
    charp = nextchar(charp, YES);
    start = chunkstart = charp;
    string = nil;
    while(*charp != endchar)
    {
        if(*charp == '&')
        {
            if(string == nil)
                string = [NSMutableString stringWithCharacters:chunkstart length:(charp - chunkstart)];
            else
                [string appendString:[NSString stringWithCharacters:chunkstart length:(charp - chunkstart)]];
            [string appendString:readentity(charp, entityTable, &entitylen)];
            charp += entitylen;
            chunkstart = charp;
        }
        else
        {
            charp = nextchar(charp, YES);
        }
    }
    if(string == nil)
        string = (id)[NSString stringWithCharacters:start length:(charp - chunkstart)];
    else
        [string appendString:[NSString stringWithCharacters:chunkstart length:(charp - chunkstart)]];
    charp = nextchar(charp, NO);

    *len = (charp - start + 1);

    return string;
}


- (EDMLToken *)_nextToken
{
    EDMLToken	*token;
    id			tvalue;
    unichar		*start;
    int			len;

    if(peekedToken != nil)
    {
        token = peekedToken;
        peekedToken = nil;
        return [token autorelease];
    }

    if(*charp == (unichar)0)
        return nil;

    NSAssert((lexmode == EDMLPTextMode) || (lexmode == EDMLPSpaceMode) || (lexmode == EDMLPTagMode) || (lexmode == EDMLPProcInstrMode) || (lexmode == EDMLPCommentMode) || (lexmode == EDMLPCDATAMode) || (lexmode == EDMLPCommentBracketMode), @"Invalid lexicalizer mode");

    switch(lexmode)
    {
        case EDMLPTextMode:
            if(*charp == '<')
            {
                charp = nextchar(charp, YES);
                if(*charp == '!')
                {
                    lexmode = EDMLPCommentMode;
                    return [self _nextToken];
                }
                else if(*charp == '?')
                {
                    lexmode = EDMLPProcInstrMode;
                    return [self _nextToken];
                }
                token = [EDMLToken tokenWithType:EDMLPT_LT];
                lexmode = EDMLPTagMode;
                break; // we're done and we have to skip the following ifs...
            }
#if 0
            else if(*charp == '>')
            {
                [NSException raise:EDMLParserException format:@"Syntax Error at pos. %d; found stray `>'.", (charp - source)];
                token = nil;  // keep compiler happy
            }
#endif
            else if(EDBitmapCharsetContainsCharacter(spaceCharset, *charp))
            {
                lexmode = EDMLPSpaceMode;
                return [self _nextToken];
            }
            else if(*charp == '&')
            {
                tvalue = readentity(charp, entityTable, &len);
                charp += len;
                token = [EDMLToken tokenWithType:EDMLPT_STRING];
                [token setValue:tvalue];
            }
            else
            {
                start = charp;
                while(EDBitmapCharsetContainsCharacter(textCharset, *charp))
                    charp = nextchar(charp, NO);
                if(start == charp) // not at end and neither a text nor a switch char
                    [NSException raise:EDMLParserException format:@"Found invalid character \\u%x at pos %d.", (int)*charp, (charp - source)];
                token = [EDMLToken tokenWithType:EDMLPT_STRING];
                [token setValue:[NSString stringWithCharacters:start length:(charp - start)]];
            }
            break;

        case EDMLPSpaceMode:
            start = charp;
            while(EDBitmapCharsetContainsCharacter(spaceCharset, *charp))
                charp = nextchar(charp, NO);
                NSAssert(charp != start, @"Entered space mode when not located at a sequence of spaces.");
            token = [EDMLToken tokenWithType:[tagProcessor spaceIsString] ? EDMLPT_STRING : EDMLPT_SPACE];
            if(preservesWhitespace == YES)
                [token setValue:[NSString stringWithCharacters:start length:(charp - start)]];
            else
                [token setValue:@" "];
            lexmode = EDMLPTextMode;
            break;

        case EDMLPTagMode:
            while(EDBitmapCharsetContainsCharacter(spaceCharset, *charp))
                charp = nextchar(charp, YES);
            if(*charp == '<')
            {
                [NSException raise:EDMLParserException format:@"Syntax Error at pos. %d; found `<' in a tag.", (charp - source)];
                token = nil;  // keep compiler happy
            }
                else if(*charp == '>')
                {
                    charp = nextchar(charp, NO);
                    token = [EDMLToken tokenWithType:EDMLPT_GT];
                    lexmode = EDMLPTextMode;
                }
                else if(*charp == '/' && *(charp - 1) != '=') // this handles corrupt HTML as in <body background=/path/to/image.jpg>
                {
                    charp = nextchar(charp, YES);
                    token = [EDMLToken tokenWithType:EDMLPT_SLASH];
                }
                else if(*charp == '=')
                {
                    charp = nextchar(charp, YES);
                    token = [EDMLToken tokenWithType:EDMLPT_EQ];
                }
                else
                {
                    if(*charp == '"')
                    {
                        tvalue = readquotedstring(charp, entityTable, &len);
                        charp += len;
                    }
                    else if(*charp == '\'')
                    {
                        tvalue = readquotedstring(charp, entityTable, &len);
                        charp += len;
                    }
                    else
                    {
                        start = charp;
                        while(EDBitmapCharsetContainsCharacter(attrStopCharset, *charp) == NO)
                            charp = nextchar(charp, YES);
                        if(charp == start)
                            [NSException raise:EDMLParserException format:@"Syntax error at pos. %d; expected either `>' or a tag attribute/value. (Note that tag attribute values must be quoted if they contain anything other than alphanumeric characters.)", (charp - source)];
                        if(*(charp - 1) == '/')
                            charp -= 1;
                        tvalue = [NSString stringWithCharacters:start length:(charp - start)];
                    }
                    token = [EDMLToken tokenWithType:EDMLPT_TSTRING];
                    [token setValue:tvalue];
                }
                break;

        case EDMLPCommentMode:
            while(*charp != '>')
            {
                if(*charp == '[')
                {
                    lexmode = EDMLPCommentBracketMode;
                    return [self _nextToken];
                }
                charp = nextchar(charp, YES);
            }
            charp = nextchar(charp, NO);
            // ignore comment directives
            lexmode = EDMLPTextMode;
            return [self _nextToken];

        case EDMLPProcInstrMode:
            while(*charp != '>')
                charp = nextchar(charp, YES);
            charp = nextchar(charp, NO);
            // ignore processing directives
            lexmode = EDMLPTextMode;
            return [self _nextToken];

        case EDMLPCDATAMode:
            start = charp;
            while((*charp != '>') || (*(charp - 1) != ']') || (*(charp - 2) != ']'))
                charp = nextchar(charp, YES);
                token = [EDMLToken tokenWithType:EDMLPT_STRING];
            [token setValue:[NSString stringWithCharacters:start length:charp - start - 3]];
            charp = nextchar(charp, NO);
            lexmode = EDMLPTextMode;
            break;

        case EDMLPCommentBracketMode:
            start = charp;
            while(*charp != ']')
            {
                if(*charp == '[')
                {
                    // check for <![CDATA[ ... ]]>
                    if((charp == start + 6) && ([[NSString stringWithCharacters:start length:7] isEqualToString:@"[CDATA["]))
                    {
                        lexmode = EDMLPCDATAMode;
                        return [self _nextToken];
                    }
                }
                charp = nextchar(charp, YES);
            }


                charp = nextchar(charp, NO);
            // ignore special processing directives
            lexmode = EDMLPCommentMode;
            return [self _nextToken];

        default: // keep compiler happy
            token = nil;
            break;
    }

    return token;
}

@end
