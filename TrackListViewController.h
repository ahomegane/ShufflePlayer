//
//  TrackListViewController.h
//  ShufflePlayer
//
//  Created by Keiichiro Watanabe on 2013/10/17.
//  Copyright (c) 2013年 ahomegane. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface TrackListViewController : UITableViewController

@property (nonatomic, strong) NSArray *tracks;
@property (nonatomic, strong) AVAudioPlayer *player;

@end
