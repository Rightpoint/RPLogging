import XCTest
import RPLogging

class LogTests: XCTestCase {

    final class Loggers {
        static let userInterface = Log("UI", logLevel: .verbose)
        static let app = Log("App")
    }

    class NetworkLog: Log {
        static var networkLog = Log("Network")

        override class var instance: Log {
            return networkLog
        }
    }

    /// Test that the `LogDestination` handles LogEvents properly.
    func testLogDestination() {

        let globalLog = TestLogHandler()
        let networkLog = TestLogHandler()

        Log.addGlobalHandler(globalLog)
        NetworkLog.addHandler(networkLog)

        let localInstance = Log("Local Instance", logLevel: .verbose, useEmoji: true)

        Log.logLevel = .debug
        Log.useEmoji = false

        Log.verbose("Ignore me")
        Log.error("Don't ignore me!")

        NetworkLog.logLevel = .info
        NetworkLog.verbose("network verbose")
        NetworkLog.debug("network debug")
        NetworkLog.info("network info")
        NetworkLog.warn("Network warning")
        NetworkLog.error("network ERROR!")

        localInstance.debug("Local debug")
        localInstance.error("Local error")
        localInstance.warn("Local Instance Warning")
        Loggers.userInterface.info("Button Pressed")
        Loggers.userInterface.info("Button Released")
        Loggers.app.warn("Out of Memory")

        XCTAssertEqual(globalLog.count, 9)
        XCTAssertEqual(networkLog.count, 3)

        // Log messages include the date, which is not conducive to testing,
        // so we just check the end of the logged string.
        XCTAssertEqual(globalLog[0].level, .error)
        XCTAssertTrue(globalLog[0].description.hasSuffix("Don't ignore me!"))
        XCTAssertTrue(globalLog[1].description.hasSuffix("network info"))

        XCTAssertFalse(globalLog[0].description.hasPrefix("⁉️"))
        XCTAssertTrue(globalLog[5].description.hasPrefix("⁉️"))
    }
}

class TestLogHandler: LogHandler {

    private(set) var messages: [Log.Message] = []

    var count: Int {
        messages.count
    }

    subscript(index: Int) -> Log.Message {
        messages[index]
    }

    func handle(message: Log.Message) {
        messages.append(message)
    }
}
