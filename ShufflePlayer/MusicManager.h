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

- (void)changeGenreBefore;
- (void)changeGenreComplete;
- (void)changeTrackBefore:(NSDictionary *)newTrack withplayingBeforeChangeTrackFlag:(BOOL)isPlaying;
- (void)changeTrackComplete:(NSDictionary *)newTrack withplayingBeforeChangeTrackFlag:(BOOL)isPlaying;
- (void)playSequenceOnPlaying:(float)currentTime
            withTrackDuration:(float)duration;

@end

@interface MusicManager : NSObject {
  id<MusicManagerDelegate> delegate;
}

- (NSDictionary *)fetchCurrentTrack;
- (BOOL)play;
- (BOOL)pause;
- (void)changeGenre:(NSArray *)genres withFlagForcePlay:(BOOL)isForcePlay;
- (void)prevTrack:(BOOL)isFrocePlay;
- (void)nextTrack:(BOOL)isFrocePlay;
@property(retain, nonatomic) id<MusicManagerDelegate> delegate;
@property(retain, nonatomic) NSArray* genreList;
@property(readonly) BOOL playing;

@end
