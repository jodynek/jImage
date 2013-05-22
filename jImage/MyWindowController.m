//
//  MyWindowController.m
//  jImage
//
//  Created by Petr Jodas on 10.05.13.
//  Copyright (c) 2013 Petr Jodas. All rights reserved.
//

#import "MyWindowController.h"
#import <Quartz/Quartz.h>
#import <AppKit/AppKit.h>
#import "DMSplitView.h"

#define ZOOM_IN_FACTOR  1.414214 // doubles the area
#define ZOOM_OUT_FACTOR 0.7071068 // halves the area

@implementation MyWindowController

- (id)initWithWindow:(NSWindow *)window
{
  self = [super initWithWindow:window];
  if (self)
  {
    [window setBackgroundColor:[NSColor blueColor]];
    if (mListOfImages)
      [mListOfImages removeAllObjects];
    else
      mListOfImages = [[NSMutableArray alloc] init];
    iDirPos = 0;
    
    [_imgMain setDelegate:self];
    [_imgMain zoomImageToFit: self];
    // !!!!!!!!! crashing
    //[[[NSDocumentController sharedDocumentController] currentDocument] setDraggingDestinationDelegate:self];
 }
  
  return self;
}

- (void) setImageURL:(NSURL *)imageURL
{
  _imageURL = imageURL;
}

- (void)windowDidLoad
{
  [super windowDidLoad];

  [_splitView setMinSize:200 ofSubviewAtIndex:1];
  [_splitView setCanCollapse:YES subviewAtIndex:1];
  [_splitView collapseOrExpandSubviewAtIndex:1
                                    animated:NO];

  // customize the IKImageView...
  [_imgMain setDoubleClickOpensImageEditPanel: YES];
  [_imgMain setCurrentToolMode: IKToolModeMove];
  [_imgMain setAutoresizes:  YES];
  [_imgMain setAutohidesScrollers: NO];
  [_imgMain setHasHorizontalScroller: YES];
  [_imgMain setHasVerticalScroller: YES];
  [self openImageURL:[self imageURL]];
  
  // every segment width
  [_segZoom setWidth:50 forSegment:0];
  [_segZoom setWidth:50 forSegment:1];
  [_segZoom setWidth:50 forSegment:2];
  [_segZoom setWidth:50 forSegment:3];
  [_segTools setWidth:50 forSegment:0];
  [_segTools setWidth:50 forSegment:1];
  [_segTools setWidth:50 forSegment:2];
  [_segTools setWidth:50 forSegment:3];
}

