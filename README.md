# Hybricons / What is this
Hybricons is a workaround which allows using an Icon Composer `.icon` on iOS 26+ together with an equally named asset catalog `.appiconset` for earlier versions. Using it, you can have a separate Liquid Glass and non-Liquid Glass design.
This repository also contains a demo project showing the setup in practice.
- **Note**: This is an unsupported workaround relying on behavior of Xcode 26.0.1's `actool`. It may stop working with future iOS/Xcode/App Store validation changes.
- **Important: Hybricons replaces Xcode's normal asset-compilation. All Asset Catalogs and Icon Composer files used by the target must therefore be provided to Hybricons.**

## Requirements
- Xcode 26 or newer for building the application
- Xcode 26.0.1 installed in `/Applications/` (if you really want to change this, take a look at XcodeLocator.swift)
  - Hybricons relies on the hidden actool flag `--enable-icon-stack-fallback-generation=disabled`. This behavior allowed for providing icons in an asset catalog that were used instead of Icon Composer icons for older versions of iOS. Newer versions of actool no longer honor this behavior.

## Tested with
- Xcode 27 RC1: main project build
- iOS 18.6 Simulator: legacy artwork
- iOS 26.0.1 Simulator: Icon Composer artwork
- Xcode Archive / Validate App: Validation succeeded

## Demo
A small demo app is available in Hybricons/Demo. 
To see Hybricons in effect, open the project in any modern Xcode version (tested by me with Xcode 27 RC1) and launch the app in both an iOS 26+ and an older simulator.
Keep in mind that Xcode 26.0.1 must be installed in `/Applications/` for Hybricons to work.

## Icon Configurations
When using Hybricons keep these three different options for providing icons in mind.  
An app icon can be provided as an `.appiconset` in an asset catalog, as an Icon Composer `.icon` or as both with the same name.
- `.appiconset` only
  - Used on all supported iOS versions. 
  - On iOS 26+ the system may apply its own Liquid Glass treatment
- `.icon` only
  - On iOS 26+ Liquid Glass is applied, while older versions get a statically rendered version of the glass icon.
  - Providing a custom fallback is recommended. Being able to do so is the reason for using Hybricons.
- Both (recommended)
  - iOS 26+ will use the modern `.icon` file while older iOS uses the equally named `.appiconset` file
  - e.g. `Assets.xcassets/Split.appiconset` and `Split.icon` would become one icon that dynamically changes for iOS 26.0+ vs. older versions

## Project Setup
1. If not done already, specify a primary app icon in your app target under General -> App Icons and Launch Screen -> App Icon (and enable "Include all app icon assets" if you want alternative app icons)
2. Add the Hybricons Package to your project in Xcode
3. In your app target, add HybriconsPlugin in Build Phases -> Run Build Tool Plug-ins
4. In your app target, add a New Run Script Phase with the following script:
```
"${BUILD_DIR}/${CONFIGURATION}/HybriconsBuilder"
```
5. In that Run Script Phase, add one output file:
```
$(DERIVED_FILE_DIR)/Hybricons/Info.plist
```
6. Add all Asset Catalogs as well as `.icon` files as Input Files to the Run Script Phase. If using an `Info.plist`, add it here too. Instead of providing .icon files individually, one or more directories containing them can also be used. 
```
$(SRCROOT)/AppIcons                        # Directory containing .icon files
$(SRCROOT)/Assets.xcassets                 # Asset catalog
$(SRCROOT)/Resources/MoreAssets.xcassets   # Another asset catalog
$(SRCROOT)/Special.icon                    # Individual Icon Composer file
$(SRCROOT)/Info.plist                      # Info.plist (optional, max. 1)
etc...
```
7. In Build Settings -> Packaging -> Info.plist File, change the path to `$(DERIVED_FILE_DIR)/Hybricons/Info.plist` 
8. Remove all Asset Catalogs, Icon Composer files and `Info.plist` from Copy Bundle Resources Build Phase. Hybricons is now responsible for compiling them.

## How it works
Hybricons works in four steps
- First, all `.icon` files are compared against the provided `.appiconset` files
  - Every `.icon` with no equally named `.appiconset` gets a fallback `.appiconset` generated.
  - Fallback generation works by having actool compile into an `Assets.car` and then extracting and recombining the resulting images into a `.appiconset` 
  - Extraction works by using a private CoreUI API. However, this usage is limited to the build process and is not reflected in the resulting app bundle, so it does not prevent App Store distribution.
- With Xcode 26.0.1 actool, the `Assets.car` is generated, which includes all app icons as well as all other assets.
  - Using this actool version with the hidden flag prevents an `.icon` from overriding an equally named `.appiconset`.
  - Using this flag prevents actool from generating two bundle icons required for App Store submission which also means the `Info.plist` is incomplete.
- Modern actool is given all `.appiconset` files, including generated fallbacks but only those `.icon` files with no equally named `.appiconset` are included.
  - The resulting `Assets.car` is missing the rest of the `.icon` files, so it is discarded
  - The resulting `Info.plist` includes all app icons
  - The two bundle icons are generated from the primary app icon's `.appiconset` 
- The `Assets.car` from the Xcode 26.0.1 pass and the two bundle icons from the modern actool pass are copied into the app bundle. The `Info.plist` is given to Xcode for potential further processing

## Thanks
Special thanks to Michael Tsai's blog, and in particular Phil Sulak, who created a reproducible project for macOS.  
Phil Sulak's Solution for macOS: [Tahoe-Sequoia-Hybrid-Icon](https://github.com/psulak/Tahoe-Sequoia-Hybrid-Icon)  
Michael Tsai's blog article: [separate Icons for macOS Tahoe vs. Earlier](https://mjtsai.com/blog/2025/08/08/separate-icons-for-macos-tahoe-vs-earlier/)
