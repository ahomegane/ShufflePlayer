//
//  ViewController.h
//  ShufflePlayer
//
//  Created by Keiichiro Watanabe on 2013/10/17.
//  Copyright (c) 2013年 ahomegane. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "GenreListViewController.h"

@interface ViewController : UIViewController <GenreListViewControllerDelegate, AVAudioPlayerDelegate>

-(void)selectGenre:(NSArray *)genreList;

@end
