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

#import "SMSHTTPRequest.h"
#import <UIKit/UIKit.h>
#import "SMSAlertView.h"
#import "NSString+UUID.h"
#import "DDXML.h"


NSString *const SMSHTTPRequestKey = @"SMSHTTPRequestKey";
NSString *const SMSHTTPResponseKey = @"SMSHTTPResponseKey";


static NSUInteger networkActivityCounter = 0;
BOOL SMSLoggingEnabled = YES;
static NSUInteger streamResponseToDiskThreshhold = 5000000;
static NSString *connectionErrorAlertMessage = nil;
static BOOL errorAlertRecentlyShown = NO;

static NSString *defaultURL = nil;
static SMSHTTPMethod defaultHTTPMethod = SMSHTTPMethodGET;
static SMSContentType defaultRequestContentType = SMSContentTypeAny;
static SMSContentType defaultResponseContentType = SMSContentTypeAny;
static NSURLRequestCachePolicy defaultCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
static NSTimeInterval defaultTimeout = 30;
static BOOL defaultIgnoreCertificateWarnings = NO;
static id defaultResponseHandlerTarget = nil;
static SEL defaultResponseHandlerSelector = nil;


@interface SMSHTTPRequest ()

- (void)cleanUp;

@end


@implementation SMSHTTPRequest

@synthesize URL, query, requestType;
@synthesize delegate, userInfo, showActivityIndicator;
@synthesize httpMethod, httpHeaders, requestContentType, responseContentType;
@synthesize useStoredCookiesAndCredentials, cachePolicy, timeout, ignoreCertificateWarnings, statusCode, responseLength, ignoreData, skipDefaultResponseMethod;

#pragma mark - Class

