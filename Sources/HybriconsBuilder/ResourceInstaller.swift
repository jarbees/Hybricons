import Foundation

func installResources(assetsCar: URL, bundleIcons: [URL], build: Build) throws {
    try FileManager.default.createDirectory(at: build.resourcesDirectory, withIntermediateDirectories: true)

    let files = bundleIcons + [assetsCar]
    
    for file in files {
        let destination = build.resourcesDirectory.appending(path: file.lastPathComponent)

        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }

        try FileManager.default.copyItem(at: file, to: destination)
    }

    print("Installed hybrid app icons")
}
