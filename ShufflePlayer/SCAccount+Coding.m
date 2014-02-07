//
//  SCAccount+Coding.m
//  ShufflePlayer
//
//  Created by k-watanabe on 2014/02/07.
//  Copyright (c) 2014年 ahomegane. All rights reserved.
//

#import "SCAccount+Coding.h"

@implementation SCAccount (Coding)

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:oauthAccount forKey:@"scAccount"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super init];
  if (self){
    oauthAccount = [aDecoder decodeObjectForKey:@"scAccount"];
  }
  return self;
}

@end
