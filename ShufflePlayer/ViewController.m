//
//  ViewController.m
//  ShufflePlayer
//
//  Created by Keiichiro Watanabe on 2013/10/17.
//  Copyright (c) 2013年 ahomegane. All rights reserved.
//
#import "ViewController.h"
#import "Constants.h"
#import "UIButton+Helper.h"
#import "STDeferred.h"

// oauth invalid_grant おそらくアカウントオブジェクトの有効期間

@interface ViewController () {

  GenreListViewController *_genreListVC;

  UIScrollView *_baseScrollView;
  TrackScrollView *_prevTrackScrollView;
  TrackScrollView *_currentTrackScrollView;
  TrackScrollView *_nextTrackScrollView;

  AlarmViewController *_alarmVC;

  int _trackScrollViewIndex;
  int _tracksCount;

  BOOL _isInterruptionBeginInPlayFlag;

  UIButton *_playButton;
  UIImage *_playImage;
  UIImage *_stopImage;

  // オープニング
  UIView *_openingView;

  // ローディング
  UIView *_loadingView;
  UIActivityIndicatorView *_indicator;
}
@end

@implementation ViewController

@synthesize accountManager, musicManager;

#pragma mark - UIViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  // MusicManager
  self.musicManager = [[MusicManager alloc] init];
  self.musicManager.delegate = self;

  // AccountManager
  self.accountManager = [[AccountManager alloc] init];
  self.accountManager.delegate = self;

  // GenreListViewControler
  _genreListVC = [[GenreListViewController alloc]
      initWithNibName:@"GenreListViewController"
               bundle:nil];
  _genreListVC.genreData = self.musicManager.genreList;
  _genreListVC.delegate = self;

  _alarmVC = [[AlarmViewController alloc] initWithNibName:@"AlarmViewController"
                                                   bundle:nil];
  _alarmVC.delegate = self;

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

  // エレメント初期化
  [self initElement];

  // すべてのジェンルでリクエスト
  [self.musicManager changeGenre:self.musicManager.genreList
               withForcePlayFlag:NO
                    withInitFlag:YES];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - View Element

