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
#import "CProperties.h"

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
    
    [_imgMain zoomImageToFit: self];
    //[_imgMain setDelegate:self];
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

  // datasource
  arrEXIF = [[NSMutableArray alloc] init];
  arrIPTC = [[NSMutableArray alloc] init];
  [_outlineView setDelegate:self];
  [_outlineView setDataSource:self];
  
  // split view
  [_splitView setMinSize:200 ofSubviewAtIndex:0];
  [_splitView setMinSize:100 ofSubviewAtIndex:1];
  [_splitView setPriority:1 ofSubviewAtIndex:0];
  [_splitView setPriority:0 ofSubviewAtIndex:1];
  [_splitView setCanCollapse:YES subviewAtIndex:1];
  [_splitView collapseOrExpandSubviewAtIndex:1 animated:NO];
  NSView* subview = _splitView.subviews[1];
  int iWidth = [subview frame].size.width;
  (iWidth == 0) ? [_segEXIF setSelected:FALSE forSegment:0] : [_segEXIF setSelected:TRUE forSegment:0];
  if (iWidth != 0)
    [self loadEXIFData:_imageURL];
 
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

- (void)loadEXIFData:(NSURL *)url
{
  [self exif:url];
  [_outlineView reloadData];
  // expand all items
  [_outlineView expandItem:nil expandChildren:YES];
}

- (void)fillCustomArray:(NSArray *)inputArray
            outputArray:(NSMutableArray *)outputArray
               rootItem:(NSString *)rootItem
{
  [outputArray removeAllObjects];
  // for root items
  CProperties *propRoot = [[CProperties alloc] init];
  [propRoot setIsRoot:TRUE];
  [propRoot setSKey:rootItem];
  [outputArray addObject: propRoot];
  // child items
  for(NSString *key in inputArray)
  {
    CProperties *prop = [[CProperties alloc] init];
    NSString *value = [inputArray valueForKey:key];
    if (value != nil)
    {
      if ([value isKindOfClass:[NSArray class]])
      {
        NSArray *subArray = [[NSArray alloc] initWithArray:(NSArray *)value];
        [prop setValues:subArray];
        [prop setSKey:key];
      } else {
        [prop setSKey:key];
        [prop setSValue:value];
        //NSLog(@"obj: %@, %@", key, value);
      }
    }
    [outputArray addObject:prop];
  }
}

- (void) exif:(NSURL *) url
{
  CGImageSourceRef source = CGImageSourceCreateWithURL( (__bridge CFURLRef) url,NULL);
  if (!source)
  {
    int response;
    NSAlert *alert = [NSAlert alertWithMessageText:@"Could not create image source !" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
    [alert beginSheetModalForWindow:[self window]
                      modalDelegate:self
                     didEndSelector:nil
                        contextInfo:&response];
    NSLog(@"***Could not create image source ***");
    return;
  }
  //get all the metadata in the image
  NSDictionary *metadata = (__bridge NSDictionary *) CGImageSourceCopyPropertiesAtIndex(source,0,NULL);
  
  //get all the metadata EXIF in the image
  NSArray *exif = [metadata valueForKey:@"{Exif}"];
  //NSLog(@"AnnotationProfil: Exif -> %@", exif);
  [self fillCustomArray:exif outputArray:arrEXIF rootItem:@"EXIF"];
  
  //get all the metadata IPTC in the image
  NSArray *iptc = [metadata valueForKey:@"{IPTC}"];
  NSLog(@"AnnotationProfil: IPTC -> %@",iptc);
  [self fillCustomArray:iptc outputArray:arrIPTC rootItem:@"IPTC"];
}

//
// NSOutlineView
//
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
  CProperties *prop = item;
  if (prop == nil)
  {
    //item is nil when the outline view wants to inquire for root level items
    // we have 2 root items - EXIF & IPTC
    return 2;
  } else {
    if ([prop values] != nil)
      return [[prop values] count];
    else
    {
      if ([[prop sKey] isEqualToString:@"EXIF"])
        return [arrEXIF count] - 1;
      else
        return [arrIPTC count] - 1;
    }
  }
  return 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
  if ([item isKindOfClass:[CProperties class]])
  {
    CProperties *prop = item;
    if ([prop values] != nil || [prop isRoot])
    {
      return YES;
    } else {
      return NO;
    }
  } else
    return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
  CProperties *prop = item;
  if ([[prop sKey] isEqualToString:@"EXIF"])
  {
    if ([arrEXIF count] == 0)
      return nil;
  } else {
    if ([arrIPTC count] == 0)
      return nil;
  }
  if (prop == nil)
  { //item is nil when the outline view wants to inquire for root level items
    if (index == 0)
      return [arrEXIF objectAtIndex:0];
    else if (index == 1)
      return [arrIPTC objectAtIndex:0];
  } else {
    if ([prop values] != nil)
    {
      return [[prop values] objectAtIndex:index];
    } else {
      if ([[prop sKey] isEqualToString:@"EXIF"])
        return [arrEXIF objectAtIndex:index + 1];
      else
        return [arrIPTC objectAtIndex:index + 1];
    }
  }
  return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn
           byItem:(id)item
{
  if ([item isKindOfClass:[CProperties class]])
  {
    CProperties *prop = item;
    if ([[tableColumn identifier] isEqualToString:@"sKey"])
    {
      if ([prop values] != nil && [prop isRoot])
        return [NSString stringWithFormat:@"%@ (%li values)",[prop sKey], [[item values] count]];
      if ([prop values] != nil )
      {
        // ... then write something informative in the header (number of values)
        return [NSString stringWithFormat:@"%@ (%li values)",[prop sKey], [[item values] count]];
      }
      return [prop sKey]; // ...and, if we actually have a value, return the value
    } else if ([[tableColumn identifier] isEqualToString:@"sValue"]) {
      if ([prop values] == nil)
      {
        return [prop sValue]; // return value without children
      }
    }
  } else {
    if ([[tableColumn identifier] isEqualToString:@"sKey"])
      return item;
  }
  return nil;
}

-(NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName
{
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
  [self displayOrHideEXIF];
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
      //NSString * fileName = [[[self imageURL] path] lastPathComponent];
      [savePanel beginSheetModalForWindow: [self window] completionHandler: ^(NSInteger result)
      {
        if (result == NSOKButton)
        {
          NSString * path = [[savePanel URL] path];
          [self saveFileNameAs:[NSURL fileURLWithPath:path]];
        }
      }];
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

- (void)displayOrHideEXIF
{
  NSView* subview = _splitView.subviews[1];
  int iWidth = [subview frame].size.width;
  if (iWidth != 0)
  {
    [self loadEXIFData:_imageURL];
  }  
}

- (IBAction)segEXIFClicked:(id)sender
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
      [_splitView collapseOrExpandSubviewAtIndex:1
                                        animated:NO];
      [self displayOrHideEXIF];
      break;
    }
  }
}

@end
