/*
 * RNBlurModal
 *
 * Created by Ryan Nystrom on 10/2/12.
 * Copyright (c) 2012 Ryan Nystrom. All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#import <Accelerate/Accelerate.h>
#import <QuartzCore/QuartzCore.h>
#import "RNBlurModalView.h"
#import "UIView+Sizes.h"

/*
    This bit is important! In order to prevent capturing selected states of UIResponders I've implemented a delay. Please feel free to set this delay to *whatever* you deem apprpriate.
    I've defaulted it to 0.125 seconds. You can do shorter/longer as you see fit. 
 */
CGFloat const kRNBlurDefaultDelay = 0.125f;

/*
    You can also change this constant to make the blur more "blurry". I recommend the tasteful level of 0.2 and no higher. However, you are free to change this from 0.0 to 1.0.
 */
CGFloat const kRNDefaultBlurScale = 0.2f;

CGFloat const kRNBlurDefaultDuration = 0.2f;
CGFloat const kRNBlurViewMaxAlpha = 1.f;

CGFloat const kRNBlurBounceOutDurationScale = 0.8f;

NSString * const kRNBlurDidShowNotification = @"com.whoisryannystrom.RNBlurModalView.show";
NSString * const kRNBlurDidHidewNotification = @"com.whoisryannystrom.RNBlurModalView.hide";

typedef void (^RNBlurCompletion)(void);

@interface UIView (Screenshot)
- (UIImage*)screenshot;
@end

@interface UIImage (Blur)
-(UIImage *)boxblurImageWithBlur:(CGFloat)blur;
@end

@interface RNBlurView : UIImageView
- (id)initWithCoverView:(UIView*)view;
@end

@interface RNBlurModalView ()
@property (assign, readwrite) BOOL isVisible;
@end

#pragma mark - RNBlurModalView

@implementation RNBlurModalView {
    UIViewController *_controller;
    UIView *_parentView;
    UIView *_contentView;
    RNBlurView *_blurView;
    RNBlurCompletion _completion;
}

+ (RNBlurMessageView *)generateModalViewWithTitle:(NSString*)title message:(NSString*)message
{
    return [[RNBlurMessageView alloc] initWithFrame:CGRectMake(0, 0, 280.f, 0) withTitle:title withMessage:message];
}


- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.dismissButton = [[RNCloseButton alloc] init];
        self.dismissButton.center = CGPointZero;
        self.dismissButton.accessibilityLabel = @"Close";
        self.dismissButton.accessibilityHint = @"Double-tap to dismiss popup";
        [self.dismissButton addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
        
        self.alpha = 0.f;
        self.backgroundColor = [UIColor clearColor];
//        self.backgroundColor = [UIColor redColor];
//        self.layer.borderWidth = 2.f;
//        self.layer.borderColor = [UIColor blackColor].CGColor;
        
        self.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                  UIViewAutoresizingFlexibleHeight |
                                  UIViewAutoresizingFlexibleLeftMargin |
                                  UIViewAutoresizingFlexibleTopMargin);
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChangeNotification:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    }
    return self;
}



- (id)initWithViewController:(UIViewController*)viewController view:(UIView*)view {
    if (self = [self initWithFrame:CGRectMake(0, 0, viewController.view.width, viewController.view.height)]) {
        [self addSubview:view];
        _contentView = view;
        _controller = viewController;
        _parentView = nil;
        _contentView.clipsToBounds = YES;
        _contentView.layer.masksToBounds = YES;
        
        self.dismissButton.center = CGPointMake(view.left, view.top);
        [self addSubview:self.dismissButton];
    }
    return self;
}


- (id)initWithViewController:(UIViewController*)viewController title:(NSString*)title message:(NSString*)message {
    UIView *view = [RNBlurModalView generateModalViewWithTitle:title message:message];
    if (self = [self initWithViewController:viewController view:view]) {
        // nothing to see here
    }
    return self;
}

