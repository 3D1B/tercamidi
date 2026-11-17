import Foundation
import CoreMIDI
import HarmonyCore

struct MIDIEndpoint: Identifiable { let id: MIDIEndpointRef; let name: String }

final class MIDIService: ObservableObject {
    @Published var sources: [MIDIEndpoint] = []
    @Published var destinations: [MIDIEndpoint] = []
    @Published var source: MIDIEndpointRef = 0
    @Published var destination: MIDIEndpointRef = 0
    @Published var error: String?
    @Published var received = 0
    private var client = MIDIClientRef()
    private var input = MIDIPortRef()
    private var output = MIDIPortRef()
    private let queue = DispatchQueue(label: "org.openharmony.midi")
    private let queueKey = DispatchSpecificKey<Bool>()
    private var parser = MIDIParser()
    private let engine = HarmonyEngine()
    private var target: MIDIEndpointRef = 0
    private var connected: MIDIEndpointRef = 0
    init() {
        queue.setSpecific(key: queueKey, value: true)
        check(MIDIClientCreateWithBlock("OpenHarmony" as CFString, &client) { [weak self] _ in
            DispatchQueue.main.async { self?.refresh() }
        })
        check(MIDIOutputPortCreate(client, "Harmony output" as CFString, &output))
        check(MIDIInputPortCreateWithBlock(client, "Melody input" as CFString, &input) { [weak self] list, _ in
            var bytes: [UInt8] = []
            var packet = UnsafeRawPointer(list).advanced(by: MemoryLayout<MIDIPacketList>.offset(of: \.packet)!).assumingMemoryBound(to: MIDIPacket.self)
            for _ in 0..<list.pointee.numPackets {
                let start = UnsafeRawPointer(packet).advanced(by: MemoryLayout<MIDIPacket>.offset(of: \.data)!)
                bytes += Array(UnsafeRawBufferPointer(start: start, count: Int(packet.pointee.length)))
                packet = UnsafePointer(MIDIPacketNext(UnsafeMutablePointer(mutating: packet)))
            }
            self?.receive(bytes)
        })
        refresh()
    }
    private func check(_ code: OSStatus) {
        if code != noErr { DispatchQueue.main.async { self.error = "CoreMIDI: \(code)" } }
    }
    private func endpoint(_ ref: MIDIEndpointRef) -> MIDIEndpoint {
        var name: Unmanaged<CFString>?
        MIDIObjectGetStringProperty(ref, kMIDIPropertyDisplayName, &name)
        return .init(id: ref, name: name?.takeRetainedValue() as String? ?? "MIDI \(ref)")
    }
    func refresh() {
        sources = (0..<MIDIGetNumberOfSources()).map { endpoint(MIDIGetSource($0)) }
        destinations = (0..<MIDIGetNumberOfDestinations()).map { endpoint(MIDIGetDestination($0)) }
        if source != 0 && !sources.contains(where: { $0.id == source }) { connect(0) }
        if destination != 0 && !destinations.contains(where: { $0.id == destination }) { selectOutput(0) }
    }
    func connect(_ ref: MIDIEndpointRef) {
        queue.sync {
            send(engine.panic())
            if connected != 0 { MIDIPortDisconnectSource(input, connected) }
            connected = 0; parser = MIDIParser()
            if ref != 0 {
                let status = MIDIPortConnectSource(input, ref, nil)
                check(status)
                if status == noErr { connected = ref }
            }
        }
        source = connected
    }
    func selectOutput(_ ref: MIDIEndpointRef) {
        queue.sync { send(engine.panic()); target = ref }
        destination = ref
    }
    func configure(preset: HarmonyPreset, tonic: Int, octave: Int, velocity: Int, inputChannel: Int, outputChannel: Int, enabled: Bool) {
        queue.async {
            self.send(self.engine.panic())
            self.engine.preset = preset; self.engine.tonic = tonic; self.engine.octave = octave
            self.engine.velocityPercent = velocity; self.engine.inputChannel = inputChannel
            self.engine.outputChannel = outputChannel; self.engine.enabled = enabled
        }
    }
    func panic() { queue.async { self.send(self.engine.panic()) } }
    private func receive(_ bytes: [UInt8]) {
        queue.async {
            let messages = self.parser.feed(bytes)
            for message in messages { self.send(self.engine.process(message)) }
            if !messages.isEmpty { DispatchQueue.main.async { self.received += messages.count } }
        }
    }
    private func send(_ messages: [MIDIMessage]) {
        guard target != 0 else { return }
        for message in messages {
            var packetList = MIDIPacketList()
            let sent: OSStatus = withUnsafeMutablePointer(to: &packetList) { list in
                let first = MIDIPacketListInit(list)
                return message.bytes.withUnsafeBufferPointer { bytes in
                    guard MIDIPacketListAdd(list, MemoryLayout<MIDIPacketList>.size, first, 0, bytes.count, bytes.baseAddress!) != nil else { return -1 }
                    return MIDISend(output, target, list)
                }
            }
            check(sent)
        }
    }
    deinit {
        if DispatchQueue.getSpecific(key: queueKey) == true { send(engine.panic()) }
        else { queue.sync { send(engine.panic()) } }
        if input != 0 { MIDIPortDispose(input) }; if output != 0 { MIDIPortDispose(output) }
        if client != 0 { MIDIClientDispose(client) }
    }
}
