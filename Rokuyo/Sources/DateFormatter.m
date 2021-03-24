// SPDX-License-Identifier: GPL-3.0-only
// Rokuyo Clock
// Copyright (c) 2020 ilammy's tearoom

#import "DateFormatter.h"

#import "NSDate+Extra.h"

@interface DateFormatter ()

// We manipuate the "dateFormat" property and use this lock to ensure that
// its value stays the same while we do the "stringFromDate" call.
@property (nonatomic) NSLock *formatStringLock;

@end

@implementation DateFormatter

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.formatStringLock = [NSLock new];

        // Automatically track locale updates, some properties depend on that
        self.locale = NSLocale.autoupdatingCurrentLocale;
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(localeChanged:)
                                                   name:NSCurrentLocaleDidChangeNotification
                                                 object:nil];

        // If we are going to show hours in 24-hour format, say so
        if (self.alwaysHours24) {
            self.useHours24 = YES;
            self.showAMPM = NO;
        } else {
            self.useHours24 = self.prefersHours24;
            self.showAMPM = self.prefersAMPM;
        }
    }
    return self;
}

#pragma mark - 24-hour clock

// It's hidden pretty well in Apple documentation but the date patterns
// are governed by UTS #35 -- expectedly, since Core Foundation uses ICU.
//
// It would be nice to have some more friendly API to these properties
// of locale, but we use what we have because UTS says so:
//
// > Note that use of 'j' in a skeleton passed to an API is the only way
// > to have a skeleton request a locale's preferred time cycle type
// > (12-hour or 24-hour).
//
// "j" is 'input skeleton symbol' which gets transformed into preferred
// hour representation:
//   - "h": 1-based 12-hour (1..12) 12:00 AM  6:00 AM  12:00 PM   6:00 PM
//   - "H": 0-based 24-hour (0..23)  0:00     6:00     12:00     18:00
//   - "K": 0-based 12-hour (0..11)  0:00 AM  6:00 AM   0:00 PM   6:00 PM
//   - "k": 1-based 24-hour (1..24) 24:00     6:00     12:00     18:00
// possibly with appropriately positioned day period marker, if preferred:
//   - "a": AM, PM
//   - "b": AM, PM + midnight, noon
// There is also "J" which is the same but without day period marker.
// Additionally, they may be duplicated (e.g., "jj") to get zero-padded
// two-digit form. There are other features but we don't make use of them.
//
// And yes, all of this is actually used. Some cultures prefer 12-hour clock,
// some prefer 24-hour one, some enforce either format. Some prefer writing
// their equivalent of AM/PM, some occasionally don't, some always do. Some
// cultures use 0-based clock and some use 1-based one, sometimes different
// based on whether it's 12-hour clock or 24-hour one. FFS, use ISO 8601!

- (BOOL)prefersHours24
{
    NSString *format = [self.class dateFormatFromTemplate:@"j:mm"
                                                  options:0
                                                   locale:self.locale];
    return [format containsString:@"H"] || [format containsString:@"k"];
}

- (BOOL)prefersAMPM
{
    NSString *format = [self.class dateFormatFromTemplate:@"j:mm"
                                                  options:0
                                                   locale:self.locale];
    return [format containsString:@"a"] || [format containsString:@"b"];
}

- (BOOL)alwaysHours24
{
    NSString *format = [self.class dateFormatFromTemplate:@"h:mm"
                                                  options:0
                                                   locale:self.locale];
    return [format containsString:@"H"] || [format containsString:@"k"];
}

- (BOOL)alwaysHours12
{
    NSString *format = [self.class dateFormatFromTemplate:@"H:mm"
                                                  options:0
                                                   locale:self.locale];
    return [format containsString:@"h"] || [format containsString:@"K"];
}

- (BOOL)alwaysFixedHours
{
    return self.alwaysHours24 || self.alwaysHours12;
}

- (BOOL)alwaysAMPM
{
    NSString *format = [self.class dateFormatFromTemplate:@"J:mm"
                                                  options:0
                                                   locale:self.locale];
    return [format containsString:@"a"] || [format containsString:@"b"];
}

- (void)localeChanged:(NSNotification *)notification
{
    // Values of the properites above change depending on the current locale.
    // Make observers aware of the possible change (after-the-fact).
    NSArray<NSString *> *derivedProperties = @[
        @"prefersHours24", @"prefersAMPM",
        @"alwaysHours24", @"alwaysHours12", @"alwaysFixedHours",
        @"alwaysAMPM",
    ];
    for (NSString *property in derivedProperties) {
        [self willChangeValueForKey:property];
        [self didChangeValueForKey:property];
    }
}