- (id)initWithParentView:(UIView*)parentView view:(UIView*)view {
    if (self = [self initWithFrame:CGRectMake(0, 0, parentView.width, parentView.height)]) {
        [self addSubview:view];
        _contentView = view;
        _controller = nil;
        _parentView = parentView;
        _contentView.clipsToBounds = YES;
        _contentView.layer.masksToBounds = YES;
        
        self.dismissButton.center = CGPointMake(view.left, view.top);
        [self addSubview:self.dismissButton];
    }
    return self;
}

- (id)initWithParentView:(UIView*)parentView title:(NSString*)title message:(NSString*)message {
    UIView *view = [RNBlurModalView generateModalViewWithTitle:title message:message];
    if (self = [self initWithParentView:parentView view:view]) {
        // nothing to see here
    }
    return self;
}


- (id)initWithView:(UIView*)view {
    if (self = [self initWithParentView:[[UIApplication sharedApplication].delegate window].rootViewController.view view:view]) {
        // nothing to see here
    }
    return self;
}

- (id)initWithTitle:(NSString*)title message:(NSString*)message {
    UIView *view = [RNBlurModalView generateModalViewWithTitle:title message:message];
    if (self = [self initWithView:view]) {
        // nothing to see here
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.dismissButton.center = CGPointMake(_contentView.left, _contentView.top);
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    if (newSuperview) {
        self.center = CGPointMake(CGRectGetMidX(newSuperview.frame), CGRectGetMidY(newSuperview.frame));
    }
}


- (void)orientationDidChangeNotification:(NSNotification*)notification {
    [self performSelector:@selector(updateSubviews) withObject:nil afterDelay:0.3f];
}


- (void)updateSubviews {
    self.hidden = YES;
    
    // get new screenshot after orientation
    [_blurView removeFromSuperview]; _blurView = nil;
    if (_controller) {
        _blurView = [[RNBlurView alloc] initWithCoverView:_controller.view];
        _blurView.alpha = 1.f;
        [_controller.view insertSubview:_blurView belowSubview:self];

    }
    else if(_parentView) {
        _blurView = [[RNBlurView alloc] initWithCoverView:_parentView];
        _blurView.alpha = 1.f;
        [_parentView insertSubview:_blurView belowSubview:self];

    }
    
    
    
    self.hidden = NO;

    _contentView.center = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
    self.dismissButton.center = _contentView.origin;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)show {
    [self showWithDuration:kRNBlurDefaultDuration delay:0 options:kNilOptions completion:NULL];
}


- (void)showWithDuration:(CGFloat)duration delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options completion:(void (^)(void))completion {
    self.animationDuration = duration;
    self.animationDelay = delay;
    self.animationOptions = options;
    _completion = [completion copy];
    
    // delay so we dont get button states
    [self performSelector:@selector(delayedShow) withObject:nil afterDelay:kRNBlurDefaultDelay];
}


- (void)delayedShow {
    if (! self.isVisible) {
        if (! self.superview) {
            if (_controller) {
                self.frame = CGRectMake(0, 0, _controller.view.bounds.size.width, _controller.view.bounds.size.height);
                [_controller.view addSubview:self];
            }
            else if(_parentView) {
                self.frame = CGRectMake(0, 0, _parentView.bounds.size.width, _parentView.bounds.size.height);

                [_parentView addSubview:self];
            }
            self.top = 0;
        }
        
        if (_controller) {
            _blurView = [[RNBlurView alloc] initWithCoverView:_controller.view];
            _blurView.alpha = 0.f;
            self.frame = CGRectMake(0, 0, _controller.view.bounds.size.width, _controller.view.bounds.size.height);

            [_controller.view insertSubview:_blurView belowSubview:self];
        }
        else if(_parentView) {
            _blurView = [[RNBlurView alloc] initWithCoverView:_parentView];
            _blurView.alpha = 0.f;
            self.frame = CGRectMake(0, 0, _parentView.bounds.size.width, _parentView.bounds.size.height);

            [_parentView insertSubview:_blurView belowSubview:self];
        }
        
        self.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.4, 0.4);
        [UIView animateWithDuration:self.animationDuration animations:^{
            _blurView.alpha = 1.f;
            self.alpha = 1.f;
            self.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.f, 1.f);
        } completion:^(BOOL finished) {
            if (finished) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kRNBlurDidShowNotification object:nil];
                self.isVisible = YES;
                if (_completion) {
                    _completion();
                }
            }
        }];

    }

}


