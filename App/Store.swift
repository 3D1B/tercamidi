import Foundation
import HarmonyCore
import SwiftUI

enum PresetError: LocalizedError {
    case invalid
    var errorDescription: String? { NSLocalizedString("Invalid preset file or empty name.", comment: "Preset validation") }
}

final class Store: ObservableObject {
    @Published var presets: [HarmonyPreset] = HarmonyPreset.defaults
    @Published var selected = 0
    @Published var tonic = 0
    @Published var octave = 0
    @Published var velocity = 85
    @Published var inputChannel = 1
    @Published var outputChannel = 2
    @Published var enabled = true
    @Published var page = 0
    @Published var error: String?
    private let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("harmonies.json")
    init() {
        if FileManager.default.fileExists(atPath: url.path) {
            do { try load(Data(contentsOf: url)) } catch { self.error = error.localizedDescription }
        }
        let defaults = UserDefaults.standard
        if let values = defaults.dictionary(forKey: "midiSettings") as? [String: Int] {
            tonic = min(11, max(0, values["tonic"] ?? 0))
            octave = min(3, max(-3, values["octave"] ?? 0))
            velocity = min(150, max(10, values["velocity"] ?? 85))
            inputChannel = min(16, max(0, values["input"] ?? 1))
            outputChannel = min(16, max(1, values["output"] ?? 2))
            selected = min(presets.count - 1, max(0, values["selected"] ?? 0)); page = selected / 6
        }
    }
    func save() {
        do { try data().write(to: url, options: .atomic) } catch { self.error = error.localizedDescription }
        UserDefaults.standard.set(["tonic":tonic, "octave":octave, "velocity":velocity, "input":inputChannel, "output":outputChannel, "selected":selected], forKey: "midiSettings")
    }
    func data() throws -> Data {
        let file = PresetFile(presets: presets)
        guard file.validate() else { throw PresetError.invalid }
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted,.sortedKeys]
        return try encoder.encode(file)
    }
    func load(_ data: Data) throws {
        guard data.count <= 4_000_000 else { throw CocoaError(.fileReadTooLarge) }
        let file = try JSONDecoder().decode(PresetFile.self, from: data)
        guard file.validate() else { throw PresetError.invalid }
        presets = file.presets; selected = 0; page = 0
    }
    func add() {
        guard presets.count < 256 else { return }
        presets.append(.init(name: String(localized: "New harmony"), mapping: Array(repeating: [4], count: 128)))
        selected = presets.count - 1; page = selected / 6; save()
    }
    func exportURL() throws -> URL {
        let export = FileManager.default.temporaryDirectory.appendingPathComponent("OpenHarmony.json")
        try data().write(to: export, options: .atomic); return export
    }
}
