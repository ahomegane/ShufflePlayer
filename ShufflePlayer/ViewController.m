//
//  ViewController.m
//  ShufflePlayer
//
//  Created by Keiichiro Watanabe on 2013/10/17.
//  Copyright (c) 2013年 ahomegane. All rights reserved.
//

//ローディング
// Class分け
// アカウント保存
// 再生の表示

// AVAudioPlayer
// http://lab.dolice.net/blog/2013/07/14/objc-av-audio-player/
// http://blog.volv.jp/memo/2011/06/avaudioplayer.html
//バックグラウンド再生でほかのアプリで音楽が再生されて戻ってきたとき

#import "SCUI.h"
#import "ViewController.h"
#import "TrackListViewController.h"

@interface ViewController () {
  AVAudioPlayer* _player;

  SCAccount* _scaccount;

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
}
@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  [NSTimer scheduledTimerWithTimeInterval:0.1
                                   target:self
                                 selector:@selector(playSequence)
                                 userInfo:nil
                                  repeats:YES];

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
  [self changeGenre:_genreList withFlagForcePlay:false];
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
}

- (void)changeGenre:(NSArray*)genres withFlagForcePlay:(bool)isForcePlay {
  NSString* resourceURL = @"https://api.soundcloud.com/tracks.json";
  //    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
  //                            @"cef5e6d3c083503120892b041572abff",
  // @"client_id",
  //                            @"ahomegane", @"q",
  //                            @"hiphop", @"genres",
  //                            @"japan", @"tags",
  //                            @"public,streamable", @"filter",
  //                            nil];
  NSDictionary* params = [NSDictionary
      dictionaryWithObjectsAndKeys:@"cef5e6d3c083503120892b041572abff",
                                   @"client_id",
                                   [genres componentsJoinedByString:@","],
                                   @"genres",
                                   @"public,streamable",
                                   @"filter",
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
  };

  [SCRequest performMethod:SCRequestMethodGET
                  onResource:[NSURL URLWithString:resourceURL]
             usingParameters:params
                 withAccount:nil
      sendingProgressHandler:nil
             responseHandler:handler];
}

