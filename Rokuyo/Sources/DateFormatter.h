// SPDX-License-Identifier: GPL-3.0-or-later
// Rokuyo Clock
// Copyright (c) 2020 ilammy's tearoom

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DateFormatter : NSDateFormatter

// Extra date-time elements to include besides hours and minutes
@property (atomic) BOOL showWeekNumber;
@property (atomic) BOOL showRokuyo;
@property (atomic) BOOL showDayOfWeek;
@property (atomic) BOOL showDate;
@property (atomic) BOOL showSeconds;

// Query date formatter's locale to see what time format it prefers
@property (readonly) BOOL prefersHours24;
@property (readonly) BOOL prefersAMPM;

// Query date formatter's locale to see what time format it enforces
@property (readonly) BOOL alwaysHours24;
@property (readonly) BOOL alwaysAMPM;

// Set the format to use. Overrides preferred format. Overridden by enforced format.
@property (atomic) BOOL useHours24;
@property (atomic) BOOL showAMPM;

@end

NS_ASSUME_NONNULL_END
