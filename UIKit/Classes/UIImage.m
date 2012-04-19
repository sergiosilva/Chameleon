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

#import "UIImage+UIPrivate.h"
#import "UIThreePartImage.h"
#import "UINinePartImage.h"
#import "UIGraphics.h"
#import "UIPhotosAlbum.h"
#import <AppKit/NSImage.h>

@implementation UIImage {
    CGImageRef _image;
    CGImageSourceRef _imageSource;
}

- (void)dealloc
{
    if (_image) {
        CGImageRelease(_image);
    }
    if (_imageSource) {
        CFRelease(_imageSource);
    }
    [super dealloc];
}

- (id)initWithNSImage:(NSImage *)theImage
{
    if (!theImage) {
        [self release];
        return nil;
    }
    return [self initWithCGImage:[theImage CGImageForProposedRect:NULL context:NULL hints:nil]];
}

- (id)initWithCGImageSource:(CGImageSourceRef)imageSource
{
    NSAssert(imageSource != nil, @"???");
    if (nil != (self = [super init])) {
        _imageSource = (CGImageSourceRef)CFRetain(imageSource);
    }
    return self;
}

- (id)initWithData:(NSData *)data
{
    if (!data) {
        [self release];
        return nil;
    }
    
    const NSDictionary* options = [NSDictionary dictionaryWithObject:(id)kCFBooleanFalse forKey:(NSString*)kCGImageSourceShouldCache]; // no caching
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)data, (CFDictionaryRef)options);
    if (!imageSource) {
        [self release];
        return nil;
    }
    if (nil != (self = [self initWithCGImageSource:imageSource])) {
        /**/
    }
    CFRelease(imageSource);
    return self;
}

- (id)initWithContentsOfFile:(NSString *)path
{
    const NSDictionary *options = [NSDictionary dictionaryWithObject:(id)kCFBooleanFalse forKey:(NSString*)kCGImageSourceShouldCache];
    NSString *imagePath = [isa _pathForFile:path];
    if (!imagePath) {
        [self release];
        return nil;
    }
    NSURL *url = [NSURL fileURLWithPath:imagePath];
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((CFURLRef)url, (CFDictionaryRef)options);
    if (!imageSource) {
        [self release];
        return nil;
    }
    if (nil != (self = [self initWithCGImageSource:imageSource])) {
        /**/
    }
    CFRelease(imageSource);
    return self;
}

- (id)initWithCGImage:(CGImageRef)imageRef
{
    if (!imageRef) {
        [self release];
        return nil;
    }
    
    if (nil != (self = [super init])) {
        _image = CGImageRetain(imageRef);
    }
    return self;
}

- (id) initWithCoder:(NSCoder*)coder
{
    if (nil != (self = [super init])) {
        /* XXX: Implement Me */
    }
    return self;
}

- (void) encodeWithCoder:(NSCoder*)coder
{
    [self doesNotRecognizeSelector:_cmd];
}

+ (UIImage *)_loadImageNamed:(NSString *)name
{
    if ([name length] > 0) {
        NSString *macName = [self _macPathForFile:name];
        
        // first check for @mac version of the name
        UIImage *cachedImage = [self _cachedImageForName:macName];
        if (!cachedImage) {
            // otherwise try again with the original given name
            cachedImage = [self _cachedImageForName:name];
        }
        
        if (!cachedImage) {
            // okay, we couldn't find a cached version so now lets first try to make an original with the @mac name.
            // if that fails, try to make it with the original name.
            NSBundle *bundle = [NSBundle mainBundle];
            NSString *path = [bundle pathForImageResource:macName];
            if (!path) {
                path = [bundle pathForImageResource:name];
            }
            if (path) {
                NSURL *url = [NSURL fileURLWithPath:path];
                // the UIImage class handles the caching, so we don't need Core Graphics to do it
                const NSDictionary *options = [NSDictionary dictionaryWithObject:(id)kCFBooleanFalse forKey:(NSString*)kCGImageSourceShouldCache];
                CGImageSourceRef imageSource = CGImageSourceCreateWithURL((CFURLRef)url, (CFDictionaryRef)options);
                if (!imageSource) {
                    return nil; 
                }
                CGImageRef image = (CGImageRef)[(id)CGImageSourceCreateImageAtIndex(imageSource, 0, (CFDictionaryRef)options) autorelease];
                CFRelease(imageSource);
                cachedImage = [[[self alloc] initWithCGImage:image] autorelease];
                [self _cacheImage:cachedImage forName:name];
            }
        }
        return cachedImage;
    } else {
        return nil;
    }
}

+ (UIImage *)imageNamed:(NSString *)name
{
    // first try it with the given name
    UIImage *image = [self _loadImageNamed:name];
    
    // if nothing is found, try again after replacing any underscores in the name with dashes.
    // I don't know why, but UIKit does something similar. it probably has a good reason and it might not be this simplistic, but
    // for now this little hack makes Ramp Champ work. :)
    if (!image) {
        image = [self _loadImageNamed:[name stringByReplacingOccurrencesOfString:@"_" withString:@"-"]];
    }
    
    return image;
}

