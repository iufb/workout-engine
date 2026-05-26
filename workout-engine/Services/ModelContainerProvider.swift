import Foundation
import SwiftData

/// Creates the app's SwiftData container, recovering from schema mismatches on device.
enum ModelContainerProvider {
    static let schema = Schema([StoredPreset.self])

    static func make() -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            logContainerError(error, context: "initial open")

            // Typical cause: schema changed (e.g. added `phasesJSON`) while an old
            // SQLite file still exists — lightweight migration did not run.
            destroyStoreFiles(at: configuration.url)

            do {
                return try ModelContainer(for: schema, configurations: [configuration])
            } catch {
                logContainerError(error, context: "after store reset")
                fatalError(
                    """
                    Could not create ModelContainer after reset.
                    \(formattedError(error))
                    Delete the app from the simulator/device and install again if this persists.
                    """
                )
            }
        }
    }

    private static func destroyStoreFiles(at storeURL: URL) {
        let candidates = [
            storeURL,
            URL(fileURLWithPath: storeURL.path + "-shm"),
            URL(fileURLWithPath: storeURL.path + "-wal"),
        ]
        for url in candidates where FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private static func logContainerError(_ error: Error, context: String) {
        let ns = error as NSError
        // Core Data / SwiftData often expose `nil` localizedDescription; details live in userInfo.
        print("[ModelContainer] \(context) failed:")
        print("  domain: \(ns.domain) code: \(ns.code)")
        print("  description: \(ns.localizedDescription)")
        print("  failureReason: \(ns.localizedFailureReason ?? "nil")")
        print("  recoverySuggestion: \(ns.localizedRecoverySuggestion ?? "nil")")
        if let underlying = ns.userInfo[NSUnderlyingErrorKey] as? NSError {
            print("  underlying: \(underlying.domain) \(underlying.code) — \(underlying.localizedDescription)")
        }
        print("  userInfo: \(ns.userInfo)")
    }

    private static func formattedError(_ error: Error) -> String {
        let ns = error as NSError
        var lines: [String] = ["\(ns.domain) (\(ns.code))"]
        if !ns.localizedDescription.isEmpty, ns.localizedDescription != "(null)" {
            lines.append(ns.localizedDescription)
        }
        if let reason = ns.localizedFailureReason, !reason.isEmpty {
            lines.append(reason)
        }
        if let underlying = ns.userInfo[NSUnderlyingErrorKey] as? Error {
            lines.append("Underlying: \(underlying)")
        }
        return lines.joined(separator: "\n")
    }
}
