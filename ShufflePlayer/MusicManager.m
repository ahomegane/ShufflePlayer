//
//  MusicManager.m
//  ShufflePlayer
//
//  Created by k-watanabe on 2014/02/07.
//  Copyright (c) 2014年 ahomegane. All rights reserved.
//

#import "MusicManager.h"
#import "SCUI.h"
#import "Constants.h"

@interface MusicManager () {

  AVPlayer *_player;
  AVPlayerItem *_playerItem;

  int _trackIndex;
  NSMutableArray *_tracks;

  NSTimer *_sequenceTimer;
}
@end

@implementation MusicManager

@synthesize delegate, genreList, playing;

#pragma mark - Initialize

- (id)init {
  self = [super init];
  if (self) {
    // genreList
    NSMutableArray *tmp = [[NSMutableArray alloc] init];
    int i = 0;
    while (GENRE_LIST[i] != nil) {
      [tmp addObject:GENRE_LIST[i]];
      i++;
    }
    self.genreList = [tmp copy];
  }
  return self;
}

#pragma mark - Instance Method

- (BOOL)play {
  if (_player == nil) {
    [self getAudioData:[self fetchCurrentTrack] withLoadedCallback:^()
     {
      [self setPlaySequence];
      [_player play];
    }];
  } else {
    [self setPlaySequence];
    [_player play];
  }
  return YES;
}

- (BOOL)pause {
  [self clearPlaySequence];
  [_player pause];
  return YES;
}

- (BOOL)playing {
  return _player.rate != 0.0 ? YES : NO;
}

- (NSDictionary *)fetchCurrentTrack {
  return [_tracks objectAtIndex:_trackIndex];
}

- (NSDictionary *)fetchPrevTrack {
  if (_trackIndex - 1 < 0)
    return nil;
  return [_tracks objectAtIndex:_trackIndex - 1];
}

- (NSDictionary *)fetchNextTrack {
  if (_trackIndex + 1 > [_tracks count] - 1)
    return nil;
  return [_tracks objectAtIndex:_trackIndex + 1];
}

- (void)changeGenre:(NSArray *)genres
    withForcePlayFlag:(BOOL)isForcePlay
         withInitFlag:(BOOL)isInit {
  [self.delegate changeGenreBefore:isInit];

  //    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
  //                            @"cef5e6d3c083503120892b041572abff",
  // @"client_id",
  //                            @"ahomegane", @"q",
  //                            @"hiphop", @"genres",
  //                            @"japan", @"tags",
  //                            @"public,streamable", @"filter",//効かない
  //                            nil];
  NSDictionary *params = [NSDictionary
      dictionaryWithObjectsAndKeys:SC_CLIENT_ID, @"client_id",
                                   [genres componentsJoinedByString:@","],
                                   @"genres", nil];

  SCRequestResponseHandler handler =
      ^(NSURLResponse * response, NSData * data, NSError * error) {
    NSError *jsonError = nil;
    NSJSONSerialization *jsonResponse =
        [NSJSONSerialization JSONObjectWithData:data
                                        options:0
                                          error:&jsonError];
    if (!jsonError && [jsonResponse isKindOfClass:[NSArray class]]) {
      _tracks = [(NSArray *)jsonResponse mutableCopy];
      _tracks = [self randomSortTracks:[self filterTracks:_tracks]];
      _trackIndex = 0;
      [self changeTrack:[self fetchCurrentTrack] withFlagForcePlay:isForcePlay];
    }
    [self.delegate changeGenreComplete:[_tracks count] withInitFlag:isInit];
  };

  [SCRequest performMethod:SCRequestMethodGET
                  onResource:[NSURL URLWithString:SC_TRACK_REQUEST_URL]
             usingParameters:params
                 withAccount:nil
      sendingProgressHandler:nil
             responseHandler:handler];
}

#pragma mark - Private Method

#pragma mark Init Tracks JSON

- (NSMutableArray *)filterTracks:(NSMutableArray *)tracks {
  for (int i = 0; i < [tracks count]; i++) {
    NSDictionary *track = [tracks objectAtIndex:i];
    //        int favorite = [[_track objectForKey:@"favoritings_count"]
    // intValue];
    //        int contentSize = [[_track objectForKey:@"original_content_size"]
    // intValue] /  1000000;
    BOOL streamable = [[track objectForKey:@"streamable"] boolValue];
    NSString *format = [track objectForKey:@"original_format"];
    NSString *sharing = [track objectForKey:@"sharing"];
    if (!streamable || [format isEqualToString:@"wav"] ||
        ![sharing isEqualToString:@"public"]) { // contentSize > 7 || favorite <
                                                // 3
      [tracks removeObjectAtIndex:i];
      i--;
    }
  }
  return tracks;
}

- (NSMutableArray *)randomSortTracks:(NSMutableArray *)tracks {
  int count = [tracks count];
  for (int i = count - 1; i > 0; i--) {
    int randomNum = arc4random() % i;
    [tracks exchangeObjectAtIndex:i withObjectAtIndex:randomNum];
  }
  return tracks;
}

