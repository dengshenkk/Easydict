//
//  EZConfiguration.m
//  Easydict
//
//  Created by tisfeng on 2022/12/1.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZConfiguration.h"
#import <ServiceManagement/ServiceManagement.h>
#import <ApplicationServices/ApplicationServices.h>
#import <Sparkle/Sparkle.h>
#import "EZStatusItem.h"

static NSString *const kEasydictHelperBundleId = @"com.izual.EasydictHelper";

static NSString *const kAutoSelectTextKey = @"EZConfiguration_kAutoSelectTextKey";
static NSString *const kLaunchAtStartupKey = @"EZConfiguration_kLaunchAtStartupKey";
static NSString *const kFromKey = @"EZConfiguration_kFromKey";
static NSString *const kToKey = @"EZConfiguration_kToKey";
static NSString *const kHideMainWindowKey = @"EZConfiguration_kHideMainWindowKey";
static NSString *const kAutoSnipTranslateKey = @"EZConfiguration_kAutoSnipTranslateKey";
static NSString *const kAutoPlayAudioKey = @"EZConfiguration_kAutoPlayAudioKey";
static NSString *const kAutoCopySelectedTextKey = @"EZConfiguration_kAutoCopySelectedTextKey";
static NSString *const kAutoCopyOCRTextKey = @"EZConfiguration_kAutoCopyOCRTextKey";
static NSString *const kLanguageDetectOptimizeTypeKey = @"EZConfiguration_kLanguageDetectOptimizeTypeKey";
static NSString *const kShowGoogleLinkKey = @"EZConfiguration_kShowGoogleLinkKey";
static NSString *const kShowEudicLinkKey = @"EZConfiguration_kShowEudicLinkKey";
static NSString *const kHideMenuBarIconKey = @"EZConfiguration_kHideMenuBarIconKey";
static NSString *const kShowFixedWindowPositionKey = @"EZConfiguration_kShowFixedWindowPositionKey";
static NSString *const kWindowFrameKey = @"EZConfiguration_kWindowFrameKey";

@implementation EZConfiguration

static EZConfiguration *_instance;

+ (instancetype)shared {
    if (!_instance) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _instance = [[self alloc] init];
        });
    }
    return _instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
        [_instance setup];
    });
    return _instance;
}

- (void)setup {
    self.from = [NSUserDefaults mm_read:kFromKey defaultValue:EZLanguageAuto checkClass:NSString.class];
    self.to = [NSUserDefaults mm_read:kToKey defaultValue:EZLanguageAuto checkClass:NSString.class];
    
    self.autoSelectText = [[NSUserDefaults mm_read:kAutoSelectTextKey defaultValue:@(YES) checkClass:NSNumber.class] boolValue];
    self.autoPlayAudio = [[NSUserDefaults mm_read:kAutoPlayAudioKey defaultValue:@(NO) checkClass:NSNumber.class] boolValue];
    self.launchAtStartup = [[NSUserDefaults mm_read:kLaunchAtStartupKey defaultValue:@(NO) checkClass:NSNumber.class] boolValue];
    self.hideMainWindow = [[NSUserDefaults mm_read:kHideMainWindowKey defaultValue:@(YES) checkClass:NSNumber.class] boolValue];
    self.autoSnipTranslate = [[NSUserDefaults mm_read:kAutoSnipTranslateKey defaultValue:@(YES) checkClass:NSNumber.class] boolValue];
    self.autoCopySelectedText = [[NSUserDefaults mm_read:kAutoCopySelectedTextKey defaultValue:@(NO) checkClass:NSNumber.class] boolValue];
    self.autoCopyOCRText = [[NSUserDefaults mm_read:kAutoCopyOCRTextKey defaultValue:@(NO) checkClass:NSNumber.class] boolValue];
    self.languageDetectOptimize = [[NSUserDefaults mm_read:kLanguageDetectOptimizeTypeKey defaultValue:@(1) checkClass:NSNumber.class] integerValue];
    self.showGoogleQuickLink = [[NSUserDefaults mm_read:kShowGoogleLinkKey defaultValue:@(YES) checkClass:NSNumber.class] boolValue];
    self.showEudicQuickLink = [[NSUserDefaults mm_read:kShowEudicLinkKey defaultValue:@(YES) checkClass:NSNumber.class] boolValue];
    self.hideMenuBarIcon = [[NSUserDefaults mm_read:kHideMenuBarIconKey defaultValue:@(NO) checkClass:NSNumber.class] boolValue];
    self.fixedWindowPosition = [[NSUserDefaults mm_read:kShowFixedWindowPositionKey defaultValue:@(0) checkClass:NSNumber.class] integerValue];
}

