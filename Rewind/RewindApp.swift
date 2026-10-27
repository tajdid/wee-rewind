import SwiftUI
import AVFAudio

@main
struct RewindApp: App {
    var body: some Scene { WindowGroup { CollectionView() } }
}

enum TapeTheme: Int, CaseIterable, Identifiable {
    case original, superTape, vintage
    var id: Int { rawValue }
    var personality: TapePersonality { TapePersonality.all[rawValue] }
    var name: String { ["Original", "Super Tape", "Vintage"][rawValue] }
    var subtitle: String { ["A little analogue magic.", "For the brighter days.", "Some things age beautifully."][rawValue] }
    func memoryTitle(sideB: Bool) -> String {
        if !sideB { return ["AFTER THE LAST SONG", "FRIDAY, 11:48 PM", "A FAMILIAR VOICE"][rawValue] }
        return ["SUMMER ’98", "THE LONG WAY HOME", "SUNDAY, 4:12 PM"][rawValue]
    }
    func memoryLine(sideB: Bool) -> String {
        if !sideB { return ["The good kind of quiet.", "Streetlights keeping time.", "Some hellos never fade."][rawValue] }
        return ["Windows down. Nowhere to be.",
         "One more song before the front door.",
         "Rain on the windows. A familiar song."][rawValue]
    }
    var texture: String { ["Original", "SuperTape", "Vintage"][rawValue] }
    var colors: [Color] {
        switch self {
        case .original: return [Color(hex: 0xF36B3F), Color(hex: 0xFFF9EE), Color(hex: 0x9A8971)]
        case .superTape: return [Color(hex: 0x172239), Color(hex: 0x28B8B1), Color(hex: 0xF1BCCE)]
        case .vintage: return [Color(hex: 0x2B2A27), Color(hex: 0xA43A30), Color(hex: 0xF1E1C1)]
        }
    }
}
struct TapeMemory: Equatable, Identifiable {
    let theme: TapeTheme
    let sideB: Bool
    var id: Int { theme.rawValue * 2 + (sideB ? 1 : 0) }
    var title: String { theme.memoryTitle(sideB: sideB) }
    var line: String { theme.memoryLine(sideB: sideB) }
}

extension Color {
    init(hex: UInt32) { self.init(.sRGB, red: Double((hex >> 16) & 255)/255, green: Double((hex >> 8) & 255)/255, blue: Double(hex & 255)/255, opacity: 1) }
}

