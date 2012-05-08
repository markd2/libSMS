/*
 SMSDrawingView.m
 
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

#import "SMSDrawingView.h"
#import "UIImage+SMS.h"


@implementation SMSPoint

@synthesize x, y;
@synthesize timestamp;

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    
    x = [coder decodeFloatForKey:@"x"];
    y = [coder decodeFloatForKey:@"y"];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeFloat:x forKey:@"x"];
    [coder encodeFloat:y forKey:@"y"];
}

@end


@implementation SMSLineSegment

@synthesize canvasWidth, canvasHeight;
@synthesize width, color;
@synthesize segmentType, points;

- (id)init
{
	self = [super init];
	points = [[NSMutableArray alloc] init];
	return self;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    
    canvasWidth = [coder decodeFloatForKey:@"canvasWidth"];
    canvasHeight = [coder decodeFloatForKey:@"canvasHeight"];
    
    width = [coder decodeFloatForKey:@"width"];
    color = [coder decodeObjectForKey:@"color"];
    
    segmentType = [coder decodeIntForKey:@"segmentType"];
    points = [coder decodeObjectForKey:@"points"];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeFloat:canvasWidth forKey:@"canvasWidth"];
    [coder encodeFloat:canvasHeight forKey:@"canvasHeight"];
    
    [coder encodeFloat:width forKey:@"width"];
    [coder encodeObject:color forKey:@"color"];
    
    [coder encodeInt:segmentType forKey:@"segmentType"];
    [coder encodeObject:points forKey:@"points"];
}

@end


@implementation SMSDrawingView

@synthesize delegate;
@synthesize segmentType, lineWidth, lineColor;
@synthesize lineSegments;

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        lineWidth = 5.0;
        lineColor = [UIColor blackColor];
        opacity = 1.0;
        
        lineSegments = [[NSMutableArray alloc] init];
    }
	
	return self;
}

- (void)dealloc
{
	free(colorsBuffer);
}

#pragma mark - Setters

- (void)setLineWidth:(CGFloat)w
{
	lineWidth = w;
	lineWidthSlider.value = lineWidth;
}

- (void)setLineColor:(UIColor *)aColor
{
	lineColor = aColor;
	
	CGColorRef color = [lineColor CGColor];
	opacity = CGColorGetAlpha(color);
	alphaSlider.value = opacity;
}

- (void)setLineSegments:(NSMutableArray *)segments
{
    lineSegments = segments;
    [self setNeedsDisplay];
}

#pragma mark - Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	CGPoint p = [touch locationInView:self];

	currentLineSegment = [[SMSLineSegment alloc] init];
	currentLineSegment.canvasWidth = self.bounds.size.width;
	currentLineSegment.canvasHeight = self.bounds.size.height;
	currentLineSegment.width = lineWidth;
	currentLineSegment.color = lineColor;
	currentLineSegment.segmentType = SMSSegmentTypeDot;
	
	SMSPoint *newPoint = [[SMSPoint alloc] init];
	newPoint.x = p.x;
	newPoint.y = p.y;
    newPoint.timestamp = touch.timestamp;
	[currentLineSegment.points addObject:newPoint];
    
    if (segmentType == SMSSegmentTypeArrow) {
        currentLineSegment.segmentType = SMSSegmentTypeArrow;
        [currentLineSegment.points addObject:newPoint];
    } else
        currentLineSegment.segmentType = SMSSegmentTypeDot;
	
	[lineSegments addObject:currentLineSegment];

	[self setNeedsDisplay];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
    SMSPoint *lastPoint = [currentLineSegment.points lastObject];
	if (touch.timestamp-lastPoint.timestamp > 0.03) {
        CGPoint p = [touch locationInView:self];
        
        currentLineSegment.segmentType = SMSSegmentTypeLine;
        
        SMSPoint *newPoint = [[SMSPoint alloc] init];
        newPoint.x = p.x;
        newPoint.y = p.y;
        newPoint.timestamp = touch.timestamp;
        
        if (currentLineSegment.segmentType != SMSSegmentTypeArrow) {
            currentLineSegment.segmentType = SMSSegmentTypeLine;
            [currentLineSegment.points addObject:newPoint];
        } else
            [currentLineSegment.points replaceObjectAtIndex:1 withObject:newPoint];
        
        [self setNeedsDisplay];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	undoBarButtonItem.enabled = YES;
	
	if ([delegate respondsToSelector:@selector(drawingView:didAddLineSegment:)])
		[delegate drawingView:self didAddLineSegment:currentLineSegment];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self touchesEnded:touches withEvent:event];
}

#pragma mark - Bar Button Items

- (UIBarButtonItem *)lineWidthBarButtonItem
{
	if (lineWidthBarButtonItem == nil) {
		UIImageView *background = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 68, 30)];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            background.frame = CGRectMake(0, 0, 102, 43);
		background.contentMode = UIViewContentModeCenter;
		background.userInteractionEnabled = YES;
		background.image = [UIImage smsImageNamed:@"SMSLineSlider" scale:SMSImageScaleDefault];
		
		lineWidthSlider = [[UISlider alloc] initWithFrame:CGRectMake(7, 4, 56, 23)];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            lineWidthSlider.frame = CGRectMake(9, 5, 86, 34);
		[lineWidthSlider addTarget:self action:@selector(setWidth:) forControlEvents:UIControlEventValueChanged];
		lineWidthSlider.continuous = NO;
		lineWidthSlider.minimumValue = 1.0;
		lineWidthSlider.maximumValue = 10.0;
		lineWidthSlider.value = 5.0;
		
		UIImage *sliderThumb = [UIImage smsImageNamed:@"SMSSliderThumb" scale:SMSImageScaleDefault];
		[lineWidthSlider setThumbImage:sliderThumb forState:UIControlStateNormal];
		[lineWidthSlider setThumbImage:sliderThumb forState:UIControlStateHighlighted];
		
		UIImage *oneBlankPixel = [UIImage smsImageNamed:@"1-blank-px" scale:SMSImageScaleDefault];
		[lineWidthSlider setMinimumTrackImage:oneBlankPixel forState:UIControlStateNormal];
		[lineWidthSlider setMaximumTrackImage:oneBlankPixel forState:UIControlStateNormal];
		
		[background addSubview:lineWidthSlider];
		lineWidthBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:background];
	}
	
	return lineWidthBarButtonItem;
}

- (void)setWidth:(UISlider *)sender
{
	lineWidth = sender.value;
}

- (UIBarButtonItem *)lineColorBarButtonItem
{
	if (lineColorBarButtonItem == nil) {
        UIImage *cp = [UIImage smsImageNamed:@"SMSColorPalette" scale:SMSImageScaleDefault];
		CGImageRef colorPalette = [cp CGImage];
		CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
		int w = CGImageGetWidth(colorPalette);
		int comps = CGImageGetBitsPerPixel(colorPalette) / CGImageGetBitsPerComponent(colorPalette);
        colorsBuffer = (unsigned char *)calloc(w, comps);
		CGContextRef ctx = CGBitmapContextCreate(colorsBuffer, w, 1, 8, w * comps, space, kCGImageAlphaPremultipliedLast);
		CGContextDrawImage(ctx, CGRectMake(0, 0, w, 1), colorPalette);
		CGColorSpaceRelease(space);
		CGContextRelease(ctx);
		
		UIImageView *background = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 117, 30)];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            background.frame = CGRectMake(0, 0, 176, 43);
		background.contentMode = UIViewContentModeCenter;
		background.userInteractionEnabled = YES;
		background.image = [UIImage smsImageNamed:@"SMSColorSlider" scale:SMSImageScaleDefault];
		
		UISlider *colorSlider = [[UISlider alloc] initWithFrame:CGRectMake(9, 4, 100, 23)];
		colorSlider.maximumValue = 90.0;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            colorSlider.frame = CGRectMake(14, 5, 149, 34);
            colorSlider.maximumValue = 138;
        }
		[colorSlider addTarget:self action:@selector(setColor:) forControlEvents:UIControlEventValueChanged];
		colorSlider.continuous = NO;
        colorSlider.minimumValue = 4.0;
		colorSlider.value = 4.0;
		
		UIImage *sliderThumb = [UIImage smsImageNamed:@"SMSSliderThumb" scale:SMSImageScaleDefault];
		[colorSlider setThumbImage:sliderThumb forState:UIControlStateNormal];
		[colorSlider setThumbImage:sliderThumb forState:UIControlStateHighlighted];
		
		UIImage *oneBlankPixel = [UIImage smsImageNamed:@"1-blank-px" scale:SMSImageScaleDefault];
		[colorSlider setMinimumTrackImage:oneBlankPixel forState:UIControlStateNormal];
		[colorSlider setMaximumTrackImage:oneBlankPixel forState:UIControlStateNormal];
		
		[background addSubview:colorSlider];
		lineColorBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:background];
	}

	return lineColorBarButtonItem;
}

- (void)setColor:(UISlider *)sender
{
	int index = ((int)sender.value)*4;
	unsigned char *r = colorsBuffer+index;
	unsigned char *g = r+1;
	unsigned char *b = g+1;
	
	self.lineColor = [UIColor colorWithRed:*r/255.0 green:*g/255.0 blue:*b/255.0 alpha:opacity];
}

- (UIBarButtonItem *)alphaBarButtonItem
{
	if (alphaBarButtonItem == nil) {
		UIImageView *background = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 68, 30)];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            background.frame = CGRectMake(0, 0, 102, 43);
		background.contentMode = UIViewContentModeCenter;
		background.userInteractionEnabled = YES;
		background.image = [UIImage smsImageNamed:@"SMSAlphaSlider" scale:SMSImageScaleDefault];
		
		alphaSlider = [[UISlider alloc] initWithFrame:CGRectMake(7, 4, 56, 23)];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            alphaSlider.frame = CGRectMake(9, 5, 86, 34);
		[alphaSlider addTarget:self action:@selector(setOpacity:) forControlEvents:UIControlEventValueChanged];
		alphaSlider.continuous = NO;
		alphaSlider.minimumValue = 0.1;
		alphaSlider.maximumValue = 1.0;
		alphaSlider.value = opacity;
		
		UIImage *sliderThumb = [UIImage smsImageNamed:@"SMSSliderThumb" scale:SMSImageScaleDefault];
		[alphaSlider setThumbImage:sliderThumb forState:UIControlStateNormal];
		[alphaSlider setThumbImage:sliderThumb forState:UIControlStateHighlighted];
		
		UIImage *oneBlankPixel = [UIImage smsImageNamed:@"1-blank-px" scale:SMSImageScaleDefault];
		[alphaSlider setMinimumTrackImage:oneBlankPixel forState:UIControlStateNormal];
		[alphaSlider setMaximumTrackImage:oneBlankPixel forState:UIControlStateNormal];

		[background addSubview:alphaSlider];
		alphaBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:background];
	}
	
	return alphaBarButtonItem;
}

- (void)setOpacity:(UISlider *)sender
{
	opacity = sender.value;
	lineColor = [lineColor colorWithAlphaComponent:opacity];
}

- (UIBarButtonItem *)undoBarButtonItem
{
	if (undoBarButtonItem == nil) {
		UIImage *undoImage = [UIImage smsImageNamed:@"SMSUndo" scale:SMSImageScaleDefault];
		undoBarButtonItem = [[UIBarButtonItem alloc] initWithImage:undoImage style:UIBarButtonItemStylePlain target:self action:@selector(undoLastSegment)];
	}
	
	undoBarButtonItem.enabled = ([lineSegments count] > 0);
	return undoBarButtonItem;
}

- (void)undoLastSegment
{
    if ([lineSegments count] == 0)
        return;
    
	[lineSegments removeLastObject];
	[self setNeedsDisplay];
	
	if ([lineSegments count] == 0) {
		undoBarButtonItem.enabled = NO;
		if ([delegate respondsToSelector:@selector(drawingViewDidClearAllSegments:)])
			[delegate drawingViewDidClearAllSegments:self];
	}
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect
{
	CGContextRef gctx = UIGraphicsGetCurrentContext();
	[self drawIntoContext:gctx size:self.bounds.size];
}

- (void)drawIntoContext:(CGContextRef)gctx size:(CGSize)aSize
{
    for (SMSLineSegment *thisSegment in lineSegments) {
		CGFloat xRatio = aSize.width / thisSegment.canvasWidth;
		CGFloat yRatio = aSize.height / thisSegment.canvasHeight;
		
		if (thisSegment.segmentType == SMSSegmentTypeDot) {
			SMSPoint *onlyPoint = [thisSegment.points objectAtIndex:0];
			[thisSegment.color setFill];
			CGContextFillEllipseInRect(gctx, CGRectMake(onlyPoint.x*xRatio-thisSegment.width/2.0, onlyPoint.y*yRatio-thisSegment.width/2.0, thisSegment.width, thisSegment.width));
		} else if (thisSegment.segmentType == SMSSegmentTypeLine) {
			SMSPoint *firstPoint = [thisSegment.points objectAtIndex:0];
			CGContextMoveToPoint(gctx, firstPoint.x*xRatio, firstPoint.y*yRatio);
			for (int i=1; i<[thisSegment.points count]; i++) {
				SMSPoint *thisPoint = [thisSegment.points objectAtIndex:i];
				CGContextAddLineToPoint(gctx, thisPoint.x*xRatio, thisPoint.y*yRatio);
			}
			
			[thisSegment.color setStroke];
			CGContextSetLineWidth(gctx, thisSegment.width*(xRatio+yRatio)/2.0);
			CGContextStrokePath(gctx);
		} else {
            CGContextSaveGState(gctx);
            CGContextSetShadow(gctx, CGSizeMake(0, 2), 3.0);
            
            SMSPoint *tp = [thisSegment.points objectAtIndex:0];
            CGPoint tailPoint = CGPointMake(tp.x*xRatio, tp.y*yRatio);
            CGContextMoveToPoint(gctx, tailPoint.x, tailPoint.y);
            
            SMSPoint *hp = [thisSegment.points objectAtIndex:1];
            CGPoint headPoint = CGPointMake(hp.x*xRatio, hp.y*yRatio);
            CGContextAddLineToPoint(gctx, headPoint.x, headPoint.y);
            
            [thisSegment.color setStroke];
			CGContextSetLineWidth(gctx, thisSegment.width*1.5*(xRatio+yRatio)/2.0);
			CGContextStrokePath(gctx);
            
            CGContextMoveToPoint(gctx, headPoint.x, headPoint.y);
            
            CGFloat dx = headPoint.x-tailPoint.x;
            if (dx == 0.0f) {
                CGFloat lw_x = thisSegment.width*3*xRatio;
                CGFloat lw_y = thisSegment.width*3*yRatio;
                
                CGContextAddLineToPoint(gctx, headPoint.x-lw_x, headPoint.y);
                if (headPoint.y <= tailPoint.y)
                    CGContextAddLineToPoint(gctx, headPoint.x, headPoint.y-(lw_y*2));
                else
                    CGContextAddLineToPoint(gctx, headPoint.x, headPoint.y+(lw_y*2));
                CGContextAddLineToPoint(gctx, headPoint.x+lw_x, headPoint.y);
            } else {
                CGFloat dy_dx = (headPoint.y-tailPoint.y)/dx;
                if (dy_dx == 0.0f) {
                    CGFloat lw_x = thisSegment.width*3*xRatio;
                    CGFloat lw_y = thisSegment.width*3*yRatio;
                    
                    CGContextAddLineToPoint(gctx, headPoint.x, headPoint.y-lw_y);
                    if (headPoint.x >= tailPoint.x)
                        CGContextAddLineToPoint(gctx, headPoint.x+(lw_x*2), headPoint.y);
                    else
                        CGContextAddLineToPoint(gctx, headPoint.x-(lw_x*2), headPoint.y);
                    CGContextAddLineToPoint(gctx, headPoint.x, headPoint.y+lw_y);
                } else {
                    CGFloat lw = thisSegment.width*3*(xRatio+yRatio)/2.0;
                    
                    CGFloat perpendicular = powf(dy_dx, -1) * -1;
                    dx = sqrtf(powf(lw, 2)/(1+powf(perpendicular, 2)));
                    CGContextAddLineToPoint(gctx, headPoint.x-dx, headPoint.y+(-1*perpendicular*dx));
                    
                    CGFloat dx2 = sqrtf(powf(lw*2, 2)/(1+powf(dy_dx, 2)));
                    if (headPoint.x >= tailPoint.x)
                        CGContextAddLineToPoint(gctx, headPoint.x+dx2, headPoint.y+dy_dx*dx2);
                    else
                        CGContextAddLineToPoint(gctx, headPoint.x-dx2, headPoint.y-dy_dx*dx2);
                    
                    CGContextAddLineToPoint(gctx, headPoint.x+dx, headPoint.y+perpendicular*dx);
                }
            }
            
            CGContextClosePath(gctx);
            [thisSegment.color setFill];
			CGContextFillPath(gctx);
            
            CGContextRestoreGState(gctx);
        }
	}
}

@end