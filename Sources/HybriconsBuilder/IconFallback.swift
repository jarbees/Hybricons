import Foundation
import CoreUIBridge
import CoreGraphics
import ImageIO


func generateFallback(composerFile: URL, iconset: URL, legacyXcode: URL) throws {
    
    let tempDir = FileManager.default.temporaryDirectory.appending(path: "iconfallback-\(UUID())", directoryHint: .isDirectory)
    try createDir(at: tempDir)
    
    defer {
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    let carURL = try compileIcon(iconURL: composerFile, developerDir: legacyXcode, tempDir: tempDir)
    
    let catalog: CUICatalogFacade
    
    do {
        catalog = try CUICatalogFacade(url: carURL)
    } catch {
        throw BuildError.fallbackGenerationFailed(
            "Opening Assets.car failed: \(error.localizedDescription)"
        )
    }
    
    let iconName = composerFile.deletingPathExtension().lastPathComponent
    let stagingURL = tempDir.appending(path: "AppIcon.appiconset")
    
    try createDir(at: stagingURL)
    
    try extractFallbacks(catalog: catalog, name: iconName, outputURL: stagingURL)
    
    try writeContentsJson(appIconSetURL: stagingURL)
    
    do {
        try FileManager.default.moveItem(at: stagingURL, to: iconset)
    } catch {
        throw BuildError.fallbackGenerationFailed("Couldn't move staging output into final directory:\n\(error.localizedDescription)")
    }
}



private func compileIcon(iconURL: URL, developerDir: URL, tempDir: URL) throws -> URL {
    let actool = developerDir.appending(path: "usr/bin/actool")
    let partialInfoPlist = tempDir.appending(path: "partial.plist")
    let iconName = iconURL.deletingPathExtension().lastPathComponent
    
    let arguments = [
        iconURL.path,
        "--compile", tempDir.path,
        "--platform", "iphoneos",
        "--minimum-deployment-target", "15.0",
        "--app-icon", iconName,
        "--output-partial-info-plist", partialInfoPlist.path,
        "--enable-icon-stack-fallback-generation", "true"
    ]
    
    _ = try runProcess(actool, arguments: arguments)
    
    let carURL = tempDir.appending(path: "Assets.car")
    guard FileManager.default.fileExists(atPath: carURL.path) else {
        throw BuildError.fallbackGenerationFailed("actool did not produce Assets.car in \(tempDir)")
    }
    
    return carURL
}

private func extractFallbacks(catalog: CUICatalogFacade, name: String, outputURL: URL) throws {
    let variants: [(appearance: String, filename: String)] = [
        ("UIAppearanceAny", "Default.png"),
        ("UIAppearanceDark", "Dark.png"),
        ("ISAppearanceTintable", "Tinted.png")
    ]
    
    for variant in variants {
        guard let namedImage = catalog.iconImage(
            withName: name,
            scaleFactor: 1.0,
            deviceIdiom: 1,
            deviceSubtype: 0,
            displayGamut: 0,
            layoutDirection: 0,
            sizeClassHorizontal: 0,
            sizeClassVertical: 0,
            desiredSize: CGSize(width: 1024, height: 1024),
            appearanceName: variant.appearance
        ) else {
            throw BuildError.fallbackGenerationFailed("Failed to extract \(variant.appearance) fallback\n")
        }
        
        guard let image = namedImage.image() else {
            throw BuildError.fallbackGenerationFailed("Image could not be converted.")
        }
        
        guard image.width == 1024 && image.height == 1024 else {
            throw BuildError.fallbackGenerationFailed(
                "\(variant.appearance) fallback has unexpected size: \(image.width)x\(image.height)"
            )
        }
        
        let imageURL = outputURL.appending(path: variant.filename)
        
        
        try writePNG(image: image, url: imageURL)
    }
}

private func writePNG(image: CGImage, url: URL) throws {
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
        throw BuildError.fallbackGenerationFailed("Failed to write image to disk")
    }
    
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw BuildError.fallbackGenerationFailed("Failed to write image to disk")
    }
}

private func writeContentsJson(appIconSetURL: URL) throws {
    struct Contents: Encodable {
        struct Image: Encodable {
            let filename, idiom, platform, size: String
            var appearances: [Appearance]? = nil

            struct Appearance: Encodable {
                let appearance, value: String
            }
        }

        struct Info: Encodable {
            let author: String
            let version: Int
        }

        let images: [Image]
        let info: Info
    }

    let contents = Contents(
        images: [
            .init(filename: "Default.png", idiom: "universal", platform: "ios", size: "1024x1024"),
            .init(filename: "Dark.png", idiom: "universal", platform: "ios", size: "1024x1024",
                  appearances: [.init(appearance: "luminosity", value: "dark")]),
            .init(filename: "Tinted.png", idiom: "universal", platform: "ios", size: "1024x1024",
                  appearances: [.init(appearance: "luminosity", value: "tinted")])
        ],
        info: .init(author: "xcode", version: 1)
    )

    do {
        let data = try JSONEncoder().encode(contents)
        try data.write(to: appIconSetURL.appending(path: "Contents.json"))
    } catch {
        throw BuildError.fallbackGenerationFailed("Failed to generate .iconset json\n\(error.localizedDescription)")
    }
}


private func createDir(at url: URL) throws {
    do {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    } catch {
        throw BuildError.fallbackGenerationFailed("Couldn't create a directory at \(url.path)\n\(error.localizedDescription)")
    }
}

