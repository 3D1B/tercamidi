import Foundation

public struct PresetFile: Codable {
    public var version: Int
    public var presets: [HarmonyPreset]
    public init(version: Int = 1, presets: [HarmonyPreset]) { self.version = version; self.presets = presets }
    public func validate() -> Bool {
        version == 1 && !presets.isEmpty && presets.count <= 256 && Set(presets.map(\.id)).count == presets.count && presets.allSatisfy { $0.validate() }
    }
}

public struct HarmonyPreset: Codable, Identifiable, Equatable {
    public var id: UUID
    public var name: String
    public var color: Int
    // Rows are relative MIDI notes, rotated by the selected tonic. Values are semitone offsets.
    public var mapping: [[Int]]
    public init(id: UUID = UUID(), name: String, color: Int = 0, mapping: [[Int]]) {
        self.id = id; self.name = name; self.color = color; self.mapping = mapping
    }
    public static func diatonic(_ name: String, scale: [Int], steps: Int, color: Int) -> Self {
        let map = (0..<128).map { note -> [Int] in
            guard let degree = scale.firstIndex(of: note % 12) else { return [] }
            let target = degree + steps
            let octave = Int(floor(Double(target) / Double(scale.count)))
            let index = ((target % scale.count) + scale.count) % scale.count
            return [scale[index] + octave * 12 - scale[degree]]
        }
        return .init(name: name, color: color, mapping: map)
    }
    public static var defaults: [Self] {
        let major = [0,2,4,5,7,9,11], minor = [0,2,3,5,7,8,10]
        return [diatonic("Major thirds", scale: major, steps: 2, color: 0),
                diatonic("Minor thirds", scale: minor, steps: 2, color: 1),
                diatonic("Major sixths", scale: major, steps: 5, color: 2),
                diatonic("Harmonic minor", scale: [0,2,3,5,7,8,11], steps: 2, color: 3),
                .init(name: "Octave", color: 4, mapping: Array(repeating: [12], count: 128)),
                .init(name: "Power chord", color: 5, mapping: Array(repeating: [7,12], count: 128))]
    }
    public func validate() -> Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && name.count <= 80 &&
        (0...5).contains(color) && mapping.count == 128 &&
        mapping.allSatisfy { $0.count <= 8 && Set($0).count == $0.count && $0.allSatisfy { (-48...48).contains($0) } }
    }
}

public struct MIDIMessage: Equatable {
    public let status: UInt8
    public let data1: UInt8
    public let data2: UInt8
    public init(_ status: UInt8, _ data1: UInt8, _ data2: UInt8) { self.status = status; self.data1 = data1; self.data2 = data2 }
    public var bytes: [UInt8] { [status, data1, data2] }
}

/// Serial-queue confined. Every note-off uses the notes and output channel captured on note-on.
public final class HarmonyEngine {
    public var preset = HarmonyPreset.defaults[0]
    public var tonic = 0
    public var octave = 0
    public var velocityPercent = 85
    public var inputChannel = 0 // 0 = all, 1...16 = one channel
    public var outputChannel = 2
    public var enabled = true
    private struct Voice { var channel: Int; var notes: [Int] }
    private var voices: [Int: [Voice]] = [:]
    private var references: [Int: Int] = [:]
    private var sustainChannels: Set<Int> = []
    public init() {}
    public func process(_ m: MIDIMessage) -> [MIDIMessage] {
        let channel = Int(m.status & 15) + 1, kind = m.status & 0xF0
        let key = (channel - 1) * 128 + Int(m.data1)
        if kind == 0x80 || (kind == 0x90 && m.data2 == 0) {
            guard var stack = voices[key], !stack.isEmpty else { return [] }
            let voice = stack.removeFirst()
            if stack.isEmpty { voices.removeValue(forKey: key) } else { voices[key] = stack }
            return release(voice)
        }
        guard inputChannel == 0 || channel == inputChannel else { return [] }
        // Generated harmony echoed by MIDI Thru must never generate another harmony.
        guard channel != outputChannel else { return [] }
        if kind == 0xB0 && [120,123].contains(m.data1) { return panic() }
        // Sustain is forwarded; pitch bend, program changes and manufacturer SysEx are not interpreted.
        if kind == 0xB0 && m.data1 == 64 {
            if m.data2 >= 64 { sustainChannels.insert(outputChannel) } else { sustainChannels.remove(outputChannel) }
            return [.init(0xB0 | UInt8(outputChannel - 1), 64, m.data2)]
        }
        guard kind == 0x90, enabled, preset.validate() else { return [] }
        let relative = Int(m.data1) - tonic
        let rotated = relative < 0 ? relative + 12 : relative
        let notes = Set(preset.mapping[rotated].map { Int(m.data1) + $0 + octave * 12 }).filter { (0...127).contains($0) }.sorted()
        let voice = Voice(channel: outputChannel, notes: notes)
        voices[key, default: []].append(voice)
        let velocity = UInt8(max(1, min(127, Int(m.data2) * velocityPercent / 100)))
        var result: [MIDIMessage] = []
        for note in notes {
            let outputKey = (outputChannel - 1) * 128 + note
            if references[outputKey, default: 0] == 0 { result.append(.init(0x90 | UInt8(outputChannel - 1), UInt8(note), velocity)) }
            references[outputKey, default: 0] += 1
        }
        return result
    }
    private func release(_ voice: Voice) -> [MIDIMessage] {
        var result: [MIDIMessage] = []
        for note in voice.notes {
            let key = (voice.channel - 1) * 128 + note
            let remaining = max(0, references[key, default: 1] - 1)
            if remaining == 0 { references.removeValue(forKey: key); result.append(.init(0x80 | UInt8(voice.channel - 1), UInt8(note), 0)) }
            else { references[key] = remaining }
        }
        return result
    }
    public func panic() -> [MIDIMessage] {
        var result = references.keys.sorted().map { MIDIMessage(0x80 | UInt8($0 / 128), UInt8($0 % 128), 0) }
        let channels = Set(references.keys.map { $0 / 128 + 1 }).union(sustainChannels).union([outputChannel])
        for channel in channels.sorted() { result += [.init(0xB0 | UInt8(channel - 1), 64, 0), .init(0xB0 | UInt8(channel - 1), 123, 0)] }
        sustainChannels.removeAll()
        references.removeAll(); voices.removeAll()
        return result
    }
}

/// MIDI 1.0 stream parser: supports running status, interleaved realtime and split packets.
public struct MIDIParser {
    private var status: UInt8 = 0
    private var data: [UInt8] = []
    private var sysex = false
    public init() {}
    public mutating func feed(_ bytes: [UInt8]) -> [MIDIMessage] {
        var result: [MIDIMessage] = []
        for byte in bytes {
            if byte >= 0xF8 { continue }
            if byte >= 0x80 {
                data.removeAll()
                if byte == 0xF0 { sysex = true; status = 0; continue }
                if byte == 0xF7 { sysex = false; status = 0; continue }
                sysex = false; status = byte < 0xF0 ? byte : 0
                continue
            }
            guard !sysex, status != 0 else { continue }
            data.append(byte)
            let length = [0xC0,0xD0].contains(status & 0xF0) ? 1 : 2
            if data.count == length {
                result.append(.init(status, data[0], length == 2 ? data[1] : 0)); data.removeAll()
            }
        }
        return result
    }
}