- (void)hide {
    [self hideWithDuration:kRNBlurDefaultDuration delay:0 options:kNilOptions completion:NULL];
}


- (void)hideWithDuration:(CGFloat)duration delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options completion:(void (^)(void))completion {
    if (self.isVisible) {
        [UIView animateWithDuration:duration
                              delay:delay
                            options:options
                         animations:^{
                             self.alpha = 0.f;
                             _blurView.alpha = 0.f;
                         }
                         completion:^(BOOL finished){
                             if (finished) {
                                 [_blurView removeFromSuperview];
                                 _blurView = nil;
                                 [self removeFromSuperview];
                                 
                                 [[NSNotificationCenter defaultCenter] postNotificationName:kRNBlurDidHidewNotification object:nil];
                                 self.isVisible = NO;
                                 if (completion) {
                                     completion();
                                 }
                             }
                         }];
    }
}


@end

#pragma mark - RNBlurView

@implementation RNBlurView {
    UIView *_coverView;
}

- (id)initWithCoverView:(UIView *)view {
    if (self = [super initWithFrame:CGRectMake(0, 0, view.bounds.size.width, view.bounds.size.height)]) {
        _coverView = view;
        UIImage *blur = [_coverView screenshot];
        self.image = [blur boxblurImageWithBlur:kRNDefaultBlurScale];
    }
    return self;
}


@end

#pragma mark - RNCloseButton

@implementation RNCloseButton

- (id)init{
    if(!(self = [super initWithFrame:(CGRect){0, 0, 32, 32}])){
        return nil;
    }
    static UIImage *closeButtonImage;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        closeButtonImage = [self closeButtonImage];
    });
    [self setBackgroundImage:closeButtonImage forState:UIControlStateNormal];
    return self;
}

- (UIImage *)closeButtonImage{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0);
    
    //// General Declarations
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //// Color Declarations
    UIColor *topGradient = [UIColor colorWithRed:0.21 green:0.21 blue:0.21 alpha:0.9];
    UIColor *bottomGradient = [UIColor colorWithRed:0.03 green:0.03 blue:0.03 alpha:0.9];
    
    //// Gradient Declarations
    NSArray *gradientColors = @[(id)topGradient.CGColor,
    (id)bottomGradient.CGColor];
    CGFloat gradientLocations[] = {0, 1};
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)gradientColors, gradientLocations);
    
    //// Shadow Declarations
    CGColorRef shadow = [UIColor blackColor].CGColor;
    CGSize shadowOffset = CGSizeMake(0, 1);
    CGFloat shadowBlurRadius = 3;
    CGColorRef shadow2 = [UIColor blackColor].CGColor;
    CGSize shadow2Offset = CGSizeMake(0, 1);
    CGFloat shadow2BlurRadius = 0;
    
    
    //// Oval Drawing
    UIBezierPath *ovalPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(4, 3, 24, 24)];
    CGContextSaveGState(context);
    [ovalPath addClip];
    CGContextDrawLinearGradient(context, gradient, CGPointMake(16, 3), CGPointMake(16, 27), 0);
    CGContextRestoreGState(context);
    
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context, shadowOffset, shadowBlurRadius, shadow);
    [[UIColor whiteColor] setStroke];
    ovalPath.lineWidth = 2;
    [ovalPath stroke];
    CGContextRestoreGState(context);
    
    
    //// Bezier Drawing
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint:CGPointMake(22.36, 11.46)];
    [bezierPath addLineToPoint:CGPointMake(18.83, 15)];
    [bezierPath addLineToPoint:CGPointMake(22.36, 18.54)];
    [bezierPath addLineToPoint:CGPointMake(19.54, 21.36)];
    [bezierPath addLineToPoint:CGPointMake(16, 17.83)];
    [bezierPath addLineToPoint:CGPointMake(12.46, 21.36)];
    [bezierPath addLineToPoint:CGPointMake(9.64, 18.54)];
    [bezierPath addLineToPoint:CGPointMake(13.17, 15)];
    [bezierPath addLineToPoint:CGPointMake(9.64, 11.46)];
    [bezierPath addLineToPoint:CGPointMake(12.46, 8.64)];
    [bezierPath addLineToPoint:CGPointMake(16, 12.17)];
    [bezierPath addLineToPoint:CGPointMake(19.54, 8.64)];
    [bezierPath addLineToPoint:CGPointMake(22.36, 11.46)];
    [bezierPath closePath];
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context, shadow2Offset, shadow2BlurRadius, shadow2);
    [[UIColor whiteColor] setFill];
    [bezierPath fill];
    CGContextRestoreGState(context);
    
    
    //// Cleanup
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end

