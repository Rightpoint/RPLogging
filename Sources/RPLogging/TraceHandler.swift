import Foundation
import os

public protocol TraceHandler {
    func handle(trace: Trace, signpost: Trace.Signpost)
}
open class ConsoleLogTraceHandler: TraceHandler {

    // MARK: TraceHandler

    public func handle(trace: Trace, signpost: Trace.Signpost) {
        print(signpost.description)
    }
}
