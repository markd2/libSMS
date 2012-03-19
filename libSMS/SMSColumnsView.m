/*
 SMSColumnsView.m
 
 Copyright (c) 2012, Alex Silverman
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
#import "SMSColumnsView.h"

@implementation SMSColumnsView

@synthesize dataSource;
@synthesize borderMargin, columnPadding, sectionPadding;
@synthesize autoLayoutEnabled;

- (id<SMSColumnsViewDelegate>)delegate
{
    return (id<SMSColumnsViewDelegate>)[super delegate];
}

- (void)setDelegate:(id<SMSColumnsViewDelegate>)d
{
    [super setDelegate:d];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.showsHorizontalScrollIndicator = NO;
        
        borderMargin = 20;
        columnPadding = 20;
        sectionPadding = 10;
        
        autoLayoutEnabled = YES;
        
        _columns = [[NSMutableArray alloc] init];
        _sections = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)_reloadOrLayout
{
    if (_numberOfColumns == 0)
        [self reloadSections:NO];
    else
        [self layoutColumns:NO];
}

- (void)setBounds:(CGRect)b
{
    if (self.superview && !CGSizeEqualToSize(self.bounds.size, b.size) && b.size.width > 0.0 && b.size.height > 0.0) {
        [super setBounds:b];
        [self _reloadOrLayout];
    } else
        [super setBounds:b];
}

- (void)setFrame:(CGRect)f
{
    if (self.superview && !CGSizeEqualToSize(self.frame.size, f.size) && f.size.width > 0.0 && f.size.height > 0.0) {
        [super setFrame:f];
        [self _reloadOrLayout];
    } else
        [super setFrame:f];
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    CGRect f = self.bounds;
    if (newSuperview && f.size.width > 0.0 && f.size.height > 0.0)
        [self _reloadOrLayout];
}

- (void)setAutoLayoutEnabled:(BOOL)yesOrNo
{
    autoLayoutEnabled = yesOrNo;
    [self reloadSections:NO];
}

- (void)reloadSections:(BOOL)animated
{
    [_columns removeAllObjects];
    
    NSMutableArray *newSections = [NSMutableArray array];
    
    if (autoLayoutEnabled) {
        _numberOfSections = [dataSource numberOfSectionsInColumnsView:self];
        
        for (int i=0; i<_numberOfSections; i++) {
            UIView *thisSection = [dataSource columnsView:self viewForSectionAtIndex:i];
            if (animated && ![_sections containsObject:thisSection])
                thisSection.alpha = 0.0;
            if (!thisSection.superview)
                [self addSubview:thisSection];
            [newSections addObject:thisSection];
        }
    } else {
        if ([dataSource respondsToSelector:@selector(numberOfColumnsInColumnsView:)])
            _numberOfColumns = [dataSource numberOfColumnsInColumnsView:self];
        else
            _numberOfColumns = 1;
        
        for (int i=0; i<_numberOfColumns; i++) {
            NSMutableArray *thisColumn = [NSMutableArray array];
            for (int j=0; j<[dataSource columnsView:self numberOfSectionsInColumn:i]; j++) {
                UIView *thisSection = [dataSource columnsView:self viewForSectionAtIndexPath:[NSIndexPath indexPathForRow:j inSection:i]];
                if (animated && ![_sections containsObject:thisSection])
                    thisSection.alpha = 0.0;
                if (!thisSection.superview)
                    [self addSubview:thisSection];
                [thisColumn addObject:thisSection];
                [newSections addObject:thisSection];
            }
            [_columns addObject:thisColumn];
        }
    }
    
    NSMutableArray *removedSections = [NSMutableArray array];
    for (UIView *thisSection in _sections) {
        if (![newSections containsObject:thisSection])
            [removedSections addObject:thisSection];
    }
    
    if (animated) {
        [UIView animateWithDuration:([removedSections count] > 0 ? 0.1 : 0.0)
                              delay:0
                            options:UIViewAnimationCurveEaseInOut
                         animations:^{
                             for (UIView *thisSection in removedSections)
                                 thisSection.alpha = 0.0;
                         }
                         completion:^(BOOL finished) {
                             for (UIView *thisView in removedSections)
                                 [thisView removeFromSuperview];
                             _sections = newSections;
                             
                             [self layoutColumns:YES];
                             
                             [UIView animateWithDuration:0.1
                                                   delay:0.3
                                                 options:UIViewAnimationCurveEaseInOut
                                              animations:^{
                                                  for (UIView *thisSection in _sections)
                                                      thisSection.alpha = 1.0;
                                              }
                                              completion:nil];
                         }];
    } else {
        for (UIView *thisView in removedSections)
            [thisView removeFromSuperview];
        _sections = newSections;
        [self layoutColumns:NO];
    }
}

- (void)layoutColumns:(BOOL)animated
{
    if (animated) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0.3];
    }
    
    if (autoLayoutEnabled) {
        if ([dataSource respondsToSelector:@selector(numberOfColumnsInColumnsView:)])
            _numberOfColumns = [dataSource numberOfColumnsInColumnsView:self];
        else
            _numberOfColumns = 1;
    }
    
    CGFloat w = self.bounds.size.width;
    CGFloat contentWidth = w-(borderMargin*2.0);
    CGFloat columnWidth = 0;
    if (_numberOfColumns == 1)
        columnWidth = contentWidth;
    else
        columnWidth = (contentWidth-(columnPadding*(_numberOfColumns-1)))/_numberOfColumns;
    
    CGFloat maxColumnHeight = 0;
    
    CGFloat x;
    CGFloat sectionHeight;
    
    if (autoLayoutEnabled) {
        CGFloat *columnHeights = malloc(sizeof(CGFloat)*_numberOfColumns);
        for (int i=0; i<_numberOfColumns; i++)
            columnHeights[i] = borderMargin;
        
        int shortestColumn;
        CGFloat minColumnHeight;
        for (int j=0; j<[_sections count]; j++) {
            UIView *thisSection = [_sections objectAtIndex:j];
            sectionHeight = [self.delegate columnsView:self heightForSectionAtIndex:j withWidth:columnWidth];
            
            shortestColumn = 0;
            minColumnHeight = columnHeights[0];
            for (int i=1; i<_numberOfColumns; i++) {
                if (columnHeights[i] < minColumnHeight) {
                    shortestColumn = i;
                    minColumnHeight = columnHeights[i];
                }
            }
            
            x = borderMargin + (shortestColumn * (columnWidth + columnPadding));
            thisSection.frame = CGRectMake(x, minColumnHeight, columnWidth, sectionHeight);
            [thisSection layoutIfNeeded];
            columnHeights[shortestColumn] += sectionHeight + sectionPadding;
        }
        
        CGFloat max = 0;
        for (int i=0; i<_numberOfColumns; i++) {
            if (columnHeights[i] > max)
                max = columnHeights[i];
        }
        
        maxColumnHeight = max - sectionPadding + borderMargin;
        
        free(columnHeights);
    } else {
        x = borderMargin;
        CGFloat y;
        
        for (int i=0; i<[_columns count]; i++) {
            y = borderMargin;
            
            NSMutableArray *thisColumn = [_columns objectAtIndex:i];
            for (int j=0; j<[thisColumn count]; j++) {
                UIView *thisSection = [thisColumn objectAtIndex:j];
                sectionHeight = [self.delegate columnsView:self heightForSectionAtIndexPath:[NSIndexPath indexPathForRow:j inSection:i] withWidth:columnWidth];
                thisSection.frame = CGRectMake(x, y, columnWidth, sectionHeight);
                if (animated)
                    [thisSection layoutIfNeeded];
                y += sectionHeight + sectionPadding;
            }
            
            x += columnWidth + columnPadding;
            
            y -= sectionPadding;
            y += borderMargin;
            if (y > maxColumnHeight)
                maxColumnHeight = y;
        } 
    }

    if (maxColumnHeight < self.bounds.size.height)
        maxColumnHeight = self.bounds.size.height+1;
    
    self.contentSize = CGSizeMake(w, maxColumnHeight);
    
    if (animated)
        [UIView commitAnimations];
}

@end