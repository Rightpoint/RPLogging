# Logging

Set a logging level to dictate priority of events logged

### Quick Start

By default, nothing will be logged, so you want to set a logging level during app set-up, before any loggable events. Different logging levels are often set for different build schemes (debug scheme may be `.verbose` while release might be `.warn`).
```swift
Log.logLevel = .warn
```

Use the level functions when logging to indicate what type of event has occurred
```swift
Log.verbose("Lower priority events will not be logged")
Log.error("Errors are higher priority than .warn, so will be logged")
```

Log levels (from highest to lowest priority):
- verbose
- debug
- info
- warn
- error
- off


A Trace is similar to a Log, but can be used to measure timing. Traces will also be logged as os_signposts which are viewable in Xcode Instruments.

```swift
Trace.begin("App Startup")
...
Trace.end("App Startup")

Trace.event("App moved to background")

```


## Advanced functionality

One or more LogHandlers may be added at both the instance level, or global level. A `LogHandler` may be used for example to send the log messages to the console, or to an analytics service. There is a `OSLogHandler` defined globally by default, which will send log output to the console or oslog if running iOS 14 or greater.

```swift
public protocol LogHandler {
    func handle(message: Log.Message)
}

// add a handler that will receive messages from ALL log instances.
Log.addGlobalHandler(MyLogHandler())
```

Log messages may be categorized by defining separate instances of the Log class.

```swift
final class Loggers {
    static let userInterface = Log("UI", logLevel: .verbose)
    static let app = Log("App")
    static let network = Log("Network", logLevel: .error)
}

Loggers.userInterface.info("Button Pressed")
Loggers.network.error("Token Expired")
Loggers.app.warn("Out of Memory")
```

You may also include custom handlers per Log instance. Messages will still be reported to the global handler as well.

```swift
Loggers.network.addHandler(MyLogHandler())
```

Log level can also be represented by emoji instead of strings.

```swift
Log.useEmoji = true
```

Emoji key:
- .verbose = 📖
- .debug = 🐝
- .info = ✏️
- .warn = ⚠️
- .error = ⁉️
