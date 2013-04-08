//
//  RNBlurMessageView.m
//  CamFind
//
//  Created by Bradford Folkens on 3/10/13.
//  Copyright (c) 2013 Image Searcher Inc. All rights reserved.
//

#import <Accelerate/Accelerate.h>
#import <QuartzCore/QuartzCore.h>
#import "RNBlurMessageView.h"
#import "UIView+Sizes.h"

@interface UILabel (AutoSize)
- (void)autoHeight;
@end


const CGFloat padding = 10.0f;

@implementation RNBlurMessageView

- (id)initWithFrame:(CGRect)frame withTitle:(NSString *)title withMessage:(NSString *)message
{
    self = [super initWithFrame:frame];
    if (self) {
        UIColor *whiteColor = [UIColor colorWithRed:0.816 green:0.788 blue:0.788 alpha:1.000];
        
        self.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.8f];
        self.layer.borderColor = whiteColor.CGColor;
        self.layer.borderWidth = 2.f;
        self.layer.cornerRadius = 10.f;
        
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(padding, 0, self.frame.size.width - padding * 2.f, 0)];
        self.titleLabel.text = title;
        self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:17.f];
        self.titleLabel.textColor = [UIColor whiteColor];
        self.titleLabel.shadowColor = [UIColor blackColor];
        self.titleLabel.shadowOffset = CGSizeMake(0, -1);
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.backgroundColor = [UIColor clearColor];
        [self.titleLabel autoHeight];
        self.titleLabel.top = padding;
        [self addSubview:self.titleLabel];
        
        self.messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(padding, 0, self.frame.size.width - padding * 2.f, 0)];
        self.messageLabel.text = message;
        self.messageLabel.numberOfLines = 0;
        self.messageLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:17.f];
        self.messageLabel.textColor = self.titleLabel.textColor;
        self.messageLabel.shadowOffset = self.titleLabel.shadowOffset;
        self.messageLabel.shadowColor = self.titleLabel.shadowColor;
        self.messageLabel.textAlignment = NSTextAlignmentCenter;
        self.messageLabel.backgroundColor = [UIColor clearColor];
        [self.messageLabel autoHeight];
        self.messageLabel.top = self.titleLabel.bottom + padding;
        [self addSubview:self.messageLabel];
        
        self.height = self.messageLabel.bottom + padding;
        
        self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    }
    return self;
}

- (void)setTitle:(NSString *)title
{
    [self.titleLabel setText:title];
    [self.titleLabel autoHeight];
}

- (void)setMessage:(NSString *)message
{
    [self.messageLabel setText:message];
    [self.messageLabel autoHeight];
}

@end

#pragma mark - UILabel + Autosize

@implementation UILabel (AutoSize)

- (void)autoHeight {
    CGRect frame = self.frame;
    CGSize maxSize = CGSizeMake(frame.size.width, 9999);
    CGSize expectedSize = [self.text sizeWithFont:self.font constrainedToSize:maxSize lineBreakMode:self.lineBreakMode];
    frame.size.height = expectedSize.height;
    [self setFrame:frame];
}

@end
