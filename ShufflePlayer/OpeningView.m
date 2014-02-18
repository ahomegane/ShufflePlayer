//
//  OpeningView.m
//  ShufflePlayer
//
//  Created by k-watanabe on 2014/02/18.
//  Copyright (c) 2014年 ahomegane. All rights reserved.
//

#import "OpeningView.h"
#import "LoadIndicator.h"
#import "STDeferred.h"

@interface OpeningView() {
  UIImageView *_blur;
  UIImageView *_logo;
  LoadIndicator* _indicator;
}
@end

@implementation OpeningView

#pragma mark - Initialize

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    
    UIColor *bgImage = [UIColor colorWithPatternImage:[UIImage imageNamed:@"opening_bg"]];
    self.backgroundColor = bgImage;
    
    UIImage * blurImage = [UIImage imageNamed:@"opening_logo_blur"];
    UIImage * logoImage = [UIImage imageNamed:@"opening_logo"];
    
    CGRect logoFrame = CGRectMake(self.center.x - logoImage.size.width / 2, 154, logoImage.size.width, logoImage.size.height);
    
    _logo = [[UIImageView alloc] initWithImage:logoImage];
    _logo.frame = logoFrame;
    _logo.layer.opacity = 0;
    [self addSubview:_logo];
    
    _blur = [[UIImageView alloc] initWithImage:blurImage];
    _blur.frame = logoFrame;
    _blur.layer.opacity = 0;
    [self addSubview:_blur];
    
    UIImage * scLogoImage = [UIImage imageNamed:@"opening_sc_logo"];
    UIButton *scLogoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [scLogoButton setImage:scLogoImage forState:UIControlStateNormal];
    scLogoButton.frame = CGRectMake(self.center.x - scLogoImage.size.width / 2, self.frame.size.height - 78, scLogoImage.size.width, scLogoImage.size.height);
    [scLogoButton addTarget:self
                     action:@selector(touchScLogoButton:)
           forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:scLogoButton];
    
    _indicator = [[LoadIndicator alloc] init];
    _indicator.center = self.center;
    [self addSubview:_indicator];
  }
  return self;
}

#pragma mark - Instance Method

- (void)fadeIn {
  [self fadeInLogo];
  [_indicator startAnimating];
}

#pragma mark - Private Method

- (void)touchScLogoButton:(id)sender {
  NSURL *url = [NSURL URLWithString:@"http://soundcloud.com"];
  [[UIApplication sharedApplication] openURL:url];
}

- (void)fadeInLogo {
  CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
  animation.delegate = self;
  
  animation.duration = 600 / 1000;
  animation.fromValue = [NSNumber numberWithFloat:0.0];
  animation.toValue = [NSNumber numberWithFloat:1.0];
  animation.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseOut];
  animation.removedOnCompletion = NO;
  animation.fillMode = kCAFillModeForwards;
  
  [_logo.layer addAnimation:animation forKey:@"fadeIn"];
}

- (void)fadeOut {
  CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
  animation.delegate = self;
  
  animation.duration = 800 / 1000;
  animation.repeatCount = 1;
  animation.beginTime = CACurrentMediaTime();
  animation.fromValue = [NSNumber numberWithFloat:1.0];
  animation.toValue = [NSNumber numberWithFloat:0.0];
  animation.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseIn];
  animation.removedOnCompletion = NO;
  animation.fillMode = kCAFillModeForwards;
  
  [_indicator stopAnimating];
  [self.layer addAnimation:animation forKey:@"fadeOut"];
}

#pragma mark - Animation Delegate

- (void)animationDidStop:(CAAnimation *)animation finished:(BOOL)flag
{
  if (animation == [_logo.layer animationForKey:@"fadeIn"]) {
    [STDeferred timeout:2000 / 1000].then(^(id ret) {
      [self fadeOut];
    });
  }
  if (animation == [self.layer animationForKey:@"fadeOut"]) {
    self.hidden = YES;
    [self.layer removeAnimationForKey:@"fadeOut"];
  }
}

@end
