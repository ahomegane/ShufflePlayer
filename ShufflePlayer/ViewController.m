//
//  ViewController.m
//  ShufflePlayer
//
//  Created by Keiichiro Watanabe on 2013/10/17.
//  Copyright (c) 2013年 ahomegane. All rights reserved.
//

#import "SCUI.h"
#import "ViewController.h"
#import "TrackListViewController.h"

@interface ViewController ()
{
    bool isPlay;
    int trackIndex;
    NSArray *tracks;
    NSDictionary *track;
    
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
    
    [self setControls];
    
    SCRequestResponseHandler handler;
    handler = ^(NSURLResponse *response, NSData *data, NSError *error) {
        NSError *jsonError = nil;
        NSJSONSerialization *jsonResponse = [NSJSONSerialization
                                             JSONObjectWithData:data
                                             options:0
                                             error:&jsonError];
        if (!jsonError && [jsonResponse isKindOfClass:[NSArray class]]) {
            tracks = (NSArray *)jsonResponse;
            
            trackIndex = 1;
            [self changeTrackData:trackIndex];
            [self setMusic];
        }
    };
    
    NSString *resourceURL = @"https://api.soundcloud.com/tracks.json?client_id=cef5e6d3c083503120892b041572abff";
    [SCRequest performMethod:SCRequestMethodGET
                  onResource:[NSURL URLWithString:resourceURL]
             usingParameters:nil
                 withAccount:nil
      sendingProgressHandler:nil
             responseHandler:handler];

}

- (void)changeTrackData:(int)index
{
    track = [tracks objectAtIndex:index];
}

- (void)setMusic
{
    NSString *permalinkUrl = [track objectForKey:@"permalink_url"];
    
    NSString *artworkUrl = [track objectForKey:@"artwork_url"];
    NSLog(@"%@", artworkUrl);
    UIImage *artworkImage;
    UIImageView *artworkImageView;
    if (! [artworkUrl isEqual:[NSNull null]]) {
        NSData *artworkData = [NSData dataWithContentsOfURL:[NSURL URLWithString:artworkUrl]];
        artworkImage = [[UIImage alloc] initWithData:artworkData];
        artworkImageView = [[UIImageView alloc] initWithImage:artworkImage];
        artworkImageView.contentMode = UIViewContentModeScaleAspectFit;
    } else {
        artworkImage = [UIImage imageWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"no_image" ofType:@"png"]];
        artworkImageView = [[UIImageView alloc] initWithImage:artworkImage];
    }
    artworkImageView.frame = CGRectMake(30,
                                        70,
                                        260,
                                        260);
    [self.view addSubview:artworkImageView];
    
    NSString *title = [track objectForKey:@"title"];
    UIButton *titleButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    titleButton.frame = CGRectMake(30,340,260,20);
    [titleButton setTitle:title forState:UIControlStateNormal];
    [self.view addSubview:titleButton];
}

- (void)setControls
{
    if (playImage == nil) playImage = [UIImage imageNamed:@"button_play.png"];
    UIButton *playButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    playButton.frame = CGRectMake(139,390,41,48);
    [playButton setImage:playImage forState:UIControlStateNormal];
    [self.view addSubview:playButton];
    
    [playButton addTarget:self action:@selector( playMusic: ) forControlEvents:UIControlEventTouchUpInside ];
    
    UIImage *prevImage = [UIImage imageNamed:@"button_prev.png"];
    UIButton *prevButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    prevButton.frame = CGRectMake(29,390,40,48);
    [prevButton setImage:prevImage forState:UIControlStateNormal];
    [self.view addSubview:prevButton];
    
    UIImage *nextImage = [UIImage imageNamed:@"button_next.png"];
    UIButton *nextButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    nextButton.frame = CGRectMake(249,390,40,48);
    [nextButton setImage:nextImage forState:UIControlStateNormal];
    [self.view addSubview:nextButton];
}

-(void)playMusic:(UIButton *)playButton
{
    
    if (isPlay) {
        isPlay = false;
        if (playImage == nil) playImage = [UIImage imageNamed:@"button_play.png"];
        [playButton setImage:playImage forState:UIControlStateNormal];
        [player stop];
        return;
    }
    
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
    
    isPlay = true;
    if (stopImage == nil) stopImage = [UIImage imageNamed:@"button_stop.png"];
    [playButton setImage:stopImage forState:UIControlStateNormal];

    NSString *streamURL = [track objectForKey:@"stream_url"];
    NSLog(@"%@", streamURL);
    
    [SCRequest performMethod:SCRequestMethodGET
                  onResource:[NSURL URLWithString:streamURL]
             usingParameters:nil
                 withAccount:account
      sendingProgressHandler:nil
             responseHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                 NSError *playerError;
                 player = [[AVAudioPlayer alloc] initWithData:data error:&playerError];
                 [player prepareToPlay];
                 [player play];
             }];
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
