//
//  TrackScrollView.h
//  ShufflePlayer
//
//  Created by Keiichiro Watanabe on 2014/02/11.
//  Copyright (c) 2014年 ahomegane. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AccountManager.h"

@interface TrackScrollView : UIScrollView

- (id)initWithFrame:(CGRect)frame withAccountManagerInstance:(AccountManager*) accountManager;
- (void)initElement;
- (void)setTrackInfo:(NSDictionary *)track;
- (void)updateWaveform:(float)currentTime withTrackDuration:(float)duration;
- (void)audioDataBeginLoading;
- (void)audioDataEndLoading;
@property(retain, nonatomic) UIImage *artworkImage;
@property(retain, nonatomic) NSString *title;

@end
