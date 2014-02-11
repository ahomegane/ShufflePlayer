//
//  ViewController.m
//  ShufflePlayer
//
//  Created by Keiichiro Watanabe on 2013/10/17.
//  Copyright (c) 2013年 ahomegane. All rights reserved.
//
#import "ViewController.h"
#import "SCUI.h"
#import "Constants.h"
#import "UIButton+Helper.h"

@interface ViewController () {

  MusicManager *_musicManager;
  AccountManager *_accountManager;
  GenreListViewController *_genreListVC;
  
  BOOL _isInterruptionBeginInPlayFlag;

  UIImageView *_artworkImageView;
  UIImageView *_waveformImageView;
  UIImageView *_waveformSequenceView;
  UIButton *_titleButton;
  UIButton *_playButton;
  UIImage *_playImage;
  UIImage *_stopImage;

  // ローディング
  UIView *_loadingView;
  UIActivityIndicatorView *_indicator;
}
@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  // バックグラウンド再生
  AVAudioSession *audioSession = [AVAudioSession sharedInstance];
  [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
  [audioSession setActive:YES error:nil];
  
  // 音楽再生の割り込み
  NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
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
  
  // MusicManager
  _musicManager = [[MusicManager alloc] init];
  _musicManager.delegate = self;
  
  // AccountManager
  _accountManager = [[AccountManager alloc] init];
  _accountManager.delegate = self;
  
  // GenreListViewControler
  _genreListVC = [[GenreListViewController alloc]
                  initWithNibName:@"GenreListViewController"
                  bundle:nil];
  _genreListVC.genreData = _musicManager.genreList;
  _genreListVC.delegate = self;
  
  [self initElement];
  [_musicManager changeGenre:_musicManager.genreList withFlagForcePlay:NO];
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
  [_titleButton addTarget:self
                   action:@selector(touchTitleButton:)
         forControlEvents:UIControlEventTouchUpInside];

  _playImage = [UIImage imageNamed:@"button_play.png"];
  _stopImage = [UIImage imageNamed:@"button_stop.png"];
  _playButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  _playButton.frame = CGRectMake(139, 430, 41, 48);
  [_playButton setImage:_playImage forState:UIControlStateNormal];
  [self.view addSubview:_playButton];
  [_playButton addTarget:self
                  action:@selector(touchPlayButton:)
        forControlEvents:UIControlEventTouchUpInside];

  UIImage *prevImage = [UIImage imageNamed:@"button_prev.png"];
  UIButton *prevButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  prevButton.frame = CGRectMake(29, 430, 40, 48);
  [prevButton setImage:prevImage forState:UIControlStateNormal];
  [self.view addSubview:prevButton];
  [prevButton addTarget:self
                 action:@selector(touchPrevButton:)
       forControlEvents:UIControlEventTouchUpInside];

  UIImage *nextImage = [UIImage imageNamed:@"button_next.png"];
  UIButton *nextButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  nextButton.frame = CGRectMake(249, 430, 40, 48);
  [nextButton setImage:nextImage forState:UIControlStateNormal];
  [self.view addSubview:nextButton];
  [nextButton addTarget:self
                 action:@selector(touchNextButton:)
       forControlEvents:UIControlEventTouchUpInside];

  UIButton *genreButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  genreButton.frame = CGRectMake(20, 520, 52, 30);
  [self.view addSubview:genreButton];
  [genreButton setTitle:@"Genre" forState:UIControlStateNormal];
  [genreButton addTarget:self
                  action:@selector(touchGenreButton:)
        forControlEvents:UIControlEventTouchUpInside];

  UIButton *likeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
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

}

- (void)beginLoading {
  _loadingView.hidden = NO;
  [_indicator startAnimating];
}

- (void)endLoading {
  [_indicator stopAnimating];
  _loadingView.hidden = YES;
}

- (void)renderTrackInfo:(NSDictionary *)track {

  NSString *artworkUrl = [track objectForKey:@"artwork_url"];
  UIImage *artworkImage;
  if (![artworkUrl isEqual:[NSNull null]]) {
    NSRegularExpression *regexp = [NSRegularExpression
        regularExpressionWithPattern:@"^(.+?)\\-[^\\-]+?\\.(.+?)$"
                             options:0
                               error:nil];
    NSString *artworkUrlLarge = [regexp
        stringByReplacingMatchesInString:artworkUrl
                                 options:0
                                   range:NSMakeRange(0, artworkUrl.length)
                            withTemplate:
                                [NSString stringWithFormat:@"$1-%@.$2",
                                                           ARTWORK_IMAGE_SIZE]];
    NSData *artworkData =
        [NSData dataWithContentsOfURL:[NSURL URLWithString:artworkUrlLarge]];
    artworkImage = [[UIImage alloc] initWithData:artworkData];
  } else {
    artworkImage = [UIImage
        imageWithContentsOfFile:
            [[NSBundle mainBundle] pathForResource:@"no_image" ofType:@"png"]];
  }
  _artworkImageView.image = artworkImage;

  NSString *waveformUrl = [track objectForKey:@"waveform_url"];
  NSData *waveformData =
      [NSData dataWithContentsOfURL:[NSURL URLWithString:waveformUrl]];
  UIImage *waveformImage = [[UIImage alloc] initWithData:waveformData];
  _waveformImageView.image = waveformImage;

  NSString *title = [track objectForKey:@"title"];
  NSString *permalinkUrl = [track objectForKey:@"permalink_url"];
  [_titleButton setTitle:title forState:UIControlStateNormal];
  [_titleButton setStringTag:permalinkUrl];
  
  // waveform初期化
  CGRect rect = _waveformSequenceView.frame;
  _waveformSequenceView.frame =
      CGRectMake(rect.origin.x, rect.origin.y, 0, rect.size.height);

  // ロック画面に渡す
  MPMediaItemArtwork *artwork =
      [[MPMediaItemArtwork alloc] initWithImage:_artworkImageView.image];
  NSDictionary *songInfo = [NSDictionary
      dictionaryWithObjectsAndKeys:artwork, MPMediaItemPropertyArtwork, title,
                                   MPMediaItemPropertyTitle, nil];
  [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo];
}