- (NSMutableArray*)filterTracks:(NSMutableArray*)tracks {
  for (int i = 0; i < [tracks count]; i++) {
    NSDictionary* _track = [tracks objectAtIndex:i];
    //        int favorite = [[_track objectForKey:@"favoritings_count"]
    // intValue];
    //        int contentSize = [[_track objectForKey:@"original_content_size"]
    // intValue] /  1000000;
    NSString* streamURL = [_track objectForKey:@"stream_url"];
    if (streamURL == nil) {  // contentSize > 7 || favorite < 3
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

- (void)selectGenre:(NSArray*)genreList {
  [self changeGenre:genreList withFlagForcePlay:true];
  [_genreListVC dismissViewControllerAnimated:YES completion:nil];
}

- (void)renderTrackInfo:(NSDictionary*)track {
  NSString* artworkUrl = [track objectForKey:@"artwork_url"];
  NSLog(@"%@", artworkUrl);
  UIImage* artworkImage;
  if (![artworkUrl isEqual:[NSNull null]]) {
    NSData* artworkData =
        [NSData dataWithContentsOfURL:[NSURL URLWithString:artworkUrl]];
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

  CGRect rect = _waveformSequenceView.frame;
  _waveformSequenceView.frame =
      CGRectMake(rect.origin.x, rect.origin.y, 0, rect.size.height);
}

- (void)openUrl {
  if (!_permalinkUrl)
    return;
  NSURL* url = [NSURL URLWithString:_permalinkUrl];
  [[UIApplication sharedApplication] openURL:url];
}

- (void)changeTrack:(NSDictionary*)newTrack
    withFlagForcePlay:(bool)isForcePlay {
  // updateAudioData で _player が更新される前の状態を保存
  bool isPlaying = _player.playing;
  if (isForcePlay) {
    isPlaying = YES;
  }

  [self renderTrackInfo:newTrack];

  if (_scaccount == nil) {
    [self login: nil widthLoginedCallback:^()
    {
      _scaccount = [self getAccount];
      [self updateAudioData: newTrack withLoadedCallback:^()
      {
        if (isPlaying) {
          [self playStateToPlay];
        } else {
          [self playStateToStop];
        }
      }];
    }];
  } else {
    [self updateAudioData: newTrack withLoadedCallback:^()
    {
      if (isPlaying) {
        [self playStateToPlay];
      } else {
        [self playStateToStop];
      }
    }];
  }
}

- (void)playStateToPlay {
  if (_player == nil)
    return;
  [_playButton setImage:_stopImage forState:UIControlStateNormal];
  [_player play];
}

- (void)playStateToStop {
  if (_player == nil)
    return;
  [_playButton setImage:_playImage forState:UIControlStateNormal];
  [_player pause];
}

- (void)prevTrack:(bool)isFrocePlay {
  if (_trackIndex == 0)
    return;
  _trackIndex--;
  [self changeTrack:[_tracks objectAtIndex:_trackIndex]
      withFlagForcePlay:isFrocePlay];
}

- (void)nextTrack:(bool)isFrocePlay {
  if (_trackIndex == [_tracks count] - 1)
    return;
  _trackIndex++;
  [self changeTrack:[_tracks objectAtIndex:_trackIndex]
      withFlagForcePlay:isFrocePlay];
}

- (void)updateAudioData:(NSDictionary*)newTrack
     withLoadedCallback:(void (^)())callback {
  [SCRequest performMethod:SCRequestMethodGET
                onResource:[NSURL URLWithString: [newTrack objectForKey:@"stream_url"]]
           usingParameters:nil
               withAccount:_scaccount
    sendingProgressHandler:nil
           responseHandler:^(NSURLResponse *response, NSData *data, NSError *error)
  {
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];

    NSError* playerError;
    _player = [[AVAudioPlayer alloc] initWithData:data error:&playerError];
    _player.delegate = self;

    //バックグラウンド再生
    AVAudioSession* audioSession = [AVAudioSession sharedInstance];
    NSError* sessionError = nil;
    [audioSession setCategory:AVAudioSessionCategoryPlayback
                        error:&sessionError];
    [audioSession setActive:YES error:&sessionError];

    [_player prepareToPlay];
    _player.currentTime = 0;

    if (callback != nil)
      callback();
  }];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer*)player
                       successfully:(BOOL)flag {
  // Music completed
  if (flag) {
    [self nextTrack:true];
  }
}

- (void)touchPlayButton:(id)sender {
  if (_player.playing) {  // stop
    [self playStateToStop];
    return;
  } else {  // play
    [self playStateToPlay];
  }
}

- (void)touchPrevButton:(id)sender {
  [self prevTrack:_player.playing];
  [self playStateToStop];
}

- (void)touchNextButton:(id)sender {
  [self nextTrack:_player.playing];
  [self playStateToStop];
}

- (id)getAccount {
  SCAccount* account = [SCSoundCloud account];
  if (account == nil) {
    UIAlertView* alert =
        [[UIAlertView alloc] initWithTitle:@"Not Logged In"
                                   message:@"You must login first"
                                  delegate:nil
                         cancelButtonTitle:@"OK"
                         otherButtonTitles:nil];
    [alert show];
    return nil;
  }
  return account;
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

- (void)playSequence {
  if (_player.playing) {
    //    NSLog(@"%@", [NSString stringWithFormat:@"%f", _player.currentTime]);
    CGRect rect = _waveformSequenceView.frame;
    _waveformSequenceView.frame =
        CGRectMake(rect.origin.x,
                   rect.origin.y,
                   260 * _player.currentTime / _player.duration,
                   rect.size.height);
  }
}

// RemoteControlDelegate
// http://blog.valeur3.com/?p=663
- (void)remoteControlReceivedWithEvent:(UIEvent*)event {
  NSLog(@"receive remote control events");
}
// FirstResponderDelegate
- (BOOL)canBecomeFirstResponder {
  return YES;
}
- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  //ファーストレスポンダ登録
  [self becomeFirstResponder];
}
- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  //ファーストレスポンダ解除
  [self resignFirstResponder];
}

- (IBAction)openGenreList:(id)sender {
  [self playStateToStop];

  _genreListVC = [[GenreListViewController alloc]
      initWithNibName:@"GenreListViewController"
               bundle:nil];
  _genreListVC.genreData = _genreList;
  _genreListVC.delegate = self;
  [self presentViewController:_genreListVC animated:YES completion:nil];
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
