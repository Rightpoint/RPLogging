import Foundation
import os

public protocol LogHandler {
    func handle(message: Log.Message)
}

open class OSLogHandler: LogHandler {
    /// Subsystem of the OSLog message when running on iOS 14 or later.
    public var subsystem: String

    /// Initializes a ConsoleLogDestination using the bundle identifier as the subsystem
    public init() {
        let bundleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        self.subsystem = (bundleName ?? "com.rightpoint.logger") + ".log"
    }

    /// Initializes a ConsoleLogDestination
    ///
    /// - Parameter subsystem: Subsystem of the OSLog messages.
    public init(subsystem: String) {
        self.subsystem = subsystem
    }

    // MARK: LogHandler

    public func handle(message: Log.Message) {
        if #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *) {
            osLog(level: message.level, category: message.category, message: message.message)
        } else {
            print(message.description)
        }
    }


    // MARK: Private Methods

    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
    internal func osLog(level: Log.Level, category: String, message: String) {
        let logger = os.Logger(subsystem: subsystem, category: category)
        switch level {
        case .verbose:
            logger.trace("\(message)")
        case .debug:
            logger.debug("\(message)")
        case .info:
            logger.info("\(message)")
        case .warn:
            logger.warning("\(message)")
        case .error:
            logger.error("\(message)")
        case .off:
            break
        }
    }
}
