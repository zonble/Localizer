#import <Cocoa/Cocoa.h>

@class JHTranslatedWindowController;
@protocol JHTranslatedWindowControllerDelegate <NSObject>
@required
- (void)windowController:(JHTranslatedWindowController *)inWindowController didMerge:(id)inSomething;
@end

@interface JHTranslatedWindowController : NSWindowController
{
    IBOutlet NSTextView *__unsafe_unretained translatedView;
    IBOutlet NSButton *__weak mergeButton;
    IBOutlet NSButton *__weak closeButton;

    id <JHTranslatedWindowControllerDelegate> __unsafe_unretained translatedWindowControllerDelegate;
}

- (IBAction)mergeTranslatedString:(id)sender;
- (IBAction)close:(id)sender;

@property (unsafe_unretained, nonatomic) IBOutlet NSTextView *translatedView;
@property (weak, nonatomic) IBOutlet NSButton *mergeButton;
@property (weak, nonatomic) IBOutlet NSButton *closeButton;

@property (unsafe_unretained, nonatomic) id<JHTranslatedWindowControllerDelegate> translatedWindowControllerDelegate;

@end
