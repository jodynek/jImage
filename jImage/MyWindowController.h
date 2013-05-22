//
//  MyWindowController.h
//  jImage
//
//  Created by Petr Jodas on 10.05.13.
//  Copyright (c) 2013 Petr Jodas. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class IKImageView;
@class IKSaveOptions;
@class DMSplitView;

@interface MyWindowController : NSWindowController
{
  NSDictionary * mImageProperties;
  NSString *     mImageUTType;
  IKSaveOptions * mSaveOptions;
  NSURL *_imageURL;
  MyWindowController *windowsController;
  NSMutableArray * mListOfImages;
  int iDirPos;
}
@property (weak) IBOutlet DMSplitView *splitView;
@property (weak) IBOutlet NSSegmentedControl *segFileOp;
- (IBAction)segFileOpClicked:(id)sender;
@property (weak) IBOutlet NSSegmentedControl *segZoom;
- (IBAction)segZoomClicked:(id)sender;
@property (weak) IBOutlet NSSegmentedControl *segTools;
- (IBAction)segToolsClicked:(id)sender;
@property (weak) IBOutlet NSSegmentedControl *segRotate;
- (IBAction)segRotateClicked:(id)sender;
- (IBAction)segGoToClicked:(id)sender;
@property (weak) IBOutlet IKImageView *imgMain;
- (BOOL)readFromURL:(NSURL *)url;
- (void)saveImage:(NSString *)path;
@property (strong, nonatomic, readwrite) NSURL *imageURL;

- (IBAction)rotateLeftClicked:(id)sender;
- (IBAction)rotateRightClicked:(id)sender;
- (IBAction)nextImageClicked:(id)sender;
- (IBAction)previousImageClicked:(id)sender;
- (IBAction)btnPrintClicked:(id)sender;

@end
