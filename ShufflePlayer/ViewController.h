//
//  ViewController.h
//  ShufflePlayer
//
//  Created by Keiichiro Watanabe on 2013/10/17.
//  Copyright (c) 2013年 ahomegane. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "MusicManager.h"
#import "AccountManager.h"
#import "GenreListViewController.h"

@interface ViewController : UIViewController <MusicManagerDelegate, GenreListViewControllerDelegate,AccountManagerDelegate, AVAudioSessionDelegate>

// delegate MusicManager
- (void)changeGenreBefore;
- (void)changeGenreComplete;
- (void)changeTrackBefore:(NSDictionary *)newTrack withplayingBeforeChangeTrackFlag:(BOOL)isPlaying;
- (void)changeTrackComplete:(NSDictionary *)newTrack withplayingBeforeChangeTrackFlag:(BOOL)isPlaying;
- (void)playSequenceOnPlaying:(float)currentTime
            withTrackDuration:(float)duration;

// delegate AccountManager
- (void)showModal:(id)view;

// delegate GenreListViewController
- (void)selectGenre:(NSArray *)genreList;

@end