+ (void)showNetworkActivityIndicator
{
    if (networkActivityCounter == 0)
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    networkActivityCounter++;
}
+ (void)hideNetworkActivityIndicator
{
    if (networkActivityCounter > 0)
        networkActivityCounter--;
    if (networkActivityCounter == 0)
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

+ (BOOL)isLoggingEnabled { return SMSLoggingEnabled; }
+ (void)setLoggingEnabled:(BOOL)yesOrNo { SMSLoggingEnabled = yesOrNo; }

+ (NSUInteger)streamResponseToDiskThreshold { return streamResponseToDiskThreshhold; }
+ (void)setStreamResponseToDiskThreshold:(NSUInteger)bytes { streamResponseToDiskThreshhold = bytes; }

+ (NSString *)connectionErrorAlertMessage
{
    return connectionErrorAlertMessage;
}
+ (void)setConnectionErrorAlertMessage:(NSString *)msg
{
    [msg retain];
    [connectionErrorAlertMessage release];
    connectionErrorAlertMessage = msg;
}

#pragma mark - Defaults

+ (NSString *)defaultURL { return defaultURL; }
+ (void)setDefaultURL:(NSString *)url
{
    [url retain];
    [defaultURL release];
    defaultURL = url;
}

+ (SMSHTTPMethod)defaultHTTPMethod { return defaultHTTPMethod; }
+ (void)setDefaultHTTPMethod:(SMSHTTPMethod)method { defaultHTTPMethod = method; }

+ (SMSContentType)defaultRequestContentType { return defaultRequestContentType; }
+ (void)setDefaultRequestContentType:(SMSContentType)type { defaultRequestContentType = type; }

+ (SMSContentType)defaultResponseContentType { return defaultResponseContentType; }
+ (void)setDefaultResponseContentType:(SMSContentType)type { defaultResponseContentType = type; }

+ (NSURLRequestCachePolicy)defaultCachePolicy { return defaultCachePolicy; }
+ (void)setDefaultCachePolicy:(NSURLRequestCachePolicy)cp { defaultCachePolicy = cp; }

+ (NSTimeInterval)defaultTimeout { return defaultTimeout; }
+ (void)setDefaultTimeout:(NSTimeInterval)t { defaultTimeout = t; }

+ (BOOL)defaultIgnoreCertificateWarnings { return defaultIgnoreCertificateWarnings; }
+ (void)setDefaultIgnoreCertificateWarnings:(BOOL)yesOrNo { defaultIgnoreCertificateWarnings = yesOrNo; }

+ (id)defaultResponseHandlerTarget { return defaultResponseHandlerTarget; }
+ (void)setDefaultResponseHandlerTarget:(id)obj { defaultResponseHandlerTarget = obj; }
+ (SEL)defaultResponseHandlerSelector { return defaultResponseHandlerSelector; }
+ (void)setDefaultResponseHandlerSelector:(SEL)sel { defaultResponseHandlerSelector = sel; }

#pragma mark - Init + Dealloc

- (id)initWithURL:(NSString *)url requestType:(int)type
{
    self = [super init];
    
    URL = [url copy];
    requestType = type;
    showActivityIndicator = YES;
    
	httpMethod = SMSHTTPMethodDefault;
    requestContentType = SMSContentTypeDefault;
    responseContentType = SMSContentTypeDefault;
    
    useStoredCookiesAndCredentials = YES;
    cachePolicy = defaultCachePolicy;
    timeout = defaultTimeout;
    ignoreCertificateWarnings = defaultIgnoreCertificateWarnings;
    
    return self;
}

+ (id)requestWithURL:(NSString *)url requestType:(int)type
{
    return [[[self alloc] initWithURL:url requestType:type] autorelease];
}

- (id)initWithURL:(NSString *)url
{
    return [self initWithURL:url requestType:0];
}

+ (id)requestWithURL:(NSString *)url
{
    return [[[self alloc] initWithURL:url requestType:0] autorelease];
}

- (id)initWithRequestType:(int)type
{
    return [self initWithURL:defaultURL requestType:type];
}

+ (id)requestWithType:(int)type
{
    return [[[self alloc] initWithRequestType:type] autorelease];
}

+ (id)request
{
	return [[[self alloc] initWithURL:defaultURL requestType:0] autorelease];
}

- (id)init
{
    return [self initWithURL:defaultURL requestType:0];
}

- (void)cancel
{
    [self cleanUp];
	delegate = nil;
}

- (void)cleanUp
{
    if (connection != nil)
        [SMSHTTPRequest hideNetworkActivityIndicator];
    
	[connection cancel];
	connection = nil;
    
    receivedData = nil;
}

- (void)dealloc
{
	if (connection)
		[self cleanUp];
}

#pragma mark - Send

- (void)sendRequestWithQuery:(NSString *)q method:(SMSHTTPMethod)method body:(id)body contentType:(SMSContentType)contentType
{
    if (fired) {
        [NSException raise:@"SMSHTTPRequestException" format:@"An SMSHTTPRequest object is only meant to be used one time."];
        return;
    }
    fired = YES;
    
	query = [q copy];
    NSURL *url = [NSURL URLWithString:[[[NSString stringWithFormat:@"%@%@", URL, query ? query : @""] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    if (SMSLoggingEnabled)
		NSLog(@"SMSHTTPRequest: url = %@", url);
    
    if (!useStoredCookiesAndCredentials) {
        NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:url];
        if (SMSLoggingEnabled)
            NSLog(@"SMSHTTPRequest: deleting stored cookies = %@", cookies);
        for (NSHTTPCookie *thisCookie in cookies)
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:thisCookie];
    }
    
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:cachePolicy timeoutInterval:timeout];
    
    httpMethod = method;
    if (httpMethod == SMSHTTPMethodDefault) httpMethod = defaultHTTPMethod;
	switch (httpMethod) {
        case SMSHTTPMethodOPTIONS: [request setHTTPMethod:@"OPTIONS"];  if (SMSLoggingEnabled) NSLog(@"SMSHTTPRequest: method = OPTIONS"); break;
		case SMSHTTPMethodGET: [request setHTTPMethod:@"GET"]; if (SMSLoggingEnabled) NSLog(@"SMSHTTPRequest: method = GET"); break;
        case SMSHTTPMethodHEAD: [request setHTTPMethod:@"HEAD"]; if (SMSLoggingEnabled) NSLog(@"SMSHTTPRequest: method = HEAD"); break;
		case SMSHTTPMethodPOST: [request setHTTPMethod:@"POST"]; if (SMSLoggingEnabled) NSLog(@"SMSHTTPRequest: method = POST"); break;
        case SMSHTTPMethodPUT: [request setHTTPMethod:@"PUT"]; if (SMSLoggingEnabled) NSLog(@"SMSHTTPRequest: method = PUT"); break;
		case SMSHTTPMethodDELETE: [request setHTTPMethod:@"DELETE"]; if (SMSLoggingEnabled) NSLog(@"SMSHTTPRequest: method = DELETE"); break;
        case SMSHTTPMethodTRACE: [request setHTTPMethod:@"TRACE"]; if (SMSLoggingEnabled) NSLog(@"SMSHTTPRequest: method = TRACE"); break;
        case SMSHTTPMethodCONNECT: [request setHTTPMethod:@"CONNECT"]; if (SMSLoggingEnabled) NSLog(@"SMSHTTPRequest: method = CONNECT"); break;
        default: break;
	}
    
	if (body != nil) {
		NSData *bodyData = nil;
		
        requestContentType = contentType;
        if (requestContentType == SMSContentTypeDefault) requestContentType = defaultRequestContentType;
		switch (requestContentType) {
			case SMSContentTypeText:
			{
				bodyData = [(NSString *)body dataUsingEncoding:NSUTF8StringEncoding];
				[request setValue:@"text/plain; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
			} break;
                
			case SMSContentTypeJSON:
			{
                bodyData = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
				if (SMSLoggingEnabled) {
                    NSData *prettyData = [NSJSONSerialization dataWithJSONObject:body options:NSJSONWritingPrettyPrinted error:nil];
                    NSString *prettyString = [[NSString alloc] initWithData:prettyData encoding:NSUTF8StringEncoding];
					NSLog(@"SMSHTTPRequest: json = %@", prettyString);
                }
				[request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
			} break;
                
			case SMSContentTypeXML:
			{
				if (SMSLoggingEnabled)
					NSLog(@"SMSHTTPRequest: xml = %@", [(DDXMLDocument *)body XMLStringWithOptions:DDXMLNodePrettyPrint]);
				bodyData = [(DDXMLDocument *)body XMLData];
				[request setValue:@"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
			} break;
                
			default:
			{
				if ([body isKindOfClass:[NSData class]])
					bodyData = (NSData *)body;
			} break;
		}
		
		if (bodyData != nil)
			[request setHTTPBody:bodyData];
		
		NSString *contentLength = [NSString stringWithFormat:@"%lu", [bodyData length]];
		[request setValue:contentLength forHTTPHeaderField:@"Content-Length"];
	}
	
    if (responseContentType == SMSContentTypeDefault) responseContentType = defaultResponseContentType;
	switch (responseContentType) {
		case SMSContentTypeText:
        {
			[request setValue:@"text/plain" forHTTPHeaderField:@"Accept"];
			[request setValue:@"utf-8" forHTTPHeaderField:@"Accept-Charset"];
        } break;
            
		case SMSContentTypeJSON:
        {
			[request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
			[request setValue:@"utf-8" forHTTPHeaderField:@"Accept-Charset"];
        } break;
            
		case SMSContentTypeXML:
        {
			[request setValue:@"text/xml" forHTTPHeaderField:@"Accept"];
			[request setValue:@"utf-8" forHTTPHeaderField:@"Accept-Charset"];
        } break;
            
        default: break;
	}
	
    for (NSString *field in httpHeaders)
        [request addValue:[httpHeaders objectForKey:field] forHTTPHeaderField:field];
    
	connection = [[NSURLConnection connectionWithRequest:request delegate:self] retain];
	if (connection != nil) {
        if (showActivityIndicator)
            [SMSHTTPRequest showNetworkActivityIndicator];
		if ([delegate respondsToSelector:@selector(requestStarting:)])
			[delegate requestStarting:self];
	} else {
        if ([delegate respondsToSelector:@selector(requestFailed:)])
            [delegate requestFailed:self];
        if ([delegate respondsToSelector:@selector(requestFinished:)])
            [delegate requestFinished:self];
    }
}

- (void)sendRequestWithQuery:(NSString *)q method:(SMSHTTPMethod)method body:(id)body
{
	[self sendRequestWithQuery:q method:method body:body contentType:requestContentType];
}

- (void)sendRequestWithQuery:(NSString *)q method:(SMSHTTPMethod)method
{
	[self sendRequestWithQuery:q method:method body:nil contentType:requestContentType];
}

- (void)sendRequestWithQuery:(NSString *)q body:(id)body
{
    [self sendRequestWithQuery:q method:httpMethod body:body contentType:requestContentType];
}

- (void)sendRequestWithQuery:(NSString *)q
{
    [self sendRequestWithQuery:q method:httpMethod body:nil contentType:requestContentType];
}

- (void)sendRequestWithBody:(id)body
{
    [self sendRequestWithQuery:nil method:httpMethod body:body contentType:requestContentType];
}

- (void)sendRequest
{
    [self sendRequestWithQuery:nil method:httpMethod body:nil contentType:requestContentType];
}

#pragma mark - NSURLConnection delegate

- (void)resetErrorAlert
{
	errorAlertRecentlyShown = NO;
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
{
	if (SMSLoggingEnabled)
		NSLog(@"SMSHTTPRequest: request headers = %@", [request allHTTPHeaderFields]);
    
    if ([delegate respondsToSelector:@selector(request:willSendRequest:)])
        [delegate request:self willSendRequest:request];
    
    [self performSelector:@selector(resetErrorAlert) withObject:nil afterDelay:5.0];
    return request;
}

- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error
{
	if (SMSLoggingEnabled)
		NSLog(@"SMSHTTPRequest: connection failed, error = %@", error);

	[self cleanUp];
	
    if ([delegate respondsToSelector:@selector(requestFailed:)])
		[delegate requestFailed:self];
    else if (connectionErrorAlertMessage != nil && !errorAlertRecentlyShown) {
		errorAlertRecentlyShown = YES;
        [SMSAlertView errorWithMessage:connectionErrorAlertMessage];
    }
    
    if ([delegate respondsToSelector:@selector(requestFinished:)])
		[delegate requestFinished:self];
}

- (void)connection:(NSURLConnection *)conn didReceiveResponse:(NSHTTPURLResponse *)response
{     
    if (responseContentType == SMSContentTypeAny) {
		NSString *contentType = [[response allHeaderFields] valueForKey:@"Content-Type"];
		if ([contentType rangeOfString:@"text/plain" options:NSCaseInsensitiveSearch].location != NSNotFound)
			responseContentType = SMSContentTypeText;
		else if ([contentType rangeOfString:@"application/json" options:NSCaseInsensitiveSearch].location != NSNotFound)
			responseContentType = SMSContentTypeJSON;
		else if ([contentType rangeOfString:@"text/xml" options:NSCaseInsensitiveSearch].location != NSNotFound)
			responseContentType = SMSContentTypeXML;
    }
    
    statusCode = [response statusCode];
    responseLength = [[[response allHeaderFields] valueForKey:@"Content-Length"] intValue];
	if (SMSLoggingEnabled)
		NSLog(@"SMSHTTPRequest: status code = %d, response headers = %@", statusCode, [response allHeaderFields]);
	
	if ([delegate respondsToSelector:@selector(request:receivedResponseWithStatusCode:)])
		[delegate request:self receivedResponseWithStatusCode:statusCode];
	
	if (responseLength <= streamResponseToDiskThreshhold)
		receivedData = [[NSMutableData alloc] init];
	else {
		if (SMSLoggingEnabled)
			NSLog(@"SMSHTTPRequest: response length > threshold, streaming to file");
		filePath = [[NSTemporaryDirectory() stringByAppendingString:[NSString UUID]] retain];
		dataFile = [[NSOutputStream alloc] initToFileAtPath:filePath append:NO];
		[dataFile open];
	}
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection
{
    if (!useStoredCookiesAndCredentials) {
        if (SMSLoggingEnabled)
            NSLog(@"SMSHTTPRequest: do not use stored credentials");
        return NO;
    } else
        return YES;
}

- (BOOL)connection:(NSURLConnection *)conn canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
	if (SMSLoggingEnabled)
		NSLog(@"SMSHTTPRequest: received authentication challenge, authentication method = %@, host = %@, protocol = %@", protectionSpace.authenticationMethod, protectionSpace.host, protectionSpace.protocol);

    if (ignoreCertificateWarnings)
		return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
	else if ([protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodClientCertificate] || [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
		return NO;
	else
		return YES;
}

- (void)connection:(NSURLConnection *)conn didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	if (SMSLoggingEnabled)
		NSLog(@"SMSHTTPRequest: accepted authentication challenge");
	if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust] && ignoreCertificateWarnings) {
		[challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
		return;
	}
		
	if ([delegate respondsToSelector:@selector(request:receivedAuthenticationChallenge:)])
        [delegate request:self receivedAuthenticationChallenge:challenge];
    else
        [[challenge sender] cancelAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	if (SMSLoggingEnabled)
		NSLog(@"SMSHTTPRequest: canceled authentication challenge");
}

- (void)connection:(NSURLConnection *)conn didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
	if ([delegate respondsToSelector:@selector(request:updatedProgress:)])
        [delegate request:self updatedProgress:(float)totalBytesWritten/(float)totalBytesExpectedToWrite];
}

- (void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)data
{
	if (receivedData)
		[receivedData appendData:data];
	else {
		NSUInteger l = [data length];
		if ([dataFile write:[data bytes] maxLength:l] != l) {
            [SMSAlertView errorWithMessage:@"Insufficient storage space to hold the response of the request."];
			
			[self cleanUp];
			
			if ([delegate respondsToSelector:@selector(requestFinished:)])
				[delegate requestFinished:self];
			
			return;
		}
	}
	
	bytesReceived += [data length];
    if ([delegate respondsToSelector:@selector(request:updatedProgress:)])
        [delegate request:self updatedProgress:(float)bytesReceived/(float)responseLength];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)conn
{
    responseLength = bytesReceived;
	
    if (bytesReceived > 0) {
		if (statusCode == 200) {
			id responseData = nil;
			
			if (receivedData) {
				switch (responseContentType) {
					case SMSContentTypeText:
					{
						NSString *responseString = [[[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding] autorelease];
						if (SMSLoggingEnabled)
							NSLog(@"SMSHTTPRequest: text = %@", responseString);
						responseData = responseString;
					} break;
                        
					case SMSContentTypeBinary:
						responseData = receivedData;
						break;
					
                    case SMSContentTypeJSON:
					{
						NSString *responseString = [[[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding] autorelease];
                        responseData = [NSJSONSerialization JSONObjectWithData:receivedData options:NSJSONReadingAllowFragments error:nil];
						if (SMSLoggingEnabled) {
                            NSData *prettyData = [NSJSONSerialization dataWithJSONObject:responseData options:NSJSONWritingPrettyPrinted error:nil];
                            NSString *prettyString = [[NSString alloc] initWithData:prettyData encoding:NSUTF8StringEncoding];
							NSLog(@"SMSHTTPRequest: json = %@", prettyString);
                        }
					} break;
                        
					case SMSContentTypeXML:
					{
						NSError *error = nil;
						responseData = [[[DDXMLDocument alloc] initWithData:receivedData options:0 error:&error] autorelease];
						if (SMSLoggingEnabled) {
							if (!error)
								NSLog(@"SMSHTTPRequest: xml = %@", [(DDXMLDocument *)responseData XMLStringWithOptions:DDXMLNodePrettyPrint]);
							else
								NSLog(@"SMSHTTPRequest: xml error = %@", error);
						}
					} break;
                        
                    default: break;
				}
			} else
				responseData = [NSData dataWithContentsOfMappedFile:filePath];
			
			if (!skipDefaultResponseMethod) {
                NSMutableDictionary *context = [NSMutableDictionary dictionaryWithObject:self forKey:SMSHTTPRequestKey];
                if (responseData != nil)
                    [context setValue:responseData forKey:SMSHTTPResponseKey];
				[defaultResponseHandlerTarget performSelector:defaultResponseHandlerSelector withObject:context];
            }
			
			if ([delegate respondsToSelector:@selector(request:receivedData:)] && !ignoreData)
				[delegate request:self receivedData:responseData];
		} else if (responseContentType != SMSContentTypeBinary) {
			NSString *response = [[[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding] autorelease];
			if (SMSLoggingEnabled)
				NSLog(@"SMSHTTPRequest: response = %@", response);
		}
	}

    [self cleanUp];
    
	if ([delegate respondsToSelector:@selector(requestFinished:)])
		[delegate requestFinished:self];
}

@end