#pragma mark - getter

- (BOOL)launchAtStartup {
    BOOL launchAtStartup = [[NSUserDefaults mm_read:kLaunchAtStartupKey] boolValue];
    [self updateLoginItemWithLaunchAtStartup:launchAtStartup];
    return launchAtStartup;
}

- (BOOL)automaticallyChecksForUpdates {
    return [SUUpdater sharedUpdater].automaticallyChecksForUpdates;
}

#pragma mark - setter

- (void)setAutoSelectText:(BOOL)autoSelectText {
    _autoSelectText = autoSelectText;
    [NSUserDefaults mm_write:@(autoSelectText) forKey:kAutoSelectTextKey];
}

- (void)setLaunchAtStartup:(BOOL)launchAtStartup {
    [NSUserDefaults mm_write:@(launchAtStartup) forKey:kLaunchAtStartupKey];
    [self updateLoginItemWithLaunchAtStartup:launchAtStartup];
}

- (void)setAutomaticallyChecksForUpdates:(BOOL)automaticallyChecksForUpdates {
    [[SUUpdater sharedUpdater] setAutomaticallyChecksForUpdates:automaticallyChecksForUpdates];
}

- (void)setFrom:(EZLanguage)from {
    _from = from;
    [NSUserDefaults mm_write:from forKey:kFromKey];
}

- (void)setTo:(EZLanguage)to {
    _to = to;
    [NSUserDefaults mm_write:to forKey:kToKey];
}

- (void)setHideMainWindow:(BOOL)hideMainWindow {
    _hideMainWindow = hideMainWindow;
    
    [NSUserDefaults mm_write:@(hideMainWindow) forKey:kHideMainWindowKey];
}

- (void)setAutoSnipTranslate:(BOOL)autoSnipTranslate {
    _autoSnipTranslate = autoSnipTranslate;
    
    [NSUserDefaults mm_write:@(autoSnipTranslate) forKey:kAutoSnipTranslateKey];
}

- (void)setAutoPlayAudio:(BOOL)autoPlayAudio {
    _autoPlayAudio = autoPlayAudio;
    
    [NSUserDefaults mm_write:@(autoPlayAudio) forKey:kAutoPlayAudioKey];
}

- (void)setAutoCopySelectedText:(BOOL)autoCopySelectedText {
    _autoCopySelectedText = autoCopySelectedText;
    
    [NSUserDefaults mm_write:@(autoCopySelectedText) forKey:kAutoCopySelectedTextKey];
}

- (void)setAutoCopyOCRText:(BOOL)autoCopyOCRText {
    _autoCopyOCRText = autoCopyOCRText;
    
    [NSUserDefaults mm_write:@(autoCopyOCRText) forKey:kAutoCopyOCRTextKey];
}

- (void)setLanguageDetectOptimize:(EZLanguageDetectOptimize)languageDetectOptimizeType {
    _languageDetectOptimize = languageDetectOptimizeType;
    
    [NSUserDefaults mm_write:@(languageDetectOptimizeType) forKey:kLanguageDetectOptimizeTypeKey];
}

- (void)setShowGoogleQuickLink:(BOOL)showGoogleLink {
    _showGoogleQuickLink = showGoogleLink;
    
    [NSUserDefaults mm_write:@(showGoogleLink) forKey:kShowGoogleLinkKey];
    [self postUpdateQuickLinkButtonNotification];
}

