//
//  KKDocument.m
//  Localizer
//
//  Created by KKBOX on 12/10/11.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "KKDocument.h"
#import "KKSourceCodeParser.h"
#import "KKFilePathTableViewController.h"
#import "KKMatchInfo.h"
#import "KKLocalizableSettingParser.h"
#import "KKMatchInfoTableViewController.h"
#import "KKMatchInfoRecordColorTransformer.h"
#import "NSString+RelativePath.h"

@implementation KKDocument

- (void)dealloc
{
    self.filePathTableViewController = nil;
    self.matchInfoTableViewController = nil;
    self.matchInfoProcessor = nil;
    self.localizableInfoSet = nil;
    [super dealloc];    
}

- (id)init
{
    self = [super init];
    if (self) {
        //註冊 value transformer
        KKMatchInfoRecordColorTransformer *transformer = [[[KKMatchInfoRecordColorTransformer alloc] init] autorelease];
        [NSValueTransformer setValueTransformer:transformer forName:@"KKMatchInfoRecordColorTransformer"];
        
        matchInfoProcessor = [[KKMatchInfoProcessor alloc] init];
    }
    return self;
}

#pragma mark -  override NSDocument

//在 saveToURL 中才可以得到即將要存入的檔案路徑
- (void)saveToURL:(NSURL *)url ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation completionHandler:(void (^)(NSError *))completionHandler
{
    [filePathTableViewController updateRelativeFilePathArrayWithNewBaseURL:url];
	
    [super saveToURL:url ofType:typeName forSaveOperation:saveOperation completionHandler:completionHandler];
}

//將檔案依照規定的格式寫入檔案中
- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation originalContentsURL:(NSURL *)absoluteOriginalContentsURL error:(NSError **)outError
{
    NSMutableString *resultString = [NSMutableString string];
    
    //寫入 header 的 files 路徑字串和 body 的 matchInfos 字串
    [resultString appendFormat:@"%@%@",filePathTableViewController.relativeSourceFilepahtsStringRepresentation, matchInfoTableViewController.matchInfosString];
	    
    BOOL boolResult = [resultString writeToURL:absoluteURL atomically:YES encoding:NSUTF8StringEncoding error:outError];
 
    //成功儲存完相關資料後，更新 localizable 的 set
    if (boolResult) [self updateLocalizableSet];
    
    return boolResult;
}

//讀入檔案，並且利用 parser 得到所要的資料
- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    BOOL readSuccess = NO;
    //截取自 .strings 檔所讀出的 key value pair
    NSString *localizableFileContent = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    if (!localizableFileContent && outError) {
        *outError = [NSError errorWithDomain:NSCocoaErrorDomain
                                        code:NSFileReadUnknownError userInfo:nil];
    }
    if (localizableFileContent) {
        readSuccess = YES;
        // get localizable related info from Localizable.strings
        KKLocalizableSettingParser *localizableSettingParser = [[[KKLocalizableSettingParser alloc] init] autorelease];
            
        NSArray *tempScanArray = nil;
        NSSet *tempMatchRecordSet = nil;
    
        [localizableSettingParser parse:localizableFileContent scanFolderPathArray:&tempScanArray matchRecordSet:&tempMatchRecordSet];
      
        scanArray = [tempScanArray copy];
        localizableInfoSet = [tempMatchRecordSet copy];
    }
    [localizableFileContent release];
   
    return readSuccess;
}

- (void)windowControllerDidLoadNib:(NSWindowController *)windowController
{
    [super windowControllerDidLoadNib:windowController];
    
    //將 undo manager 傳入 controller 讓 controller 可以自行 undo/redo
    [self.matchInfoTableViewController setUndoManager:[self undoManager]];
    [self.filePathTableViewController setUndoManager:[self undoManager]];
        
    //載入 matchInfoTable 中的資料
    [self.matchInfoTableViewController reloadMatchInfoRecords:[localizableInfoSet allObjects]];
    
    //載入 scan array 的資料
    [self.filePathTableViewController setSourceFilePaths:scanArray withBaseURL:[self fileURL]];
}

- (NSString *)windowNibName
{
    return @"KKDocument";
}

#pragma mark - NSToolbarDelegate
- (void)toolbarWillAddItem:(NSNotification *)notification
{
//    NSDictionary *toolbarItemNameDictionary = @{
//        @"Add Scan Folders or Files": NSLocalizedString(@"Add Scan Folders or Files", @""),
//        @"Scan":NSLocalizedString(@"Scan", @"")
//    };
    NSDictionary *toolbarItemNameDictionary = [NSDictionary dictionaryWithObjectsAndKeys: NSLocalizedString(@"Add Scan Folders or Files", @""),@"Add Scan Folders or Files", NSLocalizedString(@"Scan", @""), @"Scan", nil];
    
    NSToolbarItem *item = [notification.userInfo objectForKey:@"item"];
    item.label = [toolbarItemNameDictionary objectForKey:item.itemIdentifier];
}

#pragma mark -  button action

//加入檔案路徑的 action
- (IBAction)addScanFolderAndFiles:(id)sender
{
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseFiles:YES];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setAllowsMultipleSelection:YES];
	[openPanel setAllowedFileTypes:[NSArray arrayWithObjects:@"h", @"m",@"mm", nil]];
	
	NSWindow *window = [[[self windowControllers] objectAtIndex:0] window];
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
            [filePathTableViewController addFilePaths:pathsToAdd];
		}
		
	}];
}

//merge src 和 localizable.strings 的資料
- (IBAction)scan:(id)sender
{            
    NSMutableSet *sourceCodeInfoSet = [NSMutableSet setWithSet:[self parseSourceCode:filePathTableViewController.filePathArray]];
        
    // merge src info set and localizable info set
    NSArray *result = [matchInfoProcessor mergeSetWithSrcInfoSet:sourceCodeInfoSet withLocalizableInfoSet:localizableInfoSet withLocalizableFileExist:([self fileURL] != nil)];
    
    // reload match info table view
    [self.matchInfoTableViewController reloadMatchInfoRecords:result];
}

#pragma mark - validate tool bar item

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{ 
	SEL action = [theItem action];
	if (action == @selector(addScanFolderAndFiles:)) {
		return YES;
	}
	else if (action == @selector(scan:)) {
		return !![[self filePathTableViewController].filePathArray count];
	}
	return [super validateToolbarItem:theItem];
	return NO;
}

#pragma mark -  others
- (NSSet *)parseSourceCode:(NSArray *)filePathArray
{
    NSMutableSet *sourceCodeInfoSet = [NSMutableSet set];
    KKSourceCodeParser *sourceCodeParser = [[KKSourceCodeParser alloc] init];
    for (NSURL *filePath in filePathArray) {
        [sourceCodeInfoSet unionSet: [sourceCodeParser parse:[filePath path]]];
    }
    [sourceCodeParser release];
    return sourceCodeInfoSet;
}

- (void)updateLocalizableSet
{
    NSArray *updatedLocalizableInfoArray = [NSArray arrayWithArray:matchInfoTableViewController.matchInfoArray];
    [updatedLocalizableInfoArray enumerateObjectsUsingBlock:^(KKMatchInfo *obj, NSUInteger idx, BOOL *stop) {
        
        [[obj filePath] isEqualToString:@"Not exist"]?[obj setState:notExist]:[obj setState:existing];
    }];
    
    NSSet *temp = localizableInfoSet;
    localizableInfoSet = [[NSSet setWithArray:updatedLocalizableInfoArray] retain];
    [temp release];
}
@synthesize filePathTableViewController, matchInfoTableViewController, localizableInfoSet, scanArray, matchInfoProcessor;
@end