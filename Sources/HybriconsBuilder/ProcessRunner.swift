import Foundation

struct ProcessResult {
    let stdout: String
    let stderr: String
}

func runProcess(_ executable: URL, arguments: [String], environment: [String: String]? = nil) throws -> ProcessResult {
    let process = Process()
    process.executableURL = executable
    process.arguments = arguments
    process.environment = environment
    
    let temporaryDirectory = FileManager.default.temporaryDirectory
    let identifier = UUID().uuidString
    
    let stdoutURL = temporaryDirectory.appending(path: "hybricons-\(identifier).stdout")
    let stderrURL = temporaryDirectory.appending(path: "hybricons-\(identifier).stderr")
    
    FileManager.default.createFile(atPath: stdoutURL.path, contents: nil)
    FileManager.default.createFile(atPath: stderrURL.path, contents: nil)
    
    defer {
        try? FileManager.default.removeItem(at: stdoutURL)
        try? FileManager.default.removeItem(at: stderrURL)
    }
    
    let stdoutHandle = try FileHandle(forWritingTo: stdoutURL)
    let stderrHandle = try FileHandle(forWritingTo: stderrURL)
    
    process.standardOutput = stdoutHandle
    process.standardError = stderrHandle
    
    try process.run()
    process.waitUntilExit()
    
    try stdoutHandle.close()
    try stderrHandle.close()
    
    let result = ProcessResult(
        stdout: String(decoding: try Data(contentsOf: stdoutURL), as: UTF8.self),
        stderr: String(decoding: try Data(contentsOf: stderrURL), as: UTF8.self)
    )
    
    guard process.terminationStatus == 0 else {
        throw BuildError.processFailed(
            executable.lastPathComponent,
            process.terminationStatus,
            result.stdout,
            result.stderr
        )
    }
    
    return result
}
