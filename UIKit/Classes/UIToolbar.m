/*
 * Copyright (c) 2011, The Iconfactory. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of The Iconfactory nor the names of its contributors may
 *    be used to endorse or promote products derived from this software without
 *    specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE ICONFACTORY BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "UIToolbar.h"
#import "UIToolbarItem.h"
#import "UIGraphics.h"

@implementation UIToolbar 
@synthesize barStyle = _barStyle;
@synthesize tintColor = _tintColor;
@synthesize translucent = _translucent;

- (id)init
{
    return [self initWithFrame:CGRectMake(0,0,320,32)];
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self=[super initWithFrame:frame])) {
        _toolbarItems = [[NSMutableArray alloc] init];
        self.barStyle = UIBarStyleDefault;
        self.translucent = NO;
        self.tintColor = nil;
    }
    return self;
}

- (void)dealloc
{
    [_tintColor release];
    [_toolbarItems release];
    [super dealloc];
}

- (void)setBarStyle:(UIBarStyle)newStyle
{
    _barStyle = newStyle;

    // this is for backward compatibility - UIBarStyleBlackTranslucent is deprecated 
    if (_barStyle == UIBarStyleBlackTranslucent) {
        self.translucent = YES;
        self.alpha = 0.80;
    }
}

/*
- (void)_updateItemViews
{
    [_itemViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_itemViews removeAllObjects];

    NSUInteger numberOfFlexibleItems = 0;
    
    for (UIBarButtonItem *item in _items) {
        if ((item->_isSystemItem) && (item->_systemItem == UIBarButtonSystemItemFlexibleSpace)) {
            numberOfFlexibleItems++;
        }
    }

    const CGSize size = self.bounds.size;
    const CGFloat flexibleSpaceWidth = (numberOfFlexibleItems > 0)? MAX(0, size.width/numberOfFlexibleItems) : 0;
    CGFloat left = 0;
    
    for (UIBarButtonItem *item in _items) {
        UIView *view = item.customView;

        if (!view) {
            if (item->_isSystemItem && item->_systemItem == UIBarButtonSystemItemFlexibleSpace) {
                left += flexibleSpaceWidth;
            } else if (item->_isSystemItem && item->_systemItem == UIBarButtonSystemItemFixedSpace) {
                left += item.width;
            } else {
                view = [[[UIToolbarButton alloc] initWithBarButtonItem:item] autorelease];
            }
        }
        
        if (view) {
            CGRect frame = view.frame;
            frame.origin.x = left;
            frame.origin.y = (size.height / 2.f) - (frame.size.height / 2.f);
            frame = CGRectStandardize(frame);
            
            view.frame = frame;
            left += frame.size.width;
            
            [self addSubview:view];
        }
    }
}
*/

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat itemWidth = 0;
    NSUInteger numberOfFlexibleItems = 0;
    
    for (UIToolbarItem *toolbarItem in _toolbarItems) {
        const CGFloat width = toolbarItem.width;
        if (width >= 0) {
            itemWidth += width;
        } else {
            numberOfFlexibleItems++;
        }
    }
    
    const CGSize size = self.bounds.size;
    const CGFloat flexibleSpaceWidth = (numberOfFlexibleItems > 0)? ((size.width - itemWidth) / numberOfFlexibleItems) : 0;
    const CGFloat centerY = size.height / 2.f;

    CGFloat x = 0;
    
    for (UIToolbarItem *toolbarItem in _toolbarItems) {
        UIView *view = toolbarItem.view;
        const CGFloat width = toolbarItem.width;
        
        if (view) {
            CGRect frame = view.frame;
            frame.origin.x = x;
            frame.origin.y = floor(centerY - (frame.size.height / 2.f));
            view.frame = frame;
        }

        if (width < 0) {
            x += flexibleSpaceWidth;
        } else {
            x += width;
        }
    }
}

- (void)setItems:(NSArray *)newItems animated:(BOOL)animated
{
    if (![self.items isEqualToArray:newItems]) {
        // if animated, fade old item views out, otherwise just remove them
        for (UIToolbarItem *toolbarItem in _toolbarItems) {
            UIView* view = toolbarItem.view;
            if (view) {
                if (animated) {
                    [UIView animateWithDuration: 0.2
                                     animations:^(void) {
                                         view.alpha = 0;
                                     }
                                     completion:^(BOOL finished) {
                                         [view removeFromSuperview];
                                     }];
                } else {
                    [view removeFromSuperview];
                }
            }
        }
        
        [_toolbarItems removeAllObjects];
        
        for (UIBarButtonItem *item in newItems) {
            UIToolbarItem *toolbarItem = [[UIToolbarItem alloc] initWithBarButtonItem:item];
            [toolbarItem _setToolbar:self];
            [_toolbarItems addObject:toolbarItem];
            
            UIView* view = toolbarItem.view;
            if (view) {
                if (animated) {
                    view.alpha = 0.0;
                    [self addSubview:view];
                    [UIView animateWithDuration:0.2
                                     animations:^(void) {
                                         view.alpha = 1.0;
                                     }
                     ];
                    
                } else {
                    [self addSubview:view];
                }
            }
            [toolbarItem release];
        }
    }
}

- (void)setItems:(NSArray *)items
{
    [self setItems:items animated:NO];
}

- (NSArray *)items
{
    return [_toolbarItems valueForKey:@"item"];
}

- (void)drawRect:(CGRect)rect
{
    const CGRect bounds = self.bounds;
    
    UIColor *color = _tintColor ?: [UIColor colorWithRed:21/255.f green:21/255.f blue:25/255.f alpha:1];

    [color setFill];
    UIRectFill(bounds);
    
    self.translucent ? [[UIColor colorWithRed:112/255.f green:112/255.f blue:112/255.f alpha:0.8] setFill] : [[UIColor blackColor] setFill];
    UIRectFill(CGRectMake(0,0,bounds.size.width,1));
}

- (NSString *)description
{
    NSString *barStyle = @"";
    switch (self.barStyle) {
        case UIBarStyleDefault:
            barStyle = @"Default";
            break;
        case UIBarStyleBlack:
            barStyle = @"Black";
            break;
        case UIBarStyleBlackTranslucent:
            barStyle = @"Black Translucent (Deprecated)";
            break;
    }
    return [NSString stringWithFormat:@"<%@: %p; barStyle = %@; tintColor = %@, isTranslucent = %@>", [self className], self, barStyle, ([self.tintColor description] ?: @"Default"), (self.translucent ? @"YES" : @"NO")];
}

@end