-(NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName
{
  //[[self window] setTitle:[_imageURL path]];
  [[self window] setTitle:displayName];
  return displayName;
}

- (NSString *)getImagePath
{
  return [[self imageURL] path];
}

- (void)openImageURL: (NSURL*)url
{
  [_imgMain setImageWithURL:url];
}

// open image document
- (BOOL)readFromURL:(NSURL *)url
{
  [self setImageURL:url];
  [NSThread detachNewThreadSelector:@selector(addImagesWithPaths:)
                           toTarget:self withObject:[[url path] stringByDeletingLastPathComponent]];
  return YES;
}

- (void) addImagesWithPath:(NSString *) path recursive:(BOOL) recursive
{
  int i, n;
  BOOL dir;
  
  [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&dir];
  if(dir)
  {
    NSError *error;
    NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
    n = (int)[content count];
    for(i=0; i<n; i++){
      if(recursive)
        [self addImagesWithPath:
         [path stringByAppendingPathComponent:
          [content objectAtIndex:i]]
                      recursive:NO];
      else
      {
        NSString *sExtension = [[content objectAtIndex:i] pathExtension];
        if ([sExtension compare:@"jpg"] == NSOrderedSame || [sExtension compare:@"jpeg"] == NSOrderedSame ||
            [sExtension compare:@"JPG"] == NSOrderedSame || [sExtension compare:@"JPEG"] == NSOrderedSame ||
            [sExtension compare:@"gif"] == NSOrderedSame || [sExtension compare:@"GIF"] == NSOrderedSame ||
            [sExtension compare:@"png"] == NSOrderedSame || [sExtension compare:@"PNG"] == NSOrderedSame ||
            [sExtension compare:@"bmp"] == NSOrderedSame || [sExtension compare:@"BMP"] == NSOrderedSame)
        {
          [self addAnImageWithPath: [path stringByAppendingPathComponent:[content objectAtIndex:i]]];
        }
      }
    }
  }
  else
  {
    NSString *sExtension = [path pathExtension];
    if ([sExtension compare:@"jpg"] == NSOrderedSame || [sExtension compare:@"jpeg"] == NSOrderedSame ||
        [sExtension compare:@"JPG"] == NSOrderedSame || [sExtension compare:@"JPEG"] == NSOrderedSame ||
        [sExtension compare:@"gif"] == NSOrderedSame || [sExtension compare:@"GIF"] == NSOrderedSame ||
        [sExtension compare:@"png"] == NSOrderedSame || [sExtension compare:@"PNG"] == NSOrderedSame ||
        [sExtension compare:@"bmp"] == NSOrderedSame || [sExtension compare:@"BMP"] == NSOrderedSame)
    {
      [self addAnImageWithPath:path];
    }
  }
}

- (void) addImagesWithPaths:(NSString *) path
{
  [self addImagesWithPath:path recursive:NO];
}

- (void) addAnImageWithPath:(NSString *) path
{
  NSString *f = [[NSString alloc] initWithString:path];
  [mListOfImages addObject:f];
  NSLog(@"%@", [path lastPathComponent]);
}

float RadiantoDegree(float radian)
{
  return ((radian / M_PI) * 180.0f);
}

float DegreetoRadian(float degree)
{
  return ((degree / 180.0f) * M_PI);
}

- (void)savePanelDidEnd: (NSSavePanel *)sheet
             returnCode: (int)returnCode
            contextInfo: (void *)contextInfo
{
  if (returnCode == NSOKButton)
  {
    NSString * path = [[sheet URL] path];
    [self saveFileNameAs:[NSURL fileURLWithPath:path]];
  }
}

- (void)saveImage:(NSString *)path
{
  mSaveOptions = [[IKSaveOptions alloc] initWithImageProperties:mImageProperties imageUTType: mImageUTType];
  NSString * newUTType = [mSaveOptions imageUTType];
  CGImageRef targetImgRef = [_imgMain image];
  if (targetImgRef) {
    NSURL *url = [NSURL fileURLWithPath: path];
    CGImageDestinationRef dest = CGImageDestinationCreateWithURL((__bridge CFURLRef)url, (__bridge CFStringRef)newUTType, 1, NULL);
    
    if (dest) {
      CGImageDestinationAddImage(dest, targetImgRef, (__bridge CFDictionaryRef)[mSaveOptions imageProperties]);
      CGImageDestinationFinalize(dest);
      CFRelease(dest);
    }
  }
}

- (void)saveFileNameAs:(NSURL *)sFileName
{
  NSString * path = [sFileName path];
  NSString * newUTType = [mSaveOptions imageUTType];
  CGImageRef image;
  
  image = [_imgMain image];
  if (image)
  {
    NSURL * url = [NSURL fileURLWithPath: path];
    CGImageDestinationRef dest = CGImageDestinationCreateWithURL((__bridge CFURLRef)url,
                                                                 (__bridge CFStringRef)newUTType, 1, NULL);
    if (dest)
    {
      CGImageDestinationAddImage(dest, image,
                                 (__bridge CFDictionaryRef)[mSaveOptions imageProperties]);
      CGImageDestinationFinalize(dest);
      CFRelease(dest);
    }
  } else
  {
    NSLog(@"*** saveImageToPath - no image");
  }
}

- (IBAction)segFileOpClicked:(id)sender
{
  NSInteger iChoose;
  if ([sender isKindOfClass: [NSSegmentedControl class]])
    iChoose = [sender selectedSegment];
  else
    iChoose = [sender tag];
  
  switch (iChoose)
  {
    case 0:
    {
      // open
      [[NSDocumentController sharedDocumentController] openDocument:self];
      break;
    }
    case 1:
      // save
      [[[NSDocumentController sharedDocumentController] currentDocument] saveDocument:self];
      //[self saveImage:[imageURL path]];
      break;
    case 2:
    {
      // save as
      NSSavePanel *savePanel = [NSSavePanel savePanel];
      mSaveOptions = [[IKSaveOptions alloc]
                      initWithImageProperties: mImageProperties
                      imageUTType: mImageUTType];
      [mSaveOptions addSaveOptionsAccessoryViewToSavePanel: savePanel];
      
      NSString * fileName = [[[self imageURL] path] lastPathComponent];
      [savePanel beginSheetForDirectory: NULL
                                   file: fileName
                         modalForWindow: [self window]
                          modalDelegate: self
                         didEndSelector: @selector(savePanelDidEnd:returnCode:contextInfo:)
                            contextInfo: NULL];
      break;
    }
  }
}

- (IBAction)segZoomClicked:(id)sender
{
  CGFloat   zoomFactor;
  NSSegmentedControl *segmentedControl = (NSSegmentedControl *) sender;
  NSInteger selectedSegment = segmentedControl.selectedSegment;
  if (selectedSegment == 0) {
    zoomFactor = [_imgMain zoomFactor];
    [_imgMain setZoomFactor: zoomFactor * ZOOM_IN_FACTOR];
  } else if (selectedSegment == 1) {
    zoomFactor = [_imgMain zoomFactor];
    [_imgMain setZoomFactor: zoomFactor * ZOOM_OUT_FACTOR];
  } else if (selectedSegment == 2) {
    [_imgMain zoomImageToActualSize:self];
  } else if (selectedSegment == 3) {
    [_imgMain zoomImageToFit:self];
  }
}

- (IBAction)segToolsClicked:(id)sender
{
  NSInteger newTool;
  if ([sender isKindOfClass: [NSSegmentedControl class]])
    newTool = [sender selectedSegment];
  else
    newTool = [sender tag];
  
  switch (newTool)
  {
    case 0:
      [_imgMain setCurrentToolMode: IKToolModeMove];
      break;
    case 1:
      [_imgMain setCurrentToolMode: IKToolModeSelect];
      break;
    case 2:
      [_imgMain setCurrentToolMode: IKToolModeCrop];
      break;
    case 3:
      [_imgMain setCurrentToolMode: IKToolModeAnnotate];
      break;
  }
}

- (IBAction)segRotateClicked:(id)sender
{
  NSInteger iChoose;
  if ([sender isKindOfClass: [NSSegmentedControl class]])
    iChoose = [sender selectedSegment];
  else
    iChoose = [sender tag];
  
  switch (iChoose)
  {
    case 0:
    {
      [self rotateLeftClicked:self];
      break;
    }
    case 1:
    {
      [self rotateRightClicked:self];
      break;
    }
    case 2:
      [_imgMain setCurrentToolMode: IKToolModeRotate];
      break;
  }
}

- (IBAction)segGoToClicked:(id)sender
{
  NSInteger iChoose;
  if ([sender isKindOfClass: [NSSegmentedControl class]])
    iChoose = [sender selectedSegment];
  else
    iChoose = [sender tag];
  
  switch (iChoose)
  {
    case 0:
    {
      [self previousImageClicked:self];
      break;
    }
    case 1:
    {
      [self nextImageClicked:self];
      break;
    }
  }
}

- (IBAction)rotateLeftClicked:(id)sender
{
  float fRotationAngle = RadiantoDegree([_imgMain rotationAngle]);
  fRotationAngle = (fRotationAngle == 360.0f) ? 0 : fRotationAngle;
  fRotationAngle = fRotationAngle == 0 ? 90.0f : fRotationAngle + 90.0f;
  float angleRadians = DegreetoRadian(fRotationAngle);
  NSLog(@"Rotation angle: %f", fRotationAngle);
  [_imgMain setRotationAngle:angleRadians];
}

- (IBAction)rotateRightClicked:(id)sender
{
  float fRotationAngle = RadiantoDegree([_imgMain rotationAngle]);
  fRotationAngle = (fRotationAngle == 360.0f) ? 0 : fRotationAngle;
  fRotationAngle = fRotationAngle == 0 ? 270.0f : fRotationAngle - 90.0f;
  float angleRadians = DegreetoRadian(fRotationAngle);
  NSLog(@"Rotation angle: %f", fRotationAngle);
  [_imgMain setRotationAngle:angleRadians];
}

- (IBAction)nextImageClicked:(id)sender
{
  if (iDirPos < [mListOfImages count] - 1)
    iDirPos++;
  else
    iDirPos = 0;
  NSString *sFileName = [mListOfImages objectAtIndex:iDirPos];
  [self setImageURL:[NSURL fileURLWithPath:sFileName]];
  [self openImageURL:[self imageURL]];
  [self windowTitleForDocumentDisplayName:[[self imageURL] path]];
}

- (IBAction)previousImageClicked:(id)sender
{
  if (iDirPos > 0)
    iDirPos--;
  else
    iDirPos = (int)[mListOfImages count] - 1;
  NSString *sFileName = [mListOfImages objectAtIndex:iDirPos];
  [self setImageURL:[NSURL fileURLWithPath:sFileName]];
  [self openImageURL:[self imageURL]];
  [self windowTitleForDocumentDisplayName:[[self imageURL] path]];
}

- (NSSize)getRealImageSize:(NSURL *)url
{
  NSArray * imageReps = [NSBitmapImageRep imageRepsWithContentsOfURL:url];
  NSInteger width = 0;
  NSInteger height = 0;
  for (NSImageRep * imageRep in imageReps) {
    if ([imageRep pixelsWide] > width)
      width = [imageRep pixelsWide];
    if ([imageRep pixelsHigh] > height)
      height = [imageRep pixelsHigh];
  }
  NSSize size;
  size.width = (CGFloat)width;
  size.height = (CGFloat)height;
  return size;
}

- (IBAction)btnPrintClicked:(id)sender
{
  CGImageRef imgRef = [_imgMain image];
  NSSize size = [self getRealImageSize:_imageURL];
  NSImage *image = [[NSImage alloc] initWithCGImage:imgRef size:size];
  
  [[NSPrintInfo sharedPrintInfo] setHorizontalPagination:NSAutoPagination];
  NSImageView *printView = [[NSImageView alloc]
                            initWithFrame:[[NSPrintInfo sharedPrintInfo] imageablePageBounds]];
  [printView setImageScaling:NSScaleProportionally];
  [printView setImage:image];
  [printView print:sender];
}

@end
