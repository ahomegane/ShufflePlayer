//
//  AlarmViewController.h
//  ShufflePlayer
//
//  Created by k-watanabe on 2014/02/13.
//  Copyright (c) 2014年 ahomegane. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AlarmViewControllerDelegate

- (void)playAlarm;
- (void)hideAlarmView;

@end

@interface AlarmViewController : UIViewController {
  id<AlarmViewControllerDelegate> delegate;
}

@property NSDate *selectedTime;
@property(retain, nonatomic) id<AlarmViewControllerDelegate> delegate;

@end
