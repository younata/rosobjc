//
//  NSCalendarDate+ISO8601.m
//  XMLRPC
//
//  Created by znek on Tue Aug 28 2001.
//  $Id: NSCalendarDate+ISO8601.m,v 1.3 2003/03/28 13:12:01 znek Exp $
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


#include "NSCalendarDate+ISO8601.h"


@implementation NSCalendarDate (ISO8601)

/*"
 * Convenience category to make handling of XML-RPC's dateTime.iso8601 data type easier.
"*/

+ (id)dateWithISO8601Representation:(NSString *)iso8601Representation
/*"
 * Returns the NSCalendarDate represented by an ISO8601 representation. Because ISO8601 representations
 * lack the notion of a timezone, they're not that useful at all. This implementation assumes that the timezone
 * is %GMT which might be wrong in your case.
 *
 * This method is not very clever and will do weird stuff (and might even raise an NSRangeException)
 * if the given argument does not represent an ISO8601 representation.
"*/
{
    /* This implementation should have been implemented as
        return [NSCalendarDate dateWithCalendarFormat:@"%Y%M%DT%H:%M:%S"];
        However, this method is broken (tested on Rhapsody)! Try it.
    
        FORMAT/EXAMPLE
        %Y%M%DT%H:%M:%S
        20010208T13:59:25
    */
    NSTimeZone *tz;
    unsigned month, day, hour, minute, second;
    int year;
    year = [[iso8601Representation substringWithRange:(NSMakeRange(0,4))] intValue];
    month = [[iso8601Representation substringWithRange:(NSMakeRange(4,2))] intValue];
    day = [[iso8601Representation substringWithRange:(NSMakeRange(6,2))] intValue];
    hour = [[iso8601Representation substringWithRange:(NSMakeRange(9,2))] intValue];
    minute = [[iso8601Representation substringWithRange:(NSMakeRange(12,2))] intValue];
    second = [[iso8601Representation substringWithRange:(NSMakeRange(15,2))] intValue];
    
    tz = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    return [NSCalendarDate dateWithYear:year month:month day:day hour:hour minute:minute second:second timeZone:tz];
}

@end
