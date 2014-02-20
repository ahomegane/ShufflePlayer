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

@synthesize delegate, genres, genreNameList, playing;

#pragma mark - Initialize

- (id)init {
  self = [super init];
  if (self) {

    self.genreNameList = @[
      @"All",
      @"Techno",
      @"House",
      @"HipHop / BreakBeats",
      @"Electronica / Experimental",
      @"Downtempo / Ambient",
      @"Rock / Punk",
      @"Reggae / Dub",
      @"Soul / R&B",
      @"Jazz / Funk",
      @"Acoustic / World",
      @"Pop",
      @"Japanese"
    ];
    // genreList
    NSMutableDictionary *tmp =
        [@{
           @"Techno" : @[ @"techno,drumn" ],
           @"House" : @[ @"house,disco" ],
           @"HipHop / BreakBeats" : @[ @"hiphop,breakbeats,rap,triphop" ],
           @"Electronica / Experimental" :
           @[ @"electronica,experimental,postrock" ],
           @"Downtempo / Ambient" :
           @[ @"downtempo,ambient,chill,soudtrack,mellow" ],
           @"Rock / Punk" : @[ @"rock,punk,metal" ],
           @"Reggae / Dub" : @[ @"reggae,dub" ],
           @"Soul / R&B" : @[ @"soul,r&b,blues" ],
           @"Jazz / Funk" : @[ @"jazz,funk" ],
           @"Acoustic / World" :
           @[ @"acoustic,folk,countroy,samba,bossanova,afro" ],
           @"Pop" : @[ @"pop" ],
           @"Japanese" : @[ @"japanese,jpop" ]
         } mutableCopy];

    NSMutableArray *all = [@[] mutableCopy];
    for (id key in [tmp keyEnumerator]) {
      [all addObjectsFromArray:tmp[key]];
    }
    tmp[@"All"] = (NSArray *)all;
    self.genres = tmp;
  }
  return self;
}

#pragma mark - Instance Method

- (BOOL)play {
  if (_player == nil) {
    [self getAudioData:[self fetchCurrentTrack] withLoadedCallback:^()
    {
      [self startPlaySequence];
      [_player play];
    }];
  } else {
    [self startPlaySequence];
    [_player play];
  }
  return YES;
}

- (BOOL)pause {
  [self clearPlaySequence];
  [_player pause];
  return YES;
}

- (void)seekWithRate:(float)rate {
  float duration = CMTimeGetSeconds(_player.currentItem.asset.duration);
  Float64 seconds = rate * duration;

  [self seekWithSeconds:seconds duration:duration];
}

- (void)seekWithSeconds:(Float64)seconds duration:(float)duration {
  [self clearPlaySequence];
  if (_player.status == AVPlayerStatusReadyToPlay &&
      _player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
    CMTime targetTime = CMTimeMakeWithSeconds(seconds, NSEC_PER_SEC);
    [_player seekToTime:targetTime
        toleranceBefore:kCMTimeZero
         toleranceAfter:kCMTimeZero];

    [self.delegate playSequenceOnPlaying:seconds withTrackDuration:duration];
  }
  [self startPlaySequence];
}

- (BOOL)playing {
  return _player.rate != 0.0 ? YES : NO;
}

- (NSMutableDictionary *)fetchCurrentTrack {
  return _tracks[_trackIndex];
}

- (NSMutableDictionary *)fetchPrevTrack {
  if (_trackIndex - 1 < 0)
    return nil;
  return _tracks[_trackIndex - 1];
}

- (NSMutableDictionary *)fetchNextTrack {
  if (_trackIndex + 1 > [_tracks count] - 1)
    return nil;
  return _tracks[_trackIndex + 1];
}

- (void)changeGenre:(NSString *)genreName
    withForcePlayFlag:(BOOL)isForcePlay
         withInitFlag:(BOOL)isInit {
  [self.delegate changeGenreBefore:isInit];

  NSDictionary *params = @{
    @"client_id" : SC_CLIENT_ID,
    @"tags" : [self.genres[genreName] componentsJoinedByString:@","],
    @"order" : @"created_at",
    @"limit" : @"100",
    @"filter" : @"streamable"
  };

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
        
      [self saveSelectedGenreToUserDefault:genreName];
      [self.delegate changeGenreComplete:[_tracks count] withInitFlag:isInit error: error];
    }
  };
  NSLog(@"%@", params);
  [SCRequest performMethod:SCRequestMethodGET
                  onResource:[NSURL URLWithString:SC_TRACK_REQUEST_URL]
             usingParameters:params
                 withAccount:nil
      sendingProgressHandler:nil
             responseHandler:handler];
}

- (NSString *)replaceArtworkSize:(NSString*)defaultUrl withReplaceSize:(NSString*) replaceSize {
  NSRegularExpression *regexp = [NSRegularExpression
                                 regularExpressionWithPattern:@"^(.+?)\\-[^\\-]+?\\.(.+?)$"
                                 options:0
                                 error:nil];
  NSString *url = [regexp stringByReplacingMatchesInString:defaultUrl
                               options:0
                               range:NSMakeRange(0, defaultUrl.length)
                               withTemplate:
                               [NSString stringWithFormat:@"$1-%@.$2",
                                replaceSize]];
  return url;
}

#pragma mark - Private Method

#pragma mark Init Tracks JSON

- (NSMutableArray *)filterTracks:(NSMutableArray *)tracks {
  for (int i = 0; i < [tracks count]; i++) {
    NSMutableDictionary *track = [tracks[i] mutableCopy];
    BOOL streamable = [track[@"streamable"] boolValue];
    NSString *format = track[@"original_format"];
    NSString *sharing = track[@"sharing"];

    // 削除
    if (!streamable || [format isEqualToString:@"wav"] ||
        ![sharing isEqualToString:@"public"]) {
      [tracks removeObjectAtIndex:i];
      i--;
    } else {
      tracks[i] = track;
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

- (void)changeTrack:(NSMutableDictionary *)newTrack
    withFlagForcePlay:(BOOL)isForcePlay {

  NSLog(@"%@", newTrack[@"original_format"]);

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

- (void)getAudioData:(NSMutableDictionary *)newTrack
    withLoadedCallback:(void (^)())callback {
  [self.delegate getAudioDataBefore];

  NSString *streamUrl =
      [NSString stringWithFormat:@"%@?client_id=%@", newTrack[@"stream_url"],
                                 SC_CLIENT_ID];

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
  [self.delegate endTrack];
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

- (void)startPlaySequence {
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

#pragma mark - UserDefault Control

- (BOOL)saveSelectedGenreToUserDefault:(NSString *)genreName {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:genreName forKey:@"genreName"];
  BOOL isSuccess = [defaults synchronize];
  return isSuccess;
}

- (NSString *)restoreSelectedGenreFromUserDefault {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *genreName = [defaults objectForKey:@"genreName"];
  return genreName;
}

@end
