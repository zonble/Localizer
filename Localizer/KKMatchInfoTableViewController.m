//
//  KKMatchInfoTableViewController.m
//  Localizer
//
//  Created by joehsieh on 12/10/14.
//
//

#import "KKMatchInfoTableViewController.h"
#import "ImageAndTextCell.h"
#import "KKMatchInfo.h"

@implementation KKMatchInfoTableViewController

- (void)dealloc
{
    [self stopObservingMatchInfoArray:[arrayController content]];
    self.arrayController = nil;
    [super dealloc];
}

#pragma mark -  NSTableViewDelegate
- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if ([tableColumn.identifier isEqualToString:@"key"] || [tableColumn.identifier isEqualToString:@"from"] ) {
        return NO;
    }
    return  YES;
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{    
    if ([[tableColumn identifier] isEqualToString:@"from"]) {
        ImageAndTextCell *imageAndTextCell = (ImageAndTextCell *)cell;
        NSString *path = [imageAndTextCell stringValue];
        NSString *fileExtension = [path pathExtension];
        if ([fileExtension length]) {
            NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFileType:fileExtension];
            [icon setSize:NSMakeSize(10.0, 10.0)];
            [imageAndTextCell setImage:icon];
        }
        else {
            [imageAndTextCell setImage:nil];
        }
    }
}

#pragma mark -  NSTableViewDelegateMatchInfoExtension
- (void)tableView:(NSTableView *)inTableView didDeleteMatchInfosWithIndexes:(NSIndexSet *)inIndexes
{
    [self removeMatchInfoArray:[arrayController.content objectsAtIndexes:inIndexes]]; 
}

- (void)tableView:(NSTableView *)inTableView didCopiedMatchInfosWithIndexes:(NSIndexSet *)inIndexes
{
    if ([inIndexes count] != 0) {
        NSMutableArray *matchInfoArray = [NSMutableArray array];
        [inIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            KKMatchInfo *selectedMatchInfo = [arrayController.content objectAtIndex:idx];
            if ([arrayController.content containsObject:selectedMatchInfo]) {
                KKMatchInfo *matchInfo = [[[KKMatchInfo alloc] init] autorelease];
                matchInfo.key = [NSString stringWithFormat:@"%@ copy",selectedMatchInfo.key];
                matchInfo.translateString = selectedMatchInfo.translateString;
                matchInfo.comment = selectedMatchInfo.comment;
                matchInfo.filePath = selectedMatchInfo.filePath;
                
                [matchInfoArray addObject:matchInfo];
            }
        }];
        NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
        [pasteBoard clearContents];
        [pasteBoard writeObjects:matchInfoArray];
        
    }
}

- (void)tableView:(NSTableView *)inTableView didPasteMatchInfos:(NSIndexSet *)inIndexes
{
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSArray *classArray = [NSArray arrayWithObject:[KKMatchInfo class]];
    NSDictionary *options = [NSDictionary dictionary];
    
    BOOL ok = [pasteboard canReadObjectForClasses:classArray options:options];
    if (ok) {
        NSArray *objectsToPaste = [pasteboard readObjectsForClasses:classArray options:options];
        [self insetMatchInfoArray:objectsToPaste withIndex:[inIndexes firstIndex] + 1];
    }
}


- (void)reloadMatchInfoRecords:(NSArray *)inArray
{
    if (![[arrayController content] isEqualToArray:inArray]) {
        [self startObservingMatchInfoArray:inArray];
        arrayController.content = inArray;
    } 
}

#pragma mark -  redo/undo add/delete matchInfo record
- (void)removeMatchInfoArray:(NSArray *)matchInfoArray
{
    NSString *actionName = NSLocalizedString(@"Delete", @"");
    [self stopObservingMatchInfoArray:matchInfoArray];
    
    [[undoManager prepareWithInvocationTarget:self] restoreMatchinfoArray:[[[arrayController content]copy]autorelease]  actionName:actionName];
    if (!undoManager.isUndoing) {
        [undoManager setActionName:actionName];
    }
    
    NSMutableArray *result = [NSMutableArray arrayWithArray:arrayController.content];
    [result removeObjectsInArray:matchInfoArray];
    arrayController.content = result;
}

