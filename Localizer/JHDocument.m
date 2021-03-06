/*
 JHDocument.m
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

#import "JHDocument.h"

#import "JHSourceCodeParser.h"
#import "JHLocalizableSettingParser.h"
#import "JHMatchInfo.h"

@interface JHDocument () <JHTranslatedWindowControllerDelegate>
@end

@implementation JHDocument

+ (BOOL)autosavesInPlace
{
	return YES;
}

- (void)dealloc
{
	self.filePathTableViewController = nil;
	self.matchInfoTableViewController = nil;
}

- (instancetype)init
{
	self = [super init];
	if (self) {
		self.matchInfoProcessor = [[JHMatchInfoProcessor alloc] init];
	}
	return self;
}

#pragma mark -    override NSDocument

// We need to capture the path that we will write data to here. Due to
// the sandboxing design of Mac OS X 10.7 and later, the file URL
// passed from the
// "writeToURL ofType:forSaveOperation:originalContentsURL:error:" is
// a temporary file but not the real path, while the what contained in
// the "originalContentsURL" might be nil.

- (void)saveToURL:(NSURL *)url ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation completionHandler:(void (^)(NSError *))completionHandler
{
	[self.filePathTableViewController updateRelativeFilePathArrayWithNewBaseURL:url];
	[super saveToURL:url ofType:typeName forSaveOperation:saveOperation completionHandler:completionHandler];
}

// Write data.
- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation originalContentsURL:(NSURL *)absoluteOriginalContentsURL error:(NSError **)outError
{
	NSMutableString *resultString = [NSMutableString string];

	//寫入 header 的 files 路徑字串和 body 的 matchInfos 字串
	[resultString appendFormat:@"%@%@", self.filePathTableViewController.relativeSourceFilepahtsStringRepresentation, self.matchInfoTableViewController.matchInfosString];

	BOOL boolResult = [resultString writeToURL:absoluteURL atomically:YES encoding:NSUTF8StringEncoding error:outError];

	//成功儲存完相關資料後，更新 localizable 的 set
	if (boolResult) {
		[self updateLocalizableSet];
	}

	return boolResult;
}

// Read data from "Localizable.string.
- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	NSString *localizableFileContent = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if (!localizableFileContent) {
		if (outError) {
			*outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnknownError userInfo:nil];
		}
		return NO;
	}
	if (localizableFileContent) {
		// get localizable related info from Localizable.strings
		JHLocalizableSettingParser *localizableSettingParser = [[JHLocalizableSettingParser alloc] init];

		NSArray *tempScanArray = nil;
		NSSet *tempMatchRecordSet = nil;

		[localizableSettingParser parse:localizableFileContent scanFolderPathArray:&tempScanArray matchRecordSet:&tempMatchRecordSet];

		self.scanArray = [tempScanArray copy];
		self.localizableInfoSet = [tempMatchRecordSet copy];
	}
	return YES;
}

- (void)windowControllerDidLoadNib:(NSWindowController *)windowController
{
	[super windowControllerDidLoadNib:windowController];

	//將 undo manager 傳入 controller 讓 controller 可以自行 undo/redo
	self.matchInfoTableViewController.undoManager = [self undoManager];
	self.filePathTableViewController.undoManager = [self undoManager];

	//載入 matchInfoTable 中的資料
	[self.matchInfoTableViewController reloadMatchInfoRecords:[self.localizableInfoSet allObjects]];

	//載入 scan array 的資料
	[self.filePathTableViewController setSourceFilePaths:self.scanArray withBaseURL:[self fileURL]];
}

- (NSString *)windowNibName
{
	return @"JHDocument";
}

#pragma mark - NSToolbarDelegate

- (void)toolbarWillAddItem:(NSNotification *)notification
{
}

#pragma mark -    button action

//加入檔案路徑的 action
- (IBAction)addScanFolderAndFiles:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	openPanel.canChooseFiles = YES;
	openPanel.canChooseDirectories = YES;
	openPanel.allowsMultipleSelection = YES;
	openPanel.allowedFileTypes = @[@"h", @"m", @"mm"];

	NSWindow *window = [[self windowControllers][0] window];
	[openPanel beginSheetModalForWindow:window completionHandler:^(NSInteger result) {
		if (result == NSOKButton) {
			NSMutableArray *pathsToAdd = [NSMutableArray array];
			NSSet *filePathSet = [NSSet setWithArray:self.filePathTableViewController.filePathArray];
			NSArray *URLs = openPanel.URLs;
			[URLs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
				if (![filePathSet containsObject:obj]) {
					[pathsToAdd addObject:obj];
				}
			}];
			[self.filePathTableViewController addFilePaths:pathsToAdd];
		}

	}];
}

//merge src 和 localizable.strings 的資料
- (IBAction)scan:(id)sender
{
	NSArray *filePathArray = self.filePathTableViewController.filePathArray;
	NSMutableSet *sourceCodeInfoSet = [NSMutableSet set];

	JHSourceCodeParser *sourceCodeParser = [[JHSourceCodeParser alloc] init];
	for (NSURL *filePath in filePathArray) {
		[sourceCodeInfoSet unionSet:[sourceCodeParser parse:[filePath path]]];
	}

	NSArray *addedResult = [self.matchInfoProcessor getAddedSortedArray:sourceCodeInfoSet localizableInfoSet:self.localizableInfoSet];
	if ([addedResult count] && [addedResult count] < 10) {
		NSMutableString *message = [NSMutableString string];
		[message appendFormat:NSLocalizedString(@"After this scan, we have added %d new key\n\n", @""), [addedResult count]];
		int count = 0;
		for (JHMatchInfo *addedMatchInfo in addedResult) {
			count++;
			[message appendFormat:@"%d. %@\n\n", count, addedMatchInfo.key];
		}
		NSAlert *alert = [NSAlert alertWithMessageText:message defaultButton:NSLocalizedString(@"OK", @"") alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
		NSWindow *window = [[self windowControllers][0] window];
		[alert beginSheetModalForWindow:window modalDelegate:nil didEndSelector:nil contextInfo:nil];
	}
	// merge src info set and localizable info set
	NSArray *result = [self.matchInfoProcessor mergeSetWithSrcInfoSet:sourceCodeInfoSet withLocalizableInfoSet:self.localizableInfoSet withLocalizableFileExist:([self fileURL] != nil)];

	// reload match info table view
	[self.matchInfoTableViewController reloadMatchInfoRecords:result];
}

- (IBAction)translate:(id)sender
{
	if (!self.translatedWindowController) {
		self.translatedWindowController = [[JHTranslatedWindowController alloc] initWithWindowNibName:@"JHTranslatedWindow"];
		self.translatedWindowController.translatedWindowControllerDelegate = self;
		[self addWindowController:self.translatedWindowController];
	}
	NSWindow *window = [[self windowControllers][0] window];
	[NSApp beginSheet:self.translatedWindowController.window modalForWindow:window modalDelegate:nil didEndSelector:NULL contextInfo:nil];
}

- (IBAction)filterWithSearchType:(id)sender
{
	NSInteger tag = [sender tag];
	[self.segmentedControl setSelectedSegment:tag];
	[self.matchInfoTableViewController fileterByType:self.segmentedControl];
}

- (IBAction)performFindPanelAction:(id)sender
{
	if ([sender tag] == 1) {
		NSWindow *window = [self.windowControllers[0] window];
		[window makeFirstResponder:self.searchField];
	}
}

#pragma mark - validate tool bar item

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	SEL action = [menuItem action];
	if (action == @selector(addScanFolderAndFiles:)) {
		return YES;
	}
	else if (action == @selector(scan:)) {
		return self.filePathTableViewController.filePathArray.count != 0;
	}
	else if (action == @selector(translate:)) {
		return YES;
	}
	else if (action == @selector(filterWithSearchType:)) {
		NSInteger tag = [menuItem tag];
		menuItem.state = (self.segmentedControl.selectedSegment == tag) ? NSOnState : NSOffState;
		return YES;
	}
	else if (action == @selector(performFindPanelAction:)) {
		return menuItem.tag == 1;
	}
	return [super validateMenuItem:menuItem];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
	SEL action = [theItem action];
	if (action == @selector(addScanFolderAndFiles:)) {
		return YES;
	}
	else if (action == @selector(scan:)) {
		return self.filePathTableViewController.filePathArray.count != 0;
	}
	else if (action == @selector(translate:)) {
		return YES;
	}
	return [super validateToolbarItem:theItem];
}

#pragma mark - Others

- (void)updateLocalizableSet
{
	NSArray *updatedLocalizableInfoArray = [NSArray arrayWithArray:self.matchInfoTableViewController.matchInfoArray];
	self.localizableInfoSet = [NSSet setWithArray:updatedLocalizableInfoArray];
}

- (void)windowController:(JHTranslatedWindowController *)inWindowController didMerge:(id)inSomething;
{
	NSUndoManager *undoManager = [self undoManager];
	NSString *inActionName = NSLocalizedString(@"Translate", @"");
	[[undoManager prepareWithInvocationTarget:self.matchInfoTableViewController] restoreMatchinfoArray:[[self.matchInfoTableViewController.arrayController content] copy] actionName:inActionName];
	if (!undoManager.isUndoing) {
		undoManager.actionName = NSLocalizedString(inActionName, @"");
	}
	NSString *translatedContent = [NSString stringWithFormat:@"/* Not exist */ \n %@", inWindowController.translatedView.textStorage.string];

	// 在加入翻譯字串前，先將 localizanbleSet 更新到最新的狀態
	[self updateLocalizableSet];

	if (translatedContent && self.localizableInfoSet) {
		JHLocalizableSettingParser *localizableSettingParser = [[JHLocalizableSettingParser alloc] init];

		NSArray *tempScanArray = nil;
		NSSet *translatedMatchRecordSet = nil;

		[localizableSettingParser parse:translatedContent scanFolderPathArray:&tempScanArray matchRecordSet:&translatedMatchRecordSet];

		NSMutableArray *result = [NSMutableArray arrayWithArray:[self.localizableInfoSet allObjects]];

		[translatedMatchRecordSet enumerateObjectsUsingBlock:^(JHMatchInfo *obj, BOOL *stop) {
			//matchInfo 是以 key 為比對方式，key 相同就存在，在除了 key 以外的資訊有可能不同，所以採用 replace 的方式置換
			if ([self.localizableInfoSet containsObject:obj]) {
				NSUInteger index = [result indexOfObject:obj];

				JHMatchInfo *matchInfo = result[index];
				obj.filePath = matchInfo.filePath;

				if ([obj.key isEqualToString:obj.translateString]) {
					obj.state = unTranslated;
				}

				if ([obj.filePath isEqualToString:@"Not exist"]) {
					obj.state = notExist;
				}
				result[index] = obj;
			}
			else {
				obj.state = notExist;
				[result addObject:obj];
			}
		}];
		[self.matchInfoTableViewController reloadMatchInfoRecords:result];
	}
}

@end
