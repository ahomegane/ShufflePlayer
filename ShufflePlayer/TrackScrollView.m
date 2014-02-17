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

@interface TrackScrollView () {

  AccountManager *_accountManager;

  UIImageView *_artworkImageView;
  UIImageView *_waveformImageView;
  UIImageView *_waveformSequenceView;
  UIButton *_titleButton;
  UIButton *_likeButton;
  UIButton * _artworkScLogoButton;
  UIImage* _likeImage;
  UIImage* _likeImageOn;
}
@end

@implementation TrackScrollView

@synthesize artworkImage, title;

#pragma mark - Initialize

- (id)initWithFrame:(CGRect)frame withAccountManagerInstance: (AccountManager*) accountManager {
  self = [super initWithFrame:frame];
  if (self) {
    // Initialization code    
    [self initElement];
    _accountManager = accountManager;
  }
  return self;
}

#pragma mark - View Element

- (void)initElement {

  CGRect artworkFrame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.width);
  
  UIView * artworkArea = [[UIView alloc]initWithFrame:artworkFrame];
  [self addSubview:artworkArea];
  
  _artworkImageView = [[UIImageView alloc] init];
  _artworkImageView.frame = artworkFrame;
  _artworkImageView.contentMode = UIViewContentModeScaleAspectFit;
  [artworkArea addSubview:_artworkImageView];
  
  UIImage * artworkScLogoImage = [UIImage imageNamed:@"artwork_sc_logo"];
  _artworkScLogoButton = [UIButton buttonWithType:UIButtonTypeCustom];
  _artworkScLogoButton.frame = CGRectMake(artworkFrame.size.width - 60, artworkFrame.size.height - 16, artworkScLogoImage.size.width, artworkScLogoImage.size.height);
  [_artworkScLogoButton setImage:artworkScLogoImage forState:UIControlStateNormal];
  [artworkArea addSubview:_artworkScLogoButton];
  [_artworkScLogoButton addTarget:self
                           action:@selector(touchTitleButton:)
                 forControlEvents:UIControlEventTouchUpInside];

  CGRect waveformFrame = CGRectMake(0, self.frame.size.height - 50, self.frame.size.width, 50);
  
  _waveformSequenceView = [[UIImageView alloc] initWithFrame: waveformFrame];
  _waveformSequenceView.backgroundColor = [UIColor colorWithRed:0.310 green:0.310 blue:0.310 alpha:1.0];
  [self addSubview:_waveformSequenceView];

  _waveformImageView = [[UIImageView alloc] initWithFrame:waveformFrame];
  _waveformImageView.contentMode = UIViewContentModeScaleAspectFit;
  [self addSubview:_waveformImageView];

  _titleButton = [UIButton buttonWithType:UIButtonTypeCustom];
  _titleButton.frame = CGRectMake(self.frame.size.width / 2 - 125, self.frame.size.height - 125, 250, 14);
  _titleButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];//UltraLight
  [_titleButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  [self addSubview:_titleButton];
  [_titleButton addTarget:self
                   action:@selector(touchTitleButton:)
         forControlEvents:UIControlEventTouchUpInside];

  _likeImage = [UIImage imageNamed:@"button_like"];
  _likeImageOn = [UIImage imageNamed:@"button_like_on"];
  _likeButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [_likeButton setImage:_likeImage forState:UIControlStateNormal];
  _likeButton.frame = CGRectMake(self.frame.size.width / 2 - _likeImage.size.width / 2, self.frame.size.height - 97, _likeImage.size.width, _likeImage.size.height);
  [_likeButton addTarget:self
                  action:@selector(touchLikeButton:)
        forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:_likeButton];
  _likeButton.tag = 0;
  
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
    self.artworkImage = [UIImage imageNamed:@"artwork_no_image"];
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
  
  [_artworkScLogoButton setStringTag:permalinkUrl];

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
  [self openUrlOnSafari:permalinkUrl];
}

- (void)openUrlOnSafari:(NSString *)permalinkUrl {
  NSURL *url = [NSURL URLWithString:permalinkUrl];
  [[UIApplication sharedApplication] openURL:url];
}

- (void)touchLikeButton:(id)sender {
  UIButton *button = sender;
  NSString *trackId = [button getStringTag];
  if (button.tag == 0) {// put
    [_accountManager sendLike:trackId method:@"post" withCompleteCallback:^(NSError * error){
      if (SC_CANCELED(error)) {
        NSLog(@"Canceled!");
      } else if (error) {
        NSLog(@"Error: %@", [error localizedDescription]);
      } else {
        NSLog(@"Liked track: %@", trackId);
        [_likeButton setImage:_likeImageOn forState:UIControlStateNormal];
        button.tag = 1;
      }
    }];
  } else {// delete
    [_accountManager sendLike:trackId method:@"delete" withCompleteCallback:^(NSError * error){
      if (SC_CANCELED(error)) {
        NSLog(@"Canceled!");
      } else if (error) {
        NSLog(@"Error: %@", [error localizedDescription]);
      } else {
        NSLog(@"Like deleted track: %@", trackId);
        [_likeButton setImage:_likeImage forState:UIControlStateNormal];
        button.tag = 0;
      }
    }];
  }
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
