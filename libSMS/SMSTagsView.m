/*
 SMSTagsView.m
 
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

#import "SMSTagsView.h"

@implementation SMSTagsView

@synthesize tagPadding, tagHeight, addButton;
@synthesize delegate;
@synthesize tags, enabled;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        tagPadding = 5;
        tagHeight = 42;
        
        tags = [NSArray array];
        enabled = YES;
    }
    return self;
}

- (void)setAddButton:(UIButton *)b
{
    [addButton removeFromSuperview];
    addButton = b;
    [self addSubview:b];
}

- (void)setEnabled:(BOOL)yesOrNo
{
    enabled = yesOrNo;
    
    for (UIControl *thisTag in tags) {
        thisTag.enabled = enabled;
        thisTag.selected = NO;
    }
    
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         addButton.alpha = (enabled ? 1.0 : 0.0);
                     }
                     completion:nil];
}

- (void)setTags:(NSArray *)t
{
    [self setTags:t animated:NO];
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGFloat w = size.width;
    
    CGFloat x = 0;
    CGFloat y = 0;
    CGRect f;
    
    for (UIControl *thisTag in tags) {
        f = thisTag.bounds;
        if (x + f.size.width > w) {
            x = 0;
            y += tagHeight+tagPadding;
        }
        
        f.origin.x = x;
        f.origin.y = y;
        thisTag.frame = f;
        
        x += f.size.width+tagPadding;
    }
    
    f = addButton.bounds;
    f.origin.x = w-f.size.width;
    f.origin.y = y;
    if (f.origin.x < x) {
        f.origin.y += tagHeight+tagPadding;
        if (self.enabled)
            y = f.origin.y;
    }
    addButton.frame = f;
    
    return CGSizeMake(w, y+tagHeight);
}

- (void)setTags:(NSArray *)t animated:(BOOL)animated
{
    for (UIControl *thisTag in tags) {
        if (![t containsObject:thisTag])
            [thisTag removeFromSuperview];
    }
    
    tags = t;
    
    for (UIControl *thisTag in tags) {
        if (thisTag.superview != self) {
            if (animated)
                thisTag.alpha = 0.0;
            [self addSubview:thisTag];
            
            [thisTag removeTarget:self action:@selector(_selectTag:) forControlEvents:UIControlEventTouchUpInside];
            [thisTag addTarget:self action:@selector(_selectTag:) forControlEvents:UIControlEventTouchUpInside];
        }
        
        thisTag.enabled = enabled;
    }
    
    if (animated) {
        [UIView animateWithDuration:0.5
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             [self sizeToFit];
                         }
                         completion:^(BOOL finished) {
                             [UIView animateWithDuration:0.3
                                                   delay:0.0
                                                 options:UIViewAnimationOptionCurveEaseInOut
                                              animations:^{
                                                  for (UIControl *thisTag in tags) {
                                                      thisTag.alpha = 1.0;
                                                  }
                                              }
                                              completion:nil];
                         }];
        
    } else
        [self sizeToFit];
}

- (void)_selectTag:(UIControl *)tag
{
    if (tag.selected) {
        tag.selected = NO;
        if ([delegate respondsToSelector:@selector(tagsView:didDeselectTag:)])
            [delegate tagsView:self didDeselectTag:tag];
    } else {
        for (UIControl *thisTag in tags) {
            if (thisTag.selected) {
                thisTag.selected = NO;
                if ([delegate respondsToSelector:@selector(tagsView:didDeselectTag:)])
                    [delegate tagsView:self didDeselectTag:thisTag];
            }
        }
        
        tag.selected = YES;
        if ([delegate respondsToSelector:@selector(tagsView:didSelectTag:)])
            [delegate tagsView:self didSelectTag:tag];
    }
}

@end