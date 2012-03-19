//
//  UIImage+SMS.m
//  Created by Alex Silverman on 8/25/10.
//

#import "UIImage+SMS.h"

@implementation UIImage (SMS)

+ (id)smsImageNamed:(NSString *)img scale:(SMSImageScale)scale;
{
    UIImage *result = [UIImage imageNamed:img];
    
    UIScreen *mainScreen = [UIScreen mainScreen];
    BOOL scaleEnabled = ([mainScreen respondsToSelector:@selector(scale)] && mainScreen.scale >= 2.0f);
    
    if (!result) {
        NSBundle *bundle = [NSBundle bundleWithIdentifier:@"libSMSResources"];
        if (!bundle) {
            NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"libSMSResources" ofType:@"bundle"];
            bundle = [NSBundle bundleWithPath:bundlePath];
        }
        
        NSString *ext = [img pathExtension];
        if ([ext length] == 0)
            ext = @"png";
        NSString *path = nil;
        if (scale == SMSImageScaleOne || scaleEnabled) {
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
                path = [bundle pathForResource:[img stringByAppendingString:@"@2x~ipad"] ofType:ext];
            if (path == nil)
                path = [bundle pathForResource:[img stringByAppendingString:@"@2x"] ofType:ext];
        }
        if (!path) {
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
                path = [bundle pathForResource:[img stringByAppendingString:@"~ipad"] ofType:ext];
            if (path == nil)
                path = [bundle pathForResource:img ofType:ext];
        }
        
        result = [UIImage imageWithContentsOfFile:path];
    }
    
	if (scale == SMSImageScaleOne && scaleEnabled)
		result = [UIImage imageWithCGImage:[result CGImage] scale:1.0 orientation:UIImageOrientationUp];
	return result;
}

- (UIImage *)resizedImageWithContentMode:(UIViewContentMode)contentMode
                                  bounds:(CGSize)bounds
                    interpolationQuality:(CGInterpolationQuality)quality
{
    CGFloat horizontalRatio = bounds.width / self.size.width;
    CGFloat verticalRatio = bounds.height / self.size.height;
    
    CGFloat ratio;
    switch (contentMode) {
        case UIViewContentModeScaleAspectFill:
            ratio = MAX(horizontalRatio, verticalRatio);
            break;
            
        case UIViewContentModeScaleAspectFit:
            ratio = MIN(horizontalRatio, verticalRatio);
            break;
            
        case UIViewContentModeScaleToFill:
            ratio = 1.0;
            break;
            
        default:
            [NSException raise:NSInvalidArgumentException format:@"UIImage+SMS: unsupported content mode = %d", contentMode];
    }
    
    CGSize newSize = CGSizeMake(self.size.width*ratio, self.size.height*ratio);    
    CGFloat scale = [[UIScreen mainScreen] scale];
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width*scale, newSize.height*scale));
    
    UIGraphicsBeginImageContext(newRect.size);
	CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, quality);
    
    [self drawInRect:newRect];
    
    CGImageRef newImageRef = CGBitmapContextCreateImage(context);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef scale:scale orientation:self.imageOrientation];
    
    UIGraphicsEndImageContext();
    CGImageRelease(newImageRef);
    
    return newImage;
}

@end