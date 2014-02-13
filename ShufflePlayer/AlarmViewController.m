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
  UIDatePicker *_picker;
  NSDateFormatter *_formatter;
  
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
    
    self.selectedTime = [self restoreSelectedTime];
    if (self.selectedTime != nil) [self setTimer];

  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self initElement];
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

#pragma mark - Instance Method

- (void)overrideSelectedTime:(NSDate*)date {
  NSLog(@"overrideSelectedTime");
  self.selectedTime = date;
}

#pragma mark - View Element

- (void)initElement {
  _picker = [[UIDatePicker alloc] init];
  _picker.datePickerMode = UIDatePickerModeTime;
  _picker.minuteInterval = 1;
  CGRect frame = CGRectZero;
  frame.origin.y = self.view.frame.origin.y +
                   (self.view.frame.size.height - _picker.frame.size.height);
  _picker.frame = frame;
  [self.view addSubview:_picker];

  UIButton *saveButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  saveButton.frame = CGRectMake(0, 0, 100, 20);
  saveButton.center = CGPointMake(self.view.frame.size.width * 1 / 4, 300);
  [saveButton setTitle:@"Save" forState:UIControlStateNormal];
  [saveButton addTarget:self
                 action:@selector(touchSaveButton:)
       forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:saveButton];

  UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  clearButton.frame = CGRectMake(0, 0, 100, 20);
  clearButton.center = CGPointMake(self.view.frame.size.width * 3 / 4, 300);
  [clearButton setTitle:@"Clear" forState:UIControlStateNormal];
  [clearButton addTarget:self
                  action:@selector(touchClearButton:)
        forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:clearButton];

  UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  closeButton.frame = CGRectMake(250, 20, 52, 30);
  [closeButton setTitle:@"Close" forState:UIControlStateNormal];
  [self.view addSubview:closeButton];
  [closeButton addTarget:self
                  action:@selector(touchCloseButton:)
        forControlEvents:UIControlEventTouchUpInside];

  _selectedTimeLabel = [[UILabel alloc]
      initWithFrame:CGRectMake(0, 100, self.view.frame.size.width, 100)];
  _selectedTimeLabel.center = CGPointMake(self.view.frame.size.width / 2, 150);

  if (self.selectedTime != nil) {
    _selectedTimeLabel.text = [self formatDate:self.selectedTime];
  } else {
    _selectedTimeLabel.text = CLEAR_TEXT;
  }

  _selectedTimeLabel.font = [UIFont systemFontOfSize:100];
  _selectedTimeLabel.textAlignment = NSTextAlignmentCenter;
  [self.view addSubview:_selectedTimeLabel];
}

#pragma mark Event Listener

- (void)touchSaveButton:(id)sender {
  self.selectedTime = _picker.date;
  _selectedTimeLabel.text = [self formatDate:self.selectedTime];
  [self saveSelectedTime:self.selectedTime];
  [self setTimer];
}

- (void)touchClearButton:(id)sender {
  _selectedTimeLabel.text = CLEAR_TEXT;
  [self clearTimer];
}

- (void)touchCloseButton:(id)sender {
  [self.delegate hideAlarmView];
}

#pragma mark - Timer

- (void)setTimer {
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
  NSLog(@"%@", nowStr);
  
  NSString *selectedTimeStr = [formatter stringFromDate:self.selectedTime];
  if ([nowStr isEqualToString:selectedTimeStr]) {
    
    [self clearTimer];
    
    [self.delegate hideAlarmView];
    [self.delegate playAlarm];
    
    // 設定が分刻みのため連続してlunchAlarmが呼ばてしまうのを防ぐため、61秒間はtimerを止める
    [STDeferred timeout:61.0f].then(^(id ret) {
      [self setTimer];
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

- (BOOL)saveSelectedTime:(NSDate*)date {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:date forKey:@"alarmTime"];
  BOOL isSuccess = [defaults synchronize];
  return isSuccess;
}

- (NSDate *)restoreSelectedTime {
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
