import XCTest
@testable import HarmonyCore

final class HarmonyTests: XCTestCase {
    func testEveryPresetKeyAndMIDINoteReleasesExactlyItsOutput() {
        let e = HarmonyEngine()
        for preset in HarmonyPreset.defaults {
            e.preset = preset
            for key in 0..<12 {
                e.tonic = key
                for note in 0..<128 {
                    let on = e.process(.init(0x90, UInt8(note), 100))
                    let off = e.process(.init(0x80, UInt8(note), 0))
                    XCTAssertEqual(on.map(\.data1), off.map(\.data1))
                    XCTAssertTrue(on.allSatisfy { $0.data2 > 0 && $0.status == 0x91 })
                    XCTAssertTrue(off.allSatisfy { $0.data2 == 0 && $0.status == 0x81 })
                }
            }
        }
    }
    func testPresetFileRejectsUnknownVersionsDuplicateIDsAndMalformedRows() throws {
        var file = PresetFile(presets: HarmonyPreset.defaults)
        XCTAssertTrue(file.validate())
        XCTAssertTrue(try JSONDecoder().decode(PresetFile.self, from: JSONEncoder().encode(file)).validate())
        file.version = 2; XCTAssertFalse(file.validate()); file.version = 1
        file.presets.append(file.presets[0]); XCTAssertFalse(file.validate()); file.presets.removeLast()
        file.presets[0].mapping.removeLast(); XCTAssertFalse(file.validate())
        XCTAssertFalse(PresetFile(presets: []).validate())
    }
    func testMajorThirdsFollowKey() {
        let e = HarmonyEngine()
        XCTAssertEqual(e.process(.init(0x90,60,100)), [.init(0x91,64,85)])
        XCTAssertEqual(e.process(.init(0x80,60,0)), [.init(0x81,64,0)])
        e.tonic = 2
        XCTAssertEqual(e.process(.init(0x90,62,100)), [.init(0x91,66,85)])
        XCTAssertTrue(e.process(.init(0x90,63,100)).isEmpty) // chromatic notes are deliberately unmapped
    }
    func testNoteOffRemembersMappingAndChannel() {
        let e = HarmonyEngine()
        _ = e.process(.init(0x90,60,100))
        e.tonic = 5; e.outputChannel = 5; e.enabled = false
        XCTAssertEqual(e.process(.init(0x90,60,0)), [.init(0x81,64,0)])
    }
    func testOverlappingOutputNotesAreReferenceCounted() {
        let e = HarmonyEngine()
        e.preset.mapping[60] = [4]; e.preset.mapping[62] = [2]
        XCTAssertEqual(e.process(.init(0x90,60,100)).count, 1)
        XCTAssertTrue(e.process(.init(0x90,62,100)).isEmpty)
        XCTAssertTrue(e.process(.init(0x80,60,0)).isEmpty)
        XCTAssertEqual(e.process(.init(0x80,62,0)), [.init(0x81,64,0)])
    }
    func testRepeatedNotesAndPanic() {
        let e = HarmonyEngine()
        _ = e.process(.init(0x90,60,100)); _ = e.process(.init(0x90,60,100))
        XCTAssertTrue(e.process(.init(0x80,60,0)).isEmpty)
        let panic = e.panic()
        XCTAssertTrue(panic.contains(.init(0x81,64,0)))
        XCTAssertFalse(panic.contains { $0.status & 15 == 0 }) // never kill keyboard melody on channel 1
        XCTAssertTrue(e.process(.init(0x80,60,0)).isEmpty)
    }
    func testChannelFiltersAndLoopGuard() {
        let e = HarmonyEngine(); e.inputChannel = 1
        XCTAssertTrue(e.process(.init(0x92,60,100)).isEmpty)
        e.inputChannel = 0
        XCTAssertTrue(e.process(.init(0x91,60,100)).isEmpty)
    }
    func testBoundsChordsAndVelocity() {
        let e = HarmonyEngine()
        e.preset.mapping[120] = [4,12,-12]; e.velocityPercent = 150
        XCTAssertEqual(e.process(.init(0x90,120,127)), [.init(0x91,108,127), .init(0x91,124,127)])
        XCTAssertTrue(HarmonyPreset.defaults.allSatisfy { $0.validate() })
        e.preset.mapping[0] = [49]
        XCTAssertFalse(e.preset.validate())
    }
    func testRunningStatusRealtimeSplitPacketsAndSysEx() {
        var p = MIDIParser()
        XCTAssertTrue(p.feed([0x90,60]).isEmpty)
        XCTAssertEqual(p.feed([0xF8,100,62,90]), [.init(0x90,60,100), .init(0x90,62,90)])
        XCTAssertEqual(p.feed([0xC0,4,5]), [.init(0xC0,4,0), .init(0xC0,5,0)])
        XCTAssertTrue(p.feed([0xF0,1,2,0xF8,3,0xF7,60,100]).isEmpty)
    }
    func testSustainAndAllNotesOff() {
        let e = HarmonyEngine()
        XCTAssertEqual(e.process(.init(0xB0,64,127)), [.init(0xB1,64,127)])
        _ = e.process(.init(0x90,60,80))
        let messages = e.process(.init(0xB0,123,0))
        XCTAssertTrue(messages.contains(.init(0xB1,64,0)))
        XCTAssertTrue(messages.contains(.init(0x81,64,0)))
    }
    func testPresetRoundTripAndLowNotes() throws {
        let presets = HarmonyPreset.defaults
        let encoded = try JSONEncoder().encode(presets)
        XCTAssertEqual(try JSONDecoder().decode([HarmonyPreset].self, from: encoded), presets)
        let e = HarmonyEngine(); e.tonic = 11
        // C-sharp is the second degree in B major: E is the generated third.
        XCTAssertTrue(e.process(.init(0x90,0,100)).isEmpty) // C is chromatic in B major
        XCTAssertEqual(e.process(.init(0x90,1,100)), [.init(0x91,4,85)])
    }
}
