//
//  NSNumber+SMS.m
//  Created by Alex Silverman on 5/16/11.
//

#import "NSNumber+SMS.h"

@implementation NSNumber (SMS)

- (id)increment
{
    NSNumber *ret = nil;
    
    const char *type = [self objCType];
    switch (type[0]) {
        case 'c':
            ret = [NSNumber numberWithChar:[self charValue]+1];
            break;
        case 'C':
            ret = [NSNumber numberWithUnsignedChar:[self unsignedCharValue]+1];
            break;
        case 'd':
            ret = [NSNumber numberWithDouble:[self doubleValue]+1.0];
            break;
        case 'f':
            ret = [NSNumber numberWithFloat:[self floatValue]+1.0];
            break;
        case 'i':
            ret = [NSNumber numberWithInt:[self intValue]+1];
            break;
        case 'I':
            ret = [NSNumber numberWithUnsignedInt:[self unsignedIntValue]+1];
            break;
        case 'l':
            ret = [NSNumber numberWithLong:[self longValue]+1];
            break;
        case 'L':
            ret = [NSNumber numberWithUnsignedLong:[self unsignedLongValue]+1];
            break;
        case 'q':
            ret = [NSNumber numberWithLongLong:[self longLongValue]+1];
            break;
        case 'Q':
            ret = [NSNumber numberWithUnsignedLongLong:[self unsignedLongLongValue]+1];
            break;
        case 's':
            ret = [NSNumber numberWithShort:[self shortValue]+1];
            break;
        case 'S':
            ret = [NSNumber numberWithUnsignedShort:[self unsignedShortValue]+1];
            break;
        default:
            ret = [NSNumber numberWithInteger:[self integerValue]+1];
            break;
    }
                   
    return ret;
}

- (id)decrement
{
    NSNumber *ret = nil;
    
    const char *type = [self objCType];
    switch (type[0]) {
        case 'c':
            ret = [NSNumber numberWithChar:[self charValue]-1];
            break;
        case 'C':
            ret = [NSNumber numberWithUnsignedChar:[self unsignedCharValue]-1];
            break;
        case 'd':
            ret = [NSNumber numberWithDouble:[self doubleValue]-1.0];
            break;
        case 'f':
            ret = [NSNumber numberWithFloat:[self floatValue]-1.0];
            break;
        case 'i':
            ret = [NSNumber numberWithInt:[self intValue]-1];
            break;
        case 'I':
            ret = [NSNumber numberWithUnsignedInt:[self unsignedIntValue]-1];
            break;
        case 'l':
            ret = [NSNumber numberWithLong:[self longValue]-1];
            break;
        case 'L':
            ret = [NSNumber numberWithUnsignedLong:[self unsignedLongValue]-1];
            break;
        case 'q':
            ret = [NSNumber numberWithLongLong:[self longLongValue]-1];
            break;
        case 'Q':
            ret = [NSNumber numberWithUnsignedLongLong:[self unsignedLongLongValue]-1];
            break;
        case 's':
            ret = [NSNumber numberWithShort:[self shortValue]-1];
            break;
        case 'S':
            ret = [NSNumber numberWithUnsignedShort:[self unsignedShortValue]-1];
            break;
        default:
            ret = [NSNumber numberWithInteger:[self integerValue]-1];
            break;
    }
    
    return ret;
}

- (id)toggleBool
{
    if ([self boolValue])
        return [NSNumber numberWithBool:NO];
    else
        return [NSNumber numberWithBool:YES];
}

@end