//
//  ViewController.h
//  ShufflePlayer
//
//  Created by Keiichiro Watanabe on 2013/10/17.
//  Copyright (c) 2013年 ahomegane. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "MusicManager.h"
#import "AccountManager.h"
#import "TrackScrollView.h"
#import "GenreListViewController.h"
#import "AlarmViewController.h"

@interface ViewController
    : UIViewController <AVAudioSessionDelegate, UIScrollViewDelegate,
                        MusicManagerDelegate, AccountManagerDelegate,
                        GenreListViewControllerDelegate,
                        AlarmViewControllerDelegate>

@property(retain, nonatomic) MusicManager *musicManager;
@property(retain, nonatomic) GenreListViewController *genreListVC;
@property(retain, nonatomic) AlarmViewController *alarmVC;

@property BOOL lunchAlarmFlag;

@end