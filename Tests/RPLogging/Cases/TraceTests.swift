import XCTest

@testable import RPLogging

class TraceTests: XCTestCase {

    final class Traces {
        static let userInterface = Trace("UI")
        static let app = Trace("App")
    }

    /// Test Traces.
    func testTrace() {

        let globalDestination = TestTraceHandler()

        var date = Date(timeIntervalSince1970: 0)

        Trace.globalHandlers = [globalDestination]

        // log a trace
        Traces.app.begin("App Startup", date: date)
        date.addTimeInterval(4)
        Traces.app.end("App Startup", date: date)

        // log a trace event
        Traces.userInterface.event("event", date: date)

        // log a second trace
        Traces.app.begin("App Startup", date: date)
        date.addTimeInterval(3)
        Traces.app.end("App Startup", date: date)

        // log a third trace
        Traces.app.begin("App Startup", date: date)
        date.addTimeInterval(2)
        Traces.app.end("App Startup", date: date)

        XCTAssertEqual(globalDestination.count, 4)
        XCTAssertEqual(globalDestination[0].averageDuration, 4)
        XCTAssertEqual(globalDestination[0].duration, 4)
        XCTAssertEqual(globalDestination[2].averageDuration, 3.5)
        XCTAssertEqual(globalDestination[2].duration, 3)
        XCTAssertEqual(globalDestination[3].averageDuration, 3)
        XCTAssertEqual(globalDestination[3].duration, 2)
    }
}

class TestTraceHandler: TraceHandler {

    private(set) var signposts: [Trace.Signpost] = []

    var count: Int {
        signposts.count
    }

    subscript(index: Int) -> Trace.Signpost {
        signposts[index]
    }

    func handle(trace: Trace, signpost: Trace.Signpost) {
        signposts.append(signpost)
    }
}
