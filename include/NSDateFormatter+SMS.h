//
//  NSDateFormatter+SMS.h
//  Created by Alex Silverman on 9/15/10.
//

#import <Foundation/Foundation.h>

@interface NSDateFormatter (SMS)

+ (id)shortFormatter;
+ (id)mediumFormatter;
+ (id)iso8601Formatter;

@end