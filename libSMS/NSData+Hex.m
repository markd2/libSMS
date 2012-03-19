//
//  NSData+Hex.m
//  Created by Alex Silverman on 5/12/10.
//

#import "NSData+Hex.h"

@implementation NSData (Hex)

/* Code found here:
 http://stackoverflow.com/a/7520655/1274672 */

- (NSString *)hexString
{
    NSUInteger capacity = [self length] * 2;
    NSMutableString *stringBuffer = [NSMutableString stringWithCapacity:capacity];
    const unsigned char *dataBuffer = [self bytes];
    for (NSInteger i=0; i<[self length]; i++) {
        [stringBuffer appendFormat:@"%02X", (NSUInteger)dataBuffer[i]];
    }
    return stringBuffer;
}

@end