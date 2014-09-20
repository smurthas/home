
#import "HMAuthAlert.h"


@implementation HMAuthAlert


- (id) initWithYesBlock:(void(^)(void))yesBlock noBlock:(void(^)(void))noBlock
{
    self = [super init];
    if (self)
    {
        self.yesBlock = yesBlock;
        self.noBlock = noBlock;
    }
    return self;
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0 && self.noBlock)
        self.noBlock();
    else if (buttonIndex == 1 && self.yesBlock)
        self.yesBlock();
}

- (void) alertViewCancel:(UIAlertView *)alertView
{
    if (self.noBlock)
        self.noBlock();
}

+ (void) yesNoWithTitle:(NSString*)title message:(NSString*)message yesBlock:(void(^)(void))yesBlock noBlock:(void(^)(void))noBlock
{
    HMAuthAlert* yesNoListener = [[HMAuthAlert alloc] initWithYesBlock:yesBlock noBlock:noBlock];
    [[[UIAlertView alloc] initWithTitle:title message:message delegate:yesNoListener cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] show];
}

@end