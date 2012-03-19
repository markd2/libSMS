//
//  UIImage+SMS.h
//  Created by Alex Silverman on 8/25/10.
//

#import <UIKit/UIKit.h>


typedef enum {
	SMSImageScaleDefault,
	SMSImageScaleOne
} SMSImageScale;


@interface UIImage (SMS)

+ (id)smsImageNamed:(NSString *)img scale:(SMSImageScale)scale;

- (UIImage *)resizedImageWithContentMode:(UIViewContentMode)contentMode
                                  bounds:(CGSize)bounds
                    interpolationQuality:(CGInterpolationQuality)quality; // 0 for default

@end