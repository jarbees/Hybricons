import Foundation

func mergeInfoPlist(_ source: URL, into destination: URL?, at output: URL) throws {
    var result = try destination.map(read) ?? [:]
    
    result.merge(try read(source), uniquingKeysWith: { _, new in new })

    let data = try PropertyListSerialization.data(fromPropertyList: result, format: .xml, options: 0)
    
    try data.write(to: output,  options: .atomic)
}

private func read(_ url: URL) throws -> [String: Any] {
    let data = try Data(contentsOf: url)
    let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)

    guard let dictionary = plist as? [String: Any] else {
        throw BuildError.invalidInfoPlist(url)
    }

    return dictionary
}
