//
//  NSString+UUID.m
//  Created by Alex Silverman on 8/5/10.
//

#import "NSString+UUID.h"

@implementation NSString (UUID)

+ (NSString *)UUID;
{
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    CFStringRef uuidStr = CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);
    return (__bridge_transfer NSString *)uuidStr;
}

@end