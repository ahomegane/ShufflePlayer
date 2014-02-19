//
//  OpeningView.h
//  ShufflePlayer
//
//  Created by k-watanabe on 2014/02/18.
//  Copyright (c) 2014年 ahomegane. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STDeferred.h"

@interface OpeningView : UIView

- (void)fadeOut;
- (STDeferred*)fadeIn;

@end
