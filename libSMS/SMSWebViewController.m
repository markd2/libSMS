/*
 SMSWebViewController.m
 
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

#import "SMSWebViewController.h"
#import "SMSWebView.h"
#import "SMSHTTPRequest.h"
#import "SMSAlertView.h"


@interface SMSWebViewController ()

@property (nonatomic, strong) NSURL *authURL;

@end


@implementation SMSWebViewController

@synthesize webView=view, URL;
@synthesize backButtonHidden;
@synthesize inSafariButtonHidden, safariURL;
@synthesize authenticationEnabled, authURL;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    backButtonHidden = YES;
    authenticationEnabled = NO;
    return self;
}

- (void)loadView
{
	webView = [[SMSWebView alloc] initWithFrame:CGRectZero];
	webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	webView.delegate = self;
	webView.scalesPageToFit = YES;
	self.view = webView;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
    
    if (backButtonHidden)
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleBordered target:self action:@selector(done:)];
    else
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(back:)];

    if (!inSafariButtonHidden)
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"In Safari" style:UIBarButtonItemStyleBordered target:self action:@selector(inSafari:)];
	
	if (URL)
		[webView loadRequest:[NSURLRequest requestWithURL:URL]];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	spinner = nil;
}

- (void)dealloc
{
    webView.delegate = nil;
	[webView stopLoading];

    [authConnection cancel];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Actions

- (void)done:(id)sender
{
    [authConnection cancel];
    [self dismissModalViewControllerAnimated:YES];
}

- (void)back:(id)sender
{
    [webView goBack];
}

- (void)inSafari:(UIBarButtonItem *)sender
{
    UIApplication *app = [UIApplication sharedApplication];
	if (safariURL)
		[app openURL:safariURL];
	else if ([app canOpenURL:[webView.request URL]])
		[app openURL:[webView.request URL]];
    else
        [app openURL:URL];
}

- (void)setURL:(NSURL *)u
{
    URL = u;
	[webView loadRequest:[NSURLRequest requestWithURL:URL]];
}

#pragma mark - UIWebView delegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if ([[request.URL absoluteString] rangeOfString:@"mailto:"].location != NSNotFound) {
        if (![[UIApplication sharedApplication] canOpenURL:request.URL])
            [SMSAlertView errorWithMessage:@"The Mail app must be setup before you can send an email."];
        else
            [[UIApplication sharedApplication] openURL:request.URL];
        return NO;
    }
    
    if (spinner == nil) {
		spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		spinner.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
		spinner.hidesWhenStopped = YES;
		CGRect b = self.view.bounds;
		spinner.center = CGPointMake(b.size.width/2.0, b.size.height/2.0-42);
		[self.view addSubview:spinner];
	}
    
    if (authenticationEnabled && !authenticated) {
        [spinner startAnimating];
        
        [authConnection cancel];
        
        self.authURL = request.URL;
        NSMutableURLRequest *req = [NSURLRequest requestWithURL:request.URL];
        authConnection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
        
        return NO;
    }
    
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	[spinner startAnimating];
}

- (void)showLoadError
{
    SMSAlertView *alert = [[SMSAlertView alloc] initWithTitle:@"Error"
                                                      message:@"Could not load the page. Please check your internet connection before trying again."
                                                     delegate:nil
                                            cancelButtonTitle:@"Dismiss"
                                            otherButtonTitles:nil];
    [alert show];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	[spinner stopAnimating];
    [self showLoadError];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	[spinner stopAnimating];
}

#pragma mark - NSURLConnectionDelegate

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSHTTPURLResponse *)redirectResponse
{
    if (SMSLoggingEnabled) {
        NSLog(@"SMSWebViewController: auth request redirect response code = %d, headers = %@", [redirectResponse statusCode], [redirectResponse allHeaderFields]);
        NSLog(@"SMSWebViewController: auth request url = %@", [[request URL] absoluteString]);
		NSLog(@"SMSWebViewController: auth request headers = %@", [request allHTTPHeaderFields]);
    }
    return request;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (SMSLoggingEnabled)
        NSLog(@"SMSWebViewController: auth connecton failure = %@", error);
    [spinner stopAnimating];
    [self showLoadError];
    
	[authConnection cancel];
    authConnection = nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    SMSAlertView *alert = [[SMSAlertView alloc] initWithTitle:@"Login"
                                                      message:nil 
                                                     delegate:self
                                            cancelButtonTitle:@"Cancel"
                                            otherButtonTitles:@"Submit", nil];
    alert.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    alert.userInfo = challenge;
    [alert show];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response;
{
    if (SMSLoggingEnabled)
		NSLog(@"SMSWebViewController: auth request status code = %d, response headers = %@", [response statusCode], [response allHeaderFields]);
    
    authenticated = YES;
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:authURL];
    [webView loadRequest:urlRequest];
    
    [authConnection cancel];
    authConnection = nil;
}

#pragma mark - UIAlertView delegate

- (BOOL)alertViewShouldEnableFirstOtherButton:(SMSAlertView *)alertView
{
    if (alertView.alertViewStyle == UIAlertViewStyleDefault)
        return YES;
    
    if ([[[alertView textFieldAtIndex:0] text] length] == 0)
        return NO;
    if (alertView.alertViewStyle == UIAlertViewStylePlainTextInput)
        return YES;
    else 
        return ([[[alertView textFieldAtIndex:1] text] length] > 0);
}

- (void)alertView:(SMSAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex)
        return;
    
    NSString *username = [[[alertView textFieldAtIndex:0] text] stringByReplacingOccurrencesOfString:@"/" withString:@"\\"];
    NSString *password = [[alertView textFieldAtIndex:1] text];
    
    NSURLCredential *creds = [NSURLCredential credentialWithUser:username password:password persistence:NSURLCredentialPersistenceForSession];
    [[(NSURLAuthenticationChallenge *)alertView.userInfo sender] useCredential:creds forAuthenticationChallenge:(NSURLAuthenticationChallenge *)alertView.userInfo];
}

@end