//
//  ViewController.m
//  ShufflePlayer
//
//  Created by Keiichiro Watanabe on 2013/10/17.
//  Copyright (c) 2013年 ahomegane. All rights reserved.
//

// Class分け
#import "SCUI.h"
#import "ViewController.h"
#import "TrackListViewController.h"

@interface ViewController () {

  BOOL _isInterruptionBeginInPlayFlag;

  AVPlayer* _player;
  AVPlayerItem* _playerItem;

  SCAccount* _scAccount;

  NSMutableArray* _tracks;
  int _trackIndex;
  NSString* _permalinkUrl;

  UIImageView* _artworkImageView;
  UIImageView* _waveformImageView;
  UIImageView* _waveformSequenceView;
  UIButton* _titleButton;
  UIButton* _playButton;
  UIImage* _playImage;
  UIImage* _stopImage;

  GenreListViewController* _genreListVC;
  NSArray* _genreList;

  // ローディング
  UIView* _loadingView;
  UIActivityIndicatorView* _indicator;
}
@end

@implementation ViewController

NSString* const _SC_CLIENT_ID = @"cef5e6d3c083503120892b041572abff";
NSString* const _ARTWORK_IMAGE_SIZE = @"t500x500";
NSString* const _SC_TRACK_REQUEST_URL =
    @"https://api.soundcloud.com/tracks.json";
NSString* const _SC_LIKE_URL = @"https://api.soundcloud.com/me/favorites/";

- (void)viewDidLoad {
  [super viewDidLoad];
  
//  [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"scAccount"];

  // sequence timer
  [NSTimer scheduledTimerWithTimeInterval:0.1
                                   target:self
                                 selector:@selector(playSequence)
                                 userInfo:nil
                                  repeats:YES];

  // バックグラウンド再生
  AVAudioSession* audioSession = [AVAudioSession sharedInstance];
  [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
  [audioSession setActive:YES error:nil];

  // 音楽再生の割り込み
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self
             selector:@selector(sessionDidInterrupt:)
                 name:AVAudioSessionInterruptionNotification
               object:nil];
  [center addObserver:self
             selector:@selector(sessionRouteDidChange:)
                 name:AVAudioSessionRouteChangeNotification
               object:nil];

  // ロック画面用 remoteControlEventsを受け取り開始
  [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];

  _genreList = [[NSArray alloc] initWithObjects:@"hiphop",
                                                @"electronica",
                                                @"breakbeats",
                                                @"house",
                                                @"techno",
                                                @"pop",
                                                @"rock",
                                                @"japanese",
                                                nil];

  [self initElement];
  [self changeGenre:_genreList withFlagForcePlay:NO];
}