- (void)playStateToPlay {
  if ([_musicManager play]) {
    [_playButton setImage:_stopImage forState:UIControlStateNormal];
    _isInterruptionBeginInPlayFlag = YES;
  }
}

- (void)playStateToStop {
  if ([_musicManager pause]) {
    [_playButton setImage:_playImage forState:UIControlStateNormal];
    _isInterruptionBeginInPlayFlag = NO;
  }
}

- (void)openUrlOnSafari: (NSString *)permalinkUrl {
  NSURL *url = [NSURL URLWithString:permalinkUrl];
  [[UIApplication sharedApplication] openURL:url];
}

- (void)touchPlayButton:(id)sender {
  if (_musicManager.playing) {
    [self playStateToStop];
  } else {
    [self playStateToPlay];
  }
}

- (void)touchPrevButton:(id)sender {
  BOOL isPlay = _musicManager.playing;
  [self playStateToStop];
  [_musicManager prevTrack:isPlay];
}

- (void)touchNextButton:(id)sender {
  BOOL isPlay = _musicManager.playing;
  [self playStateToStop];
  [_musicManager nextTrack:isPlay];
}

- (void)touchGenreButton:(id)sender {
  [self playStateToStop];
  _genreListVC.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
  [self presentViewController:_genreListVC animated:YES completion:nil];
}

- (void)touchLikeButton:(id)sender {
  NSDictionary *currentTrack = [_musicManager fetchCurrentTrack];

  [_accountManager sendLike:currentTrack withCompleteCallback:^(NSError * error){
    if (SC_CANCELED(error)) {
      NSLog(@"Canceled!");
    } else if (error) {
      NSLog(@"Error: %@", [error localizedDescription]);
    } else {
      NSLog(@"Liked track: %@", [currentTrack objectForKey:@"id"]);
    }
  }];
}

- (void)touchTitleButton:(id)sender {
  UIButton* button = sender;
  NSString* permalinkUrl = [button getStringTag];
  NSLog(@"%@", permalinkUrl);
  [self openUrlOnSafari: permalinkUrl];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

// ロック画面からのイベントを受け取る
- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent {
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
- (void)sessionDidInterrupt:(NSNotification *)notification {
  switch ([notification.userInfo[AVAudioSessionInterruptionTypeKey] intValue]) {
  case AVAudioSessionInterruptionTypeEnded: // 電話 割り込みend
    NSLog(_isInterruptionBeginInPlayFlag ? @"YES" : @"NO");
    if (_isInterruptionBeginInPlayFlag) {
      [self playStateToPlay];
    } else {
      [self playStateToStop];
    }
    break;
  case AVAudioSessionInterruptionTypeBegan: // 電話/ipod 割り込みstart
  default:
    [_playButton setImage:_playImage forState:UIControlStateNormal];
    break;
  }
}
// イヤホンジャック抜いたとき
- (void)sessionRouteDidChange:(NSNotification *)notification {
  NSLog(@"%@", NSStringFromSelector(_cmd));
  [_playButton setImage:_playImage forState:UIControlStateNormal];
}

//////////////////// delegate MusicManager

- (void)changeGenreBefore {
  [self beginLoading];
}

- (void)changeGenreComplete {
  [self endLoading];
}

- (void)changeTrackBefore:(NSDictionary *)newTrack withplayingBeforeChangeTrackFlag:(BOOL)isPlaying {
  [self renderTrackInfo:newTrack];
}

- (void)changeTrackComplete:(NSDictionary *)newTrack withplayingBeforeChangeTrackFlag:(BOOL)isPlaying {
  if (isPlaying) {
    [self playStateToPlay];
  } else {
    [self playStateToStop];
  }
}

- (void)playSequenceOnPlaying:(float)currentTime
            withTrackDuration:(float)duration {
  CGRect rect = _waveformSequenceView.frame;
  _waveformSequenceView.frame =
  CGRectMake(rect.origin.x, rect.origin.y, 260 * currentTime / duration,
             rect.size.height);
}

//////////////////// delegate AccountManager
-(void)showSubView:(id)view {
  [self presentViewController:view
                              animated:YES
                            completion:nil];
}

//////////////////// delegate GenreListViewController

- (void)selectGenre:(NSArray *)genreList {
  [_musicManager changeGenre:genreList withFlagForcePlay:YES];
  _genreListVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
  [_genreListVC dismissViewControllerAnimated:YES completion:nil];
}

@end
