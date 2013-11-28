//
//  ViewController.m
//  ShufflePlayer
//
//  Created by Keiichiro Watanabe on 2013/10/17.
//  Copyright (c) 2013年 ahomegane. All rights reserved.
//

//アカウントは必須か
//ジャンル選択
//バックリンク
//画像サイズ
//ログインいていないときにアラートがでない

//AVAudioPlayer
//http://lab.dolice.net/blog/2013/07/14/objc-av-audio-player/
//切り替え時の遅延　ロード中の検知
//一時停止
//曲が終了したら次の曲へ
//曲進行中の表示

#import "SCUI.h"
#import "ViewController.h"
#import "TrackListViewController.h"

@interface ViewController ()
{
    bool isPause;
    int trackIndex;
    NSMutableArray *tracks;
    NSDictionary *track;
    SCAccount *scaccount;
    NSString *permalinkUrl;
    
    UIImageView *artworkImageView;
    UIImageView *waveformImageView;
    UIButton *titleButton;
    
    UIImage *playImage;
    UIImage *stopImage;
}
@end

@implementation ViewController

//なぜかsynthesizeにしないとエラー
//AVAudioPlayer *player;ではだめ
@synthesize player;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setElement];
    
    SCRequestResponseHandler handler;
    handler = ^(NSURLResponse *response, NSData *data, NSError *error) {
        NSError *jsonError = nil;
        NSJSONSerialization *jsonResponse = [NSJSONSerialization
                                             JSONObjectWithData:data
                                             options:0
                                             error:&jsonError];
        if (!jsonError && [jsonResponse isKindOfClass:[NSArray class]]) {
            tracks = [(NSArray *)jsonResponse mutableCopy];
            tracks = [self filterTracks:tracks];
            trackIndex = 0;
            track = [tracks objectAtIndex:trackIndex];
            [self setMusic];
        }
    };
    
    NSString *resourceURL = @"https://api.soundcloud.com/tracks.json";
    [SCRequest performMethod:SCRequestMethodGET
                  onResource:[NSURL URLWithString:resourceURL]
             usingParameters: [NSDictionary dictionaryWithObjectsAndKeys:
                               @"cef5e6d3c083503120892b041572abff", @"client_id",
//                               @"ahomegane", @"q",
                               @"hiphop", @"genres",
                               @"japan", @"tags",
                               @"public,streamable", @"filter",
                               nil]
                 withAccount:nil
      sendingProgressHandler:nil
             responseHandler:handler];

}

- (id)filterTracks:(NSMutableArray *)_tracks
{
    for(int i = 0; i < [_tracks count]; i++){
        NSDictionary *_track = [_tracks objectAtIndex:i];
        int favorite = [[_track objectForKey:@"favoritings_count"] intValue];
        int contentSize = [[_track objectForKey:@"original_content_size"] intValue] /  1000000;
        if (contentSize > 7 || favorite < 3) {
            [_tracks removeObjectAtIndex:i];
            i--;
        }
    }
    return _tracks;
}

- (void)setElement
{
    artworkImageView = [[UIImageView alloc] init];
    artworkImageView.contentMode = UIViewContentModeScaleAspectFit;
    artworkImageView.frame = CGRectMake(30,70,260,260);
    [self.view addSubview:artworkImageView];
    
    waveformImageView = [[UIImageView alloc] init];
    waveformImageView.contentMode = UIViewContentModeScaleAspectFit;
    waveformImageView.frame = CGRectMake(30,330,260,41);
    waveformImageView.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:waveformImageView];
    
    titleButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    titleButton.frame = CGRectMake(30,380,260,20);
    [self.view addSubview:titleButton];
    
    playImage = [UIImage imageNamed:@"button_play.png"];
    UIButton *playButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    playButton.frame = CGRectMake(139,430,41,48);
    [playButton setImage:playImage forState:UIControlStateNormal];
    [self.view addSubview:playButton];
    [playButton addTarget:self action:@selector( playMusic: ) forControlEvents:UIControlEventTouchUpInside ];
    
    UIImage *prevImage = [UIImage imageNamed:@"button_prev.png"];
    UIButton *prevButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    prevButton.frame = CGRectMake(29,430,40,48);
    [prevButton setImage:prevImage forState:UIControlStateNormal];
    [self.view addSubview:prevButton];
    [prevButton addTarget:self action:@selector( prevMusic: ) forControlEvents:UIControlEventTouchUpInside ];
    
    UIImage *nextImage = [UIImage imageNamed:@"button_next.png"];
    UIButton *nextButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    nextButton.frame = CGRectMake(249,430,40,48);
    [nextButton setImage:nextImage forState:UIControlStateNormal];
    [self.view addSubview:nextButton];
    [nextButton addTarget:self action:@selector( nextMusic: ) forControlEvents:UIControlEventTouchUpInside ];
}

- (void)setMusic
{
    NSString *artworkUrl = [track objectForKey:@"artwork_url"];
    NSLog(@"%@", artworkUrl);
    UIImage *artworkImage;
    if (! [artworkUrl isEqual:[NSNull null]]) {
        NSData *artworkData = [NSData dataWithContentsOfURL:[NSURL URLWithString:artworkUrl]];
        artworkImage = [[UIImage alloc] initWithData:artworkData];
    } else {
        artworkImage = [UIImage imageWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"no_image" ofType:@"png"]];
    }
    artworkImageView.image = artworkImage;
    
    NSString *waveformUrl = [track objectForKey:@"waveform_url"];
    NSData *waveformData = [NSData dataWithContentsOfURL:[NSURL URLWithString:waveformUrl]];
    UIImage *waveformImage = [[UIImage alloc] initWithData:waveformData];
    waveformImageView.image = waveformImage;
    
    NSString *title = [track objectForKey:@"title"];
    permalinkUrl = [track objectForKey:@"permalink_url"];
    [titleButton setTitle:title forState:UIControlStateNormal];
    [titleButton addTarget:self action:@selector( openUrl ) forControlEvents:UIControlEventTouchUpInside ];
}

