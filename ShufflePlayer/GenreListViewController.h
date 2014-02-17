//
//  GenreListViewController.h
//  ShufflePlayer
//
//  Created by k-watanabe on 2014/02/17.
//  Copyright (c) 2014年 ahomegane. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GenreListViewControllerDelegate

- (void)selectGenre:(NSArray *)genreList;
- (void)hideGenreView;

@end

@interface GenreListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

- (void)setBlurImage:(UIImage *)blurImage;
@property(retain, nonatomic) id<GenreListViewControllerDelegate> delegate;
@property(nonatomic, retain) NSArray *genreData;

@end
