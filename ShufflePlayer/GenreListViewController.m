//
//  GenreListViewController.m
//  ShufflePlayer
//
//  Created by k-watanabe on 2014/02/17.
//  Copyright (c) 2014年 ahomegane. All rights reserved.
//

#import "GenreListViewController.h"

@interface GenreListViewController () {

  UIImageView *_blurImageView;
  UITableView *_tableView;
  UIView *_backgroundView;
  UIImageView *_checkImageView;
}
@end

@implementation GenreListViewController

@synthesize genreData, delegate, selectedGenreIndex;

#pragma mark - UIViewController

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    [self initElement];
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle {
  return UIStatusBarStyleLightContent;
}

#pragma mark - Instance Method

- (void)setBlurImage:(UIImage *)blurImage {
  _blurImageView.image = blurImage;
}

#pragma mark - View Element

- (void)initElement {
  UIColor *bgColorAlpha = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];

  // ブラー処理用
  _blurImageView = [[UIImageView alloc] initWithFrame:self.view.frame];
  [self.view addSubview:_blurImageView];

  //　背景
  UIView *bgView = [[UIView alloc] initWithFrame:self.view.frame];
  bgView.backgroundColor = bgColorAlpha;
  [self.view addSubview:bgView];

  // タイトル
  UIFont *titleFont =
      [UIFont fontWithName:@"HelveticaNeue-Light" size:18]; // UltraLight

  UIView *titleArea =
      [[UIView alloc] initWithFrame:CGRectMake(15, 40, 290, 24)];
  [self.view addSubview:titleArea];

  UIImage *iconImage = [UIImage imageNamed:@"title_genre"];
  UIImageView *iconImageView = [[UIImageView alloc] initWithImage:iconImage];
  [titleArea addSubview:iconImageView];

  UILabel *title = [[UILabel alloc]
      initWithFrame:CGRectMake(32, 0, 230, titleArea.frame.size.height)];
  title.font = titleFont;
  title.textColor = [UIColor whiteColor];
  title.text = @"Select Genre";
  title.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
  [titleArea addSubview:title];

  UIImage *closeImage = [UIImage imageNamed:@"button_close"];
  UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [closeButton setImage:closeImage forState:UIControlStateNormal];
  closeButton.frame =
      CGRectMake(titleArea.frame.size.width - closeImage.size.width, -3,
                 closeImage.size.width, closeImage.size.height);
  [closeButton addTarget:self
                  action:@selector(touchCloseButton:)
        forControlEvents:UIControlEventTouchUpInside];
  [titleArea addSubview:closeButton];

  //　テーブルビュー
  _backgroundView = [[UIView alloc] init];
  _backgroundView.backgroundColor =
      [UIColor colorWithRed:1 green:1 blue:1 alpha:1.0];

  int marginTop = 80;
  _tableView = [[UITableView alloc]
      initWithFrame:CGRectMake(0, marginTop, self.view.frame.size.width,
                               self.view.frame.size.height - marginTop)];
  _tableView.delegate = self;
  _tableView.dataSource = self;
  _tableView.separatorColor = [UIColor whiteColor];
  _tableView.backgroundColor = [UIColor clearColor];
  //  _tableView.rowHeight = 50;

  //　border
  //  CALayer *bottorTop = [CALayer layer];
  //  bottorTop.frame = CGRectMake(0, 0, _tableView.frame.size.width, 0.5f);
  //  bottorTop.backgroundColor = [UIColor whiteColor].CGColor;
  //  [_tableView.layer addSublayer:bottorTop];

  [self.view addSubview:_tableView];

  _checkImageView = [[UIImageView alloc]
      initWithImage:[UIImage imageNamed:@"icon_table_selected"]];
}

#pragma mark Event Listener

- (void)touchCloseButton:(id)sender {
  [self.delegate hideGenreView];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  // Return the number of sections.
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
  // Return the number of rows in the section.
  return [self.genreData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  NSLog(@"call");
  static NSString *CellIdentifier = @"Cell";
  UITableViewCell *cell =
      [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                  reuseIdentifier:CellIdentifier];
  }

  cell.textLabel.text = self.genreData[indexPath.row];
  cell.backgroundColor = [UIColor clearColor];
  cell.textLabel.textColor = [UIColor whiteColor];
  cell.textLabel.highlightedTextColor =
      [UIColor colorWithRed:0.10196078431372549
                      green:0.10196078431372549
                       blue:0.10196078431372549
                      alpha:1.0];
  cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
  cell.selectedBackgroundView = _backgroundView;

  if (indexPath.row == 0) {
    CGRect frame = _checkImageView.frame;
    _checkImageView.frame =
        CGRectMake(cell.frame.size.width - frame.size.width - 15,
                   cell.center.y - frame.size.height / 2, frame.size.width,
                   frame.size.height);
  }

  if (indexPath.row == self.selectedGenreIndex) {
    [cell addSubview:_checkImageView];
  }

  return cell;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath
 *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView
 commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
 forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath]
 withRowAnimation:UITableViewRowAnimationFade];
 }
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the
 array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath
 *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath
 *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in
// -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];

  [_checkImageView removeFromSuperview];

  UITableViewCell *cell = [_tableView cellForRowAtIndexPath:indexPath];
  [cell addSubview:_checkImageView];
  NSLog(@"%@", cell.textLabel.text);
  [self.delegate selectGenre:cell.textLabel.text];
}

@end
