/*
 SMSDrawingView.h
 
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

#import <UIKit/UIKit.h>


typedef enum SMSSegmentType {
	SMSSegmentTypeDot = 1,
	SMSSegmentTypeLine,
    SMSSegmentTypeArrow
} SMSSegmentType;


@interface SMSPoint : NSObject <NSCoding> {
	CGFloat x;
	CGFloat y;
    
    NSTimeInterval timestamp;
}
@property (nonatomic) CGFloat x;
@property (nonatomic) CGFloat y;

@property (nonatomic) NSTimeInterval timestamp;

@end


@interface SMSLineSegment : NSObject <NSCoding> {
	CGFloat canvasWidth;
	CGFloat canvasHeight;
	
	CGFloat width;
	UIColor *color;
	
	SMSSegmentType segmentType;
	NSMutableArray *points;
}
@property (nonatomic) CGFloat canvasWidth;
@property (nonatomic) CGFloat canvasHeight;

@property (nonatomic) CGFloat width;
@property (nonatomic, strong) UIColor *color;

@property (nonatomic) SMSSegmentType segmentType;
@property (nonatomic, strong) NSMutableArray *points;

@end


@interface SMSDrawingView : UIView {
    SMSSegmentType segmentType;
	CGFloat lineWidth;
	UIColor *lineColor;
	CGFloat opacity;
	
	NSMutableArray *lineSegments;
	SMSLineSegment *currentLineSegment;

	UIBarButtonItem *lineWidthBarButtonItem;
	UISlider *lineWidthSlider;
	
	UIBarButtonItem *lineColorBarButtonItem;
	unsigned char *colorsBuffer;
	
	UIBarButtonItem *alphaBarButtonItem;
	UISlider *alphaSlider;
	
	UIBarButtonItem *undoBarButtonItem;
}
@property (nonatomic, weak) id delegate;

@property (nonatomic) SMSSegmentType segmentType;
@property (nonatomic) CGFloat lineWidth;
@property (nonatomic, strong) UIColor *lineColor;

@property (nonatomic, strong) NSMutableArray *lineSegments;

- (UIBarButtonItem *)lineWidthBarButtonItem;
- (UIBarButtonItem *)lineColorBarButtonItem;
- (UIBarButtonItem *)alphaBarButtonItem;
- (UIBarButtonItem *)undoBarButtonItem;
- (void)undoLastSegment;

- (void)drawIntoContext:(CGContextRef)ctx size:(CGSize)aSize;

@end


@protocol SMSDrawingViewDelegate

- (void)drawingView:(SMSDrawingView *)aDrawingView didAddLineSegment:(SMSLineSegment *)aLineSegment;
- (void)drawingViewDidClearAllSegments:(SMSDrawingView *)aDrawingView;

@end