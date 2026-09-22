import PackagePlugin
import XcodeProjectPlugin

@main
struct HybriconsPlugin: BuildToolPlugin, XcodeBuildToolPlugin {
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        // Resolve the builder as a plugin tool so Xcode builds it for the macOS host.
        // The actual invocation happens in the app target's Run Script phase.
        _ = try context.tool(named: "HybriconsBuilder")
        return []
    }

    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        []
    }
}