-(void)openUrl
{
    if (! permalinkUrl) return;
    NSURL* url = [NSURL URLWithString:permalinkUrl];
    [[UIApplication sharedApplication] openURL:url];
}

-(void)prevMusic:(UIButton *)prevButton
{
    if (trackIndex == 0) return;
    trackIndex--;
    track = [tracks objectAtIndex:trackIndex];
    [self setMusic];
    if (player.playing) {
        [player stop];
        [self playMusic:nil];
    }
}

-(void)nextMusic:(UIButton *)nextButton
{
    if (trackIndex == [tracks count] - 1) return;
    trackIndex++;
    track = [tracks objectAtIndex:trackIndex];
    [self setMusic];
    if (player.playing) {
        [player stop];
        [self playMusic:nil];
    }
}

-(void)playMusic:(UIButton *)playButton
{
    
    if (playButton) {
        if (player.playing) {
            if (playImage == nil) playImage = [UIImage imageNamed:@"button_play.png"];
            [playButton setImage:playImage forState:UIControlStateNormal];
            [player pause];
            isPause = true;
            return;
        }
        
        if (stopImage == nil) stopImage = [UIImage imageNamed:@"button_stop.png"];
        [playButton setImage:stopImage forState:UIControlStateNormal];

        if (isPause) {
            [player prepareToPlay];
            [player play];
            isPause = false;
            return;
        }
    }
    
    if (! scaccount) scaccount = [self getAccount];
    if (! scaccount) return;
    
    NSString *streamURL = [track objectForKey:@"stream_url"];
    NSLog(@"%@", streamURL);
    
    [SCRequest performMethod:SCRequestMethodGET
                  onResource:[NSURL URLWithString:streamURL]
             usingParameters:nil
                 withAccount:scaccount
      sendingProgressHandler:nil
             responseHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                 NSError *playerError;
                 player = [[AVAudioPlayer alloc] initWithData:data error:&playerError];
                 [player prepareToPlay];
                 player.currentTime = 0;
                 [player play];
             }];

}

- (id)getAccount
{
    SCAccount *account = [SCSoundCloud account];
    if (account == nil) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Not Logged In"
                              message:@"You must login first"
                              delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        [alert show];
        return nil;
    }
    return account;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction) login:(id) sender
{
    SCLoginViewControllerCompletionHandler handler = ^(NSError *error) {
        if (SC_CANCELED(error)) {
            NSLog(@"Canceled!");
        } else if (error) {
            NSLog(@"Error: %@", [error localizedDescription]);
        } else {
            NSLog(@"Done!");
        }
    };
    
    [SCSoundCloud requestAccessWithPreparedAuthorizationURLHandler:^(NSURL *preparedURL) {
        SCLoginViewController *loginViewController;
        
        loginViewController = [SCLoginViewController
                               loginViewControllerWithPreparedURL:preparedURL
                               completionHandler:handler];
        [self presentViewController:loginViewController animated:YES completion:nil];
    }];
}


- (IBAction) getTracks:(id) sender
{
    SCAccount *account = [SCSoundCloud account];
    if (account == nil) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Not Logged In"
                              message:@"You must login first"
                              delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    SCRequestResponseHandler handler;
    handler = ^(NSURLResponse *response, NSData *data, NSError *error) {
        NSError *jsonError = nil;
        NSJSONSerialization *jsonResponse = [NSJSONSerialization
                                             JSONObjectWithData:data
                                             options:0
                                             error:&jsonError];
        if (!jsonError && [jsonResponse isKindOfClass:[NSArray class]]) {
            TrackListViewController *trackListVC;
            trackListVC = [[TrackListViewController alloc]
                           initWithNibName:@"TrackListViewController"
                           bundle:nil];
            trackListVC.tracks = (NSArray *)jsonResponse;
            [self presentViewController:trackListVC
                               animated:YES completion:nil];
        }
    };
    
    NSString *resourceURL = @"https://api.soundcloud.com/me/tracks.json";
    [SCRequest performMethod:SCRequestMethodGET
                  onResource:[NSURL URLWithString:resourceURL]
             usingParameters:nil
                 withAccount:account
      sendingProgressHandler:nil
             responseHandler:handler];
}

- (IBAction)upload:(id)sender
{
    NSURL *trackURL = [NSURL
                       fileURLWithPath:[
                                        [NSBundle mainBundle]pathForResource:@"example" ofType:@"mp3"]];
    
    SCShareViewController *shareViewController;
    SCSharingViewControllerCompletionHandler handler;
    
    handler = ^(NSDictionary *trackInfo, NSError *error) {
        if (SC_CANCELED(error)) {
            NSLog(@"Canceled!");
        } else if (error) {
            NSLog(@"Error: %@", [error localizedDescription]);
        } else {
            NSLog(@"Uploaded track: %@", trackInfo);
        }
    };
    shareViewController = [SCShareViewController
                           shareViewControllerWithFileURL:trackURL
                           completionHandler:handler];
    [shareViewController setTitle:@"Funny sounds"];
    [shareViewController setPrivate:YES];
    [self presentViewController:shareViewController animated:YES completion:nil];
}

@end