#pragma mark - UIView + Screenshot

@implementation UIView (Screenshot)

- (UIImage*)screenshot {
    UIGraphicsBeginImageContext(self.bounds.size);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // hack, helps w/ our colors when blurring
    NSData *imageData = UIImageJPEGRepresentation(image, 1); // convert to jpeg
    image = [UIImage imageWithData:imageData];
    
    return image;
}

@end

#pragma mark - UIImage + Blur

@implementation UIImage (Blur)

-(UIImage *)boxblurImageWithBlur:(CGFloat)blur {
    if (blur < 0.f || blur > 1.f) {
        blur = 0.5f;
    }
    int boxSize = (int)(blur * 40);
    boxSize = boxSize - (boxSize % 2) + 1;
    
    CGImageRef img = self.CGImage;
    
    vImage_Buffer inBuffer, outBuffer;
    
    vImage_Error error;
    
    void *pixelBuffer;
    
    
    //create vImage_Buffer with data from CGImageRef
    
    CGDataProviderRef inProvider = CGImageGetDataProvider(img);
    CFDataRef inBitmapData = CGDataProviderCopyData(inProvider);

    
    inBuffer.width = CGImageGetWidth(img);
    inBuffer.height = CGImageGetHeight(img);
    inBuffer.rowBytes = CGImageGetBytesPerRow(img);
    
    inBuffer.data = (void*)CFDataGetBytePtr(inBitmapData);
    
    //create vImage_Buffer for output
    
    pixelBuffer = malloc(CGImageGetBytesPerRow(img) * CGImageGetHeight(img));
    
    if(pixelBuffer == NULL)
        NSLog(@"No pixelbuffer");
    
    outBuffer.data = pixelBuffer;
    outBuffer.width = CGImageGetWidth(img);
    outBuffer.height = CGImageGetHeight(img);
    outBuffer.rowBytes = CGImageGetBytesPerRow(img);
    
    // Create a third buffer for intermediate processing
    void *pixelBuffer2 = malloc(CGImageGetBytesPerRow(img) * CGImageGetHeight(img));
    vImage_Buffer outBuffer2;
    outBuffer2.data = pixelBuffer2;
    outBuffer2.width = CGImageGetWidth(img);
    outBuffer2.height = CGImageGetHeight(img);
    outBuffer2.rowBytes = CGImageGetBytesPerRow(img);
    
    //perform convolution
    error = vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer2, NULL, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
    if (error)
        NSLog(@"error from convolution %ld", error);

    error = vImageBoxConvolve_ARGB8888(&outBuffer2, &inBuffer, NULL, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
    if (error)
        NSLog(@"error from convolution %ld", error);

    error = vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, NULL, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
    if (error)
        NSLog(@"error from convolution %ld", error);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(outBuffer.data,
                                             outBuffer.width,
                                             outBuffer.height,
                                             8,
                                             outBuffer.rowBytes,
                                             colorSpace,
                                             kCGImageAlphaNoneSkipLast);
    CGImageRef imageRef = CGBitmapContextCreateImage (ctx);
    UIImage *returnImage = [UIImage imageWithCGImage:imageRef];
    
    //clean up
    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);
    
    free(pixelBuffer);
    CFRelease(inBitmapData);
    
    CGImageRelease(imageRef);
    
    return returnImage;
}

@end
