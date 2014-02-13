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
  
  UILabel* _selectedTimeLabel;
  UIDatePicker *_picker;
}
@end

@implementation AlarmViewController

NSString *const CLEAR_TEXT = @"-- : --";

@synthesize delegate, selectedTime;

#pragma mark - ViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  [self initElement];
  [self clearTimer];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - View Element

- (void)initElement {
  _picker = [[UIDatePicker alloc]init];
  _picker.datePickerMode = UIDatePickerModeTime;
  _picker.minuteInterval = 1;
  CGRect frame = CGRectZero;
  frame.origin.y = self.view.frame.origin.y + (self.view.frame.size.height - _picker.frame.size.height);
  _picker.frame = frame;
  [_picker addTarget:self
                 action:@selector(datePickerValueChanged:)
       forControlEvents:UIControlEventValueChanged];
  [self.view addSubview:_picker];
  
  UIButton *saveButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  saveButton.frame = CGRectMake(0, 0, 100, 20);
  saveButton.center = CGPointMake(self.view.frame.size.width*1/4, 300);
  [saveButton setTitle:@"Save" forState:UIControlStateNormal];
  [saveButton addTarget:self
                 action:@selector(touchSaveButton:)
       forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:saveButton];
  
  UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  clearButton.frame = CGRectMake(0, 0, 100, 20);
  clearButton.center = CGPointMake(self.view.frame.size.width*3/4, 300);
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
  
  _selectedTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,100,self.view.frame.size.width, 100)];
  _selectedTimeLabel.center = CGPointMake(self.view.frame.size.width/2, 150);
  _selectedTimeLabel.text = CLEAR_TEXT;
  _selectedTimeLabel.font = [UIFont systemFontOfSize:100];
  _selectedTimeLabel.textAlignment = NSTextAlignmentCenter;
  [self.view addSubview:_selectedTimeLabel];
}

#pragma mark Event Listener

- (void)touchSaveButton:(id)sender {
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  [formatter setDateFormat:@"HH:mm"];
  _selectedTimeLabel.text = [formatter stringFromDate:_picker.date];

  self.selectedTime = _picker.date;
  [self setTimer];
}

- (void)touchClearButton:(id)sender {
  _selectedTimeLabel.text = CLEAR_TEXT;
  
  [self clearTimer];
}

- (void)touchCloseButton:(id)sender {
  [self.delegate hideAlarmView];
}

#pragma mark - DataPicker

- (void)datePickerValueChanged:(id)sender {
  
}

#pragma mark - Timer

- (void)setTimer {
  _timer = [NSTimer scheduledTimerWithTimeInterval:10.0f
                                            target:self
                                          selector:@selector(timeCheck:)
                                          userInfo:nil
                                           repeats:YES];
}

- (void)clearTimer {
  [_timer invalidate];
  _timer = nil;
}

- (void)timeCheck:(NSTimer *)timer {
  NSDate* now = [NSDate date];
  NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
  [formatter setDateFormat:@"HH:mm"];
  NSString* nowStr = [formatter stringFromDate:now];
  NSLog(@"%@", nowStr);
  
  NSString* selectedTimeStr = [formatter stringFromDate:self.selectedTime];
  if ([nowStr isEqualToString:selectedTimeStr]) {
    [self clearTimer];
    [self.delegate hideAlarmView];
    [self.delegate playAlarm];
    
    NSTimeInterval interval = 60.0f + 30.0f;
    [STDeferred timeout:interval].then(^(id ret) {
      [self setTimer];
    });
  }
}

@end
