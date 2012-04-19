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

#import "UIThreePartImage.h"
#import "UIGraphics.h"

@implementation UIThreePartImage

- (id)initWithCGImage:(CGImageRef)theImage capSize:(NSInteger)capSize vertical:(BOOL)isVertical
{
    if ((self=[super initWithCGImage:theImage])) {
        const CGSize size = self.size;
        
        _vertical = isVertical;
        
        if (_vertical) {
            const CGFloat stretchyHeight = (capSize < size.height)? 1 : 0;
            const CGFloat bottomCapHeight = size.height - capSize - stretchyHeight;
            
            _startCap = CGImageCreateWithImageInRect(theImage, CGRectMake(0,0,size.width,capSize));
            _centerFill = CGImageCreateWithImageInRect(theImage, CGRectMake(0,capSize,size.width,stretchyHeight));
            _endCap = CGImageCreateWithImageInRect(theImage, CGRectMake(0,size.height-bottomCapHeight,size.width,bottomCapHeight));
        } else {
            const CGFloat stretchyWidth = (capSize < size.width)? 1 : 0;
            const CGFloat rightCapWidth = size.width - capSize - stretchyWidth;
            
            _startCap = CGImageCreateWithImageInRect(theImage, CGRectMake(0,0,capSize,size.height));
            _centerFill = CGImageCreateWithImageInRect(theImage, CGRectMake(capSize,0,stretchyWidth,size.height));
            _endCap = CGImageCreateWithImageInRect(theImage, CGRectMake(size.width-rightCapWidth,0,rightCapWidth,size.height));
        }
    }
    return self;
}

- (void)dealloc
{
    if (_startCap)
        CGImageRelease(_startCap);
    if (_centerFill)
        CGImageRelease(_centerFill);
    if (_endCap)
        CGImageRelease(_endCap);
    [super dealloc];
}

- (NSInteger)leftCapWidth
{
    return _vertical? 0 : CGImageGetWidth(_startCap);
}

- (NSInteger)topCapHeight
{
    return _vertical ? CGImageGetHeight(_startCap) : 0;
}

- (void)drawInRect:(CGRect)rect
{
    CGRect startCapRect = CGRectMake(rect.origin.x, rect.origin.y, _vertical ? rect.size.width : CGImageGetWidth(_startCap), _vertical ? CGImageGetHeight(_startCap) : rect.size.height);
    CGSize endCapSize = CGSizeMake(CGImageGetWidth(_endCap), CGImageGetHeight(_endCap));
    CGRect endCapRect = _vertical ? CGRectMake(rect.origin.x, CGRectGetMaxY(rect) - endCapSize.height, rect.size.width, endCapSize.height) : CGRectMake(CGRectGetMaxX(rect) - endCapSize.width, rect.origin.y, endCapSize.width, rect.size.height);
    CGRect centerFillRect = _vertical ? CGRectMake(rect.origin.x, CGRectGetMaxY(startCapRect), rect.size.width, rect.size.height - (startCapRect.size.height + endCapRect.size.height)) : CGRectMake(CGRectGetMaxX(startCapRect), rect.origin.y, rect.size.width - (startCapRect.size.width + endCapRect.size.width), rect.size.height);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
	CGContextScaleCTM(ctx, 1, -1);
	CGContextTranslateCTM(ctx, 0, -rect.size.height);
    CGContextDrawImage(ctx, startCapRect, _startCap);
    CGContextDrawImage(ctx, endCapRect, _endCap);
    CGContextClipToRect(ctx, centerFillRect); // bug in CGContextDrawTiledImage, has to be clipped before drawing
    CGContextDrawTiledImage(ctx, centerFillRect, _centerFill);
    CGContextRestoreGState(ctx);
}

@end

