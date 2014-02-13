//
//  TrackScrollView.m
//  ShufflePlayer
//
//  Created by Keiichiro Watanabe on 2014/02/11.
//  Copyright (c) 2014年 ahomegane. All rights reserved.
//

#import "TrackScrollView.h"
#import "SCUI.h"
#import "Constants.h"
#import "UIButton+Helper.h"
#import "AccountManager.h"

@interface TrackScrollView () {

  AccountManager *_accountManager;

  UIImageView *_artworkImageView;
  UIImageView *_waveformImageView;
  UIImageView *_waveformSequenceView;
  UIButton *_titleButton;
  UIButton *_likeButton;
}
@end

@implementation TrackScrollView

@synthesize artworkImage, title;

#pragma mark - Initialize

- (id)initWithFrame:(CGRect)frame withAccountManagerInstance:accountManager {
  self = [super initWithFrame:frame];
  if (self) {
    [self initElement];
    // Initialization code
  }
  return self;
}

#pragma mark - View Element

- (void)initElement {

  _artworkImageView = [[UIImageView alloc] init];
  _artworkImageView.contentMode = UIViewContentModeScaleAspectFit;
  _artworkImageView.frame = CGRectMake(30, 70, 260, 260);
  [self addSubview:_artworkImageView];

  _waveformSequenceView = [[UIImageView alloc] init];
  _waveformSequenceView.frame = CGRectMake(30, 330, 0, 41);
  _waveformSequenceView.backgroundColor = [UIColor lightGrayColor];
  [self addSubview:_waveformSequenceView];

  _waveformImageView = [[UIImageView alloc] init];
  _waveformImageView.contentMode = UIViewContentModeScaleAspectFit;
  _waveformImageView.frame = CGRectMake(30, 330, 260, 41);
  [self addSubview:_waveformImageView];

  _titleButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  _titleButton.frame = CGRectMake(30, 380, 260, 20);
  [self addSubview:_titleButton];
  [_titleButton addTarget:self
                   action:@selector(touchTitleButton:)
         forControlEvents:UIControlEventTouchUpInside];

  _likeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  _likeButton.frame = CGRectMake(20, 30, 50, 30);
  [self addSubview:_likeButton];
  [_likeButton setTitle:@"Like" forState:UIControlStateNormal];
  [_likeButton addTarget:self
                  action:@selector(touchLikeButton:)
        forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - Instance Method

- (void)setTrackInfo:(NSDictionary *)track {

  if (track == nil) {
    self.hidden = YES;
    return;
  } else {
    self.hidden = NO;
  }

  NSString *artworkUrl = [track objectForKey:@"artwork_url"];
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
    self.artworkImage = [[UIImage alloc] initWithData:artworkData];
  } else {
    self.artworkImage = [UIImage
        imageWithContentsOfFile:
            [[NSBundle mainBundle] pathForResource:@"no_image" ofType:@"png"]];
  }
  _artworkImageView.image = self.artworkImage;

  NSString *waveformUrl = [track objectForKey:@"waveform_url"];
  NSData *waveformData =
      [NSData dataWithContentsOfURL:[NSURL URLWithString:waveformUrl]];
  UIImage *waveformImage = [[UIImage alloc] initWithData:waveformData];
  _waveformImageView.image = waveformImage;

  self.title = [track objectForKey:@"title"];
  NSString *permalinkUrl = [track objectForKey:@"permalink_url"];
  [_titleButton setTitle:self.title forState:UIControlStateNormal];
  [_titleButton setStringTag:permalinkUrl];

  NSString *trackId = [track objectForKey:@"id"];
  [_likeButton setStringTag:trackId];

  // waveform初期化
  CGRect rect = _waveformSequenceView.frame;
  _waveformSequenceView.frame =
      CGRectMake(rect.origin.x, rect.origin.y, 0, rect.size.height);
}

- (void)updateWaveform:(float)currentTime withTrackDuration:(float)duration {
  CGRect rect = _waveformSequenceView.frame;
  _waveformSequenceView.frame =
      CGRectMake(rect.origin.x, rect.origin.y, 260 * currentTime / duration,
                 rect.size.height);
}

#pragma mark - Private Method
#pragma mark Event Listener

- (void)touchTitleButton:(id)sender {
  UIButton *button = sender;
  NSString *permalinkUrl = [button getStringTag];
  NSLog(@"%@", permalinkUrl);
  [self openUrlOnSafari:permalinkUrl];
}

- (void)openUrlOnSafari:(NSString *)permalinkUrl {
  NSURL *url = [NSURL URLWithString:permalinkUrl];
  [[UIApplication sharedApplication] openURL:url];
}

- (void)touchLikeButton:(id)sender {
  UIButton *button = sender;
  NSString *trackId = [button getStringTag];
  [_accountManager sendLike:trackId withCompleteCallback:^(NSError * error){
    if (SC_CANCELED(error)) {
      NSLog(@"Canceled!");
    } else if (error) {
      NSLog(@"Error: %@", [error localizedDescription]);
    } else {
      NSLog(@"Liked track: %@", trackId);
    }
  }];
}

#pragma mark - UIScrollViewDelegate

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