- (void)setShowEudicQuickLink:(BOOL)showEudicLink {
    _showEudicQuickLink = showEudicLink;
    
    [NSUserDefaults mm_write:@(showEudicLink) forKey:kShowEudicLinkKey];
    [self postUpdateQuickLinkButtonNotification];
}

- (void)setHideMenuBarIcon:(BOOL)hideMenuBarIcon {
    _hideMenuBarIcon = hideMenuBarIcon;
    
    [NSUserDefaults mm_write:@(hideMenuBarIcon) forKey:kHideMenuBarIconKey];
    
    [self hideMenuBarIcon:hideMenuBarIcon];
}

- (void)setFixedWindowPosition:(EZShowWindowPosition)showFixedWindowPosition {
    _fixedWindowPosition = showFixedWindowPosition;
    
    [NSUserDefaults mm_write:@(showFixedWindowPosition) forKey:kShowFixedWindowPositionKey];
}


#pragma mark - Window Frame

- (CGRect)windowFrameWithType:(EZWindowType)windowType {
    NSString *key = [self windowFrameKey:windowType];
    NSString *frameString = [NSUserDefaults mm_read:key];
    CGRect frame = NSRectFromString(frameString);
    return frame;
}
- (void)setWindowFrame:(CGRect)frame windowType:(EZWindowType)windowType {
    NSString *key = [self windowFrameKey:windowType];
    NSString *frameString = NSStringFromRect(frame);
    [NSUserDefaults mm_write:frameString forKey:key];
}

- (NSString *)windowFrameKey:(EZWindowType)windowType {
    NSString *key = [NSString stringWithFormat:@"%@_%@", kWindowFrameKey, @(windowType)];
    return key;
}

#pragma mark -

- (void)updateLoginItemWithLaunchAtStartup:(BOOL)launchAtStartup {
    //    [self isLoginItemEnabled];
    
    NSString *helperBundleId = [self helperBundleId];
    
    NSError *error;
    if (@available(macOS 13.0, *)) {
        // Ref: https://www.bilibili.com/read/cv19361413
        SMAppService *appService = [SMAppService loginItemServiceWithIdentifier:helperBundleId];
        BOOL success;
        if (launchAtStartup) {
            success = [appService registerAndReturnError:&error];
        } else {
            success = [appService unregisterAndReturnError:&error];
        }
        if (error) {
            MMLogInfo(@"SMAppService error: %@", error);
        }
        if (!success) {
            MMLogInfo(@"SMAppService fail");
        }
    } else {
        // Ref: https://nyrra33.com/2019/09/03/cocoa-launch-at-startup-best-practice/
        BOOL success = SMLoginItemSetEnabled((__bridge CFStringRef)helperBundleId, launchAtStartup);
        if (!success) {
            MMLogInfo(@"SMLoginItemSetEnabled fail");
        }
    }
}

- (BOOL)isLoginItemEnabled {
    BOOL enabled = NO;
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CFArrayRef loginItems = SMCopyAllJobDictionaries(kSMDomainUserLaunchd);
#pragma clang diagnostic pop
    
    NSString *helperBundleId = [self helperBundleId];
    for (id item in (__bridge NSArray *)loginItems) {
        if ([[[item objectForKey:@"Label"] description] isEqualToString:helperBundleId]) {
            enabled = YES;
            break;
        }
    }
    CFRelease(loginItems);
    return enabled;
}

- (NSString *)helperBundleId {
#if DEBUG
    NSString *helperId = [NSString stringWithFormat:@"%@-debug", kEasydictHelperBundleId];
#else
    NSString *helperId = kEasydictHelperBundleId;
#endif
    return helperId;
}

- (void)postUpdateQuickLinkButtonNotification {
    NSNotification *notification = [NSNotification notificationWithName:EZQuickLinkButtonUpdateNotification object:nil userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

// hide menu bar icon
- (void)hideMenuBarIcon:(BOOL)hidden {
    EZStatusItem *statusItem = [EZStatusItem shared];
    if (self.hideMenuBarIcon) {
        [statusItem remove];
    } else {
        [statusItem setup];
    }
}

@end
