#import <UIKit/UIKit.h>

@interface PSOverlayWindow : UIWindow
@property (nonatomic, strong) UILabel *translationLabel;
+ (instancetype)sharedWindow;
- (void)updateWithSource:(NSString *)source translation:(NSString *)translation;
@end

@implementation PSOverlayWindow

+ (instancetype)sharedWindow {
    static PSOverlayWindow *window;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        window = [[PSOverlayWindow alloc]
            initWithFrame:CGRectMake(0, 60, UIScreen.mainScreen.bounds.size.width, 120)];
        window.windowLevel = UIWindowLevelAlert + 1;
        window.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
        window.hidden = NO;
        window.userInteractionEnabled = NO;

        UILabel *label = [[UILabel alloc] initWithFrame:window.bounds];
        label.textColor = UIColor.whiteColor;
        label.textAlignment = NSTextAlignmentCenter;
        label.numberOfLines = 3;
        label.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
        label.text = @"Platica-Say activo";
        window.translationLabel = label;
        [window addSubview:label];
    });
    return window;
}

- (void)updateWithSource:(NSString *)source translation:(NSString *)translation {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.translationLabel.text =
            [NSString stringWithFormat:@"%@\n→ %@", source, translation];
    });
}

@end
