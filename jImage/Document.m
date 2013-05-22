//
//  Document.m
//  jImage
//
//  Created by Petr Jodas on 05.05.13.
//  Copyright (c) 2013 Petr Jodas. All rights reserved.
//

#import "Document.h"
#import "MyWindowController.h"

@implementation Document

- (id)init
{
  self = [super init];
  if (self)
  {
  }
  return self;
}

- (void)makeWindowControllers
{
  windowsController = [[MyWindowController alloc] initWithWindowNibName:@"Document"];
  if (imageURL)
    [windowsController readFromURL:imageURL];
  [self addWindowController:windowsController];
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
  if ([typeName compare:@"ImageFile"] == NSOrderedSame )
  {
    BOOL dir;
    [[NSFileManager defaultManager] fileExistsAtPath:[url path] isDirectory:&dir];
    if(!dir)
    {
      imageURL = url;
      [self setFileURL:url];
      [self updateChangeCount:NSChangeCleared];
    }
    else
      return NO;
  }
  return YES;
}

/*
- (BOOL)writeToURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
  if ([typeName compare:@"ImageFile"] == NSOrderedSame ) {
    [windowsController saveImage:[url path]];
  } else {
    NSLog(@"ERROR: dataOfType pTypeName=%@",typeName);
    *outError = [NSError errorWithDomain:NSOSStatusErrorDomain
                                    code:unimpErr
                                userInfo:NULL];
    return NO;
  }
  [self updateChangeCount:NSChangeDone];
  return YES;
}
*/

- (void)saveDocument:(id)sender
{
  [windowsController saveImage:[[windowsController imageURL] path]];
  [self updateChangeCount:NSChangeCleared];
}

+ (BOOL)autosavesInPlace
{
  return NO;
}

@end
