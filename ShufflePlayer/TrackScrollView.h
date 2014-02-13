//
//  TrackScrollView.h
//  ShufflePlayer
//
//  Created by Keiichiro Watanabe on 2014/02/11.
//  Copyright (c) 2014年 ahomegane. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TrackScrollView : UIScrollView

- (id)initWithFrame:(CGRect)frame withAccountManagerInstance:accountManager;
- (void)initElement;
- (void)setTrackInfo:(NSDictionary *)track;
- (void)updateWaveform:(float)currentTime withTrackDuration:(float)duration;
@property(retain, nonatomic) UIImage *artworkImage;
@property(retain, nonatomic) NSString *title;

@end