- (void)initElement {
  _artworkImageView = [[UIImageView alloc] init];
  _artworkImageView.contentMode = UIViewContentModeScaleAspectFit;
  _artworkImageView.frame = CGRectMake(30, 70, 260, 260);
  [self.view addSubview:_artworkImageView];

  _waveformSequenceView = [[UIImageView alloc] init];
  _waveformSequenceView.frame = CGRectMake(30, 330, 0, 41);
  _waveformSequenceView.backgroundColor = [UIColor lightGrayColor];
  [self.view addSubview:_waveformSequenceView];

  _waveformImageView = [[UIImageView alloc] init];
  _waveformImageView.contentMode = UIViewContentModeScaleAspectFit;
  _waveformImageView.frame = CGRectMake(30, 330, 260, 41);
  [self.view addSubview:_waveformImageView];

  _titleButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  _titleButton.frame = CGRectMake(30, 380, 260, 20);
  [self.view addSubview:_titleButton];

  _playImage = [UIImage imageNamed:@"button_play.png"];
  _stopImage = [UIImage imageNamed:@"button_stop.png"];
  _playButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  _playButton.frame = CGRectMake(139, 430, 41, 48);
  [_playButton setImage:_playImage forState:UIControlStateNormal];
  [self.view addSubview:_playButton];
  [_playButton addTarget:self
                  action:@selector(touchPlayButton:)
        forControlEvents:UIControlEventTouchUpInside];

  UIImage* prevImage = [UIImage imageNamed:@"button_prev.png"];
  UIButton* prevButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  prevButton.frame = CGRectMake(29, 430, 40, 48);
  [prevButton setImage:prevImage forState:UIControlStateNormal];
  [self.view addSubview:prevButton];
  [prevButton addTarget:self
                 action:@selector(touchPrevButton:)
       forControlEvents:UIControlEventTouchUpInside];

  UIImage* nextImage = [UIImage imageNamed:@"button_next.png"];
  UIButton* nextButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  nextButton.frame = CGRectMake(249, 430, 40, 48);
  [nextButton setImage:nextImage forState:UIControlStateNormal];
  [self.view addSubview:nextButton];
  [nextButton addTarget:self
                 action:@selector(touchNextButton:)
       forControlEvents:UIControlEventTouchUpInside];

  UIButton* genreButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  genreButton.frame = CGRectMake(20, 520, 52, 30);
  [self.view addSubview:genreButton];
  [genreButton setTitle:@"Genre" forState:UIControlStateNormal];
  [genreButton addTarget:self
                  action:@selector(touchGenreButton:)
        forControlEvents:UIControlEventTouchUpInside];

  UIButton* likeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  likeButton.frame = CGRectMake(20, 30, 50, 30);
  [self.view addSubview:likeButton];
  [likeButton setTitle:@"Like" forState:UIControlStateNormal];
  [likeButton addTarget:self
                 action:@selector(touchLikeButton:)
       forControlEvents:UIControlEventTouchUpInside];

  // loading
  _loadingView = [[UIView alloc] initWithFrame:self.view.bounds];
  _loadingView.backgroundColor = [UIColor whiteColor];
  //  _loadingView.alpha = 0.5f;

  _indicator = [[UIActivityIndicatorView alloc]
      initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
  _indicator.activityIndicatorViewStyle =
      UIActivityIndicatorViewStyleWhiteLarge;
  _indicator.color = [UIColor blackColor];
  [_indicator setCenter:CGPointMake(_loadingView.bounds.size.width / 2,
                                    _loadingView.bounds.size.height / 2)];
  [_loadingView addSubview:_indicator];
  [self.view addSubview:_loadingView];

  // genreListViewControler
  _genreListVC = [[GenreListViewController alloc]
      initWithNibName:@"GenreListViewController"
               bundle:nil];
  _genreListVC.genreData = _genreList;
  _genreListVC.delegate = self;
}

- (void)beginLoading {
  _loadingView.hidden = NO;
  [_indicator startAnimating];
}

- (void)endLoading {
  [_indicator stopAnimating];
  _loadingView.hidden = YES;
}

- (void)changeGenre:(NSArray*)genres withFlagForcePlay:(BOOL)isForcePlay {
  [self beginLoading];

  //    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
  //                            @"cef5e6d3c083503120892b041572abff",
  // @"client_id",
  //                            @"ahomegane", @"q",
  //                            @"hiphop", @"genres",
  //                            @"japan", @"tags",
  //                            @"public,streamable", @"filter",//効かない
  //                            nil];
  NSDictionary* params = [NSDictionary
      dictionaryWithObjectsAndKeys:_SC_CLIENT_ID,
                                   @"client_id",
                                   [genres componentsJoinedByString:@","],
                                   @"genres",
                                   nil];

  SCRequestResponseHandler handler =
      ^(NSURLResponse * response, NSData * data, NSError * error) {
    NSError* jsonError = nil;
    NSJSONSerialization* jsonResponse =
        [NSJSONSerialization JSONObjectWithData:data
                                        options:0
                                          error:&jsonError];
    if (!jsonError && [jsonResponse isKindOfClass:[NSArray class]]) {
      _tracks = [(NSArray*)jsonResponse mutableCopy];
      _tracks = [self randomSortTracks:[self filterTracks:_tracks]];
      _trackIndex = 0;
      [self changeTrack:[_tracks objectAtIndex:_trackIndex]
          withFlagForcePlay:isForcePlay];
    }
    [self endLoading];
  };

  [SCRequest performMethod:SCRequestMethodGET
                  onResource:[NSURL URLWithString:_SC_TRACK_REQUEST_URL]
             usingParameters:params
                 withAccount:nil
      sendingProgressHandler:nil
             responseHandler:handler];
}

- (NSMutableArray*)filterTracks:(NSMutableArray*)tracks {
  for (int i = 0; i < [tracks count]; i++) {
    NSDictionary* track = [tracks objectAtIndex:i];
    //        int favorite = [[_track objectForKey:@"favoritings_count"]
    // intValue];
    //        int contentSize = [[_track objectForKey:@"original_content_size"]
    // intValue] /  1000000;
    BOOL streamable = [[track objectForKey:@"streamable"] boolValue];
    NSString* format = [track objectForKey:@"original_format"];
    NSString* sharing = [track objectForKey:@"sharing"];
    if (!streamable || [format isEqualToString:@"wav"] ||
        ![sharing isEqualToString:@"public"]) {  // contentSize > 7 || favorite
                                                 // < 3
      [tracks removeObjectAtIndex:i];
      i--;
    }
  }
  return tracks;
}

- (NSMutableArray*)randomSortTracks:(NSMutableArray*)tracks {
  int count = [tracks count];
  for (int i = count - 1; i > 0; i--) {
    int randomNum = arc4random() % i;
    [tracks exchangeObjectAtIndex:i withObjectAtIndex:randomNum];
  }
  return tracks;
}

- (void)renderTrackInfo:(NSDictionary*)track {

  NSString* artworkUrl = [track objectForKey:@"artwork_url"];
  UIImage* artworkImage;
  if (![artworkUrl isEqual:[NSNull null]]) {
    NSRegularExpression* regexp = [NSRegularExpression
        regularExpressionWithPattern:@"^(.+?)\\-[^\\-]+?\\.(.+?)$"
                             options:0
                               error:nil];
    NSString* artworkUrlLarge = [regexp
        stringByReplacingMatchesInString:artworkUrl
                                 options:0
                                   range:NSMakeRange(0, artworkUrl.length)
                            withTemplate:[NSString stringWithFormat:
                                                       @"$1-%@.$2",
                                                       _ARTWORK_IMAGE_SIZE]];
    NSData* artworkData =
        [NSData dataWithContentsOfURL:[NSURL URLWithString:artworkUrlLarge]];
    artworkImage = [[UIImage alloc] initWithData:artworkData];
  } else {
    artworkImage = [UIImage
        imageWithContentsOfFile:
            [[NSBundle mainBundle] pathForResource:@"no_image" ofType:@"png"]];
  }
  _artworkImageView.image = artworkImage;

  NSString* waveformUrl = [track objectForKey:@"waveform_url"];
  NSData* waveformData =
      [NSData dataWithContentsOfURL:[NSURL URLWithString:waveformUrl]];
  UIImage* waveformImage = [[UIImage alloc] initWithData:waveformData];
  _waveformImageView.image = waveformImage;

  NSString* title = [track objectForKey:@"title"];
  _permalinkUrl = [track objectForKey:@"permalink_url"];
  [_titleButton setTitle:title forState:UIControlStateNormal];
  [_titleButton addTarget:self
                   action:@selector(openUrl)
         forControlEvents:UIControlEventTouchUpInside];

  // waveform初期化
  CGRect rect = _waveformSequenceView.frame;
  _waveformSequenceView.frame =
      CGRectMake(rect.origin.x, rect.origin.y, 0, rect.size.height);

  // ロック画面に渡す
  MPMediaItemArtwork* artwork =
      [[MPMediaItemArtwork alloc] initWithImage:_artworkImageView.image];
  NSDictionary* songInfo =
      [NSDictionary dictionaryWithObjectsAndKeys:artwork,
                                                 MPMediaItemPropertyArtwork,
                                                 title,
                                                 MPMediaItemPropertyTitle,
                                                 nil];
  [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo];
}

- (void)openUrl {
  if (!_permalinkUrl)
    return;
  NSURL* url = [NSURL URLWithString:_permalinkUrl];
  [[UIApplication sharedApplication] openURL:url];
}

- (void)changeTrack:(NSDictionary*)newTrack
    withFlagForcePlay:(BOOL)isForcePlay {
  // updateAudioData で _player が更新される前の状態を保存
  BOOL isPlaying = [_player rate] != 0.0 ? YES : NO;
  if (isForcePlay) {
    isPlaying = YES;
  }

  [self renderTrackInfo:newTrack];

  //  if (_scAccount == nil) {
  //    [self login: nil widthLoginedCallback:^()
  //    {
  //      _scAccount = [self getScAccount];
  //      [self updateAudioData: newTrack withLoadedCallback:^()
  //      {
  //        if (isPlaying) {
  //          [self playStateToPlay];
  //        } else {
  //          [self playStateToStop];
  //        }
  //      }];
  //    }];
  //  } else {
  //    [self updateAudioData: newTrack withLoadedCallback:^()
  //    {
  //      if (isPlaying) {
  //        [self playStateToPlay];
  //      } else {
  //        [self playStateToStop];
  //      }
  //    }];
  //  }
  [self updateAudioData: newTrack withLoadedCallback:^()
   {
    if (isPlaying) {
      [self playStateToPlay];
    } else {
      [self playStateToStop];
    }
  }];
}

- (void)playStateToPlay {
  if (_player == nil)
    return;
  [_playButton setImage:_stopImage forState:UIControlStateNormal];
  [_player play];
  _isInterruptionBeginInPlayFlag = YES;
}

- (void)playStateToStop {
  if (_player == nil)
    return;
  [_playButton setImage:_playImage forState:UIControlStateNormal];
  [_player pause];
  _isInterruptionBeginInPlayFlag = NO;
}

- (void)prevTrack:(BOOL)isFrocePlay {
  if (_trackIndex == 0)
    return;
  _trackIndex--;
  [self changeTrack:[_tracks objectAtIndex:_trackIndex]
      withFlagForcePlay:isFrocePlay];
}

- (void)nextTrack:(BOOL)isFrocePlay {
  if (_trackIndex == [_tracks count] - 1)
    return;
  _trackIndex++;
  [self changeTrack:[_tracks objectAtIndex:_trackIndex]
      withFlagForcePlay:isFrocePlay];
}

- (void)updateAudioData:(NSDictionary*)newTrack
     withLoadedCallback:(void (^)())callback {

  NSString* streamUrl =
      [NSString stringWithFormat:@"%@?client_id=%@",
                                 [newTrack objectForKey:@"stream_url"],
                                 _SC_CLIENT_ID];

  NSLog(@"%@", streamUrl);
  _playerItem =
      [[AVPlayerItem alloc] initWithURL:[NSURL URLWithString:streamUrl]];
  NSString* ItemStatusContext;
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

- (void)observeValueForKeyPath:(NSString*)keyPath
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context {
  NSLog(@"%@", NSStringFromSelector(_cmd));
  if (object == _playerItem && [keyPath isEqualToString:@"status"]) {

    if (_playerItem.status == AVPlayerStatusReadyToPlay) {
      NSLog(@"AVPlayerStatusReadyToPlay");
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

- (void)playerItemDidReachEnd:(NSNotification*)notification {
  // Music completed
  [self nextTrack:YES];
}

- (void)touchPlayButton:(id)sender {
  if ([_player rate] != 0.0) {  // stop
    [self playStateToStop];
  } else {  // play
    [self playStateToPlay];
  }
}

- (void)touchPrevButton:(id)sender {
  BOOL isPlay = [_player rate] != 0.0 ? YES : NO;
  [self playStateToStop];
  [self prevTrack:isPlay];
}

- (void)touchNextButton:(id)sender {
  BOOL isPlay = [_player rate] != 0.0 ? YES : NO;
  [self playStateToStop];
  [self nextTrack:isPlay];
}

- (void)touchGenreButton:(id)sender {
  [self playStateToStop];
  [self presentViewController:_genreListVC animated:YES completion:nil];
}

- (void)selectGenre:(NSArray*)genreList {
  [self changeGenre:genreList withFlagForcePlay:YES];
  [_genreListVC dismissViewControllerAnimated:YES completion:nil];
}

- (void)touchLikeButton:(id)sender {

  NSDictionary* currentTrack = [_tracks objectAtIndex:_trackIndex];
  NSString* resourcetURL =
      [NSString stringWithFormat:
                    @"%@%@", _SC_LIKE_URL, [currentTrack objectForKey:@"id"]];

  SCRequestResponseHandler handler =
      ^(NSURLResponse * response, NSData * data, NSError * error) {
    if (SC_CANCELED(error)) {
      NSLog(@"Canceled!");
    } else if (error) {
      NSLog(@"Error: %@", [error localizedDescription]);
    } else {
      NSLog(@"Liked track: %@", [currentTrack objectForKey:@"id"]);
    }
  };

  [self getScAccount: ^(SCAccount * scAccount) {
    _scAccount = scAccount;
    [SCRequest performMethod:SCRequestMethodPUT
                  onResource:[NSURL URLWithString:resourcetURL]
             usingParameters:nil
                 withAccount:_scAccount
      sendingProgressHandler:nil
             responseHandler:handler];
  }];
}

// ロック画面からのイベントを受け取る
- (void)remoteControlReceivedWithEvent:(UIEvent*)receivedEvent {
  if (receivedEvent.type == UIEventTypeRemoteControl) {

    switch (receivedEvent.subtype) {

      case UIEventSubtypeRemoteControlPlay:
      case UIEventSubtypeRemoteControlPause:
      case UIEventSubtypeRemoteControlTogglePlayPause:
        [self touchPlayButton:nil];
        break;

      case UIEventSubtypeRemoteControlNextTrack:
        [self touchNextButton:nil];
        break;

      case UIEventSubtypeRemoteControlPreviousTrack:
        [self touchPrevButton:nil];
        break;

      default:
        break;
    }
  }
}

// remoteControlReceivedWithEventのため、firstResponderに設定
- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self becomeFirstResponder];
}

// 音楽再生の割り込み
- (void)sessionDidInterrupt:(NSNotification*)notification {
  switch ([notification.userInfo[AVAudioSessionInterruptionTypeKey] intValue]) {
    case AVAudioSessionInterruptionTypeEnded:  // 電話 割り込みend
      NSLog(_isInterruptionBeginInPlayFlag ? @"YES" : @"NO");
      if (_isInterruptionBeginInPlayFlag) {
        [self playStateToPlay];
      } else {
        [self playStateToStop];
      }
      break;
    case AVAudioSessionInterruptionTypeBegan:  // 電話/ipod 割り込みstart
    default:
      [_playButton setImage:_playImage forState:UIControlStateNormal];
      break;
  }
}
// イヤホンジャック抜いたとき
- (void)sessionRouteDidChange:(NSNotification*)notification {
  NSLog(@"%@", NSStringFromSelector(_cmd));
  [_playButton setImage:_playImage forState:UIControlStateNormal];
}

- (void)getScAccount:(void (^)())callback {
  SCAccount* scAccount;
  
  if (_scAccount == nil) {
    
    scAccount = [self restoreScAccount];
    
    if (scAccount == nil) {
      [self login: nil widthLoginedCallback:^() {
        
        SCAccount* scAccount = [SCSoundCloud account];
        
        if (scAccount == nil) {
          UIAlertView* alert =
          [[UIAlertView alloc] initWithTitle:@"Not Logged In"
                                     message:@"You must login"
                                    delegate:nil
                           cancelButtonTitle:@"OK"
                           otherButtonTitles:nil];
          [alert show];
        } else {
          [self saveScAccount:scAccount];
        }
        if (callback != nil)
          callback(scAccount);
      }];

    } else {
      NSLog(@"restore");
      if (callback != nil)
        callback(scAccount);
    }
    
  } else {
    scAccount = _scAccount;

    if (callback != nil)
      callback(scAccount);
  }
}

- (IBAction)login:(id)sender widthLoginedCallback:(void (^)())callback {
  SCLoginViewControllerCompletionHandler handler = ^(NSError * error) {
    if (SC_CANCELED(error)) {
      NSLog(@"Canceled!");
    } else if (error) {
      NSLog(@"Error: %@", [error localizedDescription]);
    } else {
      if (callback != nil)
        callback();
    }
  };

  [SCSoundCloud requestAccessWithPreparedAuthorizationURLHandler:^(NSURL *preparedURL)
  {
    SCLoginViewController* loginViewController;

    loginViewController =
        [SCLoginViewController loginViewControllerWithPreparedURL:preparedURL
                                                completionHandler:handler];
    [self presentViewController:loginViewController
                       animated:YES
                     completion:nil];
  }];
}

-(BOOL)saveScAccount: (SCAccount*) scAccount {
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:scAccount];
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:data forKey:@"scAccount"];
  BOOL isSuccess = [defaults synchronize];
  return isSuccess;
}

-(SCAccount*)restoreScAccount {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSData *data = [defaults dataForKey:@"scAccount"];
  SCAccount* scAccount = [NSKeyedUnarchiver unarchiveObjectWithData:data];
  return scAccount;
}

- (void)playSequence {
  if ([_player rate] != 0.0) {
    float currentTime = CMTimeGetSeconds(_player.currentTime);
    NSLog(@"%f", currentTime);
    float duration = CMTimeGetSeconds(_player.currentItem.asset.duration);
    CGRect rect = _waveformSequenceView.frame;
    _waveformSequenceView.frame = CGRectMake(rect.origin.x,
                                             rect.origin.y,
                                             260 * currentTime / duration,
                                             rect.size.height);
  }
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (IBAction)getTracks:(id)sender {
  SCAccount* account = [SCSoundCloud account];
  if (account == nil) {
    UIAlertView* alert =
        [[UIAlertView alloc] initWithTitle:@"Not Logged In"
                                   message:@"You must login first"
                                  delegate:nil
                         cancelButtonTitle:@"OK"
                         otherButtonTitles:nil];
    [alert show];
    return;
  }

  SCRequestResponseHandler handler;
  handler = ^(NSURLResponse * response, NSData * data, NSError * error) {
    NSError* jsonError = nil;
    NSJSONSerialization* jsonResponse =
        [NSJSONSerialization JSONObjectWithData:data
                                        options:0
                                          error:&jsonError];
    if (!jsonError && [jsonResponse isKindOfClass:[NSArray class]]) {
      TrackListViewController* trackListVC;
      trackListVC = [[TrackListViewController alloc]
          initWithNibName:@"TrackListViewController"
                   bundle:nil];
      trackListVC.tracks = (NSArray*)jsonResponse;
      [self presentViewController:trackListVC animated:YES completion:nil];
    }
  };

  NSString* resourceURL = @"https://api.soundcloud.com/me/tracks.json";
  [SCRequest performMethod:SCRequestMethodGET
                  onResource:[NSURL URLWithString:resourceURL]
             usingParameters:nil
                 withAccount:account
      sendingProgressHandler:nil
             responseHandler:handler];
}

- (IBAction)upload:(id)sender {
  NSURL* trackURL =
      [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"example"
                                                             ofType:@"mp3"]];

  SCShareViewController* shareViewController;
  SCSharingViewControllerCompletionHandler handler;

  handler = ^(NSDictionary * trackInfo, NSError * error) {
    if (SC_CANCELED(error)) {
      NSLog(@"Canceled!");
    } else if (error) {
      NSLog(@"Error: %@", [error localizedDescription]);
    } else {
      NSLog(@"Uploaded track: %@", trackInfo);
    }
  };
  shareViewController =
      [SCShareViewController shareViewControllerWithFileURL:trackURL
                                          completionHandler:handler];
  [shareViewController setTitle:@"Funny sounds"];
  [shareViewController setPrivate:YES];
  [self presentViewController:shareViewController animated:YES completion:nil];
}

@end
