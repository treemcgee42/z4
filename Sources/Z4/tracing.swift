
import Foundation

struct Tracer {
    let formatter: DateFormatter

    init() {
        self.formatter = DateFormatter()
        self.formatter.dateFormat = "HH:mm:ss.SSS"
    }

    private func trace(_ message: String, level: UInt8) {
        print("\(self.formatter.string(from: Date()))  \(level)    \(message)")
    }

    private func fnTrace(_ message: String, functionName: String, level: UInt8) {
        self.trace("\(functionName) \(message)", level: level)
    }

    func fnTrace0(_ message: String, functionName: String = #function) {
        self.fnTrace(message, functionName: functionName, level: 0)
    }

    func fnTrace1(_ message: String, functionName: String = #function) {
        self.fnTrace(message, functionName: functionName, level: 1)
    }

    func fnTrace2(_ message: String, functionName: String = #function) {
        self.fnTrace(message, functionName: functionName, level: 2)
    }

    func fnAssert(condition: Bool, message: String,
                  functionName: String = #function, fileName: String = #file,
                  line: Int = #line) {
        if !condition {
            fatalError("\(fileName):\(line), in function \(functionName): \(message)")
        }
    }
}

@TaskLocal
var tracer = Tracer()
