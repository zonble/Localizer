#import "JHTranslatedWindowController.h"

@implementation JHTranslatedWindowController

- (void)dealloc
{
	self.translatedView = nil;
	self.translatedWindowControllerDelegate = nil;
}

- (void)awakeFromNib
{
	[[self window] setDefaultButtonCell:[self.mergeButton cell]];
}

- (IBAction)mergeTranslatedString:(id)sender
{
	if (self.translatedWindowControllerDelegate && [self.translatedWindowControllerDelegate respondsToSelector:@selector(windowController:didMerge:)]) {
		[self.translatedWindowControllerDelegate windowController:self didMerge:nil];
	}
}

- (IBAction)close:(id)sender
{
	[NSApp endSheet:self.window];
	[self.window orderOut:self];
}

@end
