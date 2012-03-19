/*
 SMSWebView.m
 
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

#import "SMSWebView.h"
#import <QuartzCore/QuartzCore.h>


@interface SMSWebView ()

- (void)updateAnnotationViews;
- (void)selectAnnotation:(UIButton *)sender;

@end


@implementation SMSWebView

@synthesize horizontalAnnotationsOffset, annotationsHidden;

- (void)renderInContext:(CGContextRef)ctx
{
	NSArray *allViews = [annotationViews allValues];
	for (UIView *thisView in allViews)
		[thisView removeFromSuperview];
	
	[self.layer renderInContext:ctx];
	
	for (UIView *thisView in allViews)
		[self addSubview:thisView];
}

#pragma mark - Annotations

- (void)updateAnnotationViews
{
    UIScrollView *scrollView = [self scrollView];
    
	for (id<SMSWebViewAnnotation> thisAnnotation in annotations) {
		UIButton *annotationView = [annotationViews objectForKey:thisAnnotation];
        CGPoint l = [thisAnnotation location];
        UIImage *img = [thisAnnotation img];
        CGRect f = CGRectMake(l.x*scrollView.contentSize.width, l.y*scrollView.contentSize.height, [img size].width, [img size].height);
        if (horizontalAnnotationsOffset)
            f.origin.x += scrollView.contentOffset.x;
        annotationView.frame = f;
        
        [annotationView removeFromSuperview];
        [scrollView addSubview:annotationView];
	}
}

- (void)addAnnotations:(NSArray *)a
{
	if (annotations == nil) {
		annotations = [[NSMutableArray alloc] init];
		annotationViews = [[NSMutableDictionary alloc] init];
	}

	for (id<SMSWebViewAnnotation> thisAnnotation in a) {
		if (![annotations containsObject:thisAnnotation]) {
			[annotations addObject:thisAnnotation];
            
            UIButton *annotationView = [UIButton buttonWithType:UIButtonTypeCustom];
			UIImage *img = [thisAnnotation img];
			[annotationView setImage:img forState:UIControlStateNormal];
			[annotationView addTarget:self action:@selector(selectAnnotation:) forControlEvents:UIControlEventTouchUpInside];
            annotationView.tag = [annotations indexOfObject:thisAnnotation];
            annotationView.hidden = annotationsHidden;
            
			[annotationViews setObject:annotationView forKey:thisAnnotation];
        }
	}
    
    [self updateAnnotationViews];
}

- (void)removeAnnotations:(NSArray *)a
{
    for (id<SMSWebViewAnnotation> thisAnnotation in a) {
        UIButton *annotationView = (UIButton *)[annotationViews objectForKey:thisAnnotation];
        [annotationView removeFromSuperview];
        [annotationViews removeObjectForKey:thisAnnotation];
    }
    
	[annotations removeObjectsInArray:a];
}

- (void)selectAnnotation:(UIButton *)sender
{
	id a = [annotations objectAtIndex:sender.tag];
	if ([self.delegate respondsToSelector:@selector(webView:didSelectAnnotation:)])
		[(id<SMSWebViewDelegate>)self.delegate webView:self didSelectAnnotation:a];
}

- (void)setAnnotationsHidden:(BOOL)yesOrNo
{
    annotationsHidden = yesOrNo;
    
    for (id<SMSWebViewAnnotation> thisAnnotation in annotations) {
		UIButton *annotationView = [annotationViews objectForKey:thisAnnotation];
        annotationView.hidden = yesOrNo;
	}
}

#pragma mark - UIScrollView delegate

- (void)scrollViewDidScroll:(UIScrollView *)sv
{
    if ([super respondsToSelector:@selector(scrollViewDidScroll:)])
        [super scrollViewDidScroll:sv];
    
	if ([self.delegate respondsToSelector:@selector(webViewDidScroll:)])
		[(id<SMSWebViewDelegate>)self.delegate webViewDidScroll:self];
    
    [self updateAnnotationViews];
}

- (void)scrollViewDidZoom:(UIScrollView *)sv
{
	if ([super respondsToSelector:@selector(scrollViewDidZoom:)])
        [super scrollViewDidZoom:sv];
	
	if ([self.delegate respondsToSelector:@selector(webViewDidZoom:)])
		[(id<SMSWebViewDelegate>)self.delegate webViewDidZoom:self];
    
    [self updateAnnotationViews];
}

- (void)scrollViewDidEndZooming:(UIScrollView *)sv withView:(UIView *)view atScale:(float)scale
{
    if ([super respondsToSelector:@selector(scrollViewDidEndZooming:withView:atScale:)])
        [super scrollViewDidEndZooming:sv withView:view atScale:scale];
    
    if ([self.delegate respondsToSelector:@selector(webViewDidZoom:)])
        [(id<SMSWebViewDelegate>)self.delegate webViewDidZoom:self];
    
    [self updateAnnotationViews];
}

@end