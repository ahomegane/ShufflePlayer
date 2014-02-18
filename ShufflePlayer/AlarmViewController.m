//
//  AlarmViewController.m
//  ShufflePlayer
//
//  Created by k-watanabe on 2014/02/13.
//  Copyright (c) 2014年 ahomegane. All rights reserved.
//

#import "AlarmViewController.h"
#import "STDeferred.h"

@interface AlarmViewController () {
  NSTimer *_timer;
  
  UILabel *_selectedTimeLabel;
  UILabel *_timeLabelMessage;
  UIDatePicker *_picker;
  NSDateFormatter *_formatter;
  UIImageView * _blurImageView;
  
  MusicManager* _musicManager;
}
@end

@implementation AlarmViewController

NSString *const CLEAR_TEXT = @"-- : --";

@synthesize delegate, selectedTime;

#pragma mark - ViewController

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil withMusicManagerInstance: (MusicManager*) musicManager {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    _musicManager = musicManager;
    
    self.selectedTime = [self restoreSelectedTimeFromUserDefault];
    if (self.selectedTime != nil) [self startTimer];
    
    [self initElement];
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
  NSLog(@"viewWillAppear");
  if (_picker) {
    _picker.date = [NSDate date];
  }
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle {
  return UIStatusBarStyleLightContent;
}

#pragma mark - Instance Method

- (void)setBlurImage:(UIImage *)blurImage {
  _blurImageView.image = blurImage;
}

- (void)overrideSelectedTime:(NSDate*)date {
  NSLog(@"overrideSelectedTime");
  self.selectedTime = date;
}

#pragma mark - View Element

- (void)initElement {

  UIColor * bgColorAlpha = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
  UIColor * linkColor = [UIColor colorWithRed:0.3803921568627451 green:0.8 blue:0.8588235294117647 alpha:1.0];
  UIColor * bgPickerView = [UIColor colorWithRed:0.624 green:0.624 blue:0.624 alpha:1];
  
  // ブラー処理用
  _blurImageView = [[UIImageView alloc] initWithFrame:self.view.frame];
  [self.view addSubview: _blurImageView];

  //　背景
  UIView * bgView = [[UIView alloc] initWithFrame:self.view.frame];
  bgView.backgroundColor = bgColorAlpha;
  [self.view addSubview:bgView];
  
  // タイトル
  UIFont* titleFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];//UltraLight
  
  UIView *titleArea = [[UIView alloc]initWithFrame:CGRectMake(15, 40, 290, 24)];
  [self.view addSubview:titleArea];

  UIImage *iconImage = [UIImage imageNamed:@"title_alarm"];
  UIImageView * iconImageView = [[UIImageView alloc]initWithImage:iconImage];
  [titleArea addSubview:iconImageView];
  
  UILabel * title = [[UILabel alloc]initWithFrame:CGRectMake(32, 0, 230, titleArea.frame.size.height)];
  title.font = titleFont;
  title.textColor = [UIColor whiteColor];
  title.text = @"Alarm Clock";
  title.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
  [titleArea addSubview:title];
  
  UIImage *closeImage = [UIImage imageNamed:@"button_close"];
  UIButton * closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [closeButton setImage:closeImage forState:UIControlStateNormal];
  closeButton.frame = CGRectMake(titleArea.frame.size.width - closeImage.size.width, -3, closeImage.size.width, closeImage.size.height);
  [closeButton addTarget:self
                  action:@selector(touchCloseButton:)
        forControlEvents:UIControlEventTouchUpInside];
  [titleArea addSubview:closeButton];
  
  // 時間表示
  _selectedTimeLabel = [[UILabel alloc]
                        initWithFrame:CGRectMake(0, 120, self.view.frame.size.width, 87.5)];
  _selectedTimeLabel.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:87.5];
  _selectedTimeLabel.textColor = [UIColor whiteColor];
  _selectedTimeLabel.textAlignment = NSTextAlignmentCenter;
  [self.view addSubview:_selectedTimeLabel];
  
  _timeLabelMessage = [[UILabel alloc]
                      initWithFrame:CGRectMake(0, 230, self.view.frame.size.width, 12)];
  _timeLabelMessage.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:12];
  _timeLabelMessage.textColor = [UIColor whiteColor];
  _timeLabelMessage.textAlignment = NSTextAlignmentCenter;
  [self.view addSubview:_timeLabelMessage];
  
  [self updateTimeLabel:self.selectedTime];

  // ボタン
  CGRect frameButton = CGRectMake(0, 0, 50, 20);
  CGPoint buttonCenter = CGPointMake(100, self.view.frame.size.height - 260);
  UIFont * buttonFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:20];//UltraLight

  UIButton *saveButton = [UIButton buttonWithType:UIButtonTypeCustom];
  saveButton.frame = frameButton;
  saveButton.center = buttonCenter;
  saveButton.titleLabel.font = buttonFont;
  saveButton.titleLabel.textAlignment = NSTextAlignmentCenter;
  [saveButton setTitleColor:linkColor forState:UIControlStateNormal];
  [saveButton setTitle:@"Save" forState:UIControlStateNormal];
  [saveButton addTarget:self
                 action:@selector(touchSaveButton:)
       forControlEvents:UIControlEventTouchUpInside];

  UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  clearButton.frame = frameButton;
  buttonCenter.x = self.view.frame.size.width - buttonCenter.x;
  clearButton.center = buttonCenter;
  clearButton.titleLabel.font =  buttonFont;
  clearButton.titleLabel.textAlignment = NSTextAlignmentCenter;
  [clearButton setTitleColor:linkColor forState:UIControlStateNormal];
  [clearButton setTitle:@"Clear" forState:UIControlStateNormal];
  [clearButton addTarget:self
                  action:@selector(touchClearButton:)
        forControlEvents:UIControlEventTouchUpInside];

  [self.view addSubview:saveButton];
  [self.view addSubview:clearButton];
  
  // picker
  _picker = [[UIDatePicker alloc] init];
  _picker.datePickerMode = UIDatePickerModeTime;
  _picker.minuteInterval = 1;
  
  int margin = 0;
  CGRect frame = _picker.frame;
  frame.size.height += margin * 2;
  frame.origin.y = self.view.frame.size.height - frame.size.height;
  
  UIView * pickerView = [[UIView alloc] initWithFrame:frame];
  pickerView.backgroundColor = bgPickerView;
  
  frame = _picker.frame;
  frame.origin.y = margin;
  _picker.frame = frame;
  
  [pickerView addSubview:_picker];
  [self.view addSubview:pickerView];
  
}

