import Foundation

func locateXcode(version: String, build: String) throws -> URL {
    var candidates: [URL] = []
    
    // Prefer the currently selected Xcode if it happens to match.
    if let selected = selectedDeveloperDirectory() {
        candidates.append(selected)
    }
    
    // Then inspect installed applications.
    let applications = URL(
        fileURLWithPath: "/Applications",
        isDirectory: true
    )
    
    if let contents = try? FileManager.default.contentsOfDirectory(
        at: applications,
        includingPropertiesForKeys: nil,
        options: [.skipsHiddenFiles]
    ) {
        candidates += contents
            .filter { $0.pathExtension == "app" }
            .map { $0.appending(path: "Contents/Developer", directoryHint: .isDirectory) }
    }
    
    var seen = Set<URL>()
    
    for developerDirectory in candidates {
        let path = developerDirectory.standardizedFileURL
        
        guard seen.insert(path).inserted else {
            continue
        }
        
        guard matches(developerDirectory, version: version, build: build) else {
            continue
        }
        
        return developerDirectory
    }
    
    throw BuildError.xcodeNotFound(version: version, build: build)
}

private func matches(_ developerDirectory: URL, version: String, build: String) -> Bool {
    let xcodebuild = developerDirectory.appending(path: "usr/bin/xcodebuild")

    guard let result = try? runProcess(xcodebuild, arguments: ["-version"]) else {
        return false
    }

    let lines = result.stdout
        .split(whereSeparator: \.isNewline)
        .map(String.init)

    guard lines.count >= 2,
          lines[0] == "Xcode \(version)",
          lines[1] == "Build version \(build)"
    else {
        return false
    }

    return true
}

private func selectedDeveloperDirectory() -> URL? {
    guard let result = try? runProcess(URL(fileURLWithPath: "/usr/bin/xcode-select"), arguments: ["-p"]) else {
        return nil
    }

    let path = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !path.isEmpty else {
        return nil
    }

    return URL(fileURLWithPath: path, isDirectory: true)
}
