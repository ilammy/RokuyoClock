// SPDX-License-Identifier: GPL-3.0-only
// Rokuyo Clock
// Copyright (c) 2020 ilammy's tearoom

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, Rokuyo)
{
    RokuyoSensho,
    RokuyoTomobiki,
    RokuyoSembu,
    RokuyoButsumetsu,
    RokuyoTaian,
    RokuyoShakku,
};

typedef NS_ENUM(NSInteger, Fortune)
{
    FortuneUnspecified,
    FortuneBadWholeDay,
    FortuneBadUntilNoon,
    FortuneBadSinceNoon,
    FortuneBadForNoon,
    FortuneGoodWholeDay,
    FortuneGoodUntilNoon,
    FortuneGoodSinceNoon,
    FortuneGoodForNoon,
};

@interface NSDate (Extra)

@property (readonly) Rokuyo    rokuyo;
@property (readonly) NSString *rokuyoKanji;
@property (readonly) NSString *localizedRokuyo;

@property (readonly) Fortune   fortune;
@property (readonly) NSString *localizedFortune;

@property (readonly) NSUInteger specialDay;

@end

NS_ASSUME_NONNULL_END
