import SwiftUI
import UniformTypeIdentifiers
import CoreAudioKit
import HarmonyCore

@main
struct OpenHarmonyApp: App {
    @StateObject private var store = Store()
    @StateObject private var midi = MIDIService()
    @AppStorage("language") private var language = "de"
    var body: some Scene {
        WindowGroup { StageView().environmentObject(store).environmentObject(midi).environment(\.locale, Locale(identifier: language)) }
    }
}

struct StageView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var midi: MIDIService
    @Environment(\.scenePhase) private var phase
    @State private var settings = false
    @State private var editor = false
    private let colors: [Color] = [.teal,.orange,.purple,.pink,.blue,.green]
    private let notes = ["C","C♯","D","E♭","E","F","F♯","G","A♭","A","B♭","B"]
    private var configKey: String { "\(store.selected)|\(store.tonic)|\(store.octave)|\(store.velocity)|\(store.inputChannel)|\(store.outputChannel)|\(store.enabled)" }
    private func configure() {
        guard store.presets.indices.contains(store.selected) else { return }
        midi.configure(preset: store.presets[store.selected], tonic: store.tonic, octave: store.octave, velocity: store.velocity, inputChannel: store.inputChannel, outputChannel: store.outputChannel, enabled: store.enabled)
    }
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("OPEN HARMONY").font(.headline).tracking(3)
                            Text(LocalizedStringKey(midi.source == 0 || midi.destination == 0 ? "Connect MIDI in settings" : "MIDI ready")).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("Harmony", isOn: $store.enabled).fixedSize()
                        Button { midi.panic() } label: { Label("Panic", systemImage: "stop.circle.fill").foregroundStyle(.red) }.buttonStyle(.bordered)
                        Button { settings = true } label: { Image(systemName: "slider.horizontal.3").font(.title2) }.accessibilityLabel("Settings")
                    }
                    HStack {
                        Text("Key")
                        Picker("Key", selection: $store.tonic) { ForEach(0..<12) { Text(notes[$0]).tag($0) } }.pickerStyle(.menu)
                        Spacer()
                        Stepper(value: $store.octave, in: -3...3) { Text("Octave") + Text(" \(store.octave > 0 ? "+" : "")\(store.octave)") }.fixedSize()
                        Spacer()
                        Button { editor = true } label: { Label("Edit", systemImage: "pencil") }.buttonStyle(.bordered)
                    }
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: geo.size.width > 600 ? 3 : 2), spacing: 12) {
                        ForEach(Array(store.presets.enumerated()).filter { $0.offset / 6 == store.page }, id: \.element.id) { item in
                            let i = item.offset, preset = item.element
                            Button { store.selected = i } label: {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack { Image(systemName: store.selected == i ? "waveform.circle.fill" : "waveform.circle"); Spacer(); Text(String(format: "%02d", i + 1)).font(.caption.monospaced()) }
                                    Text(LocalizedStringKey(preset.name)).font(.title3.bold()).lineLimit(2).frame(maxWidth: .infinity, alignment: .leading)
                                }.padding(16).frame(maxWidth: .infinity, minHeight: max(85, (geo.size.height - 170) / 2 - 20), alignment: .leading)
                                    .background(colors[preset.color].opacity(store.selected == i ? 0.45 : 0.15), in: RoundedRectangle(cornerRadius: 18))
                                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(store.selected == i ? colors[preset.color] : .clear, lineWidth: 3))
                            }.buttonStyle(.plain).accessibilityAddTraits(store.selected == i ? .isSelected : [])
                        }
                    }
                    HStack {
                        Button { store.page = max(0, store.page - 1) } label: { Image(systemName: "chevron.left") }.disabled(store.page == 0)
                        Spacer(); Text("\(store.page + 1) / \((store.presets.count + 5) / 6)").font(.caption.monospaced()); Spacer()
                        Button { store.page += 1 } label: { Image(systemName: "chevron.right") }.disabled((store.page + 1) * 6 >= store.presets.count)
                    }
                }.padding(16)
            }.background(Color(red: 0.035, green: 0.055, blue: 0.085)).foregroundStyle(.white)
                .toolbar(.hidden, for: .navigationBar)
                .sheet(isPresented: $settings) { SettingsView() }
                .sheet(isPresented: $editor) { PresetEditor() }
                .onAppear { UIApplication.shared.isIdleTimerDisabled = true; configure() }
                .onChange(of: configKey) { _ in configure(); store.save() }
                .onChange(of: store.presets) { _ in configure() }
                .onChange(of: phase) { value in
                    UIApplication.shared.isIdleTimerDisabled = value == .active
                    if value != .active { midi.panic(); store.save() }
                }
                .alert("Error", isPresented: Binding(get: { midi.error != nil || store.error != nil }, set: { if !$0 { midi.error = nil; store.error = nil } })) {
                    Button("OK") { midi.error = nil; store.error = nil }
                } message: { Text(LocalizedStringKey(midi.error ?? store.error ?? "")) }
        }.preferredColorScheme(.dark)
    }
}