#pragma mark - Date-time formatting

- (NSString *)stringFromDate:(NSDate *)date
{
    // Output consist of three slugs with date and time mirroring the standard
    // clock and an extra one before them with our extensions.
    return [self joinStrings:@[[self extraSlug:date],
                               [self dateSlug:date],
                               [self timeSlug:date]]
                        with:@"  "];
}

- (NSString *)extraSlug:(NSDate *)date
{
    return [self joinStrings:@[[self weekSlug:date],
                               [self rokuyoSlug:date]]
                        with:@" "];
}

- (NSString *)weekSlug:(NSDate *)date
{
    NSString *result = @"";
    if (self.showWeekNumber) {
        [self.formatStringLock lock];
        {
            [self setLocalizedDateFormatFromTemplate:@"w"];
            result = [super stringFromDate:date];
            // Mark this slug as a strong isolate so that BiDi treats it correctly.
            // Since "W" is a strong LTR character but (week) numbers are weak,
            // this slug may behave weirdly when combined with RTL text. Isolate
            // marks ensure that it is treated as isolated chunk of text.
            result = [NSString stringWithFormat:@"\u2068W%@\u2069", result];
        }
        [self.formatStringLock unlock];
    }
    return result;
}

- (NSString *)rokuyoSlug:(NSDate *)date
{
    if (!self.showRokuyo) {
        return @"";
    }
    // Ditto as with week numbers. Rokuyo kanji are LTR, we need to frame them.
    return [NSString stringWithFormat:@"\u2068%@\u2069", date.rokuyoKanji];
}

- (NSString *)dateSlug:(NSDate *)date
{
    NSString *result = @"";
    if (self.showDate || self.showDayOfWeek) {
        [self.formatStringLock lock];
        {
            // We use "EEE" and "MMM" to get compact representations,
            // like "Tue" and "Apr". "d" is for days, shortest format.
            if (self.showDate && self.showDayOfWeek) {
                [self setLocalizedDateFormatFromTemplate:@"EEE MMM d"];
            } else if (self.showDate) {
                [self setLocalizedDateFormatFromTemplate:@"MMM d"];
            } else if (self.showDayOfWeek) {
                [self setLocalizedDateFormatFromTemplate:@"EEE"];
            }
            result = [super stringFromDate:date];
            switch (date.specialDay) {
            case 1: result = NSLocalizedString(@"The 1st day", @"Day 1"); break;
            case 2: result = NSLocalizedString(@"The 2nd day", @"Day 2"); break;
            }
        }
        [self.formatStringLock unlock];
    }
    return result;
}

- (NSString *)timeSlug:(NSDate *)date
{
    NSString *result = @"";
    [self.formatStringLock lock];
    {
        NSMutableString *template = [NSMutableString stringWithCapacity:7];
        // We don't use "j" here because we know that format we need
        [template appendString:self.useHours24 ? @"H" : @"h"];
        [template appendString:@":mm"];
        if (self.showSeconds) {
            [template appendString:@":ss"];
        }
        if (self.showAMPM) {
            [template appendString:@"a"];
        }
        [self setLocalizedDateFormatFromTemplate:template];
        // We explicitly request AM/PM if the user asks for it but most locales
        // add it even if we don't ask. By default, clock preferences match
        // the locale. However, if AM/PM is turned off, we should remove it.
        // "J" format does not quite work as intended here.
        if (!self.showAMPM) {
            [template setString:self.dateFormat];
            [template replaceOccurrencesOfString:@"[:space:]?(a|b)+[:space:]?"
                                      withString:@""
                                         options:NSRegularExpressionSearch
                                           range:NSMakeRange(0, template.length)];
            [self setDateFormat:template];
        }
        result = [super stringFromDate:date];
    }
    [self.formatStringLock unlock];
    return result;
}

#pragma mark - Utilities

- (NSString *)joinStrings:(NSArray<NSString *> *)strings with:(NSString *)separator
{
    // It's okay to simply concatenate substrings.
    // BiDi will take care of right-to-left scripts.
    NSMutableString *joined = [NSMutableString stringWithCapacity:32];
    BOOL first = YES;
    for (NSString *s in strings) {
        // Skip empty slugs
        if (s.length == 0) {
            continue;
        }
        if (first) {
            first = NO;
        } else {
            [joined appendString:separator];
        }
        [joined appendString:s];
    }
    return joined;
}

@end
