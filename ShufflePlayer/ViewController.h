//
//  ViewController.h
//  ShufflePlayer
//
//  Created by Keiichiro Watanabe on 2013/10/17.
//  Copyright (c) 2013年 ahomegane. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "TrackScrollView.h"
#import "MusicManager.h"
#import "AccountManager.h"
#import "GenreListViewController.h"
#import "AlarmViewController.h"

@interface ViewController
    : UIViewController <MusicManagerDelegate, GenreListViewControllerDelegate,
                        AccountManagerDelegate, AVAudioSessionDelegate,
                        UIScrollViewDelegate, AlarmViewControllerDelegate>

@property(retain, nonatomic) MusicManager *musicManager;
@property(retain, nonatomic) AccountManager *accountManager;

@end