/*
 JHDocument.h
 Copyright (C) 2012 Joe Hsieh

 Permission is hereby granted, free of charge, to any person obtaining
 a copy of this software and associated documentation files (the
 "Software"), to deal in the Software without restriction, including
 without limitation the rights to use, copy, modify, merge, publish,
 distribute, sublicense, and/or sell copies of the Software, and to
 permit persons to whom the Software is furnished to do so, subject to
 the following conditions:

 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
 BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
*/

#import <Cocoa/Cocoa.h>
#import "JHFilePathTableViewController.h"
#import "JHMatchInfoTableViewController.h"
#import "JHTranslatedWindowController.h"
#import "JHMatchInfoProcessor.h"

// An abstract document which represents a "Localizable.strings" file.

@interface JHDocument : NSDocument <NSToolbarDelegate>
{
//	IBOutlet JHFilePathTableViewController *__weak filePathTableViewController;
//	IBOutlet JHMatchInfoTableViewController *__weak matchInfoTableViewController;
//	IBOutlet NSSegmentedControl *__weak segmentedControl;
//	IBOutlet NSSearchField *__weak searchField;
//
//	JHMatchInfoProcessor *matchInfoProcessor;
//	NSArray *scanArray;
//	NSSet *localizableInfoSet;
}

- (IBAction)addScanFolderAndFiles:(id)sender;
- (IBAction)scan:(id)sender;
- (IBAction)translate:(id)sender;
- (IBAction)filterWithSearchType:(id)sender;

@property (weak, nonatomic) IBOutlet JHFilePathTableViewController *filePathTableViewController;
@property (weak, nonatomic) IBOutlet JHMatchInfoTableViewController *matchInfoTableViewController;
@property (weak, nonatomic) IBOutlet NSSegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet NSSearchField *searchField;

@property (strong, nonatomic) JHMatchInfoProcessor *matchInfoProcessor;
@property (strong, nonatomic) JHTranslatedWindowController *translatedWindowController;
@property (strong, nonatomic) NSSet *localizableInfoSet;
@property (strong, nonatomic) NSArray *scanArray;

@end
