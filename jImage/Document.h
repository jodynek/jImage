//
//  Document.h
//  jImage
//
//  Created by Petr Jodas on 05.05.13.
//  Copyright (c) 2013 Petr Jodas. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MyWindowController;

@interface Document : NSDocument
{
  MyWindowController *windowsController;
  NSURL *imageURL;
}

@end