+ (UIImage *)imageWithData:(NSData *)data
{
    return [[[self alloc] initWithData:data] autorelease];
}

+ (UIImage *)imageWithContentsOfFile:(NSString *)path
{
    return [[[self alloc] initWithContentsOfFile:path] autorelease];
}

+ (UIImage *)imageWithCGImage:(CGImageRef)imageRef
{
    return [[[self alloc] initWithCGImage:imageRef] autorelease];
}

- (UIImage *)stretchableImageWithLeftCapWidth:(NSInteger)leftCapWidth topCapHeight:(NSInteger)topCapHeight
{
    const CGSize size = self.size;
    if ((leftCapWidth == 0 && topCapHeight == 0) || (leftCapWidth >= size.width && topCapHeight >= size.height)) {
        return self;
    } else if (leftCapWidth <= 0 || leftCapWidth >= size.width) {
        return [[[UIThreePartImage alloc] initWithCGImage:[self CGImage] capSize:MIN(topCapHeight,size.height) vertical:YES] autorelease];
    } else if (topCapHeight <= 0 || topCapHeight >= size.height) {
        return [[[UIThreePartImage alloc] initWithCGImage:[self CGImage] capSize:MIN(leftCapWidth,size.width) vertical:NO] autorelease];
    } else {
        return [[[UINinePartImage alloc] initWithCGImage:[self CGImage] leftCapWidth:leftCapWidth topCapHeight:topCapHeight] autorelease];
    }
}

- (void)drawAtPoint:(CGPoint)point blendMode:(CGBlendMode)blendMode alpha:(CGFloat)alpha
{
    const CGSize size = self.size;
    [self drawInRect:CGRectMake(point.x,point.y,size.width,size.height) blendMode:blendMode alpha:alpha];
}

- (void)drawInRect:(CGRect)rect blendMode:(CGBlendMode)blendMode alpha:(CGFloat)alpha
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    CGContextSetBlendMode(ctx, blendMode);
    CGContextSetAlpha(ctx, alpha);
    [self drawInRect:rect];
    CGContextRestoreGState(ctx);
}

- (void)drawAtPoint:(CGPoint)point
{
    const CGSize size = self.size;
    [self drawInRect:CGRectMake(point.x,point.y,size.width,size.height)];
}

- (void)drawInRect:(CGRect)rect
{
    CGImageRef image = [self CGImage];
    if (image) {
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGContextSaveGState(ctx);
        CGContextTranslateCTM(ctx, rect.origin.x, rect.origin.y+rect.size.height);
        CGContextScaleCTM(ctx, 1.0, -1.0);
        CGContextDrawImage(ctx, CGRectMake(0,0,rect.size.width,rect.size.height), image);
        CGContextRestoreGState(ctx);
    }
}

- (CGSize)size
{
    CGImageRef image = [self CGImage];
    if (image) {
        return CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
    } else {
        return CGSizeZero;
    }
}

- (NSInteger)leftCapWidth
{
    return 0;
}

- (NSInteger)topCapHeight
{
    return 0;
}

- (CGImageRef)CGImage
{
    if (!_image) {
        if (_imageSource) {
            _image = CGImageSourceCreateImageAtIndex(_imageSource, 0, NULL);
            CFRelease(_imageSource), _imageSource = nil;
        }
    }
    return _image;
}

- (UIImageOrientation)imageOrientation
{
    return UIImageOrientationUp;
}

- (NSImage *)NSImage
{
    return [[[NSImage alloc] initWithCGImage:[self CGImage] size:NSSizeFromCGSize(self.size)] autorelease];
}

- (NSBitmapImageRep *)_NSBitmapImageRep
{
    return [[[NSBitmapImageRep alloc] initWithCGImage:[self CGImage]] autorelease];
}

- (CGFloat)scale
{
    return 1.0;
}

@end

void UIImageWriteToSavedPhotosAlbum(UIImage *image, id completionTarget, SEL completionSelector, void *contextInfo)
{
    [[UIPhotosAlbum sharedPhotosAlbum] writeImage:image completionTarget:completionTarget action:completionSelector context:contextInfo];
}

void UISaveVideoAtPathToSavedPhotosAlbum(NSString *videoPath, id completionTarget, SEL completionSelector, void *contextInfo)
{
}

BOOL UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(NSString *videoPath)
{
    return NO;
}

NSData *UIImageJPEGRepresentation(UIImage *image, CGFloat compressionQuality)
{
    return [[image _NSBitmapImageRep] representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:compressionQuality] forKey:NSImageCompressionFactor]];
}

NSData *UIImagePNGRepresentation(UIImage *image)
{
    return [[image _NSBitmapImageRep] representationUsingType:NSPNGFileType properties:nil];
}