struct SettingsView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var midi: MIDIService
    @Environment(\.dismiss) var dismiss
    @AppStorage("language") private var language = "de"
    @State private var bluetooth = false
    @State private var importing = false
    @State private var share: URL?
    var body: some View {
        NavigationStack {
            Form {
                Section("Language") { Picker("Language", selection: $language) { Text("Deutsch").tag("de"); Text("English").tag("en"); Text("Srpski").tag("sr") } }
                Section("MIDI connection") {
                    Picker("Input", selection: Binding(get: { midi.source }, set: { midi.connect($0) })) {
                        Text("None").tag(UInt32(0)); ForEach(midi.sources) { Text($0.name).tag($0.id) }
                    }
                    Picker("Output", selection: Binding(get: { midi.destination }, set: { midi.selectOutput($0) })) {
                        Text("None").tag(UInt32(0)); ForEach(midi.destinations) { Text($0.name).tag($0.id) }
                    }
                    Button("Refresh devices") { midi.refresh() }
                    Button("Bluetooth MIDI") { bluetooth = true }
                    Text("Use different MIDI channels for melody and harmony. Disable MIDI Thru on your keyboard to prevent feedback.").font(.footnote)
                }
                Section("Channels") {
                    Picker("Input channel", selection: $store.inputChannel) { Text("All channels").tag(0); ForEach(1...16, id: \.self) { Text("\($0)").tag($0) } }
                    Picker("Output channel", selection: $store.outputChannel) { ForEach(1...16, id: \.self) { Text("\($0)").tag($0) } }
                    if store.inputChannel == 0 || store.inputChannel == store.outputChannel {
                        Text("Loop risk: select different input and output channels.").foregroundStyle(.orange)
                    }
                    Text("Harmony velocity") + Text(" \(store.velocity)%")
                    Slider(value: Binding(get: { Double(store.velocity) }, set: { store.velocity = Int($0) }), in: 10...150, step: 1)
                    Text("Keyboard transpose: select the matching key manually. Automatic Korg transpose is not implemented.").font(.footnote)
                }
                Section("Presets") {
                    Button("Export presets") { do { share = try store.exportURL() } catch { store.error = error.localizedDescription } }
                    if let share { ShareLink(item: share) { Label("Share file", systemImage: "square.and.arrow.up") } }
                    Button("Import presets") { importing = true }
                    Text("Import replaces the current presets. Export a backup first.").font(.footnote)
                }
                Section { Text("Free software · MIT license · No account · No purchases").font(.footnote); Text("USB: connect your keyboard using a data-capable cable and the appropriate iPhone adapter. Select both MIDI ports above.").font(.footnote) }
            }.navigationTitle("Settings").toolbar { Button("Done") { dismiss() } }
                .sheet(isPresented: $bluetooth) { BluetoothView() }
                .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
                    do {
                        let url = try result.get(); let access = url.startAccessingSecurityScopedResource()
                        defer { if access { url.stopAccessingSecurityScopedResource() } }
                        try store.load(Data(contentsOf: url)); store.save()
                    } catch { store.error = error.localizedDescription }
                }
        }
    }
}
struct BluetoothView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CABTMIDICentralViewController { CABTMIDICentralViewController() }
    func updateUIViewController(_ uiViewController: CABTMIDICentralViewController, context: Context) {}
}

