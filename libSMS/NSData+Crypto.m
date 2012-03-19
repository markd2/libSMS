/*
 NSData+Crypto.m
 
 Copyright (c) 2010, Alex Silverman
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 2. Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 
 3. Neither the name of Alex Silverman nor the
 names of its contributors may be used to endorse or promote products
 derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "NSData+Crypto.h"
#import <Security/Security.h>
#import <CommonCrypto/CommonDigest.h>

@implementation NSData (Crypto)

- (NSData *)encryptWithPublicKey:(SecKeyRef)publicKey
{
	if (publicKey == NULL) {
		NSLog(@"NSData+Crypto: public key cannot be NULL");
		return nil;
	}
	
    size_t cipherBufferSize = SecKeyGetBlockSize(publicKey);
    uint8_t *cipherBuffer = (uint8_t *)calloc(cipherBufferSize, sizeof(uint8_t));

    if (cipherBufferSize < [self length]) {
		NSLog(@"NSData+Crypto: could not encrypt, packet too large");
        return nil;
    }
	
    OSStatus status = SecKeyEncrypt(publicKey, kSecPaddingPKCS1, [self bytes], [self length], cipherBuffer, &cipherBufferSize);
	
	if (status != noErr) {
		NSLog(@"NSData+Crypto: encryption failure, OSStatus = %ld", status);
		return nil;
	}
	
	NSData *d = [NSData dataWithBytes:cipherBuffer length:cipherBufferSize];
	free(cipherBuffer);
	return d;
}

#pragma mark - Hashes

- (NSData *)sha1Hash
{
	unsigned char *hash = malloc(CC_SHA1_DIGEST_LENGTH);
	CC_SHA1([self bytes], [self length], hash);
	NSData *d = [NSData dataWithBytes:hash length:CC_SHA1_DIGEST_LENGTH];
	free(hash);
	return d;
}

- (NSData *)sha224Hash
{
	unsigned char *hash = malloc(CC_SHA224_DIGEST_LENGTH);
	CC_SHA224([self bytes], [self length], hash);
	NSData *d = [NSData dataWithBytes:hash length:CC_SHA224_DIGEST_LENGTH];
	free(hash);
	return d;
}

@end