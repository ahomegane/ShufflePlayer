//
//  AccountManager.m
//  ShufflePlayer
//
//  Created by k-watanabe on 2014/02/07.
//  Copyright (c) 2014年 ahomegane. All rights reserved.
//

#import "AccountManager.h"
#import "SCUI.h"
#import "Constants.h"

@interface AccountManager () {
  SCAccount *_scAccount;
}
@end

@implementation AccountManager

@synthesize delegate;

#pragma mark - Initialize

- (id)init {
  self = [super init];
  if (self) {
//    [self clearUserDefault];
  }
  return self;
}

#pragma mark - Instance Method

- (void)sendLike:(NSString *)trackId
                  method:(NSString *)method
    withCompleteCallback:(void (^)(NSError *error))callback {
  NSString *resourcetURL =
      [NSString stringWithFormat:@"%@%@", SC_LIKE_URL, trackId];

  [self getScAccount: ^(SCAccount * scAccount)
   {
  
     SCRequestResponseHandler handler =
     ^(NSURLResponse * response, NSData * data, NSError * error) {
       if (error) {
         NSString *errorStr = [error localizedDescription];
         
         if ([errorStr isEqualToString:@"HTTP Error: 401"]) {
           _scAccount = nil;
           [self clearUserDefault];
           
           // 再帰処理
           [self sendLike:trackId method:method withCompleteCallback:callback];
         }
       }
       
       if (callback != nil)
         callback(error);
     };
     
    if (scAccount != nil) {
      _scAccount = scAccount;
      [SCRequest performMethod:[method isEqualToString:@"delete"] ? SCRequestMethodDELETE : SCRequestMethodPUT
                    onResource:[NSURL URLWithString:resourcetURL]
               usingParameters:nil
                   withAccount:_scAccount
        sendingProgressHandler:nil
               responseHandler:handler];
    }
  }];
}

#pragma mark - Private Method

- (void)getScAccount:(void (^)(SCAccount* scAccount))callback {
  SCAccount *scAccount;

  if (_scAccount == nil) {
    
    NSLog(@"scAccount restore from UserDefaults");
    scAccount = [self restoreScAccount];

    if (scAccount == nil) {
      [self login: nil withLoginedCallback:^()
      {

        SCAccount *scAccount = [SCSoundCloud account];

        if (scAccount != nil) {
          [self saveScAccount:scAccount];
          NSLog(@"scAccount save to UserDefaults");
        }
        if (callback != nil)
          callback(scAccount);
      }];

    } else {
      if (callback != nil)
        callback(scAccount);
    }

  } else {
    scAccount = _scAccount;

    if (callback != nil)
      callback(scAccount);
  }
}

- (void)login:(id)sender withLoginedCallback:(void (^)())callback {
  SCLoginViewControllerCompletionHandler handler = ^(NSError * error) {
    if (SC_CANCELED(error)) {
      NSLog(@"login Canceled!");
    } else if (error) {
      NSLog(@"Error login: %@", [error localizedDescription]);
    } else {
      if (callback != nil)
        callback();
    }
  };

  [SCSoundCloud requestAccessWithPreparedAuthorizationURLHandler:^(NSURL *preparedURL)
  {
    SCLoginViewController *loginViewController;

    loginViewController =
        [SCLoginViewController loginViewControllerWithPreparedURL:preparedURL
                                                completionHandler:handler];
    [self.delegate showAccountView:loginViewController];
  }];
}

#pragma mark - UserDefault Control

- (BOOL)saveScAccount:(SCAccount *)scAccount {
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:scAccount];
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:data forKey:@"scAccount"];
  BOOL isSuccess = [defaults synchronize];
  return isSuccess;
}

- (SCAccount *)restoreScAccount {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSData *data = [defaults dataForKey:@"scAccount"];
  if (data == nil) {
    return nil;
  }
  SCAccount *scAccount = [NSKeyedUnarchiver unarchiveObjectWithData:data];
  return scAccount;
}

- (void)clearUserDefault {
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"scAccount"];
}

@end
