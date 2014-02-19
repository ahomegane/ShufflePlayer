//
//  AlarmViewController.h
//  ShufflePlayer
//
//  Created by k-watanabe on 2014/02/13.
//  Copyright (c) 2014年 ahomegane. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MusicManager.h"

@protocol AlarmViewControllerDelegate

- (void)playAlarm;
- (void)hideAlarmView;

@end

@interface AlarmViewController : UIViewController

- (id)initWithNibName:(NSString*)nibNameOrNil
                      bundle:(NSBundle*)nibBundleOrNil
    withMusicManagerInstance:(MusicManager*)musicManager;
- (void)setBlurImage:(UIImage*)blurImage;
- (void)overrideSelectedTime:(NSDate*)date;
@property NSDate* selectedTime;
@property(retain, nonatomic) id<AlarmViewControllerDelegate> delegate;

@end
