//
//  RNBlurMessageView.h
//  CamFind
//
//  Created by Bradford Folkens on 3/10/13.
//  Copyright (c) 2013 Image Searcher Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RNBlurMessageView : UIView

@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) UILabel *messageLabel;

- (id)initWithFrame:(CGRect)frame withTitle:(NSString *)title withMessage:(NSString *)message;
- (void)setTitle:(NSString *)title;
- (void)setMessage:(NSString *)message;

@end
