// SPDX-License-Identifier: GPL-3.0-only
// Rokuyo Clock
// Copyright (c) 2020 ilammy's tearoom

#import "NSDate+Extra.h"

@implementation NSDate (Extra)

- (NSDateComponents *)components:(NSCalendarUnit)unitFlags
{
    // Rokuyo uses Chinese lunisolar calendar, where hours and days measured
    // by the Sun's apparent movement and months are measured by the Moon,
    // with some ancient Chinese secret voodoo of leap day insertion.
    NSCalendar *chineseCalendar =
        [NSCalendar calendarWithIdentifier:NSCalendarIdentifierChinese];

    return [chineseCalendar components:unitFlags fromDate:self];
}

- (Rokuyo)rokuyo
{
    NSDateComponents *components = [self components:NSCalendarUnitMonth|NSCalendarUnitDay];

    // Rokuyo 6-day cycle starts at each of 12 months of Chinese calendar,
    // with the first day itself being in a 6-month similar cycle.
    Rokuyo starting = (components.month - 1) % 6;
    return (starting + components.day - 1) % 6;
}

- (Fortune)fortune
{
    NSDateComponents *components = [self components:NSCalendarUnitHour];

    // Rokuyo's fortune cookies act before, throughout, or after the noon,
    // which lasts for 2 hours from 11:00 to 13:00 (aka "hour of the horse").
    BOOL beforeNoon = (components.hour < 11);
    BOOL afterNoon = (components.hour >= 13);

    switch (self.rokuyo) {
        case RokuyoSensho:
            if (beforeNoon) {
                return FortuneGoodUntilNoon;
            }
            if (afterNoon) {
                return FortuneBadSinceNoon;
            }
            return FortuneUnspecified;

        case RokuyoTomobiki:
            if (beforeNoon) {
                return FortuneGoodUntilNoon;
            }
            if (afterNoon) {
                return FortuneGoodSinceNoon;
            }
            return FortuneBadForNoon;

        case RokuyoSembu:
            if (beforeNoon) {
                return FortuneBadUntilNoon;
            }
            if (afterNoon) {
                return FortuneGoodSinceNoon;
            }
            return FortuneUnspecified;

        case RokuyoButsumetsu:
            return FortuneBadWholeDay;

        case RokuyoTaian:
            return FortuneGoodWholeDay;

        case RokuyoShakku:
            if (beforeNoon) {
                return FortuneBadUntilNoon;
            }
            if (afterNoon) {
                return FortuneBadSinceNoon;
            }
            return FortuneGoodForNoon;
    }
}

- (NSString *)rokuyoKanji
{
    switch (self.rokuyo) {
        case RokuyoSensho:
            return @"先勝";
        case RokuyoTomobiki:
            return @"友引";
        case RokuyoSembu:
            return @"先負";
        case RokuyoButsumetsu:
            return @"仏滅";
        case RokuyoTaian:
            return @"大安";
        case RokuyoShakku:
            return @"赤口";
    }
}

- (NSString *)localizedRokuyo
{
    switch (self.rokuyo) {
        case RokuyoSensho:
            return NSLocalizedString(@"Sensho",     @"Rokuyo 1");
        case RokuyoTomobiki:
            return NSLocalizedString(@"Tomobiki",   @"Rokuyo 2");
        case RokuyoSembu:
            return NSLocalizedString(@"Sembu",      @"Rokuyo 3");
        case RokuyoButsumetsu:
            return NSLocalizedString(@"Butsumetsu", @"Rokuyo 4");
        case RokuyoTaian:
            return NSLocalizedString(@"Taian",      @"Rokuyo 5");
        case RokuyoShakku:
            return NSLocalizedString(@"Shakku",     @"Rokuyo 6");
    }
}

- (NSString *)localizedFortune
{
    switch (self.fortune) {
        case FortuneUnspecified:
            return NSLocalizedString(@"luck is fickle now",     @"");
        case FortuneBadWholeDay:
            return NSLocalizedString(@"bad luck whole day",     @"");
        case FortuneBadUntilNoon:
            return NSLocalizedString(@"bad luck till noon",     @"");
        case FortuneBadSinceNoon:
            return NSLocalizedString(@"bad luck since noon",    @"");
        case FortuneBadForNoon:
            return NSLocalizedString(@"bad luck for the noon",  @"");
        case FortuneGoodWholeDay:
            return NSLocalizedString(@"good luck whole day",    @"");
        case FortuneGoodUntilNoon:
            return NSLocalizedString(@"good luck till noon",    @"");
        case FortuneGoodSinceNoon:
            return NSLocalizedString(@"good luck since noon",   @"");
        case FortuneGoodForNoon:
            return NSLocalizedString(@"good luck for the noon", @"");
    }
}

// Tee-hee. Simply be existence of Core Foundation, this level of computation
// is possible for ****** *****. What do you think, everyone?
- (NSUInteger)specialDay
{
    NSCalendar *calendar =
        [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components =
        [calendar components:NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitWeekday
                    fromDate:self];
    if (components.month == 10 && components.day <= 8) {
        if (components.weekday == 7) {
            return 1;
        }
        if (components.weekday == 1 && components.day != 1) {
            return 2;
        }
    }
    return 0;
}

@end
