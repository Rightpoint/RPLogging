import Foundation
import os



/// A simple log that outputs to the console via `print()` and also logs to the console with OSLog (if available)
///
open class Log {

    // MARK: Types

    /// A structure for a log message received by an instance of `Log`.
    public struct Message: CustomStringConvertible {
        public var category: String
        public var timestamp: Date
        public var message: String
        public var level: Level
        public var location: String
        public var description: String
    }

    ///  Represents a level of detail to be logged.
    public enum Level: Int, Codable, CaseIterable {

        /// Detailed information that is frequent or lengthy.
        case verbose

        /// Information that is mainly useful for debugging purposes.
        case debug

        /// Informational messages.
        case info

        /// Conditions less severe than errors
        case warn

        /// Critical error messages.
        case error

        /// No log entries will be sent
        case off

        /// Display friendly string for the Level
        public var name: String {
            switch self {
            case .verbose: return "Verbose"
            case .debug: return "Debug"
            case .info: return "Info"
            case .warn: return "Warn"
            case .error: return "Error"
            case .off: return "Disabled"
            }
        }

        /// Emoji representation of the Level.
        public var emoji: String {
            switch self {
            case .verbose: return "📖"
            case .debug: return "🐝"
            case .info: return "✏️"
            case .warn: return "⚠️"
            case .error: return "⁉️"
            case .off: return ""
            }
        }
    }

    // MARK: Public Properties

    /// Static instance used for static helper methods.
    public static private(set) var shared = Log("Log", logLevel: .off)

    /// Returns a reference to static instance of Log, intended to be overwritten by subclassed Log implementations.
    open class var instance: Log {
        return shared
    }

    /// Displayed name of the Log instance, also used as the Category in OSLog messages
    public var name: String

    /// The log level, defaults to .Off
    public var logLevel: Level = .off

    /// If true, prints emojis to signify log type, defaults to off
    public var useEmoji: Bool = false

    /// An array of `LogHandler` that will receive messages from this instance.
    public var handlers: [LogHandler] = []

    /// An array of `LogHandler` that handles all logs from any instance of `Log`. Default is the OSLogHandler
    public static var globalHandlers: [LogHandler] = [OSLogHandler()]

    // MARK: Private Properties

    /// Date formatter for log
    fileprivate static let dateformatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "Y-MM-dd H:m:ss.SSSS"
        return df
    }()

    // MARK: Initializer

    /// Initializes a Log instance
    ///
    /// - Parameter name: Name of the log.
    /// - Parameter logLevel: Logs below this `Level` will be ignored.
    /// - Parameter useEmoji: True if emoji should be displayed next to log messages.
    required public init(
        _ name: String,
        logLevel: Level = .off,
        useEmoji: Bool = false
    ) {
        self.name = name
        self.logLevel = logLevel
        self.useEmoji = useEmoji
    }

    // MARK: Private

    private func handle(message: Message) {
        handlers.forEach { $0.handle(message: message) }
        Log.globalHandlers.forEach { $0.handle(message: message) }
    }

    /// Generic log method
    internal func log<T>(_ object: @autoclosure () -> T, level: Log.Level, _ category: String, _ fileName: String, _ functionName: String, _ line: Int) {
        guard logLevel.rawValue <= level.rawValue else {return}

        let date = Date()
        let dateString = Log.dateformatter.string(from: Date())
        let components: [String] = fileName.components(separatedBy: "/")
        let objectName = components.last ?? "Unknown Object"
        let message = "\(object())"
        let levelString = useEmoji ? level.emoji : "|" + level.name.uppercased() + "|"
        let locationString = "\(objectName) \(functionName) line \(line)"
        let logString = "\(levelString) \(dateString) \(locationString):\n\(message)"

        handle(message: Message(
            category: category,
            timestamp: date,
            message: message,
            level: level,
            location: locationString,
            description: logString
        ))
    }

    // MARK: Public

    /// Adds an `LogHandler` to the which will receive all log events.
    ///
    /// - Parameter handler: `LogHandler` that will be added.
    public func addHandler(_ handler: LogHandler) {
        handlers.append(handler)
    }

    /// Logs an error level log message.
    ///
    /// - Parameter object: Message that will be logged
    /// - Parameter fileName: Name of the file where the message was generated.
    /// - Parameter functionName: Name of the function where the message was generated.
    /// - Parameter line: Line in the file where the message was generated.
    public func error<T>(_ object: @autoclosure () -> T, _ fileName: String = #file, _ functionName: String = #function, _ line: Int = #line) {
        log(object(), level: .error, name, fileName, functionName, line)
    }

    /// Logs an warning level log message.
    ///
    /// - Parameter object: Message that will be logged
    /// - Parameter fileName: Name of the file where the message was generated.
    /// - Parameter functionName: Name of the function where the message was generated.
    /// - Parameter line: Line in the file where the message was generated.
    public func warn<T>(_ object: @autoclosure () -> T, _ fileName: String = #file, _ functionName: String = #function, _ line: Int = #line) {
        log(object(), level: .warn, name, fileName, functionName, line)
    }

    /// Logs an info level log message.
    ///
    /// - Parameter object: Message that will be logged
    /// - Parameter fileName: Name of the file where the message was generated.
    /// - Parameter functionName: Name of the function where the message was generated.
    /// - Parameter line: Line in the file where the message was generated.
    public func info<T>(_ object: @autoclosure () -> T, _ fileName: String = #file, _ functionName: String = #function, _ line: Int = #line) {
        log(object(), level: .info, name, fileName, functionName, line)
    }

    /// Logs an debug level log message.
    ///
    /// - Parameter object: Message that will be logged
    /// - Parameter fileName: Name of the file where the message was generated.
    /// - Parameter functionName: Name of the function where the message was generated.
    /// - Parameter line: Line in the file where the message was generated.
    public func debug<T>(_ object: @autoclosure () -> T, _ fileName: String = #file, _ functionName: String = #function, _ line: Int = #line) {
        log(object(), level: .debug, name, fileName, functionName, line)
    }

    /// Logs a verbose level log message.
    ///
    /// - Parameter object: Message that will be logged
    /// - Parameter fileName: Name of the file where the message was generated.
    /// - Parameter functionName: Name of the function where the message was generated.
    /// - Parameter line: Line in the file where the message was generated.
    public func verbose<T>(_ object: @autoclosure () -> T, _ fileName: String = #file, _ functionName: String = #function, _ line: Int = #line) {
        log(object(), level: .verbose, name, fileName, functionName, line)
    }
}

