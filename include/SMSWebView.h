/*
 SMSWebView.h
 
 Copyright (c) 2011, Alex Silverman
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

#import <UIKit/UIKit.h>


@protocol SMSWebViewAnnotation <NSCopying>

- (CGPoint)location; // percentage of content size
- (UIImage *)img;

@end


@interface SMSWebView : UIWebView {
	NSMutableArray *annotations;
	NSMutableDictionary *annotationViews;
    
    BOOL horizontalAnnotationsOffset;
    BOOL annotationsHidden;
}
@property (nonatomic) BOOL horizontalAnnotationsOffset;
@property (nonatomic) BOOL annotationsHidden;

- (void)addAnnotations:(NSArray *)a;
- (void)removeAnnotations:(NSArray *)a;

- (void)renderInContext:(CGContextRef)ctx;

@end


@protocol SMSWebViewDelegate <UIWebViewDelegate>

@optional
- (void)webViewDidScroll:(SMSWebView *)aWebView;
- (void)webViewDidZoom:(SMSWebView *)aWebView;
- (void)webView:(SMSWebView *)aWebView didSelectAnnotation:(id<SMSWebViewAnnotation>)annotation;

@end