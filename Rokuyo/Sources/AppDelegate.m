// SPDX-License-Identifier: GPL-3.0-or-later
// Rokuyo Clock
// Copyright (c) 2020 ilammy's tearoom

#import "AppDelegate.h"

#import "DateFormatter.h"
#import "NSDate+Extra.h"

@interface AppDelegate ()

@property (nonatomic) NSStatusItem *statusItem;

@property (nonatomic) DateFormatter *statusTimeFormatter;
@property (nonatomic) NSDateFormatter *fullDateFormatter;

@property (nonatomic) NSDate *previousTick;

@property (nonatomic, weak) IBOutlet NSMenu *statusMenu;
@property (nonatomic, weak) IBOutlet NSMenuItem *fullDateItem;
@property (nonatomic, weak) IBOutlet NSMenuItem *specialDayItem;
@property (nonatomic, weak) IBOutlet NSMenuItem *currentLuckItem;

@property (nonatomic, weak) IBOutlet NSWindow *clockPreferences;

@end

@implementation AppDelegate

#pragma mark - Initialization

static const NSTimeInterval timerTickInterval = 0.1f;

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    self.statusItem = [NSStatusBar.systemStatusBar statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.menu = self.statusMenu;

    self.statusTimeFormatter = [DateFormatter new];
    self.statusTimeFormatter.formattingContext = NSFormattingContextListItem;

    self.fullDateFormatter = [NSDateFormatter new];
    self.fullDateFormatter.dateStyle = NSDateFormatterFullStyle;
    self.fullDateFormatter.timeStyle = NSDateFormatterNoStyle;
    self.fullDateFormatter.formattingContext = NSFormattingContextListItem;

    [NSRunLoop.currentRunLoop
     addTimer:[NSTimer timerWithTimeInterval:timerTickInterval
                                      target:self
                                    selector:@selector(clockTicking:)
                                    userInfo:nil
                                     repeats:YES]
      forMode:NSDefaultRunLoopMode];

    [self registerUserDefaults];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [NSStatusBar.systemStatusBar removeStatusItem:self.statusItem];

    [self unregisterUserDefaults];
}

#pragma mark - User defaults

static NSDictionary<NSString *,id> *defaultValues;
static void *observeUserDefaults   = &observeUserDefaults;
static void *observeSecondsSetting = &observeSecondsSetting;

- (void)registerUserDefaults
{
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;

    // Unfortunately, we can't use the defaults from the system clock
    // because with App Sandbox we are not allowed to read them.
    // Use my settings which I personally find reasonable :)
    NSNumber *prefer24 = [NSNumber numberWithBool:self.statusTimeFormatter.prefersHours24];
    NSNumber *preferAM = [NSNumber numberWithBool:self.statusTimeFormatter.prefersAMPM];
    defaultValues = @{
        @"showWeekNumber":  @YES,
        @"showRokuyo":      @YES,
        @"showDate":        @YES,
        @"showDayOfWeek":   @YES,
        @"showSeconds":     @NO,
        @"useHours24":      prefer24,
        @"showAMPM":        preferAM,
    };
    [defaults registerDefaults:defaultValues];

    for (NSString *key in defaultValues) {
        [self syncWithUserDefaults:defaults forKeyPath:key];
        [defaults addObserver:self
                   forKeyPath:key
                      options:0
                      context:observeUserDefaults];
    }
    [self.statusTimeFormatter addObserver:self
                               forKeyPath:@"showSeconds"
                                  options:0
                                  context:observeSecondsSetting];

    // Give the clock initial value to display
    [self updateTimeIndication];
}

- (void)unregisterUserDefaults
{
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;

    for (NSString *key in defaultValues) {
        [defaults removeObserver:self
                      forKeyPath:key
                         context:observeUserDefaults];
    }
    [self.statusTimeFormatter removeObserver:self
                                  forKeyPath:@"showSeconds"
                                     context:observeSecondsSetting];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context
{
    // Immediately update the clock to take preference changes into account
    if (context == observeUserDefaults) {
        [self syncWithUserDefaults:object forKeyPath:keyPath];
        [self updateTimeIndication];
        return;
    }

    // Regular fonts use proportional glyphs for digits which results in annoying
    // snapping of clock indication when seconds are displayed. Use a monospaced
    // font when we display seconds, and a better-looking default one otherwise.
    if (context == observeSecondsSetting) {
        CGFloat fontSize = self.statusItem.button.font.pointSize;
        NSFont *newFont;
        if (self.statusTimeFormatter.showSeconds) {
            newFont = [NSFont monospacedDigitSystemFontOfSize:fontSize
                                                       weight:NSFontWeightRegular];
        } else {
            newFont = [NSFont systemFontOfSize:fontSize];
        }
        self.statusItem.button.font = newFont;
        return;
    }

    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)syncWithUserDefaults:(NSUserDefaults *)defaults
                  forKeyPath:(NSString *)keyPath
{
    [self.statusTimeFormatter setValue:[defaults valueForKeyPath:keyPath]
                            forKeyPath:keyPath];
}

#pragma mark - Time indication

static inline BOOL indicatedSecondsEqual(NSDate *a, NSDate *b)
{
    NSTimeInterval secondsA = floor(a.timeIntervalSinceReferenceDate);
    NSTimeInterval secondsB = floor(b.timeIntervalSinceReferenceDate);
    return secondsA == secondsB;
}

- (void)clockTicking:(NSTimer *)timer
{
    NSDate *current = [NSDate date];
    NSDate *previous = self.previousTick;
    self.previousTick = current;

    // We tick faster than the seconds change to update the clock more smoothly
    // but we don't have to actually compute updates if the indicated time does
    // not change -- that is, if the difference in time is less than a second.
    if (indicatedSecondsEqual(current, previous)) {
        return;
    }

    [self updateTimeIndication];
}

- (void)updateTimeIndication
{
    NSDate *current = [NSDate date];

    self.statusItem.button.title = [self.statusTimeFormatter stringFromDate:current];
    self.fullDateItem.title = [self.fullDateFormatter stringFromDate:current];
    self.currentLuckItem.title =
        [NSString stringWithFormat:NSLocalizedString(@"%@: %@", @"{Rokuyo}: {fortune}"),
         current.localizedRokuyo, current.localizedFortune];
    [self updateSpecialDay];
}

- (void)updateSpecialDay
{
    switch (NSDate.date.specialDay) {
    case 1:
        self.specialDayItem.title = NSLocalizedString(@"First day of the conference", @"Day 1");
        self.specialDayItem.hidden = NO;
        break;
    case 2:
        self.specialDayItem.title = NSLocalizedString(@"Second day of the conference", @"Day 2");
        self.specialDayItem.hidden = NO;
        break;
    default:
        self.specialDayItem.hidden = YES;
    }
}

#pragma mark - Menu actions

- (IBAction)openClockPreferences:(id)sender
{
    [self.clockPreferences makeKeyAndOrderFront:sender];
}

- (IBAction)openDateTimePreferences:(id)sender
{
    // We would prefer to open "Date & Time Preferences" but Apple believes
    // that peasants should not be allowed to do that. The preference pane
    // does not have necessary entitlements in its Info.plist so this opens
    // top-level "System Preferences" instead. Fuck^W I love you too, Apple.
    NSURL *url = [NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.datetime"];
    [[NSWorkspace sharedWorkspace] openURL:url];
    return;
}

- (IBAction)quitClock:(id)sender
{
    [NSApp terminate:sender];
}

@end
