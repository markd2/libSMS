//
//  NSString+XML.h
//  Created by Alex Silverman on 6/20/11.
//

#import <Foundation/Foundation.h>

@interface NSString (XML)

- (NSString *)stringByAddingXMLEscapes;
- (NSString *)stringByReplacingXMLEscapes;

@end