#pragma mark Event Listener

- (void)touchSaveButton:(id)sender {
  self.selectedTime = _picker.date;
  [self updateTimeLabel:self.selectedTime];
  
  [self saveSelectedTimeToUserDefault:self.selectedTime];
  [self startTimer];
}

- (void)touchClearButton:(id)sender {
  [self updateTimeLabel:nil];
  
  [self clearTimer];
}

- (void)touchCloseButton:(id)sender {
  [self.delegate hideAlarmView];
}

- (void)updateTimeLabel:(NSDate*) time {
  if (time != nil) {
    NSString* str = [self formatDate:time];
    _selectedTimeLabel.text = str;
    _timeLabelMessage.text = [NSString stringWithFormat:@"%@ に自動再生を開始します", str];
  } else {
    _selectedTimeLabel.text = CLEAR_TEXT;
    _timeLabelMessage.text = @"設定されていません";
  }
}

#pragma mark - Timer

- (void)startTimer {
  [self clearTimer];
  
  _timer = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                            target:self
                                          selector:@selector(timeChecker:)
                                          userInfo:nil
                                           repeats:YES];
  [self setNotification: _picker.date];
}

- (void)clearTimer {
  [_timer invalidate];
  _timer = nil;
  
  [self clearNotification];
}

- (void)timeChecker:(NSTimer *)timer {
  if (_musicManager.playing) return;
  
  NSDate *now = [NSDate date];
  
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  [formatter setDateFormat:@"HH:mm"];
  NSString *nowStr = [formatter stringFromDate:now];
//  NSLog(@"%@", nowStr);
  
  NSString *selectedTimeStr = [formatter stringFromDate:self.selectedTime];
  if ([nowStr isEqualToString:selectedTimeStr]) {
    
    [self clearTimer];
    
    [self.delegate hideAlarmView];
    [self.delegate playAlarm];
    
    // 設定が分刻みのため連続してlunchAlarmが呼ばてしまうのを防ぐため、61秒間はtimerを止める
    [STDeferred timeout:61.0f].then(^(id ret) {
      [self startTimer];
    });
  }
}

# pragma mark - LocalNotification

- (void)setNotification:(NSDate *) fireDate {
  [self clearNotification];

  UILocalNotification *localNotification = [[UILocalNotification alloc] init];
  localNotification.fireDate = fireDate;
  localNotification.repeatInterval = NSDayCalendarUnit;
  localNotification.alertBody = @"Time To Play Music";
  localNotification.timeZone = [NSTimeZone localTimeZone];
  localNotification.soundName = UILocalNotificationDefaultSoundName;
  localNotification.alertAction = @"OPEN";
  localNotification.userInfo = @{@"id" : @"alarm"};
  [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

- (void)clearNotification {
  [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

#pragma mark - UserDefault Control

- (BOOL)saveSelectedTimeToUserDefault:(NSDate*)date {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:date forKey:@"alarmTime"];
  BOOL isSuccess = [defaults synchronize];
  return isSuccess;
}

- (NSDate *)restoreSelectedTimeFromUserDefault {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSDate *date = [defaults objectForKey:@"alarmTime"];
  return date;
}

#pragma mark - utility

- (NSString*)formatDate:(NSDate*) date {
  if (_formatter == nil) {
    _formatter = [[NSDateFormatter alloc] init];
    [_formatter setDateFormat:@"HH:mm"];
  }
  return [_formatter stringFromDate: date];
}

@end
