#import <Cocoa/Cocoa.h>

@class JHTranslatedWindowController;
@protocol JHTranslatedWindowControllerDelegate <NSObject>
@required
- (void)windowController:(JHTranslatedWindowController *)inWindowController didMerge:(id)inSomething;
@end

@interface JHTranslatedWindowController : NSWindowController

- (IBAction)mergeTranslatedString:(id)sender;
- (IBAction)close:(id)sender;

@property (strong, nonatomic) IBOutlet NSTextView *translatedView;
@property (weak, nonatomic) IBOutlet NSButton *mergeButton;
@property (weak, nonatomic) IBOutlet NSButton *closeButton;

@property (weak, nonatomic) id<JHTranslatedWindowControllerDelegate> translatedWindowControllerDelegate;

@end
