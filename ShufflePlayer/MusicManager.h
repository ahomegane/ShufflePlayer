//
//  MusicManager.h
//  ShufflePlayer
//
//  Created by k-watanabe on 2014/02/07.
//  Copyright (c) 2014年 ahomegane. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@protocol MusicManagerDelegate

- (void)changeGenreBefore:(BOOL)isInit;
- (void)changeGenreComplete:(int)tracksCount withInitFlag:(BOOL)isInit;
- (void)getAudioDataBefore;
- (void)getAudioDataReadyToPlay;
- (void)didChangeTrack:(NSDictionary *)newTrack
    withPlayingBeforeChangeFlag:(BOOL)isPlaying;
- (void)playSequenceOnPlaying:(float)currentTime
            withTrackDuration:(float)duration;

@end

@interface MusicManager : NSObject

- (NSDictionary *)fetchCurrentTrack;
- (NSDictionary *)fetchPrevTrack;
- (NSDictionary *)fetchNextTrack;
- (BOOL)play;
- (BOOL)pause;
- (void)changeGenre:(NSArray *)genres
    withForcePlayFlag:(BOOL)isForcePlay
         withInitFlag:(BOOL)isInit;
- (void)prevTrack:(BOOL)isFrocePlay;
- (void)nextTrack:(BOOL)isFrocePlay;
@property(retain, nonatomic) id<MusicManagerDelegate> delegate;
@property(retain, nonatomic) NSArray *genreList;
@property(readonly) BOOL playing;

@end
