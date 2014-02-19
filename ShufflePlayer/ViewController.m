//
//  ViewController.m
//  ShufflePlayer
//
//  Created by Keiichiro Watanabe on 2013/10/17.
//  Copyright (c) 2013年 ahomegane. All rights reserved.
//
#import "ViewController.h"
#import "AppDelegate.h"
#import "Constants.h"
#import "UIButton+Helper.h"
#import "STDeferred.h"
#import "UIImage+BlurredFrame.h"
#import "LoadIndicator.h"
#import "OpeningView.h"

@interface ViewController () {
  
  STDeferred* _deferredCompeleteInit;

  UIScrollView *_baseScrollView;
  TrackScrollView *_prevTrackScrollView;
  TrackScrollView *_currentTrackScrollView;
  TrackScrollView *_nextTrackScrollView;

  int _trackScrollViewIndex;
  int _tracksCount;

  BOOL _isInterruptionBeginInPlayFlag;

  UIButton *_playButton;
  UIImage *_playImage;
  UIImage *_pauseImage;

  // オープニング
  OpeningView *_openingView;

  // ローディング
  UIView *_loadingView;
  LoadIndicator *_indicator;
}
@end

@implementation ViewController

@synthesize accountManager, musicManager, alarmVC, lunchAlarmFlag;

#pragma mark - UIViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  NSLog(@"ViewDidLoad");
  
  AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
  appDelegate.viewController = self;

  // MusicManager
  self.musicManager = [[MusicManager alloc] init];
  self.musicManager.delegate = self;

  // AccountManager
  self.accountManager = [[AccountManager alloc] init];
  self.accountManager.delegate = self;

  // GenreListViewControler
  self.genreListVC = [[GenreListViewController alloc]
      initWithNibName:nil
               bundle:nil];
  self.genreListVC.genreData = self.musicManager.genreList;
  self.genreListVC.delegate = self;

  self.alarmVC = [[AlarmViewController alloc] initWithNibName:nil
                                                       bundle:nil withMusicManagerInstance: self.musicManager];
  self.alarmVC.delegate = self;

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
               withForcePlayFlag:self.lunchAlarmFlag ? YES : NO
                    withInitFlag:YES];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle {
  return UIStatusBarStyleLightContent;
}

#pragma mark - View Element

