/*
 SMSAlertView.m
 
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

#import "SMSAlertView.h"
#import "SMSCoreGraphics.h"

static UIColor *SMSDefaultAlertColor = nil;
static UIColor *SMSErrorAlertColor = nil;
static UIImage *SMSAlertBackgroundImage = nil;

@implementation SMSAlertView

@synthesize alertStyle, userInfo;

+ (void)setColor:(UIColor *)c forStyle:(SMSAlertViewStyle)s
{
    if (s == SMSAlertViewStyleDefault) 
        SMSDefaultAlertColor = c;
    else
        SMSErrorAlertColor = c;
}

+ (void)setBackgroundImage:(UIImage *)img
{
    SMSAlertBackgroundImage = img;
}

+ (void)errorWithMessage:(NSString *)msg
{
	SMSAlertView *alert = [[SMSAlertView alloc] initWithTitle:@"Error"
                                                      message:msg
                                                     delegate:nil
                                            cancelButtonTitle:@"Dismiss" 
                                            otherButtonTitles:nil];
    alert.alertStyle = SMSAlertViewStyleError;
	[alert show];
}

- (void)drawRect:(CGRect)rect
{
    UIColor *color = nil;
    if (alertStyle == SMSAlertViewStyleDefault)
        color = SMSDefaultAlertColor;
    else
        color = SMSErrorAlertColor;
    if (!color) {
        [super drawRect:rect];
        return;
    }
    
    CGMutablePathRef outline = SMSCGPathCreateRoundedRectangle(CGRectInset(self.bounds, 4, 4), 10, NO);
    
    CGContextRef gctx = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(gctx);
    CGContextSetShadow(gctx, CGSizeMake(0.5, -2), 5);
    
    CGContextAddPath(gctx, outline);
    [color setFill];
    CGContextFillPath(gctx);
    CGContextRestoreGState(gctx);
    
    if (SMSAlertBackgroundImage) {
        CGRect b = self.bounds;
        CGRect f = CGRectMake((b.size.width-SMSAlertBackgroundImage.size.width)/2.0, (b.size.height-SMSAlertBackgroundImage.size.height)/2.0, SMSAlertBackgroundImage.size.width, SMSAlertBackgroundImage.size.height);
        [SMSAlertBackgroundImage drawInRect:f];
    }
    
    CGContextAddPath(gctx, outline);
    CGContextClip(gctx);
    
    CGContextAddEllipseInRect(gctx, CGRectMake(-20, -25, 320, 50));
    [[UIColor colorWithWhite:1.0 alpha:0.2] setFill];
    CGContextFillPath(gctx);
    
    CGPathRelease(outline);
}

- (void)layoutSubviews
{
	[super layoutSubviews];
    
	for (UIView *thisView in self.subviews) {
        if ([thisView isKindOfClass:[UIImageView class]] && CGRectEqualToRect(self.bounds, thisView.frame))
            thisView.hidden = YES;
    }
}

@end