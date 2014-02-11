//
//  AccountManager.h
//  ShufflePlayer
//
//  Created by k-watanabe on 2014/02/07.
//  Copyright (c) 2014年 ahomegane. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AccountManagerDelegate

- (void)showSubView:(id)view;

@end

@interface AccountManager : NSObject {
  id<AccountManagerDelegate> delegate;
}

- (void)getScAccount:(void (^)())callback;
- (void)sendLike: (NSDictionary *)track withCompleteCallback:(void (^)(NSError * error))callback;
@property(retain, nonatomic) id<AccountManagerDelegate> delegate;

@end