- (void)initElement {
  
  UIColor *bgColorAlpha = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
  UIColor *bgImage = [UIColor colorWithPatternImage:[UIImage imageNamed:@"opening_bg"]];
  
  // 背景指定
  self.view.backgroundColor = bgImage;
  
  // scrollView配置
  _baseScrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
  _baseScrollView.pagingEnabled = YES;
  _baseScrollView.showsHorizontalScrollIndicator = NO;
  _baseScrollView.showsVerticalScrollIndicator = NO;
  _baseScrollView.scrollsToTop = NO;
  _baseScrollView.delegate = self;
  [self.view addSubview:_baseScrollView];

  // navigationAreaを定義
  _playImage = [UIImage imageNamed:@"button_play"];
  _pauseImage = [UIImage imageNamed:@"button_pause"];

  CGRect navigationAreaFrame = CGRectMake(0, self.view.frame.size.height - 206, self.view.frame.size.width, _playImage.size.height);
  
  _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [_playButton setImage:_playImage forState:UIControlStateNormal];
  _playButton.frame = CGRectMake(navigationAreaFrame.size.width / 2 - _playImage.size.width / 2, navigationAreaFrame.origin.y, _playImage.size.width, _playImage.size.height);
  [_playButton addTarget:self
                  action:@selector(touchPlayButton:)
        forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:_playButton];
  
//  UIImage *prevImage = [UIImage imageNamed:@"button_prev.png"];
//  UIButton *prevButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
//  prevButton.frame = CGRectMake(200, navigationAreaFrame.origin.y + navigationAreaFrame.size.height / 2 - prevImage.size.height / 2, prevImage.size.width, prevImage.size.height);
//  [prevButton setImage:prevImage forState:UIControlStateNormal];
//  [self.view addSubview:prevButton];
//  [prevButton addTarget:self
//                 action:@selector(touchPrevButton:)
//       forControlEvents:UIControlEventTouchUpInside];
//
//  UIImage *nextImage = [UIImage imageNamed:@"button_next.png"];
//  UIButton *nextButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
//  nextButton.frame = CGRectMake(250, navigationAreaFrame.origin.y + navigationAreaFrame.size.height / 2 - nextImage.size.height / 2, nextImage.size.width, nextImage.size.height);
//  [nextButton setImage:nextImage forState:UIControlStateNormal];
//  [self.view addSubview:nextButton];
//  [nextButton addTarget:self
//                 action:@selector(touchNextButton:)
//       forControlEvents:UIControlEventTouchUpInside];
  
  UIImage *genreImage = [UIImage imageNamed:@"button_genre"];
  UIButton *genreButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [genreButton setImage:genreImage forState:UIControlStateNormal];
  genreButton.frame = CGRectMake(25, navigationAreaFrame.origin.y + navigationAreaFrame.size.height / 2 - genreImage.size.height / 2, genreImage.size.width, genreImage.size.height);
  [genreButton addTarget:self
                  action:@selector(touchGenreButton:)
        forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:genreButton];
  
  UIImage *alarmImage = [UIImage imageNamed:@"button_alarm"];
  UIButton *alarmButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [alarmButton setImage:alarmImage forState:UIControlStateNormal];
  alarmButton.frame = CGRectMake(74, navigationAreaFrame.origin.y + navigationAreaFrame.size.height / 2 - alarmImage.size.height / 2, alarmImage.size.width, alarmImage.size.height);
  [alarmButton addTarget:self
                  action:@selector(touchAlarmButton:)
        forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:alarmButton];

  // TrackScrollView初期化
  _trackScrollViewIndex = 0;

  CGRect trackScrollViewFrame = CGRectZero;
  trackScrollViewFrame.size = _baseScrollView.frame.size;
  trackScrollViewFrame.origin.x =
      (_trackScrollViewIndex - 1) * trackScrollViewFrame.size.width;

  for (int i = 0; i < 3; i++) {
    TrackScrollView *trackScrollView =
        [[TrackScrollView alloc] initWithFrame:trackScrollViewFrame
                    withAccountManagerInstance:self.accountManager withMusicManagerInstance:self.musicManager];
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

  // ローディング
  _loadingView = [[UIView alloc] initWithFrame:self.view.bounds];
  _loadingView.backgroundColor = bgColorAlpha;

  _indicator = [[LoadIndicator alloc] init];
  _indicator.center = _loadingView.center;

  [_loadingView addSubview:_indicator];
  [self.view addSubview:_loadingView];

  _loadingView.hidden = YES;

  // オープニング
  _openingView = [[OpeningView alloc] initWithFrame:self.view.bounds];
  [self.view addSubview:_openingView];
  [self beginOpening];

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
    [_playButton setImage:_pauseImage forState:UIControlStateNormal];
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

- (void)scrollPrev:(BOOL)isForcePlay {
  // viewの入れ替え
  TrackScrollView *tmpView = _currentTrackScrollView;

  _currentTrackScrollView = _prevTrackScrollView;
  _prevTrackScrollView = _nextTrackScrollView;
  _nextTrackScrollView = tmpView;

  CGRect frame = _currentTrackScrollView.frame;
  frame.origin.x -= frame.size.width;
  _prevTrackScrollView.frame = frame;

  BOOL isPlay = isForcePlay ? YES : self.musicManager.playing;
  [self playStateToStop];
  [self.musicManager prevTrack:isPlay];

  [self changePrevTrackInfo];
}

- (void)scrollNext:(BOOL)isForcePlay {
  // viewの入れ替え
  TrackScrollView *tmpView = _currentTrackScrollView;

  _currentTrackScrollView = _nextTrackScrollView;
  _nextTrackScrollView = _prevTrackScrollView;
  _prevTrackScrollView = tmpView;

  CGRect frame = _currentTrackScrollView.frame;
  frame.origin.x += frame.size.width;
  _nextTrackScrollView.frame = frame;

  BOOL isPlay = isForcePlay ? YES : self.musicManager.playing;
  [self playStateToStop];
  [self.musicManager nextTrack:isPlay];

  [self changeNextTrackInfo];
}

- (void)prevTrack:(BOOL)isForcePlay {
  if (_trackScrollViewIndex == 0)
    return;
  
  CGPoint point = _baseScrollView.contentOffset;
  point.x -= _baseScrollView.bounds.size.width;
  _baseScrollView.contentOffset = point;
  
  _trackScrollViewIndex -= 1;
  [self scrollPrev:isForcePlay];
}

- (void)nextTrack:(BOOL)isForcePlay {
  if (_trackScrollViewIndex == _tracksCount - 1)
    return;
  
  CGPoint point = _baseScrollView.contentOffset;
  point.x += _baseScrollView.bounds.size.width;
  _baseScrollView.contentOffset = point;
  
  _trackScrollViewIndex += 1;
  [self scrollNext:isForcePlay];
}

- (void)touchPrevButton:(id)sender {
  [self prevTrack:NO];
}

- (void)touchNextButton:(id)sender {
  [self nextTrack:NO];
}

- (void)touchGenreButton:(id)sender {
  [self.genreListVC setBlurImage:[self blurImageFromView:self.view]];
  self.genreListVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
  [self presentViewController:self.genreListVC animated:YES completion:nil];
}

- (void)touchAlarmButton:(id)sender {
  [self.alarmVC setBlurImage:[self blurImageFromView:self.view]];
  self.alarmVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
  [self presentViewController:self.alarmVC animated:YES completion:nil];
}

- (void)beginOpening {
  [[STDeferred when:[_openingView fadeIn], [self completeInit], nil] then:^(id ret) {
    [_openingView fadeOut];
  }];
}

- (STDeferred*)completeInit {
  _deferredCompeleteInit = [STDeferred deferred];
  return _deferredCompeleteInit;
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
      [self scrollNext:NO];

    } else {
      // the current page moved to left
      _trackScrollViewIndex -= 1;
      [self scrollPrev:NO];
    }
  }
}