- (void)changeTrack:(NSDictionary *)newTrack
    withFlagForcePlay:(BOOL)isForcePlay {

  NSLog(@"%@", [newTrack objectForKey:@"original_format"]);

  // updateAudioData で _player が更新される前の状態を保存
  BOOL isPlaying = self.playing;
  if (isForcePlay) {
    isPlaying = YES;
  }
  _player = nil;
  [self.delegate didChangeTrack:newTrack withPlayingBeforeChangeFlag:isPlaying];
}

- (void)prevTrack:(BOOL)isFrocePlay {
  if (_trackIndex == 0)
    return;
  _trackIndex--;
  [self changeTrack:[self fetchCurrentTrack] withFlagForcePlay:isFrocePlay];
}

- (void)nextTrack:(BOOL)isFrocePlay {
  if (_trackIndex == [_tracks count] - 1)
    return;
  _trackIndex++;
  [self changeTrack:[self fetchCurrentTrack] withFlagForcePlay:isFrocePlay];
}

#pragma mark MusicPlayer Instance

- (void)getAudioData:(NSDictionary *)newTrack
    withLoadedCallback:(void (^)())callback {
  [self.delegate getAudioDataBefore];

  NSString *streamUrl = [NSString
      stringWithFormat:@"%@?client_id=%@",
                       [newTrack objectForKey:@"stream_url"], SC_CLIENT_ID];

  NSLog(@"%@", streamUrl);
  _playerItem =
      [[AVPlayerItem alloc] initWithURL:[NSURL URLWithString:streamUrl]];
  NSString *ItemStatusContext;
  [_playerItem addObserver:self
                forKeyPath:@"status"
                   options:0
                   context:&ItemStatusContext];
  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(playerItemDidReachEnd:)
             name:AVPlayerItemDidPlayToEndTimeNotification
           object:_playerItem];

  _player = [AVPlayer playerWithPlayerItem:_playerItem];

  if (callback != nil) {
    callback();
  }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
  NSLog(@"%@", NSStringFromSelector(_cmd));
  if (object == _playerItem && [keyPath isEqualToString:@"status"]) {

    if (_playerItem.status == AVPlayerStatusReadyToPlay) {
      NSLog(@"AVPlayerStatusReadyToPlay");
      [self.delegate getAudioDataReadyToPlay];
    } else if (_playerItem.status == AVPlayerStatusFailed) {
      NSLog(@"AVPlayerStatusFailed");
    } else if (_playerItem.status == AVPlayerStatusUnknown) {
      NSLog(@"AVPlayerStatusUnknown");
    } else if (_playerItem.status == AVPlayerItemStatusReadyToPlay) {
      NSLog(@"AVPlayerItemStatusReadyToPlay");
    } else if (_playerItem.status == AVPlayerItemStatusFailed) {
      NSLog(@"AVPlayerItemStatusFailed");
    } else if (_playerItem.status == AVPlayerItemStatusUnknown) {
      NSLog(@"AVPlayerItemStatusUnknown");
    } else if (_playerItem.status == AVPlayerActionAtItemEndAdvance) {
      NSLog(@"AVPlayerActionAtItemEndAdvance");
    } else if (_playerItem.status == AVPlayerActionAtItemEndNone) {
      NSLog(@"AVPlayerActionAtItemEndNone");
    } else if (_playerItem.status == AVPlayerActionAtItemEndPause) {
      NSLog(@"AVPlayerActionAtItemEndPause");
    }

    if (context == AVPlayerItemDidPlayToEndTimeNotification) {
      NSLog(@"AVPlayerItemDidPlayToEndTimeNotification");
    } else if (context == AVPlayerItemFailedToPlayToEndTimeErrorKey) {
      NSLog(@"AVPlayerItemFailedToPlayToEndTimeErrorKey");
    } else if (context == AVPlayerItemFailedToPlayToEndTimeNotification) {
      NSLog(@"AVPlayerItemFailedToPlayToEndTimeNotification");
    } else if (context == AVPlayerItemNewAccessLogEntryNotification) {
      NSLog(@"AVPlayerItemNewAccessLogEntryNotification");
    } else if (context == AVPlayerItemNewErrorLogEntryNotification) {
      NSLog(@"AVPlayerItemNewErrorLogEntryNotification");
    } else if (context == AVPlayerItemPlaybackStalledNotification) {
      NSLog(@"AVPlayerItemPlaybackStalledNotification");
    } else if (context == AVPlayerItemTimeJumpedNotification) {
      NSLog(@"AVPlayerItemTimeJumpedNotification");
    }
  }
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
  [self nextTrack:YES];
}

#pragma mark Play Sequence

- (void)playSequence {
  if (self.playing) {
    float currentTime = CMTimeGetSeconds(_player.currentTime);
    float duration = CMTimeGetSeconds(_player.currentItem.asset.duration);

    [self.delegate playSequenceOnPlaying:currentTime
                       withTrackDuration:duration];
  }
}

- (void)setPlaySequence {
  _sequenceTimer =
      [NSTimer scheduledTimerWithTimeInterval:0.1
                                       target:self
                                     selector:@selector(playSequence)
                                     userInfo:nil
                                      repeats:YES];
}

- (void)clearPlaySequence {
  [_sequenceTimer invalidate];
  _sequenceTimer = nil;
}

@end
