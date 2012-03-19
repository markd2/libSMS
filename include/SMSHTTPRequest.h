/*
 SMSHTTPRequest.h
 
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

#import <Foundation/Foundation.h>


extern NSString *const SMSHTTPRequestKey;
extern NSString *const SMSHTTPResponseKey;

extern BOOL SMSLoggingEnabled;


typedef enum SMSHTTPMethod {
    SMSHTTPMethodDefault,
    SMSHTTPMethodOPTIONS,
	SMSHTTPMethodGET,
    SMSHTTPMethodHEAD,
    SMSHTTPMethodPOST,
    SMSHTTPMethodPUT,
	SMSHTTPMethodDELETE,
    SMSHTTPMethodTRACE,
    SMSHTTPMethodCONNECT
} SMSHTTPMethod;

typedef enum SMSContentType {
    SMSContentTypeAny,
    SMSContentTypeDefault,
    SMSContentTypeText,
    SMSContentTypeBinary,
    SMSContentTypeJSON,
    SMSContentTypeXML
} SMSContentType;


@protocol SMSHTTPRequestDelegate;

@interface SMSHTTPRequest : NSObject {
    NSString *URL;
	NSString *query;
	int requestType;
    
	id<SMSHTTPRequestDelegate> delegate;
    id userInfo;
    BOOL showActivityIndicator;
    
    SMSHTTPMethod httpMethod;
    NSDictionary *httpHeaders;
    SMSContentType requestContentType;
    SMSContentType responseContentType;
	
	NSURLConnection *connection;
    BOOL fired;
    BOOL useStoredCookiesAndCredentials;
    NSURLRequestCachePolicy cachePolicy;
    NSTimeInterval timeout;
	BOOL ignoreCertificateWarnings;
    NSInteger statusCode;
    NSUInteger responseLength;
    BOOL ignoreData;
    BOOL skipDefaultResponseHandler;
	
	NSMutableData *receivedData;
	NSString *filePath;
	NSOutputStream *dataFile;
    NSUInteger bytesReceived;
}
@property (nonatomic, strong, readonly) NSString *URL;
@property (nonatomic, strong, readonly) NSString *query;
@property (nonatomic, readonly) int requestType;

@property (nonatomic, weak) id<SMSHTTPRequestDelegate> delegate;
@property (nonatomic, strong) id<NSObject> userInfo;
@property (nonatomic) BOOL showActivityIndicator;

@property (nonatomic, readonly) SMSHTTPMethod httpMethod;
@property (nonatomic, copy) NSDictionary *httpHeaders;
@property (nonatomic, readonly) SMSContentType requestContentType;
@property (nonatomic) SMSContentType responseContentType;

@property (nonatomic) BOOL useStoredCookiesAndCredentials;
@property (nonatomic) NSURLRequestCachePolicy cachePolicy;
@property (nonatomic) NSTimeInterval timeout;
@property (nonatomic) BOOL ignoreCertificateWarnings;
@property (nonatomic) NSInteger statusCode;
@property (nonatomic, readonly) NSUInteger responseLength;
@property (nonatomic) BOOL ignoreData;
@property (nonatomic) BOOL skipDefaultResponseMethod;

+ (void)showNetworkActivityIndicator;
+ (void)hideNetworkActivityIndicator;

+ (BOOL)isLoggingEnabled;
+ (void)setLoggingEnabled:(BOOL)yesOrNo;

+ (NSUInteger)streamResponseToDiskThreshold;
+ (void)setStreamResponseToDiskThreshold:(NSUInteger)bytes;

+ (NSString *)connectionErrorAlertMessage;
+ (void)setConnectionErrorAlertMessage:(NSString *)msg;

+ (NSString *)defaultURL;
+ (void)setDefaultURL:(NSString *)url;

+ (SMSHTTPMethod)defaultHTTPMethod;
+ (void)setDefaultHTTPMethod:(SMSHTTPMethod)method;

+ (SMSContentType)defaultRequestContentType;
+ (void)setDefaultRequestContentType:(SMSContentType)type;

+ (SMSContentType)defaultResponseContentType;
+ (void)setDefaultResponseContentType:(SMSContentType)type;

+ (NSURLRequestCachePolicy)defaultCachePolicy;
+ (void)setDefaultCachePolicy:(NSURLRequestCachePolicy)cp;

+ (NSTimeInterval)defaultTimeout;
+ (void)setDefaultTimeout:(NSTimeInterval)t;

+ (BOOL)defaultIgnoreCertificateWarnings;
+ (void)setDefaultIgnoreCertificateWarnings:(BOOL)yesOrNo;

+ (id)defaultResponseHandlerTarget;
+ (void)setDefaultResponseHandlerTarget:(id)obj;
+ (SEL)defaultResponseHandlerSelector;
+ (void)setDefaultResponseHandlerSelector:(SEL)sel;
/* The default response handler can accept one argument of type NSDictionary.
   The dictionary contains two keys: SMSHTTPRequestKey and SMSHTTPResponseKey. 
   e.g. - (void)myDefaultResponseHandle:(NSDictionary *)context */

- (id)initWithURL:(NSString *)url requestType:(int)type;
+ (id)requestWithURL:(NSString *)url requestType:(int)type;
- (id)initWithURL:(NSString *)url;
+ (id)requestWithURL:(NSString *)url;
- (id)initWithRequestType:(int)type;
+ (id)requestWithType:(int)type;
+ (id)request;

- (void)sendRequestWithQuery:(NSString *)query method:(SMSHTTPMethod)method body:(id)body contentType:(SMSContentType)contentType;
- (void)sendRequestWithQuery:(NSString *)query method:(SMSHTTPMethod)method body:(id)body;
- (void)sendRequestWithQuery:(NSString *)query method:(SMSHTTPMethod)method;
- (void)sendRequestWithQuery:(NSString *)query body:(id)body;
- (void)sendRequestWithQuery:(NSString *)query;
- (void)sendRequestWithBody:(id)body;
- (void)sendRequest;

- (void)cancel;

@end


@protocol SMSHTTPRequestDelegate <NSObject>

@optional
- (void)requestStarting:(SMSHTTPRequest *)aRequest;
- (void)requestFailed:(SMSHTTPRequest *)aRequest;
- (void)request:(SMSHTTPRequest *)aRequest willSendRequest:(NSURLRequest *)req;
- (void)request:(SMSHTTPRequest *)aRequest receivedAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;
- (void)request:(SMSHTTPRequest *)aRequest receivedResponseWithStatusCode:(NSInteger)code;
- (void)request:(SMSHTTPRequest *)aRequest updatedProgress:(float)progress;
- (void)request:(SMSHTTPRequest *)aRequest receivedData:(id)data;
- (void)requestFinished:(SMSHTTPRequest *)aRequest;

@end