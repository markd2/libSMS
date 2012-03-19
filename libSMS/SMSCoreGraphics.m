/*
 SMSCoreGraphics.m
 
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

#import "SMSCoreGraphics.h"

CGRect SMSCGAspectFittedRect(CGRect inRect, CGRect maxRect)
{
    float originalAspectRatio = inRect.size.width / inRect.size.height;
	float maxAspectRatio = maxRect.size.width / maxRect.size.height;
    
	CGRect newRect = maxRect;
	if (originalAspectRatio > maxAspectRatio) {
		newRect.size.height = maxRect.size.width * inRect.size.height / inRect.size.width;
		newRect.origin.y += (maxRect.size.height - newRect.size.height)/2.0;
	} else {
		newRect.size.width = maxRect.size.height  * inRect.size.width / inRect.size.height;
		newRect.origin.x += (maxRect.size.width - newRect.size.width)/2.0;
	}
    
	return CGRectIntegral(newRect);
}

void SMSCGContextAddRoundedRectangle(CGContextRef gctx, CGRect rect, CGFloat cornerRadius, BOOL topOnly)
{
	CGContextBeginPath(gctx);
	CGContextMoveToPoint(gctx, rect.origin.x+cornerRadius, rect.origin.y);
	CGContextAddArcToPoint(gctx, rect.origin.x+rect.size.width, rect.origin.y, rect.origin.x+rect.size.width, rect.origin.y+1, cornerRadius);
	if (topOnly) {
		CGContextAddLineToPoint(gctx, rect.origin.x+rect.size.width, rect.origin.y+rect.size.height);
		CGContextAddLineToPoint(gctx, rect.origin.x, rect.origin.y+rect.size.height);
	} else {
		CGContextAddArcToPoint(gctx, rect.origin.x+rect.size.width, rect.origin.y+rect.size.height, rect.origin.x+rect.size.width-1, rect.origin.y+rect.size.height, cornerRadius);
		CGContextAddArcToPoint(gctx, rect.origin.x, rect.origin.y+rect.size.height, rect.origin.x, rect.origin.y+rect.size.height-1, cornerRadius);
	}
	CGContextAddArcToPoint(gctx, rect.origin.x, rect.origin.y, rect.origin.x+1, rect.origin.y, cornerRadius);
}

CGMutablePathRef SMSCGPathCreateRoundedRectangle(CGRect rect, CGFloat cornerRadius, BOOL topOnly)
{
    CGMutablePathRef path = CGPathCreateMutable();
    SMSCGPathAddRoundedRectangle(path, rect, cornerRadius, topOnly);
    return path;
}

void SMSCGPathAddRoundedRectangle(CGMutablePathRef path, CGRect rect, CGFloat cornerRadius, BOOL topOnly)
{
    CGPathMoveToPoint(path, NULL, rect.origin.x+cornerRadius, rect.origin.y);
    CGPathAddArcToPoint(path, NULL, rect.origin.x+rect.size.width, rect.origin.y, rect.origin.x+rect.size.width, rect.origin.y+1, cornerRadius);
    if (topOnly) {
        CGPathAddLineToPoint(path, NULL, rect.origin.x+rect.size.width, rect.origin.y+rect.size.height);
        CGPathAddLineToPoint(path, NULL, rect.origin.x, rect.origin.y+rect.size.height);
    } else {
        CGPathAddArcToPoint(path, NULL, rect.origin.x+rect.size.width, rect.origin.y+rect.size.height, rect.origin.x+rect.size.width-1, rect.origin.y+rect.size.height, cornerRadius);
        CGPathAddArcToPoint(path, NULL, rect.origin.x, rect.origin.y+rect.size.height, rect.origin.x, rect.origin.y+rect.size.height-1, cornerRadius);
    }
    CGPathAddArcToPoint(path, NULL, rect.origin.x, rect.origin.y, rect.origin.x+1, rect.origin.y, cornerRadius);    
}