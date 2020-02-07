#  六曜時計 — Rokuyo Clock

Drop-in replacement for standard macOS clock with rokuyo fortune for the day and week numbers.

<!-- TODO: screenshot here -->

**Rokuyo** is a _six-day_ cycle in Japanese lunisolar calendar which predicts (or prophesizes) how lucky your day will or will not be.

| Rokuyo | Reading    | Meaning                                    |
| ------ | ---------- | ------------------------------------------ |
|  先勝  | Sensho     | Good luck before noon, bad luck after noon |
|  友引  | Tomobiki   | Bad things happen during noon              |
|  先負  | Sembu      | Morning is unlucky, afternoon is not       |
|  仏滅  | Butsumetsu | The most unlucky day                       |
|  大安  | Taian      | The luckiest day, rest assured             |
|  赤口  | Shakku     | Glimpse of hope in the noon                |

Readings and meanings vary.
It’s your choice how to interpret them.

## 📦 Installing

1. [Download latest release](https://example.com). <!-- TODO: actual URL -->
2. Double-click the app to launch the clock.
3. Hold ⌘ and drag it where you want.  
4. Add your new clock to Login Items.
5. Hide the standard clock.

Updates are not provided automatically (to keep size to minimum).
Watch this GitHub project to be notified about new versions.
(I consider this program feature complete, bug fixes notwithstanding.)

## 🛠 Building

1. `open Rokuyo.xcodeproj`
2. Press **⌘R**

As it goes, computing rokuyo dates is easy (see [NSDate+Extra.m](Rokuyo/Sources/NSDate+Extra.m))
but displaying them is definitely not (as you may see in [DateFormatter.m](Rokuyo/Sources/DateFormatter.m)).
It gets surprisingly tricky if you drill into details, locales, scripts, calendars, etc.

## 📄 License

Rokuyo Clock is distributed under the terms of [**GNU GPL**](LICENSE) version 3 or any later version.
