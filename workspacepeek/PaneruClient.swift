import Foundation

// paneru backend for WorkspacePeek (added by ~/.dotfiles/workspacepeek/build.sh)
// workspaces come from "paneru query state --json" (same thing sketchybar uses),
// switching is "paneru send-cmd window virtualnum N"
final class PaneruClient {

    static let candidates = [
        "/opt/homebrew/bin/paneru",
        NSHomeDirectory() + "/.cargo/bin/paneru",
        "/usr/local/bin/paneru",
    ]

    static var binaryPath: String? {
        candidates.first { FileManager.default.fileExists(atPath: $0) }
    }

    // backend "paneru" in config.json, or "auto" while paneru is running
    static var isActive: Bool {
        let backend = WorkspacePeekConfig.current.windowManager.backend.lowercased()
        if backend == "paneru" { return true }
        if backend != "auto" { return false }
        guard binaryPath != nil else { return false }
        return !runTool("/usr/bin/pgrep", ["-x", "paneru"])
            .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private static func state() -> [String: Any] {
        guard let path = binaryPath else { return [:] }
        let out = runTool(path, ["query", "state", "--json"])
        guard let data = out.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return [:] }
        return obj
    }

    // ids come back as numbers, compare them as text
    private static func text(_ v: Any?) -> String {
        guard let v = v, !(v is NSNull) else { return "" }
        return "\(v)"
    }

    static func listWorkspaces() -> [Workspace] {
        let st = state()
        let active = st["active"] as? [String: Any] ?? [:]
        let ekran = text(active["native_workspace_id"])
        let wiersze = st["virtual_workspaces"] as? [[String: Any]] ?? []
        let pokazPuste = WorkspacePeekConfig.current.windowManager.includeEmptyWorkspaces

        var lista: [(Int, Workspace)] = []
        for ws in wiersze {
            // only the rows of the current macos space
            if text(ws["native_workspace_id"]) != ekran { continue }
            guard let nr = Int(text(ws["number"])) else { continue }
            let aktywny = (ws["active"] as? Bool) ?? false
            var apki: [String] = []
            for okno in ws["windows"] as? [[String: Any]] ?? [] {
                if (okno["floating"] as? Bool) ?? false { continue }
                if let nazwa = okno["app_name"] as? String { apki.append(nazwa) }
            }
            if apki.isEmpty && !aktywny && !pokazPuste { continue }
            lista.append((nr, Workspace(id: String(nr), isFocused: aktywny, appNames: apki)))
        }
        lista.sort { $0.0 < $1.0 }
        return lista.map { $0.1 }
    }

    static func focusedWorkspace() -> String {
        let active = state()["active"] as? [String: Any] ?? [:]
        return text(active["virtual_workspace_number"])
    }

    static func switchTo(_ workspace: String) {
        guard let path = binaryPath else { return }
        _ = runTool(path, ["send-cmd", "window", "virtualnum", workspace])
    }

    @discardableResult
    private static func runTool(_ path: String, _ args: [String]) -> String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: path)
        task.arguments = args
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        do { try task.run() } catch { return "" }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        return String(data: data, encoding: .utf8) ?? ""
    }
}
