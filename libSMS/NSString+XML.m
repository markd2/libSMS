//
//  NSString+XML.m
//  Created by Alex Silverman on 6/20/11.
//

#import "NSString+XML.h"

@implementation NSString (XML)

- (NSString *)stringByAddingXMLEscapes
{
    return [[[[[self stringByReplacingOccurrencesOfString: @"&" withString: @"&amp;"]
               stringByReplacingOccurrencesOfString: @"\"" withString: @"&quot;"]
              stringByReplacingOccurrencesOfString: @"'" withString: @"&apos;"]
             stringByReplacingOccurrencesOfString: @">" withString: @"&gt;"]
            stringByReplacingOccurrencesOfString: @"<" withString: @"&lt;"];
}

- (NSString *)stringByReplacingXMLEscapes
{
    return [[[[[self stringByReplacingOccurrencesOfString: @"&amp;" withString: @"&"]
               stringByReplacingOccurrencesOfString: @"&quot;" withString: @"\\"]
              stringByReplacingOccurrencesOfString: @"&apos;" withString: @"'"]
             stringByReplacingOccurrencesOfString: @"&gt;" withString: @">"]
            stringByReplacingOccurrencesOfString: @"&lt;" withString: @"<"];
}

@end