struct PresetEditor: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss
    @State private var selectedNote = 60
    @State private var intervals = ""
    @State private var invalid = false
    private var binding: Binding<HarmonyPreset> { $store.presets[store.selected] }
    var body: some View {
        NavigationStack {
            Form {
                Section("Harmony buttons") {
                    ForEach(Array(store.presets.enumerated()), id: \.element.id) { item in
                        Button { store.selected = item.offset; load() } label: {
                            HStack { Text(LocalizedStringKey(item.element.name)); Spacer(); if store.selected == item.offset { Image(systemName: "checkmark") } }
                        }
                    }.onMove { from, to in
                        let id = store.presets[store.selected].id
                        store.presets.move(fromOffsets: from, toOffset: to)
                        store.selected = store.presets.firstIndex(where: { $0.id == id }) ?? 0
                    }.onDelete { offsets in
                        guard store.presets.count > offsets.count else { return }
                        store.presets.remove(atOffsets: offsets); store.selected = min(store.selected, store.presets.count - 1); load()
                    }
                    Button("New harmony") { store.add(); load() }
                }
                Section("Edit harmony") {
                    TextField("Name", text: binding.name)
                    Picker("Colour", selection: binding.color) { ForEach(0..<6) { Text(LocalizedStringKey(["Teal","Orange","Purple","Pink","Blue","Green"][$0])).tag($0) } }
                    Stepper("MIDI note: \(selectedNote)", value: $selectedNote, in: 0...127).onChange(of: selectedNote) { _ in load() }
                    Text("C4 = 60. Notes are relative to C; the selected key rotates the mapping.").font(.footnote)
                    TextField("Semitone offsets", text: $intervals).textInputAutocapitalization(.never).autocorrectionDisabled()
                    Text("Examples: 4 = major third; 3 = minor third; 7,12 = fifth and octave; empty = silence.").font(.footnote)
                    Button("Apply note") { apply(copy: false) }
                    Button("Copy this octave to all octaves") { apply(copy: true) }
                    if invalid { Text("Enter up to 8 unique integers from -48 to 48.").foregroundStyle(.red) }
                }
            }.navigationTitle("Edit").toolbar { ToolbarItem(placement: .navigationBarLeading) { EditButton() }; ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { store.page = store.selected / 6; store.save(); dismiss() } } }.onAppear { load() }
        }
    }
    private func load() { intervals = store.presets[store.selected].mapping[selectedNote].map(String.init).joined(separator: ", "); invalid = false }
    private func apply(copy: Bool) {
        let parts = intervals.split(separator: ",", omittingEmptySubsequences: false).map { $0.trimmingCharacters(in: .whitespaces) }
        let values = intervals.trimmingCharacters(in: .whitespaces).isEmpty ? [] : parts.compactMap(Int.init)
        guard (intervals.trimmingCharacters(in: .whitespaces).isEmpty || values.count == parts.count), values.count <= 8, Set(values).count == values.count, values.allSatisfy({ (-48...48).contains($0) }) else { invalid = true; return }
        store.presets[store.selected].mapping[selectedNote] = values
        if copy {
            let base = selectedNote / 12 * 12
            let row = Array(store.presets[store.selected].mapping[base..<min(base + 12,128)])
            for note in 0..<128 { if note % 12 < row.count { store.presets[store.selected].mapping[note] = row[note % 12] } }
        }
        invalid = false; store.save()
    }
}
