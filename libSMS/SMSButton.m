/*
 SMSButton.m
 
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

#import "SMSButton.h"
#import "SMSCoreGraphics.h"

@implementation SMSBadgeView

@synthesize badgeValue, fontSize;

- (void)drawRect:(CGRect)rect
{
	CGRect bounds = self.bounds;
	bounds.origin.x = 2;
	bounds.size.width -= 3;
	bounds.origin.y = 2;
	bounds.size.height = fontSize+6;
	
	CGContextRef gctx = UIGraphicsGetCurrentContext();
	
	CGMutablePathRef outline = SMSCGPathCreateRoundedRectangle(bounds, bounds.size.height/2.0, NO);
	
	CGContextSaveGState(gctx);
	CGContextSetShadow(gctx, CGSizeMake(0.5, 2.5), 3);

	CGContextAddPath(gctx, outline);
	[[UIColor colorWithRed:0.9 green:0.0 blue:0.0 alpha:1.0] setFill];
	CGContextFillPath(gctx);
	CGContextRestoreGState(gctx);

	CGContextAddPath(gctx, outline);
	[[UIColor colorWithWhite:1.0 alpha:0.9] setStroke];
	CGContextSetLineWidth(gctx, 2.0);
	CGContextStrokePath(gctx);
	
	CGContextAddPath(gctx, outline);
	CGContextClip(gctx);
	CGContextAddEllipseInRect(gctx, CGRectMake(-4, -6, bounds.size.width+10, fontSize));
	[[UIColor colorWithWhite:1.0 alpha:0.3] setFill];
	CGContextFillPath(gctx);
	
	[[UIColor whiteColor] setFill];
	bounds.origin.y = 3;
	[badgeValue drawInRect:bounds withFont:[UIFont boldSystemFontOfSize:fontSize] lineBreakMode:UILineBreakModeTailTruncation alignment:UITextAlignmentCenter];
	
	CGPathRelease(outline);
}

@end


@implementation SMSButton

@synthesize badgeOffset, badgeValue, fontSize;

- (void)setBadgeValue:(NSString *)value
{
	badgeValue = value;
	
	if (badgeValue) {
		if (!badgeView) {
			badgeView = [[SMSBadgeView alloc] initWithFrame:CGRectZero];
			badgeView.backgroundColor = [UIColor clearColor];
			[self addSubview:badgeView];
		}
		
        if (fontSize <= 0) fontSize = 18;
		CGSize s = [badgeValue sizeWithFont:[UIFont boldSystemFontOfSize:fontSize]];
		CGFloat width = s.width+10;
		badgeView.bounds = CGRectMake(0, 0, width < fontSize+6 ? fontSize+11 : width+5, fontSize+11);
		badgeView.center = CGPointMake(self.bounds.size.width+badgeOffset.x, badgeOffset.y);
		
		badgeView.badgeValue = badgeValue;
        badgeView.fontSize = fontSize;
        [badgeView setNeedsDisplay];
	} else if (badgeView) {
		[badgeView removeFromSuperview];
		badgeView = nil;
	}
}

@end