// MARK: Static Helper Methods
extension Log {

    /// Log level of the shared Log instance.
    public static var logLevel: Level {
        get { instance.logLevel }
        set { instance.logLevel = newValue }
    }

    /// If true, prints emojis to signify log type, defaults to off
    public static var useEmoji: Bool {
        get { instance.useEmoji }
        set { instance.useEmoji = newValue }
    }

    /// Adds an `LogHandler` to the shared Log instance which will receive all log events.
    ///
    /// - Parameter handler: `LogHandler` that will be added.
    public static func addHandler(_ handler: LogHandler) {
        instance.addHandler(handler)
    }

    /// Adds an `LogHandler` to the global handlers which will receive messages from all Log instances.
    ///
    /// - Parameter handler: `LogHandler` that will be added.
    public static func addGlobalHandler(_ handler: LogHandler) {
        globalHandlers.append(handler)
    }

    /// Logs an error level log message in the shared Log instance.
    ///
    /// - Parameter object: Message that will be logged
    /// - Parameter category: Category for the message.
    /// - Parameter fileName: Name of the file where the message was generated.
    /// - Parameter functionName: Name of the function where the message was generated.
    /// - Parameter line: Line in the file where the message was generated.
    public static func error<T>(_ object: @autoclosure () -> T, _ category: String? = nil, _ fileName: String = #file, _ functionName: String = #function, _ line: Int = #line) {
        let category = category ?? instance.name
        instance.log(object(), level: .error, category, fileName, functionName, line)
    }

    /// Logs a warning level log message in the shared Log instance.
    ///
    /// - Parameter object: Message that will be logged
    /// - Parameter category: Category for the message.
    /// - Parameter fileName: Name of the file where the message was generated.
    /// - Parameter functionName: Name of the function where the message was generated.
    /// - Parameter line: Line in the file where the message was generated.
    public static func warn<T>(_ object: @autoclosure () -> T, _ category: String? = nil, _ fileName: String = #file, _ functionName: String = #function, _ line: Int = #line) {
        let category = category ?? instance.name
        instance.log(object(), level: .warn, category, fileName, functionName, line)
    }

    /// Logs an informational level log message in the shared Log instance.
    ///
    /// - Parameter object: Message that will be logged
    /// - Parameter category: Category for the message.
    /// - Parameter fileName: Name of the file where the message was generated.
    /// - Parameter functionName: Name of the function where the message was generated.
    /// - Parameter line: Line in the file where the message was generated.
    public static func info<T>(_ object: @autoclosure () -> T, _ category: String? = nil,_ fileName: String = #file, _ functionName: String = #function, _ line: Int = #line) {
        let category = category ?? instance.name
        instance.log(object(), level: .info, category, fileName, functionName, line)
    }

    /// Logs a debug level log message in the shared Log instance.
    ///
    /// - Parameter object: Message that will be logged
    /// - Parameter category: Category for the message.
    /// - Parameter fileName: Name of the file where the message was generated.
    /// - Parameter functionName: Name of the function where the message was generated.
    /// - Parameter line: Line in the file where the message was generated.
    public static func debug<T>(_ object: @autoclosure () -> T, _ category: String? = nil, _ fileName: String = #file, _ functionName: String = #function, _ line: Int = #line) {
        let category = category ?? instance.name
        instance.log(object(), level: .debug, category, fileName, functionName, line)
    }

    /// Logs a verbose level log message in the shared Log instance.
    ///
    /// - Parameter object: Message that will be logged
    /// - Parameter category: Category for the message.
    /// - Parameter fileName: Name of the file where the message was generated.
    /// - Parameter functionName: Name of the function where the message was generated.
    /// - Parameter line: Line in the file where the message was generated.
    public static func verbose<T>(_ object: @autoclosure () -> T, _ category: String? = nil, _ fileName: String = #file, _ functionName: String = #function, _ line: Int = #line) {
        let category = category ?? instance.name
        instance.log(object(), level: .verbose, category, fileName, functionName, line)
    }
}
