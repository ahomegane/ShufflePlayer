//
//  LoadIndicator.m
//  ShufflePlayer
//
//  Created by k-watanabe on 2014/02/18.
//  Copyright (c) 2014年 ahomegane. All rights reserved.
//

#import "LoadIndicator.h"

@interface LoadIndicator () {
    CABasicAnimation* _animation;
}
@end

@implementation LoadIndicator

#pragma mark - Initialize

- (id)init
{
    self = [super init];
    if (self) {
        UIImage* image = [UIImage imageNamed:@"loading_indicator"];
        self.image = image;
        self.frame = CGRectMake(0, 0, image.size.width, image.size.height);
        _animation = [self makeAnimation];
    }
    return self;
}

#pragma mark - Instance Method

- (void)startAnimating
{
    [self.layer addAnimation:_animation
                      forKey:@"rotate"];
}

- (void)stopAnimating
{
    [self.layer removeAnimationForKey:@"rotate"];
}

#pragma mark - Private Method

- (CABasicAnimation*)makeAnimation
{
    CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    animation.duration = 0.7;
    animation.repeatCount = HUGE_VALF;
    animation.beginTime = CACurrentMediaTime();
    animation.fromValue = @0.0f; // 開始時の角度
    animation.toValue = [NSNumber numberWithFloat:2 * M_PI]; // 終了時の角度
    //  animation.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseIn];
    return animation;
}

@end
