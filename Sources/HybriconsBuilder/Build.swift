import Foundation

struct AppIcon {
    let name: String
    let composerFile: URL
    let customFallbackIconSet: URL?
}

struct Build {
    
    let developerDirectory: URL
    let outputDirectory: URL
    let resourcesDirectory: URL
    
    let generatedCatalog: URL
    let assetCatalogs: [URL]
    let icons: [AppIcon]
    let sourcePlist: URL?
    
    // Asset Catalog config
    let platform: String
    let deploymentTarget: String
    let primaryIcon: String
    let includeAllAppIconAssets: Bool
    let accentColor: String?
    let developmentLanguage: String
    let targetDevices: [String]
    let compressPNGs: Bool
    let optimization: String?
    let includeInfoPlistLocalizations: Bool
    let lightweightAssetRuntimeMode: String?
    let launchImage: String?
    let widgetBackgroundColor: String?
    let skipAppStoreDeployment: Bool
    

    init(environment: [String: String] = ProcessInfo.processInfo.environment) throws {
        let fileManager = FileManager.default

        func require(_ key: String) throws -> String {
            guard let value = environment[key], !value.isEmpty else {
                throw BuildError.missingEnvironmentVariable(key)
            }

            return value
        }
        
        func bool(
            _ key: String,
            default defaultValue: Bool = false
        ) -> Bool {
            switch optional(key) {
            case "YES":
                return true
            case "NO":
                return false
            default:
                return defaultValue
            }
        }
        
        func optional(_ key: String) -> String? {
            environment[key].flatMap { $0.isEmpty ? nil : $0 }
        }

        
        // Build environment

        developerDirectory = URL(fileURLWithPath: try require("DEVELOPER_DIR"), isDirectory: true)
        
        let derivedFileDirectory = URL(fileURLWithPath: try require("DERIVED_FILE_DIR"), isDirectory: true)
        outputDirectory = derivedFileDirectory.appending(path: "Hybricons", directoryHint: .isDirectory)
        
        let targetBuildDirectory = URL(fileURLWithPath: try require("TARGET_BUILD_DIR"), isDirectory: true)
        resourcesDirectory = targetBuildDirectory.appending(path: try require("UNLOCALIZED_RESOURCES_FOLDER_PATH"), directoryHint: .isDirectory)
        
        
        // Asset Catalog config

        platform = try require("PLATFORM_NAME")
        deploymentTarget = try require("IPHONEOS_DEPLOYMENT_TARGET")
        primaryIcon = try require("ASSETCATALOG_COMPILER_APPICON_NAME")
        includeAllAppIconAssets = bool("ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS")
        accentColor = optional("ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME")
        developmentLanguage = try require("DEVELOPMENT_LANGUAGE")

        targetDevices = try require("TARGETED_DEVICE_FAMILY")
            .split(separator: ",")
            .map { family in
                switch family.trimmingCharacters(in: .whitespaces) {
                case "1": return "iphone"
                case "2": return "ipad"
                default: throw BuildError.unsupportedTargetDeviceFamily(String(family))
                }
            }

        compressPNGs = bool("COMPRESS_PNG_FILES")
        optimization = optional("ASSETCATALOG_COMPILER_OPTIMIZATION")
        
        includeInfoPlistLocalizations = bool(
            "ASSETCATALOG_COMPILER_INCLUDE_INFOPLIST_LOCALIZATIONS",
            default: true
        )

        let runtimeMode = optional("ASSETCATALOG_LIGHTWEIGHT_ASSET_RUNTIME_MODE")
        lightweightAssetRuntimeMode = runtimeMode == "default" ? nil : runtimeMode
        
        launchImage = optional("ASSETCATALOG_COMPILER_LAUNCHIMAGE_NAME")
        widgetBackgroundColor = optional("ASSETCATALOG_COMPILER_WIDGET_BACKGROUND_COLOR_NAME")
        skipAppStoreDeployment = bool("ASSETCATALOG_COMPILER_SKIP_APP_STORE_DEPLOYMENT")

        
        // Run Script inputs

        let inputCount = Int(environment["SCRIPT_INPUT_FILE_COUNT"] ?? "0") ?? 0

        let inputs = try (0..<inputCount).map { index in
            let key = "SCRIPT_INPUT_FILE_\(index)"

            guard let path = environment[key], !path.isEmpty else {
                throw BuildError.missingEnvironmentVariable(key)
            }

            return URL(fileURLWithPath: path).standardizedFileURL
        }
        
        var assetCatalogs: [URL] = []
        var iconDirectories: [URL] = []
        var composerIcons: [URL] = []
        var iconsets: [URL] = []
        var infoPlists: [URL] = []
        var seen = Set<URL>()

        for input in inputs {
            guard seen.insert(input).inserted else {
                throw BuildError.duplicateInput(input)
            }

            var isDirectory: ObjCBool = false

            guard fileManager.fileExists(atPath: input.path, isDirectory: &isDirectory) else {
                throw BuildError.inputNotFound(input)
            }

            if isDirectory.boolValue {
                switch input.pathExtension {
                case "xcassets":
                    assetCatalogs.append(input)
                case "icon":
                    composerIcons.append(input)
                case "":
                    iconDirectories.append(input)
                default:
                    throw BuildError.unsupportedInput(input)
                }
            } else if input.pathExtension == "plist" {
                infoPlists.append(input)
            } else {
                throw BuildError.unsupportedInput(input)
            }
        }
        
        guard infoPlists.count <= 1 else {
            throw BuildError.multipleInfoPlists
        }
        
        composerIcons += findFiles(in: iconDirectories, withExtension: "icon")
        iconsets += findFiles(in: assetCatalogs, withExtension: "appiconset")
        
        try requireUniqueNames(composerIcons)
        try requireUniqueNames(iconsets)

        self.assetCatalogs = assetCatalogs
        self.sourcePlist = infoPlists.first
        self.generatedCatalog = outputDirectory.appending(path: "Generated.xcassets", directoryHint: .isDirectory)
        
        self.icons = composerIcons.map { icon in
            let name = icon.deletingPathExtension().lastPathComponent
            
            let fallbackIconset = iconsets.first { iconset in
                iconset.deletingPathExtension().lastPathComponent == name
            }

            return AppIcon(
                name: name,
                composerFile: icon,
                customFallbackIconSet: fallbackIconset
            )
        }
        
        let primaryAsIcon = icons.contains { $0.name == primaryIcon }
        let primaryAsIconset = iconsets.contains { $0.deletingPathExtension().lastPathComponent == primaryIcon }

        guard primaryAsIcon || primaryAsIconset else {
            throw BuildError.primaryIconNotFound(primaryIcon)
        }
    }
}


private func findFiles(in directories: [URL], withExtension pathExtension: String) -> [URL] {
    var result: [URL] = []
    
    for directory in directories {
        if let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) {
            while let file = enumerator.nextObject() as? URL {
                if file.pathExtension == pathExtension {
                    result.append(file)
                    enumerator.skipDescendants()
                }
            }
        }
    }
    
    return result
}


private func requireUniqueNames(_ files: [URL]) throws {
    let duplicates = Dictionary(
        grouping: files,
        by: { $0.deletingPathExtension().lastPathComponent }
    )
    .filter { $0.value.count > 1 }

    guard duplicates.isEmpty else {
        throw BuildError.duplicateIcons(duplicates)
    }
}
