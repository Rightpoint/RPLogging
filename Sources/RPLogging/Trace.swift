import Foundation
import os

/// Logger for sending trace messages and os_signposts.
///
open class Trace {

    // MARK: Types
    public struct Signpost {
        /// Division within a system of classification
        public typealias Category = String

        /// Average duration of all traces completed with the same name
        public var averageDuration: TimeInterval?

        /// Category of the logged message.
        public var category: Category

        /// Timestamp of when the trace was started.
        public var started: Date

        /// Timestamp of when the trace was logged.
        public var ended: Date

        /// Name of the trace
        public var name: String

        // MARK: Initializers

        /// Initialize a `TraceEvent`.
        ///
        /// - Parameters:
        ///  - averageDuration: Average duration of all traces completed with the same name
        ///  - category: Category of the logged message.
        ///  - started: Timestamp when the trace was started.
        ///  - ended: Timestamp when the trace was logged.
        ///  - name: Name of the trace
        init(
            averageDuration: TimeInterval? = nil,
            category: Category = "",
            started: Date = Date(),
            ended: Date = Date(),
            name: String
        ) {
            self.averageDuration = averageDuration
            self.category = category
            self.started = started
            self.ended = ended
            self.name = name
        }
    }

    /// Represents the OSSignpostType when sending trace messages to instruments
    public enum TraceType {
        /// Begins a trace
        case begin

        /// Ends a trace
        case end

        /// A non-timed trace event.
        case event
    }

    // MARK: Public Properties

    /// Shared instance of Trace.
    public static private(set) var shared = Trace("")

    /// Static instance used for helper methods.
    open class var instance: Trace {
        return shared
    }

    /// Displayed name of the Trace instance.
    public var name: String

    /// A `TraceHandler` that *all* Signposts will be handled by. Default is `ConsoleLogTraceHandler`
    public static var globalHandlers: [TraceHandler] = [ConsoleLogTraceHandler()]

    /// Subsystem of the OSLog message when running on iOS 14 or later.
    open var subsystem: String {
        let bundleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        return (bundleName ?? "com.rightpoint.logger") + ".log"
    }

    // MARK: Private Properties

    /// Dictionary of traces that have started but not completed, keyed by name
    private var activeTraces: [String: Signpost] = [:]

    /// Dictionary of completed trace durations, keyed by name
    private var completedTraces: [String: (count: Int, total: TimeInterval)] = [:]

    // MARK: Initializer

    /// Initializes a Log instance
    ///
    /// - Parameter name: Name of the log.
    required public init(
        _ name: String
    ) {
        self.name = name
    }

    // MARK: Private Methods

    private func handle(signpost: Signpost) {
        Trace.globalHandlers.forEach { $0.handle(trace: self, signpost: signpost) }
    }

    // MARK: Public Methods

    /// Logs a point of interest with the "begin" type  in your code as a time interval or as an event for debugging performance in Instruments.
    ///
    /// - Parameter name: Name of the trace event.
    /// - Parameter date: Date when trace was started.
    public func begin(_ name: StaticString, date: Date = Date()) {
        let oslog = OSLog(subsystem: subsystem, category: self.name)
        let traceName = "\(name)"
        activeTraces[traceName] = Signpost(
            category: self.name,
            started: date,
            ended: date,
            name: traceName
        )
        os_signpost(.begin, log: oslog, name: name)
    }

    /// Logs a point of interest with the "end" type in your code as a time interval or as an event for debugging performance in Instruments.
    ///
    /// - Parameter name: Name of the trace event.
    /// - Parameter date: Date when trace was ended.
    public func end(_ name: StaticString, date: Date = Date()) {
        let oslog = OSLog(subsystem: subsystem, category: self.name)
        let traceName = "\(name)"
        if var trace = activeTraces[traceName] {
            trace.ended = date

            var result = completedTraces[traceName] ?? (0, 0)
            result.count += 1
            result.total += trace.duration
            completedTraces[traceName] = result
            trace.averageDuration = result.total / Double(result.count)

            handle(signpost: trace)
            activeTraces.removeValue(forKey: traceName)
        }
        os_signpost(.end, log: oslog, name: name)
    }

    /// Logs a point of interest with the "event" type in your code as a time interval or as an event for debugging performance in Instruments.
    ///
    /// - Parameter name: Name of the trace event.
    /// - Parameter date: Date when trace has occured..
    public func event(_ name: StaticString, date: Date = Date()) {
        let oslog = OSLog(subsystem: subsystem, category: self.name)
        let traceName = "\(name)"
        activeTraces.removeValue(forKey: traceName)
        handle(signpost: Signpost(
            category: self.name,
            started: date,
            ended: date,
            name: traceName
        ))
        os_signpost(.event, log: oslog, name: name)
    }

    /// Reset all trace averages.
    public func reset() {
        completedTraces.removeAll()
    }
}

// MARK: Static Helper Methods
extension Trace {

    /// Logs a point of interest with the "begin" type  in your code as a time interval or as an event for debugging performance in Instruments.
    ///
    /// - Parameter name: Name of the trace event.
    public static func begin(_ name: StaticString) {
        instance.begin(name)
    }

    /// Logs a point of interest with the "end" type in your code as a time interval or as an event for debugging performance in Instruments.
    ///
    /// - Parameter name: Name of the trace event.
    public static func end(_ name: StaticString) {
        instance.end(name)
    }

    /// Logs a point of interest with the "event" type in your code as a time interval or as an event for debugging performance in Instruments.
    ///
    /// - Parameter name: Name of the trace event.
    public static func event(_ name: StaticString) {
        instance.event(name)
    }

    /// Reset all trace averages.
    public static func reset() {
        instance.reset()
    }
}

// MARK: Signpost Extensions
extension Trace.Signpost {
    /// User friendly description of event.
    public var description: String {
        let categoryString = category.count > 0 ? "[\(category)] " : ""

        if let avg = averageDuration {
            return "\(categoryString)\(name): \(durationString(duration))\nAverage: \(durationString(avg))"
        } else {
            return "\(categoryString)\(name): \(durationString(duration))"
        }
    }

    /// How long the trace took
    public var duration: TimeInterval {
        ended.timeIntervalSince(started)
    }

    /// User friendly string of the Trace's duration.
    func durationString(_ duration: Double) -> String {
        if duration < 1 {
            return String(format: "%.0f ms", duration * 1000)
        } else {
            return String(format: "%.2f s", duration)
        }
    }
}