#pragma mark - MusicManagerDelegate

- (void)changeGenreBefore:(BOOL)isInit {
  if (! isInit) {
    [self beginLoading];
  }
}

- (void)changeGenreComplete:(int)tracksCount withInitFlag:(BOOL)isInit {
  // update
  _tracksCount = tracksCount;

  [self changeAllTrackInfo];
  [self resetScrollView];
  if (isInit) {
    [_deferredCompeleteInit resolve:nil];
  } else {
    [self endLoading];
  }
}

- (void)getAudioDataBefore {
  [_currentTrackScrollView audioDataBeginLoading];
}

- (void)getAudioDataReadyToPlay {
  [_currentTrackScrollView audioDataEndLoading];
}

- (void)endTrack {
  [self nextTrack:YES];
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

  [self hideGenreView];
}

- (void)hideGenreView {
  [self.genreListVC dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - AlarmViewControllerDelegate

- (void)playAlarm {
  [self.musicManager changeGenre:self.musicManager.genreList
               withForcePlayFlag:YES
                    withInitFlag:NO];
}

- (void)hideAlarmView {
  [self.alarmVC dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Utility

- (UIImage *)blurImageFromView:(UIView *)view {
  UIGraphicsBeginImageContextWithOptions(view.frame.size, YES, 0);
  CGContextRef context = UIGraphicsGetCurrentContext();

  CGContextTranslateCTM(context, -view.frame.origin.x, -view.frame.origin.y);
  [view.layer renderInContext:context];
  UIImage *renderedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  CGRect frame = CGRectMake(0, 0, renderedImage.size.width, renderedImage.size.height);
  UIImage * blurImage = [renderedImage applyLightEffectAtFrame:frame];
  
  return blurImage;
}

@end
