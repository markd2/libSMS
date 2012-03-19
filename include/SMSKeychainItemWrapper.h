//
//  SMSKeychainItemWrapper.h
//  Created by Alex Silverman on 9/13/11.
//

/* Based off Apple's example code here:
 http://developer.apple.com/library/ios/#samplecode/GenericKeychain/Listings/Classes_KeychainItemWrapper_h.html */

#import <Foundation/Foundation.h>

@interface SMSKeychainItemWrapper : NSObject {
    @private
    NSMutableDictionary *keychainItemData;
    NSMutableDictionary *genericPasswordQuery;
}
- (id)initWithAccount:(NSString *)account service:(NSString *)service accessGroup:(NSString *)accessGroup;

- (id)objectForKey:(id)key;
- (OSStatus)setObject:(id)obj forKey:(id)key;

// Convenience getters/setters
- (NSString *)password;
- (OSStatus)setPassword:(NSString *)pw;
- (NSDate *)lastModified;

- (OSStatus)resetKeychainItem;

@end