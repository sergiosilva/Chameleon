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

#import "UIGraphics.h"
#import "UIImage.h"
#import "UIScreen.h"
#import <AppKit/NSGraphicsContext.h>

static NSString* const kUIGraphicsContextStackKey = @"kUIGraphicsContextStackKey";
static NSString* const kUIImageContextStackKey = @"kUIImageContextStackKey";
static BOOL pdfPageStarted = FALSE;

void UIGraphicsPushContext(CGContextRef ctx)
{
    NSMutableDictionary* threadDictionary = [[NSThread currentThread] threadDictionary];
    NSMutableArray* stack = [threadDictionary objectForKey:kUIGraphicsContextStackKey];
    if (!stack) {
        stack = [[NSMutableArray alloc] initWithCapacity:1];
        [threadDictionary setObject:stack forKey:kUIGraphicsContextStackKey];
        [stack release];
    }
    [stack addObject:(id)ctx];
}

void UIGraphicsPopContext()
{
    NSMutableDictionary* threadDictionary = [[NSThread currentThread] threadDictionary];
    NSMutableArray* stack = [threadDictionary objectForKey:kUIGraphicsContextStackKey];
    assert(stack.count); // Someone didn't call *push* first.
    [stack removeLastObject];

}

CGContextRef UIGraphicsGetCurrentContext()
{
    NSMutableDictionary* threadDictionary = [[NSThread currentThread] threadDictionary];
    NSMutableArray* stack = [threadDictionary objectForKey:kUIGraphicsContextStackKey];
    assert(stack.count); // Someone didn't call *push* first.
    return (CGContextRef)[stack lastObject];
}

CGFloat _UIGraphicsGetContextScaleFactor(CGContextRef ctx)
{
    const CGRect rect = CGContextGetClipBoundingBox(ctx);
    const CGRect deviceRect = CGContextConvertRectToDeviceSpace(ctx, rect);
    const CGFloat scale = deviceRect.size.height / rect.size.height;
    return scale;
}

void UIGraphicsBeginImageContextWithOptions(CGSize size, BOOL opaque, CGFloat scale)
{
    if (scale == 0.f) {
        scale = [UIScreen mainScreen].scale;
    }

    const size_t width = size.width * scale;
    const size_t height = size.height * scale;
    
    if (width > 0 && height > 0) {
        NSMutableDictionary* threadDictionary = [[NSThread currentThread] threadDictionary];
        NSMutableArray* imageContextStack = [threadDictionary objectForKey:kUIImageContextStackKey];

        if (!imageContextStack) {
            imageContextStack = [[NSMutableArray alloc] initWithCapacity:1];
        }
        
        [imageContextStack addObject:[NSNumber numberWithFloat:scale]];

        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef ctx = CGBitmapContextCreate(NULL, width, height, 8, 4*width, colorSpace, (opaque? kCGImageAlphaNoneSkipFirst : kCGImageAlphaPremultipliedFirst));
        CGContextConcatCTM(ctx, CGAffineTransformMake(1, 0, 0, -1, 0, height));
        CGContextScaleCTM(ctx, scale, scale);
        CGColorSpaceRelease(colorSpace);
        UIGraphicsPushContext(ctx);
        CGContextRelease(ctx);
    }
}

void UIGraphicsBeginImageContext(CGSize size)
{
    UIGraphicsBeginImageContextWithOptions(size, NO, 1.f);
}

UIImage *UIGraphicsGetImageFromCurrentImageContext()
{
    NSMutableDictionary* threadDictionary = [[NSThread currentThread] threadDictionary];
    NSMutableArray* imageContextStack = [threadDictionary objectForKey:kUIImageContextStackKey];

    if ([imageContextStack lastObject]) {
        const CGFloat scale = [[imageContextStack lastObject] floatValue];
        CGImageRef theCGImage = CGBitmapContextCreateImage(UIGraphicsGetCurrentContext());
        UIImage *image = [UIImage imageWithCGImage:theCGImage scale:scale orientation:UIImageOrientationUp];
        CGImageRelease(theCGImage);
        return image;
    } else {
        return nil;
    }
}

void UIGraphicsEndImageContext()
{
    NSMutableDictionary* threadDictionary = [[NSThread currentThread] threadDictionary];
    NSMutableArray* imageContextStack = [threadDictionary objectForKey:kUIImageContextStackKey];

    if ([imageContextStack lastObject]) {
        [imageContextStack removeLastObject];
        UIGraphicsPopContext();
    }
}

void UIRectClip(CGRect rect)
{
    CGContextClipToRect(UIGraphicsGetCurrentContext(), rect);
}

void UIRectFill(CGRect rect)
{
    UIRectFillUsingBlendMode(rect, kCGBlendModeCopy);
}

void UIRectFillUsingBlendMode(CGRect rect, CGBlendMode blendMode)
{
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGContextSaveGState(c);
    CGContextSetBlendMode(c, blendMode);
    CGContextFillRect(c, rect);
    CGContextRestoreGState(c);
}

void UIRectFrame(CGRect rect)
{
    CGContextStrokeRect(UIGraphicsGetCurrentContext(), rect);
}

void UIRectFrameUsingBlendMode(CGRect rect, CGBlendMode blendMode)
{
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGContextSaveGState(c);
    CGContextSetBlendMode(c, blendMode);
    UIRectFrame(rect);
    CGContextRestoreGState(c);
}

void UIGraphicsBeginPDFPage(void)
{
    if (pdfPageStarted) {
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGPDFContextEndPage(ctx);
    } 
    pdfPageStarted = TRUE;
    CGPDFContextBeginPage(UIGraphicsGetCurrentContext(),nil);
}

void UIGraphicsEndPDFContext(void)
{
    
    CGContextRef ctx =  UIGraphicsGetCurrentContext();
    
    if (pdfPageStarted) {
        CGPDFContextEndPage(ctx);
    }
    
    CGPDFContextClose(ctx);
    UIGraphicsPopContext();
}


void UIGraphicsBeginPDFPageWithInfo(CGRect bounds, NSDictionary *pageInfo) 
{
    if (pdfPageStarted) {
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGPDFContextEndPage(ctx);
    } 
    pdfPageStarted = TRUE;
    
    NSMutableDictionary *mutableDic = [NSMutableDictionary dictionaryWithDictionary:pageInfo];
    
    if (![pageInfo objectForKey:(NSString*)kCGPDFContextMediaBox])  {
        CFDataRef mediaBox = CFDataCreate(NULL, (const UInt8 *)&bounds, sizeof(CGRect));
        [mutableDic setValue:(id)mediaBox forKey:(NSString*)kCGPDFContextMediaBox];
    }
    
    CGPDFContextBeginPage(UIGraphicsGetCurrentContext(),(CFMutableDictionaryRef)pageInfo);
}

void UIGraphicsBeginPDFContextToData(NSMutableData *data, CGRect bounds, NSDictionary *documentInfo) 
{
    CGDataConsumerRef dataConsumer = CGDataConsumerCreateWithCFData((CFMutableDataRef)data);
    
   CGContextRef ctx = CGPDFContextCreate(dataConsumer, &bounds, (CFMutableDictionaryRef)documentInfo);
    UIGraphicsPushContext(ctx);
    CGContextRelease(ctx);
}
