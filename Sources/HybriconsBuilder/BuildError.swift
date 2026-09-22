import Foundation

enum BuildError: LocalizedError {
    case missingEnvironmentVariable(String)
    case fallbackGenerationFailed(String)
    case primaryIconNotFound(String)
    case processFailed(String, Int32, String, String)
    case missingCompiledAsset(URL, output: String)
    case xcodeNotFound(version: String, build: String)
    case inputNotFound(URL)
    case unsupportedInput(URL)
    case unsupportedTargetDeviceFamily(String)
    case duplicateInput(URL)
    case duplicateIcons([String : [URL]])
    case multipleInfoPlists
    case invalidInfoPlist(URL)

    var errorDescription: String? {
        switch self {
        case .missingEnvironmentVariable(let name):
            return "Missing Xcode build setting: \(name)"

        case .fallbackGenerationFailed(let error):
            return "Failed to generate fallback:\n \(error)"
        
        case .primaryIconNotFound(let name):
            return "Primary app icon '\(name)' was not found"
            
        case .processFailed(let process, let status, let stdout, let stderr):
            return """
            \(process) failed with exit code \(status)
            \(!stdout.isEmpty ? "stdout:\n\(stdout)" : "")
            \(!stderr.isEmpty ? "stderr:\n\(stderr)" : "")
            """

        case .missingCompiledAsset(let url, let output):
            return """
            actool did not generate artifact at \(url.path)
            
            \(output)
            """
            
        case .xcodeNotFound(let version, let build):
            return "Xcode \(version) (\(build)) could not be found"
        
        case .inputNotFound(let url):
            return "Hybricons input does not exist: \(url.path)"

        case .unsupportedInput(let url):
            return """
            Unsupported Hybricons input: \(url.path)
            Run Script inputs must be .icon files, directories containing .icon files, .xcassets directories, or at most one Info.plist.
            """
            
        case .unsupportedTargetDeviceFamily(let family):
            return """
            Unsupported target device family '\(family)'.
            Hybricons currently supports iPhone and iPad targets only.
            """
        
        case .duplicateInput(let url):
            return "Hybricons input is listed more than once: \(url.path)"
            
        case .duplicateIcons(let duplicates):
            let descriptions = duplicates
                .sorted { $0.key < $1.key }
                .map { name, files in
                    let paths = files
                        .sorted { $0.path < $1.path }
                        .map { "  \($0.path)" }
                        .joined(separator: "\n")

                    return """
                    '\(name)':
                    \(paths)
                    """
                }
                .joined(separator: "\n")

            return """
            Multiple app icon resources have duplicate names:
            \(descriptions)
            """
            
        case .multipleInfoPlists:
            return "Hybricons accepts at most one Info.plist input"

        case .invalidInfoPlist(let url):
            return "Invalid Info.plist: \(url.path)"
        }
    }
}
