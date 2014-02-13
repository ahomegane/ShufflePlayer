//
//  Constants.m
//  ShufflePlayer
//
//  Created by k-watanabe on 2014/02/07.
//  Copyright (c) 2014年 ahomegane. All rights reserved.
//

#import "Constants.h"

NSString *const SC_CLIENT_ID = @"cef5e6d3c083503120892b041572abff";
NSString *const SC_CLIENT_SECRET = @"65e92b9a3659531e926a96bae165cd82";
NSString *const SC_API_REDIRECT_URL = @"test://oauth";

NSString *const SC_TRACK_REQUEST_URL =
    @"https://api.soundcloud.com/tracks.json";
NSString *const SC_LIKE_URL = @"https://api.soundcloud.com/me/favorites/";

NSString *const ARTWORK_IMAGE_SIZE = @"t500x500";

NSString *const GENRE_LIST[] = { @"hiphop", @"electronica", @"breakbeats",
                                 @"house",  @"techno",      @"pop",
                                 @"rock",   @"japanese" };