import Foundation
import CoreUIBridge

do {
    let build = try Build()
    let legacyXcode = try locateXcode(version: "26.0.1", build: "17A400")

    try? FileManager.default.removeItem(at: build.outputDirectory)
    try FileManager.default.createDirectory(at: build.outputDirectory, withIntermediateDirectories: true)
    
    try FileManager.default.createDirectory(at: build.generatedCatalog, withIntermediateDirectories: true)
    
    try loadCoreUI(from: legacyXcode)
    
    for icon in build.icons where icon.customFallbackIconSet == nil {
        let iconset = build.generatedCatalog
            .appending(path: icon.name)
            .appendingPathExtension("appiconset")

        try generateFallback(composerFile: icon.composerFile, iconset: iconset, legacyXcode: legacyXcode)
    }

    let assetCompiler = AssetCompiler(legacyXcode: legacyXcode, build: build)

    let assetsCar = try assetCompiler.generateHybridAssetsCar()
    let (partialPlist, bundleIcons) = try assetCompiler.generatePlistAndBundleIcons()
    
    let infoPlist = build.outputDirectory.appending(path: "Info.plist")

    try mergeInfoPlist(partialPlist, into: build.sourcePlist, at: infoPlist)
    try installResources(assetsCar: assetsCar, bundleIcons: bundleIcons, build: build)
    
} catch {
    fputs("error: Hybricons: \(error.localizedDescription)\n", stderr)
    exit(EXIT_FAILURE)
}


private func loadCoreUI(from legacyXcode: URL) throws {
    let path = legacyXcode.appending(path: "Platforms/MacOSX.platform/System/AssetRuntime/System/Library/PrivateFrameworks/CoreUI.framework/Versions/A/CoreUI")
    
    // Keep CoreUI loaded for the lifetime of the process.
    guard dlopen(path.path, RTLD_NOW | RTLD_GLOBAL) != nil else {
        throw BuildError.fallbackGenerationFailed("Failed to load CoreUI:\n\(String(cString: dlerror()))\n")
    }
}
