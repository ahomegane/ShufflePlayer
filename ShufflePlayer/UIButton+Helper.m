//
//  UIButton+Helper.m
//  ShufflePlayer
//
//  Created by k-watanabe on 2014/02/10.
//  Copyright (c) 2014年 ahomegane. All rights reserved.
//

#import "UIButton+Helper.h"
#import <objc/runtime.h>

@implementation UIButton (Helper)

static NSString *const STRING_TAG_KEY = @"StringTagKey";

- (NSString *)getStringTag{
  return objc_getAssociatedObject(self, CFBridgingRetain(STRING_TAG_KEY));
}

- (void)setStringTag:(NSString *) stringTag {
  objc_setAssociatedObject(self,
                           CFBridgingRetain(STRING_TAG_KEY),
                           stringTag,
                           OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end
