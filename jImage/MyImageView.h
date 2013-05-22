//
//  MyImageView.h
//  jImage
//
//  Created by Jodynek on 16.05.13.
//  Copyright (c) 2013 Petr Jodas. All rights reserved.
//

#import <Quartz/Quartz.h>
#import <AppKit/AppKit.h>

@interface MyImageView : IKImageView
{
  
}

- (NSSize)getRealImageSize:(NSURL *)url;
@end
