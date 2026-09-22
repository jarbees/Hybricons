import Foundation

struct AssetCompiler {
    let legacyXcode: URL
    let build: Build
    
    func generateHybridAssetsCar() throws -> URL {
        return try compileAssets(
            devDir: legacyXcode,
            outputDir: "Hybrid",
            resultFile: "Assets.car",
            composerFiles: build.icons.map(\.composerFile),
            additionalArguments: ["--enable-icon-stack-fallback-generation=disabled"]
        ).resultFile
    }
    
    func generatePlistAndBundleIcons() throws -> (infoPlist: URL, bundleIcons: [URL]) {
        let composerFiles = build.icons
            .filter { $0.customFallbackIconSet == nil }
            .map(\.composerFile)
        
        let (outputDir, infoPlist) = try compileAssets(
            devDir: build.developerDirectory,
            outputDir: "Other",
            resultFile: "Info.plist",
            composerFiles: composerFiles
        )
        
        let bundleIcons = try FileManager.default
            .contentsOfDirectory(at: outputDir, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "png" }
        
        return (infoPlist, bundleIcons)
    }
    
    private func compileAssets(
        devDir: URL,
        outputDir: String,
        resultFile: String,
        composerFiles: [URL],
        additionalArguments: [String] = []
    ) throws -> (outputDir: URL, resultFile: URL) {
        let output = build.outputDirectory.appending(path: outputDir, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        
        let actool = devDir.appending(path: "usr/bin/actool")
        let infoPlist = output.appending(path: "Info.plist")
        
        
        var inputs: [URL] = []
        
        inputs += [build.generatedCatalog]
        inputs += build.assetCatalogs
        inputs += composerFiles
        
        
        var arguments: [String] = []
        
        arguments += inputs.map(\.path)
        arguments += commonArguments(output: output, infoPlist: infoPlist)
        arguments += additionalArguments
        
        let result = try runProcess(actool, arguments: arguments)

        let file = output.appending(path: resultFile)
        guard FileManager.default.fileExists(atPath: file.path) else {
            throw BuildError.missingCompiledAsset(file, output: result.stderr)
        }
        
        return (output, file)
    }
    
    private func commonArguments(
        output: URL,
        infoPlist: URL
    ) -> [String] {
        var arguments = [
            "--compile", output.path,
            "--app-icon", build.primaryIcon,
            "--enable-on-demand-resources", "NO",
            "--development-region", build.developmentLanguage,
            "--platform", build.platform,
            "--minimum-deployment-target", build.deploymentTarget,
            "--output-partial-info-plist", infoPlist.path
        ]
        
        if build.includeAllAppIconAssets {
            arguments += ["--include-all-app-icons"]
        }

        for device in build.targetDevices {
            arguments += ["--target-device", device]
        }

        if build.compressPNGs {
            arguments.append("--compress-pngs")
        }

        if let accentColor = build.accentColor {
            arguments += ["--accent-color", accentColor]
        }

        if let optimization = build.optimization {
            arguments += ["--optimization", optimization]
        }

        if !build.includeInfoPlistLocalizations {
            arguments += ["--include-partial-info-plist-localizations", "NO"]
        }

        if let mode = build.lightweightAssetRuntimeMode {
            arguments += ["--lightweight-asset-runtime-mode", mode]
        }

        if let image = build.launchImage {
            arguments += ["--launch-image", image]
        }

        if let color = build.widgetBackgroundColor {
            arguments += ["--widget-background-color", color]
        }

        if build.skipAppStoreDeployment {
            arguments.append("--skip-app-store-deployment")
        }

        return arguments
    }
}