- (void)initElement {

  _baseScrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
  _baseScrollView.pagingEnabled = YES;
  _baseScrollView.showsHorizontalScrollIndicator = NO;
  _baseScrollView.showsVerticalScrollIndicator = NO;
  _baseScrollView.scrollsToTop = NO;
  _baseScrollView.delegate = self;
  [self.view addSubview:_baseScrollView];

  // initialize TrackScrollViews
  _trackScrollViewIndex = 0;

  CGRect trackScrollViewFrame = CGRectZero;
  trackScrollViewFrame.size = _baseScrollView.frame.size;
  trackScrollViewFrame.origin.x =
      (_trackScrollViewIndex - 1) * trackScrollViewFrame.size.width;

  for (int i = 0; i < 3; i++) {
    TrackScrollView *trackScrollView =
        [[TrackScrollView alloc] initWithFrame:trackScrollViewFrame
                    withAccountManagerInstance:self.accountManager];
    trackScrollView.minimumZoomScale = 1.0;
    trackScrollView.maximumZoomScale = 1.0;
    trackScrollView.showsHorizontalScrollIndicator = NO;
    trackScrollView.showsVerticalScrollIndicator = NO;

    [_baseScrollView addSubview:trackScrollView];

    switch (i) {
    case 0:
      _prevTrackScrollView = trackScrollView;
      //      _prevTrackScrollView.backgroundColor = [UIColor blueColor];
      break;
    case 1:
      _currentTrackScrollView = trackScrollView;
      //      _currentTrackScrollView.backgroundColor = [UIColor redColor];
      break;
    case 2:
      _nextTrackScrollView = trackScrollView;
      //      _nextTrackScrollView.backgroundColor = [UIColor yellowColor];
      break;
    }

    trackScrollViewFrame.origin.x += trackScrollViewFrame.size.width;
  }

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
  [genreButton setTitle:@"Genre" forState:UIControlStateNormal];
  [self.view addSubview:genreButton];
  [genreButton addTarget:self
                  action:@selector(touchGenreButton:)
        forControlEvents:UIControlEventTouchUpInside];

  UIButton *moreButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  moreButton.frame = CGRectMake(250, 520, 52, 30);
  [moreButton setTitle:@"more" forState:UIControlStateNormal];
  [self.view addSubview:moreButton];
  [moreButton addTarget:self
                 action:@selector(touchMoreButton:)
       forControlEvents:UIControlEventTouchUpInside];

  // ローディング
  _loadingView = [[UIView alloc] initWithFrame:self.view.bounds];
  _loadingView.backgroundColor = [UIColor whiteColor];
  //  _loadingView.alpha = 0.5f;

  _indicator = [[UIActivityIndicatorView alloc]
      initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
  _indicator.activityIndicatorViewStyle =
      UIActivityIndicatorViewStyleWhiteLarge;
  _indicator.color = [UIColor blackColor];
  _indicator.center = _loadingView.center;

  [_loadingView addSubview:_indicator];
  [self.view addSubview:_loadingView];

  _loadingView.hidden = YES;

  // オープニング
  _openingView = [[UIView alloc] initWithFrame:self.view.bounds];
  _openingView.backgroundColor = [UIColor whiteColor];
  UIImageView *_logoImageView = [[UIImageView alloc]
      initWithImage:[UIImage imageNamed:@"button_next.png"]];
  _logoImageView.center = _openingView.center;
  [_openingView addSubview:_logoImageView];
  [self.view addSubview:_openingView];
}

- (void)resetScrollView {
  CGPoint point = _baseScrollView.contentOffset;
  point.x = 0;
  _baseScrollView.contentOffset = point;

  _trackScrollViewIndex = 0;

  CGRect frame = _prevTrackScrollView.frame;
  frame.origin.x = (_trackScrollViewIndex - 1) * frame.size.width;
  for (int i = 0; i < 3; i++) {

    switch (i) {
    case 0:
      _prevTrackScrollView.frame = frame;
      break;
    case 1:
      _currentTrackScrollView.frame = frame;
      break;
    case 2:
      _nextTrackScrollView.frame = frame;
      break;
    }

    frame.origin.x += frame.size.width;
  }

  CGSize contentSize =
      CGSizeMake(_currentTrackScrollView.frame.size.width * _tracksCount,
                 _currentTrackScrollView.frame.size.height);
  _baseScrollView.contentSize = contentSize;
}

- (void)changeAllTrackInfo {
  NSDictionary *prevTrack = [self.musicManager fetchPrevTrack];
  [_prevTrackScrollView setTrackInfo:prevTrack];

  NSDictionary *currentTrack = [self.musicManager fetchCurrentTrack];
  [_currentTrackScrollView setTrackInfo:currentTrack];

  NSDictionary *nextTrack = [self.musicManager fetchNextTrack];
  [_nextTrackScrollView setTrackInfo:nextTrack];

  [self setSongInfoToDefaultCenter:_currentTrackScrollView.artworkImage
                             title:_currentTrackScrollView.title];
}

- (void)changePrevTrackInfo {
  NSDictionary *prevTrack = [self.musicManager fetchPrevTrack];
  [_prevTrackScrollView setTrackInfo:prevTrack];

  [self setSongInfoToDefaultCenter:_currentTrackScrollView.artworkImage
                             title:_currentTrackScrollView.title];
}

- (void)changeNextTrackInfo {
  NSDictionary *nextTrack = [self.musicManager fetchNextTrack];
  [_nextTrackScrollView setTrackInfo:nextTrack];

  [self setSongInfoToDefaultCenter:_currentTrackScrollView.artworkImage
                             title:_currentTrackScrollView.title];
}

#pragma mark Event Listener

- (void)playStateToPlay {
  if ([self.musicManager play]) {
    [_playButton setImage:_stopImage forState:UIControlStateNormal];
    _isInterruptionBeginInPlayFlag = YES;
  }
}

- (void)playStateToStop {
  if ([self.musicManager pause]) {
    [_playButton setImage:_playImage forState:UIControlStateNormal];
    _isInterruptionBeginInPlayFlag = NO;
  }
}

- (void)touchPlayButton:(id)sender {
  if (self.musicManager.playing) {
    [self playStateToStop];
  } else {
    [self playStateToPlay];
  }
}

- (void)scrollPrev {
  // viewの入れ替え
  TrackScrollView *tmpView = _currentTrackScrollView;

  _currentTrackScrollView = _prevTrackScrollView;
  _prevTrackScrollView = _nextTrackScrollView;
  _nextTrackScrollView = tmpView;

  CGRect frame = _currentTrackScrollView.frame;
  frame.origin.x -= frame.size.width;
  _prevTrackScrollView.frame = frame;

  BOOL isPlay = self.musicManager.playing;
  [self playStateToStop];
  [self.musicManager prevTrack:isPlay];

  [self changePrevTrackInfo];
}

- (void)scrollNext {
  // viewの入れ替え
  TrackScrollView *tmpView = _currentTrackScrollView;

  _currentTrackScrollView = _nextTrackScrollView;
  _nextTrackScrollView = _prevTrackScrollView;
  _prevTrackScrollView = tmpView;

  CGRect frame = _currentTrackScrollView.frame;
  frame.origin.x += frame.size.width;
  _nextTrackScrollView.frame = frame;

  BOOL isPlay = self.musicManager.playing;
  [self playStateToStop];
  [self.musicManager nextTrack:isPlay];

  [self changeNextTrackInfo];
}

- (void)touchPrevButton:(id)sender {
  if (_trackScrollViewIndex == 0)
    return;

  CGPoint point = _baseScrollView.contentOffset;
  point.x -= _baseScrollView.bounds.size.width;
  _baseScrollView.contentOffset = point;

  _trackScrollViewIndex -= 1;
  [self scrollPrev];
}

- (void)touchNextButton:(id)sender {
  if (_trackScrollViewIndex == _tracksCount - 1)
    return;

  CGPoint point = _baseScrollView.contentOffset;
  point.x += _baseScrollView.bounds.size.width;
  _baseScrollView.contentOffset = point;

  _trackScrollViewIndex += 1;
  [self scrollNext];
}

- (void)touchGenreButton:(id)sender {
  [self presentViewController:_genreListVC animated:YES completion:nil];
}

- (void)touchMoreButton:(id)sender {
  _alarmVC.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
  [self presentViewController:_alarmVC animated:YES completion:nil];
}

- (void)beginOpening {
  _openingView.hidden = NO;
}

- (void)endOpening {
  _openingView.hidden = YES;
}

- (void)beginLoading {
  _loadingView.hidden = NO;
  [_indicator startAnimating];
}

- (void)endLoading {
  [_indicator stopAnimating];
  _loadingView.hidden = YES;
}

#pragma mark RemoteEvent Control

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

// ロック画面の音楽情報を更新
- (void)setSongInfoToDefaultCenter:(UIImage *)artworkImage
                             title:(NSString *)title {
  MPMediaItemArtwork *artwork =
      [[MPMediaItemArtwork alloc] initWithImage:artworkImage];
  NSDictionary *songInfo = [NSDictionary
      dictionaryWithObjectsAndKeys:artwork, MPMediaItemPropertyArtwork, title,
                                   MPMediaItemPropertyTitle, nil];
  [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  NSLog(@"****** scrollViewDidEndDecelerating");

  CGFloat position = scrollView.contentOffset.x / scrollView.bounds.size.width;
  CGFloat delta = position - (CGFloat)_trackScrollViewIndex;

  if (fabs(delta) >= 1.0f) {

    if (delta > 0) {
      // the current page moved to right
      _trackScrollViewIndex += 1;
      [self scrollNext];

    } else {
      // the current page moved to left
      _trackScrollViewIndex -= 1;
      [self scrollPrev];
    }
  }
}

#pragma mark - MusicManagerDelegate

- (void)changeGenreBefore:(BOOL)isInit {
  if (isInit) {
    [self beginOpening];
  } else {
    [self beginLoading];
  }
}

- (void)changeGenreComplete:(int)tracksCount withInitFlag:(BOOL)isInit {
  // update
  _tracksCount = tracksCount;

  [self changeAllTrackInfo];
  [self resetScrollView];
  if (isInit) {
    [self endOpening];
  } else {
    [self endLoading];
  }
}

- (void)getAudioDataBefore {
  [self beginLoading];
}

- (void)getAudioDataReadyToPlay {
  [self endLoading];
}

- (void)didChangeTrack:(NSDictionary *)newTrack
    withPlayingBeforeChangeFlag:(BOOL)isPlaying {
  if (isPlaying) {
    [self playStateToPlay];
  } else {
    [self playStateToStop];
  }
}

- (void)playSequenceOnPlaying:(float)currentTime
            withTrackDuration:(float)duration {
  [_currentTrackScrollView updateWaveform:currentTime
                        withTrackDuration:duration];
}

#pragma mark - AccountManagerDelegate

- (void)showAccountView:(id)view {
  [self presentViewController:view animated:YES completion:nil];
}

#pragma mark - GenreListViewControllerDelegate

- (void)selectGenre:(NSArray *)genreList {
  [self.musicManager changeGenre:genreList
               withForcePlayFlag:NO
                    withInitFlag:NO];

  [_genreListVC dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - AlarmViewControllerDelegate

- (void)playAlarm {
  [self.musicManager changeGenre:self.musicManager.genreList
               withForcePlayFlag:YES
                    withInitFlag:NO];
}

- (void)hideAlarmView {
  _alarmVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
  [_alarmVC dismissViewControllerAnimated:YES completion:nil];
}

@end