- (void)insetMatchInfoArray:(NSArray *)matchInfoArray withIndex:(NSUInteger)insertedIndex
{
    NSString *actionName = NSLocalizedString(@"Insert", @"");
    [self startObservingMatchInfoArray:matchInfoArray];
    
    [[undoManager prepareWithInvocationTarget:self] restoreMatchinfoArray:[[[arrayController content]copy]autorelease]  actionName:actionName];
    if (!undoManager.isUndoing) {
        [undoManager setActionName:actionName];
    }
    NSMutableArray *result = [NSMutableArray arrayWithArray:arrayController.content];
    [matchInfoArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [result insertObject:obj atIndex:insertedIndex];
    }];
    arrayController.content = result;
}

- (void)restoreMatchinfoArray:(NSArray *)inArray actionName:(NSString *)inActionName
{
    [self startObservingMatchInfoArray:inArray];
    
    [[undoManager prepareWithInvocationTarget:self] restoreMatchinfoArray:[[[arrayController content]copy]autorelease]  actionName:inActionName];
    if (!undoManager.isUndoing) {
        [undoManager setActionName:NSLocalizedString(inActionName, @"")];
    }
    arrayController.content = inArray;
}

#pragma mark -  redo/undo edit match record
- (void)changeKeyPath:(NSString *)keyPath ofObject:(id)object toValue:(id)newValue
{
    [object setValue:newValue forKeyPath:keyPath];    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
    [[undoManager prepareWithInvocationTarget:self] changeKeyPath:keyPath ofObject:object toValue:oldValue];
    if (!undoManager.isUndoing) {
        [undoManager setActionName:NSLocalizedString(@"Edit", @"")];
    }
}

- (void)stopObservingMatchInfoArray:(NSArray *)inArray
{
    //移除 observing
    for (KKMatchInfo *matchInfo in [inArray retain]) {
        [matchInfo removeObserver:self forKeyPath:@"translateString"];
        [matchInfo removeObserver:self forKeyPath:@"comment"];
    }
}

- (void)startObservingMatchInfoArray:(NSArray *) inArray
{
    //加上 KVO 準備 Undo 用
    for (KKMatchInfo *matchInfo in [inArray retain]) {
        [matchInfo addObserver:self forKeyPath:@"translateString" options:NSKeyValueObservingOptionOld context:nil];
        [matchInfo addObserver:self forKeyPath:@"comment" options:NSKeyValueObservingOptionOld context:nil];
    }
}

#pragma mark -  others

- (NSArray *)sortedMatchInfoFilePathArray
{
    NSArray *filePaths = [[arrayController content] valueForKeyPath:@"filePath"];
    NSSet *filePathSet = [NSSet setWithArray:filePaths];
	return [[filePathSet allObjects] sortedArrayUsingSelector:@selector(compare:)];
}

- (NSArray *)matchInfoArray
{
    return arrayController.content;
}

- (NSString *)matchInfosString
{
    NSMutableString *resultString = [NSMutableString string];
    
    for (NSString *filePath in [self sortedMatchInfoFilePathArray]) {
        [resultString appendFormat:@"/* %@ */\n",filePath];
        for (KKMatchInfo *matchInfo in [self matchInfoArray]) {
            if ([[matchInfo filePath] isEqualToString:filePath]) {
                [resultString appendString:[NSString stringWithFormat:@"\"%@\" = \"%@\";/*%@*/ \n", matchInfo.key, matchInfo.translateString, matchInfo.comment]];
            }
        }
		[resultString appendString:@"\n\n"];
    }
    return resultString;
}

@synthesize arrayController;
@synthesize undoManager;
@end