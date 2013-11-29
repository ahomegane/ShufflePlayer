//
//  GenreListViewController.h
//  ShufflePlayer
//
//  Created by k-watanabe on 2013/11/29.
//  Copyright (c) 2013年 ahomegane. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GenreListViewControllerDelegate

-(void)selectGenre:(NSArray *)genreList;

@end

@interface GenreListViewController : UITableViewController
{
     id <GenreListViewControllerDelegate> delegate;
}

@property(retain, nonatomic)id <GenreListViewControllerDelegate> delegate;
@property(nonatomic, strong) NSArray *genreData;

@end
