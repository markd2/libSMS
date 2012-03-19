//
//  SMSKeychainItemWrapper.m
//  Created by Alex Silverman on 9/13/11.
//

/* Based off Apple's example code here:
 http://developer.apple.com/library/ios/#samplecode/GenericKeychain/Listings/Classes_KeychainItemWrapper_m.html */

#import "SMSKeychainItemWrapper.h"
#import <Security/Security.h>


@interface SMSKeychainItemWrapper ()

@property (nonatomic, retain) NSMutableDictionary *keychainItemData;
@property (nonatomic, retain) NSMutableDictionary *genericPasswordQuery;

- (NSMutableDictionary *)secItemFormatToDictionary:(NSDictionary *)dictionaryToConvert;
- (NSMutableDictionary *)dictionaryToSecItemFormat:(NSDictionary *)dictionaryToConvert;

- (OSStatus)writeToKeychain;

@end


@implementation SMSKeychainItemWrapper

@synthesize keychainItemData, genericPasswordQuery;

- (id)initWithAccount:(NSString *)account service:(NSString *)service accessGroup:(NSString *)accessGroup
{
    self = [super init];
    if (self)
    {
        genericPasswordQuery = [[NSMutableDictionary alloc] init];
        
		[genericPasswordQuery setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
        [genericPasswordQuery setObject:account forKey:(id)kSecAttrAccount];
        [genericPasswordQuery setObject:service forKey:(id)kSecAttrService];

		if (accessGroup != nil) {
#if !TARGET_IPHONE_SIMULATOR		
            [genericPasswordQuery setObject:accessGroup forKey:(id)kSecAttrAccessGroup];
#endif
		}
		
        [genericPasswordQuery setObject:(id)kSecMatchLimitOne forKey:(id)kSecMatchLimit];
        [genericPasswordQuery setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnAttributes];
        
        NSDictionary *tempQuery = [NSDictionary dictionaryWithDictionary:genericPasswordQuery];
        NSMutableDictionary *outDictionary = nil;
        
        if (!SecItemCopyMatching((CFDictionaryRef)tempQuery, (CFTypeRef *)&outDictionary) == noErr) {
            [self resetKeychainItem];
    
            [keychainItemData setObject:account forKey:(id)kSecAttrAccount];
            [keychainItemData setObject:service forKey:(id)kSecAttrService];
			if (accessGroup != nil) {
#if !TARGET_IPHONE_SIMULATOR
				[keychainItemData setObject:accessGroup forKey:(id)kSecAttrAccessGroup];
#endif
			}
		} else
            self.keychainItemData = [self secItemFormatToDictionary:outDictionary];
        
		[outDictionary release];
    }

    return self;
}

- (void)dealloc
{
    [keychainItemData release];
    [genericPasswordQuery release];
	[super dealloc];
}

- (id)objectForKey:(id)key
{
    return [keychainItemData objectForKey:key];
}

- (OSStatus)setObject:(id)inObject forKey:(id)key 
{
    OSStatus result = noErr;
    
    if (inObject == nil)
        inObject = @"";
    
    id currentObject = [keychainItemData objectForKey:key];
    if (key == (id)kSecValueData || ![currentObject isEqual:inObject]) {
        [keychainItemData setObject:inObject forKey:key];
        result = [self writeToKeychain];
    }
    
    return result;
}

- (NSString *)password
{
    return [self objectForKey:(id)kSecValueData];
}

- (OSStatus)setPassword:(NSString *)pw
{
    return [self setObject:pw forKey:(id)kSecValueData];
}

- (NSDate *)lastModified
{
    return (NSDate *)[self objectForKey:(id)kSecAttrModificationDate];
}

- (OSStatus)resetKeychainItem
{
	OSStatus result = noErr;
    
    if (!keychainItemData)
        self.keychainItemData = [[NSMutableDictionary alloc] init];
    else if (keychainItemData) {
        NSMutableDictionary *tempDictionary = [self dictionaryToSecItemFormat:keychainItemData];
		result = SecItemDelete((CFDictionaryRef)tempDictionary);
    }
    
    [keychainItemData setObject:@"" forKey:(id)kSecAttrAccount];
    [keychainItemData setObject:@"" forKey:(id)kSecAttrService];
    [keychainItemData setObject:@"" forKey:(id)kSecAttrLabel];
    [keychainItemData setObject:@"" forKey:(id)kSecAttrDescription];
    
    [keychainItemData setObject:@"" forKey:(id)kSecValueData];
    
    return result;
}

#pragma mark - Private

- (NSMutableDictionary *)dictionaryToSecItemFormat:(NSDictionary *)dictionaryToConvert
{
    NSMutableDictionary *returnDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionaryToConvert];
    [returnDictionary setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
    NSString *passwordString = [dictionaryToConvert objectForKey:(id)kSecValueData];
    [returnDictionary setObject:[passwordString dataUsingEncoding:NSUTF8StringEncoding] forKey:(id)kSecValueData];
    return returnDictionary;
}

- (NSMutableDictionary *)secItemFormatToDictionary:(NSDictionary *)dictionaryToConvert
{
    NSMutableDictionary *returnDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionaryToConvert];
    
    [returnDictionary setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
    [returnDictionary setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
    
    NSData *passwordData = nil;
    if (SecItemCopyMatching((CFDictionaryRef)returnDictionary, (CFTypeRef *)&passwordData) == noErr) {
        NSString *password = [[[NSString alloc] initWithBytes:[passwordData bytes] length:[passwordData length] 
                                                     encoding:NSUTF8StringEncoding] autorelease];
        [returnDictionary setObject:password forKey:(id)kSecValueData];
    }
    [passwordData release];
    
    [returnDictionary removeObjectForKey:(id)kSecReturnData];
	return returnDictionary;
}

- (OSStatus)writeToKeychain
{
	OSStatus result = noErr;
    
    NSDictionary *attributes = nil;
    if (SecItemCopyMatching((CFDictionaryRef)genericPasswordQuery, (CFTypeRef *)&attributes) == noErr) {
        NSMutableDictionary *updateItem= [NSMutableDictionary dictionaryWithDictionary:attributes];
        [updateItem setObject:[genericPasswordQuery objectForKey:(id)kSecClass] forKey:(id)kSecClass];

        NSMutableDictionary *tempCheck = [self dictionaryToSecItemFormat:keychainItemData];
        [tempCheck removeObjectForKey:(id)kSecClass];
#if TARGET_IPHONE_SIMULATOR
		[tempCheck removeObjectForKey:(id)kSecAttrAccessGroup];
#endif

        result = SecItemUpdate((CFDictionaryRef)updateItem, (CFDictionaryRef)tempCheck);
    } else
        result = SecItemAdd((CFDictionaryRef)[self dictionaryToSecItemFormat:keychainItemData], NULL);
    
    return result;
}

@end