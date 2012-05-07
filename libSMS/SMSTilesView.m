/*
 SMSTilesView.m
 
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

#import "SMSTilesView.h"

@implementation SMSTile

@synthesize reuseIdentifier;

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)iden
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        reuseIdentifier = iden;
    }
    return self;
}

- (void)prepareForReuse
{
    self.highlighted = NO;
    self.selected = NO;
}

- (void)setHighlighted:(BOOL)yesOrNo
{
    [super setHighlighted:yesOrNo];
    if (yesOrNo)
        self.alpha = 0.5;
    else
        self.alpha = 1.0;
}

@end


@implementation SMSTilesView

@synthesize dataSource;
@synthesize tileSize, borderMargin, minimumTilePadding;
@synthesize allowsMultipleSelection;

- (id<SMSTilesViewDelegate>)delegate
{
    return (id<SMSTilesViewDelegate>)[super delegate];
}

- (void)setDelegate:(id<SMSTilesViewDelegate>)d
{
    [super setDelegate:d];
}

- (id)initWithFrame:(CGRect)f
{
    self = [super initWithFrame:f];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.showsHorizontalScrollIndicator = NO;
        
        _tiles = [[NSMutableArray alloc] init];
        _tilesForResuse = [[NSMutableDictionary alloc] init];
        
        _selectedTileIndices = [NSMutableIndexSet indexSet];
        
        tileSize = CGSizeMake(100, 100);
        borderMargin = 20;
        minimumTilePadding = 20;
    }
    return self;
}

- (void)_updateTiles:(NSIndexSet *)idx
{
    CGFloat viewWidth = self.bounds.size.width;
    CGFloat viewHeight = self.bounds.size.height;
    
    CGRect contentFrame = CGRectMake(self.contentOffset.x, self.contentOffset.y, viewWidth, viewHeight);
    
    CGFloat tileWidth = tileSize.width;
    CGFloat tileHeight = tileSize.height;
    
    CGFloat _borderMargin = borderMargin;
    if (_numberOfColumns == 1)
        _borderMargin = (viewWidth-tileWidth)/2.0;
    
    CGFloat x = _borderMargin;
    CGFloat y = borderMargin;
    int c = 1;
    
    CGRect f = CGRectZero;
    for (int i=0; i<[_tiles count]; i++) {
        SMSTile *thisTile = [_tiles objectAtIndex:i];
        
        f = CGRectMake(x, y, tileWidth, tileHeight);
        if (CGRectIntersectsRect(contentFrame, f)) {
            if ((NSNull *)thisTile == [NSNull null] || [idx containsIndex:i]) {
                thisTile = [dataSource tilesView:self tileForIndex:i];
                
                [UIView setAnimationsEnabled:NO];
                thisTile.alpha = 0.0;
                thisTile.frame = f;
                [UIView setAnimationsEnabled:YES];
                
                thisTile.alpha = 1.0;
                
                [thisTile removeTarget:self action:@selector(_selectTile:) forControlEvents:UIControlEventTouchUpInside];
                [thisTile addTarget:self action:@selector(_selectTile:) forControlEvents:UIControlEventTouchUpInside];
                if ([_selectedTileIndices containsIndex:i])
                    thisTile.selected = YES;
                [self addSubview:thisTile];
                [_tiles replaceObjectAtIndex:i withObject:thisTile];
            } else
                thisTile.frame = f;
        } else {
            if ((NSNull *)thisTile != [NSNull null]) {
                NSString *reuseIdentifier = thisTile.reuseIdentifier;
                if (reuseIdentifier) {
                    NSMutableSet *tiles = [_tilesForResuse objectForKey:reuseIdentifier];
                    if (!tiles) {
                        tiles = [[NSMutableSet alloc] init];
                        [_tilesForResuse setObject:tiles forKey:reuseIdentifier];
                    }
                    [tiles addObject:thisTile];
                }
                
                [thisTile removeFromSuperview];
                [_tiles replaceObjectAtIndex:i withObject:[NSNull null]];
            }
        }
        
        c += 1;
        if (c > _numberOfColumns) {
            x = _borderMargin;
            y += (tileHeight + _tileMargin);
            c = 1;
        } else
            x += (tileWidth + _tileMargin);
    }
    
    if (c == 1)
        y -= _tileMargin;
    else
        y += tileHeight;
    self.contentSize = CGSizeMake(viewWidth, y+borderMargin);
}

- (void)_selectTile:(SMSTile *)sender
{
    NSUInteger i = [_tiles indexOfObject:sender];
    if (i == NSNotFound)
        return;
    
    if (!sender.selected) {
        sender.selected = YES;
        
        if (!allowsMultipleSelection) {
            [_selectedTileIndices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                SMSTile *thisTile = [_tiles objectAtIndex:idx];
                if ((NSNull *)thisTile != [NSNull null])
                    thisTile.selected = NO;
            }];
            [_selectedTileIndices removeAllIndexes];
        }
        [_selectedTileIndices addIndex:i];
        
        if ([self.delegate respondsToSelector:@selector(tilesView:didSelectTileAtIndex:)])
            [self.delegate tilesView:self didSelectTileAtIndex:i];
    } else {
        sender.selected = NO;
        [_selectedTileIndices removeIndex:i];
        
        if ([self.delegate respondsToSelector:@selector(tilesView:didDeselectTileAtIndex:)])
            [self.delegate tilesView:self didDeselectTileAtIndex:i];
    }
}

- (void)_computeColumnsAndMargin
{
    CGFloat viewWidth = self.bounds.size.width;
    CGFloat tileWidth = tileSize.width;
    _numberOfColumns = (viewWidth - 2*borderMargin + minimumTilePadding) / (tileWidth + minimumTilePadding);
    if (_numberOfColumns == 1)
        _tileMargin = minimumTilePadding;
    else
        _tileMargin = (viewWidth - 2*borderMargin - tileWidth*_numberOfColumns)/(_numberOfColumns-1.0);
    
    if (_numberOfTiles == 0)
        [self reloadTiles];
    else
        [self _updateTiles:nil];
}

- (void)setBounds:(CGRect)b
{
    [super setBounds:b];
    if (self.superview && b.size.width > 0.0 && b.size.height > 0.0)
        [self _computeColumnsAndMargin];
}

- (void)setFrame:(CGRect)f
{
    [super setFrame:f];
    if (self.superview && f.size.width > 0.0 && f.size.height > 0.0)
        [self _computeColumnsAndMargin];
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    CGRect f = self.bounds;
    if (newSuperview && f.size.width > 0.0 && f.size.height > 0.0)
        [self _computeColumnsAndMargin];
}

- (void)setContentOffset:(CGPoint)offset
{
    [super setContentOffset:offset];
    [self _updateTiles:nil];
}

- (void)reloadTiles
{
    for (SMSTile *thisTile in _tiles) {
        if ((NSNull *)thisTile != [NSNull null]) {
            NSString *reuseIdentifier = thisTile.reuseIdentifier;
            if (reuseIdentifier) {
                NSMutableSet *tiles = [_tilesForResuse objectForKey:reuseIdentifier];
                if (!tiles) {
                    tiles = [[NSMutableSet alloc] init];
                    [_tilesForResuse setObject:tiles forKey:reuseIdentifier];
                }
                [tiles addObject:thisTile];
            }
            
            [thisTile removeFromSuperview];
        }
    }
    [_tiles removeAllObjects];
    
    _numberOfTiles = [dataSource numberOfTilesInTilesView:self];
    for (int i=0; i<_numberOfTiles; i++)
        [_tiles addObject:[NSNull null]];
    
    [self _updateTiles:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, _numberOfTiles)]];
    [_tilesForResuse removeAllObjects];
}

- (void)reloadTilesAtIndices:(NSIndexSet *)i
{
    [i enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        SMSTile *thisTile = [_tiles objectAtIndex:idx];
        if ((NSNull *)thisTile != [NSNull null]) {
            NSString *reuseIdentifier = thisTile.reuseIdentifier;
            if (reuseIdentifier) {
                NSMutableSet *tiles = [_tilesForResuse objectForKey:reuseIdentifier];
                if (!tiles) {
                    tiles = [[NSMutableSet alloc] init];
                    [_tilesForResuse setObject:tiles forKey:reuseIdentifier];
                }
                [tiles addObject:thisTile];
            }
            
            [thisTile removeFromSuperview];
            [_tiles replaceObjectAtIndex:idx withObject:[NSNull null]];
        }
    }];
    
    [self _updateTiles:i];
    [_tilesForResuse removeAllObjects];
}

- (void)setTileSize:(CGSize)s
{
    tileSize = s;
    [self layoutSubviews];
}

- (void)setBorderMargin:(CGFloat)m
{
    borderMargin = m;
    [self layoutSubviews];
}

- (void)setMinimumTilePadding:(CGFloat)m
{
    minimumTilePadding = m;
    [self layoutSubviews];
}

- (void)insertTilesAtIndices:(NSIndexSet *)i animated:(BOOL)animated
{
    NSMutableArray *insertedTiles = [NSMutableArray array];
    [i enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        SMSTile *tile = [dataSource tilesView:self tileForIndex:idx];
        [tile addTarget:self action:@selector(_selectTile:) forControlEvents:UIControlEventTouchUpInside];
        if (animated)
            tile.alpha = 0.0;
        [self addSubview:tile];
        [insertedTiles addObject:tile];
    }];
    [_tiles insertObjects:insertedTiles atIndexes:i];
    
    NSMutableIndexSet *newSelectedIndices = [NSMutableIndexSet indexSet];
    [_selectedTileIndices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [i enumerateIndexesUsingBlock:^(NSUInteger idx2, BOOL *stop) {
            if (idx2 <= idx)
                [newSelectedIndices addIndex:idx+1];
            else
                [newSelectedIndices addIndex:idx];
        }];
    }];
    _selectedTileIndices = newSelectedIndices;
    
    _numberOfTiles = [_tiles count];
    
    if (animated) {
        [UIView animateWithDuration:0.5
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             [self _updateTiles:nil];
                         } 
                         completion:^(BOOL finished) {
                             [UIView animateWithDuration:0.3
                                                   delay:0.0
                                                 options:UIViewAnimationOptionCurveEaseInOut
                                              animations:^{
                                                  [insertedTiles enumerateObjectsUsingBlock:^(SMSTile *thisTile, NSUInteger idx, BOOL *stop) {
                                                      if ((NSNull *)thisTile != [NSNull null])
                                                          thisTile.alpha = 1.0;
                                                  }];
                                              }
                                              completion:nil];
                         }];
    } else
        [self _updateTiles:nil];
}

- (void)removeTilesAtIndices:(NSIndexSet *)i animated:(BOOL)animated
{
    if ([_tiles count] == 0)
        return;
    
    NSMutableIndexSet *newSelectedIndices = [NSMutableIndexSet indexSet];
    [_selectedTileIndices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [i enumerateIndexesUsingBlock:^(NSUInteger idx2, BOOL *stop) {
            if (idx2 < idx)
                [newSelectedIndices addIndex:idx-1];
            else if (idx2 > idx)
                [newSelectedIndices addIndex:idx];
        }];
    }];
    _selectedTileIndices = newSelectedIndices;
    
    NSArray *removedTiles = [_tiles objectsAtIndexes:i];
    
    if (animated) {
        [UIView animateWithDuration:0.3
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             [removedTiles enumerateObjectsUsingBlock:^(SMSTile *thisTile, NSUInteger idx, BOOL *stop) {
                                 if ((NSNull *)thisTile != [NSNull null])
                                     thisTile.alpha = 0.0;
                             }];
                         }
                         completion:^(BOOL finished) {
                             [removedTiles enumerateObjectsUsingBlock:^(SMSTile *thisTile, NSUInteger idx, BOOL *stop) {
                                 if ((NSNull *)thisTile != [NSNull null])
                                     [thisTile removeFromSuperview];
                             }];
                             [_tiles removeObjectsAtIndexes:i];
                             
                             _numberOfTiles = [_tiles count];
                             
                             [UIView animateWithDuration:0.5
                                                   delay:0.0
                                                 options:UIViewAnimationOptionCurveEaseInOut
                                              animations:^{
                                                  [self _updateTiles:nil];
                                              }
                                              completion:nil];
                         }];
    } else {
        [removedTiles enumerateObjectsUsingBlock:^(SMSTile *thisTile, NSUInteger idx, BOOL *stop) {
            if ((NSNull *)thisTile != [NSNull null])
                [thisTile removeFromSuperview];
        }];
        [_tiles removeObjectsAtIndexes:i];
        
        _numberOfTiles = [_tiles count];
        
        [self _updateTiles:nil];
    }
}

- (void)moveTileFromIndex:(NSUInteger)from toIndex:(NSUInteger)to animated:(BOOL)animated;
{
    SMSTile *thisTile = [_tiles objectAtIndex:from];
    [_tiles removeObjectAtIndex:from];
    [_tiles insertObject:thisTile atIndex:to];
    
    if (animated) {
        [UIView animateWithDuration:0.5
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             [self _updateTiles:nil];
                         }
                         completion:nil];
    } else
        [self _updateTiles:nil];
}

- (SMSTile *)dequeueReusableTileWithIdentifier:(NSString *)iden
{
    if (!iden)
        return nil;
    
    NSMutableSet *tiles = [_tilesForResuse objectForKey:iden];
    SMSTile *aTile = [tiles anyObject];
    if (!aTile)
        return nil;
    
    [aTile prepareForReuse];
    [tiles removeObject:aTile];
    return aTile;
}

- (SMSTile *)tileForIndex:(NSUInteger)i
{
    if (i >= [_tiles count])
        return nil;
    
    SMSTile *tile = [_tiles objectAtIndex:i];
    if ((NSNull *)tile == [NSNull null])
        return nil;
    return tile;
}

- (void)scrollToTileAtIndex:(NSUInteger)i atScrollPosition:(SMSTilesViewScrollPosition)pos animated:(BOOL)animated
{
    
}

- (void)selectTilesAtIndices:(NSIndexSet *)i animated:(BOOL)animated
{
    void (^selection)(void) = ^ {
        [i enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            SMSTile *tile = [_tiles objectAtIndex:idx];
            if ((NSNull *)tile != [NSNull null])
                tile.selected = YES;
        }];
    };
    
    [_selectedTileIndices addIndexes:i];
    
    if (animated) {
        [UIView animateWithDuration:0.3
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:selection
                         completion:nil];
    } else
        selection();
}

- (void)deselectTilesAtIndices:(NSIndexSet *)i animated:(BOOL)animated
{
    if ([_tiles count] == 0)
        return;
    
    void (^selection)(void) = ^ {
        [i enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            if (idx < [_tiles count]) {
                SMSTile *tile = [_tiles objectAtIndex:idx];
                if ((NSNull *)tile != [NSNull null])
                    tile.selected = NO;
            }
        }];
    };
    
    [_selectedTileIndices removeIndexes:i];
    
    if (animated) {
        [UIView animateWithDuration:0.3
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:selection
                         completion:nil];
    } else
        selection();
}

- (NSIndexSet *)indicesForSelectedTiles
{
    return [_selectedTileIndices copy];
}

@end