struct CollectionView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("rewind.soundEffectsEnabled") private var soundEnabled = true
    @StateObject private var sound = TapeSound()
    @State private var selection = 0
    @State private var drag = CGSize.zero
    @State private var ready = false
    @State private var tapTrigger = 0
    @State private var lastWake = Date.distantPast
    @State private var loadError: String?
    @State private var retry = UUID()
    @State private var showingCredits = false
    @State private var sides = [false, false, false]
    @State private var revealedMemory: TapeMemory?
    @State private var pendingMemory: TapeMemory?
    @State private var memoryRequest = 0
    private var theme: TapeTheme { TapeTheme(rawValue: selection)! }
    private let ink = Color(hex: 0x242424)

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    Spacer()
                    Button { showingCredits = true } label: {
                        Image(systemName: "info.circle").font(.system(size: 17, weight: .light)).frame(width: 44, height: 44)
                    }.accessibilityLabel("About Rewind and asset credits")
                }.padding(.horizontal, 30).padding(.top, 18)
                Spacer(minLength: 20)
                VStack(spacing: 8) {
                    Text("Rewind").font(.system(size: 56, weight: .regular, design: .serif)).tracking(-2.5)
                    Text("Press play on a simpler time").font(.system(size: 13)).opacity(0.5)
                }
                ZStack(alignment: .bottom) {
                    CassetteScene(selection: selection, sides: sides, drag: drag, tapTrigger: tapTrigger, reduceMotion: reduceMotion,
                                  active: scenePhase == .active, ready: $ready, loadError: $loadError)
                        .id(retry)
                        .allowsHitTesting(false)
                    Ellipse().fill(ink.opacity(0.14)).frame(width: geometry.size.width * 0.53, height: 15).blur(radius: 13).padding(.bottom, 22).allowsHitTesting(false).accessibilityHidden(true)
                    if !ready && loadError == nil {
                        ProgressView("Finding your tapes…").font(.caption).frame(maxHeight: .infinity)
                    }
                    if let loadError {
                        VStack(spacing: 12) {
                            Text("The tape couldn’t load.").font(.headline)
                            Text(loadError).font(.caption).multilineTextAlignment(.center)
                            Button("Try again") { self.loadError = nil; ready = false; retry = UUID() }.buttonStyle(.bordered)
                        }.padding().background(Color(hex: 0xF3F0E9))
                    }
                }
                .frame(height: min(geometry.size.height * 0.40, 380))
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 3)
                    .onChanged { drag = $0.translation }
                    .onEnded { value in
                        let x = value.translation.width
                        let projected = value.predictedEndTranslation.width
                        if abs(x) > abs(value.translation.height) * 1.3,
                           abs(x) > 65 || (abs(x) > 24 && abs(projected) > 140) {
                            select(selection + (x < 0 ? 1 : -1))
                        }
                        drag = .zero
                    }.exclusively(before: SpatialTapGesture().onEnded { value in
                        let width = min(geometry.size.width, 640)
                        let height = min(geometry.size.height * 0.40, 380)
                        let tapeArea = CGRect(x: width * 0.08, y: height * 0.18,
                                              width: width * 0.84, height: height * 0.64)
                        if tapeArea.contains(value.location) { wakeTape() }
                    }))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(theme.name) cassette, Side \(sides[selection] ? "B" : "A"), \(selection + 1) of 3")
                .accessibilityHint("Double tap to flip the cassette and reveal a memory. Swipe up or down to change its design")
                .accessibilityAction { wakeTape() }
                .accessibilityAdjustableAction { direction in select(selection + (direction == .increment ? 1 : -1)) }
                VStack(spacing: 10) {
                    Text(String(format: "%02d / 03", selection + 1) + " · SIDE " + (sides[selection] ? "B" : "A")).font(.system(size: 10, design: .monospaced)).tracking(2).opacity(0.4)
                    ZStack {
                        Text(theme.name)
                            .font(.system(size: 25, weight: .medium, design: .serif))
                            .id(theme.id)
                            .transition(reduceMotion ? .opacity : .asymmetric(
                                insertion: .opacity.combined(with: .offset(y: 8)),
                                removal: .opacity.combined(with: .offset(y: -5))))
                    }
                    .frame(maxWidth: .infinity, minHeight: 32, maxHeight: 32)
                    .animation(reduceMotion ? .easeInOut(duration: 0.18) : .spring(duration: theme.personality.nameDuration, bounce: 0.12), value: selection)
                    ZStack {
                        if let memory = revealedMemory {
                            VStack(spacing: 9) {
                                Capsule().fill(ink.opacity(0.16)).frame(width: 20, height: 1)
                                Text(memory.title)
                                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                                    .tracking(1.8).foregroundStyle(ink.opacity(0.5))
                                Text(memory.line)
                                    .font(.system(size: 16, design: .serif).italic())
                                    .foregroundStyle(ink.opacity(0.78))
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .id(memory.id)
                            .accessibilityElement(children: .combine)
                            .transition(reduceMotion ? .opacity : .opacity.combined(with: .offset(y: 6)))
                        } else {
                            Text(theme.subtitle).font(.system(size: 12)).opacity(0.5)
                                .transition(.opacity)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 30)
                    HStack(spacing: 5) {
                        ForEach(Array(theme.colors.enumerated()), id: \.offset) { _, color in
                            Circle().fill(color).frame(width: 8, height: 8).overlay(Circle().stroke(ink.opacity(0.1), lineWidth: 0.5))
                        }
                    }.padding(.top, 6).accessibilityHidden(true)
                }.animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: selection)
                Spacer(minLength: 20)
                HStack(spacing: 0) {
                    ForEach(TapeTheme.allCases) { item in
                        Button { select(item.rawValue) } label: {
                            VStack(spacing: 9) {
                                Capsule().fill(selection == item.rawValue ? ink : ink.opacity(0.15))
                                    .frame(width: selection == item.rawValue ? 22 : 5, height: 5)
                                Text(item.name).font(.system(size: 10)).opacity(selection == item.rawValue ? 0.9 : 0.4)
                            }.frame(maxWidth: .infinity).frame(minHeight: 48)
                        }.accessibilityAddTraits(selection == item.rawValue ? .isSelected : [])
                    }
                }.padding(.horizontal, 44)
                Text("SWIPE TO BROWSE · DRAG TO TILT").font(.system(size: 8, design: .monospaced)).tracking(1.5).opacity(0.35).padding(.top, 20).padding(.bottom, 25)
            }
            .animation(reduceMotion ? .easeOut(duration: 0.2) : .spring(duration: 0.6, bounce: 0.08), value: revealedMemory)
            .frame(maxWidth: 640).frame(maxWidth: .infinity)
        }
        .foregroundStyle(ink)
        .background(Color(hex: 0xF3F0E9).ignoresSafeArea())
        .preferredColorScheme(.light)
        .task(id: memoryRequest) {
            guard let memory = pendingMemory else { return }
            do { try await Task.sleep(for: .milliseconds(480)) }
            catch { return }
            guard !Task.isCancelled, memory.theme.rawValue == selection, memory.sideB == sides[selection],
                  ready, scenePhase == .active, !showingCredits else { return }
            withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .spring(duration: 0.6, bounce: 0.08)) {
                revealedMemory = memory
            }
            if UIAccessibility.isVoiceOverRunning {
                UIAccessibility.post(notification: .announcement,
                                     argument: "Side \(memory.sideB ? "B" : "A"). \(memory.title). \(memory.line)")
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                sound.stop()
                cancelPendingMemory()
            }
        }
        .onChange(of: showingCredits) { _, showing in
            if showing { cancelPendingMemory() }
        }
        .onChange(of: soundEnabled) { _, enabled in
            if !enabled { sound.stop() }
        }
        .sheet(isPresented: $showingCredits) {
            ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Wee Interactions / 002").font(.caption.monospaced()).foregroundStyle(.secondary)
                Text("Rewind").font(.system(.largeTitle, design: .serif))
                Text("Made by Tajdid Rahman").font(.subheadline)
                Toggle("Sound effects", isOn: $soundEnabled).tint(Color(hex: 0xF36B3F))
                Text("A playful cassette collection, made with SwiftUI and RealityKit.")
                Text("3D model: “Psx Style Cassette Tape” by pixapexel. Licensed under CC BY 4.0. Reel sections are separated for animation; Super Tape and Vintage use recolored texture atlases.").font(.footnote)
                Link("View original model ↗", destination: URL(string: "https://sketchfab.com/3d-models/psx-style-cassette-tape-f56e93a81751426e90f772c29039bd08")!)
                Link("Creative Commons Attribution 4.0 ↗", destination: URL(string: "https://creativecommons.org/licenses/by/4.0/")!)
                Button("Done") { showingCredits = false }.buttonStyle(.bordered)
            }.padding(30)
            }.presentationDetents([.medium, .large])
        }
    }
    private func wakeTape() {
        guard ready, loadError == nil, scenePhase == .active,
              Date().timeIntervalSince(lastWake) >= 0.35 else { return }
        lastWake = Date()
        tapTrigger += 1
        sides[selection].toggle()
        pendingMemory = TapeMemory(theme: theme, sideB: sides[selection])
        memoryRequest += 1
        if soundEnabled { sound.playClick(rate: theme.personality.soundRate) }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: CGFloat(theme.personality.hapticIntensity))
    }

    private func cancelPendingMemory() {
        pendingMemory = nil
        memoryRequest += 1
    }

    private func select(_ next: Int) {
        let clamped = min(2, max(0, next))
        guard clamped != selection else { return }
        cancelPendingMemory()
        revealedMemory = nil
        selection = clamped
        UISelectionFeedbackGenerator().selectionChanged()
    }
}


/// Short, preloaded interaction audio. Ambient respects silent mode and mixes
/// with music already playing; it never requests background playback or input.
@MainActor
private final class TapeSound: ObservableObject {
    private var player: AVAudioPlayer?

    init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            guard let url = Bundle.main.url(forResource: "TapeClick", withExtension: "wav") else { return }
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 0.42
            player.enableRate = true
            player.numberOfLoops = 0
            player.prepareToPlay()
            self.player = player
        } catch {
            // Motion and haptics remain usable if audio is unavailable.
            print("Rewind sound unavailable: \(error)")
        }
    }

    func playClick(rate: Float) {
        guard let player else { return }
        player.currentTime = 0
        player.rate = rate
        player.play()
    }

    func stop() {
        player?.stop()
        player?.currentTime = 0
        player?.prepareToPlay()
    }
}
