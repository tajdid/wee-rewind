import SwiftUI
import RealityKit
import Combine

struct CassetteScene: UIViewRepresentable {
    var selection: Int
    var sides: [Bool]
    var drag: CGSize
    var tapTrigger: Int
    var reduceMotion: Bool
    var active: Bool
    @Binding var ready: Bool
    @Binding var loadError: String?

    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        view.environment.background = .color(UIColor(red: 243/255, green: 240/255, blue: 233/255, alpha: 1))
        view.renderOptions = [.disableMotionBlur, .disableDepthOfField, .disableCameraGrain]
        context.coordinator.configure(view, onReady: { ready = true }, onError: { error in loadError = error })
        return view
    }
    func updateUIView(_ view: ARView, context: Context) {
        let c = context.coordinator
        c.reduceMotion = reduceMotion
        c.selection = selection
        c.sides = sides
        c.drag = drag
        c.tapTrigger = tapTrigger
        c.active = active
    }
    static func dismantleUIView(_ view: ARView, coordinator: Coordinator) {
        coordinator.loading?.cancel()
        coordinator.subscription?.cancel()
        view.scene.anchors.removeAll()
    }

    @MainActor final class Coordinator {
        var selection = 0 {
            didSet {
                guard selection != oldValue, !reduceMotion else { return }
                // Never stack another revolution onto a tape already turning.
                // Rapidly returning to it lets its existing single turn finish.
                guard spinAges[selection] >= TapePersonality.all[selection].spinDuration else { return }
                let direction: Float = selection > oldValue ? 1 : -1
                spinStarts[selection] = direction * 2 * .pi
                spinAges[selection] = 0
            }
        }
        var tapTrigger = 0 {
            didSet {
                guard tapTrigger != oldValue, !reduceMotion else { return }
                // Restart a bounded impulse rather than accumulating tap energy.
                tapAges[selection] = 0
                reelAges[selection] = 0
            }
        }
        var sides = [false, false, false]
        private var flipAngles: [Float] = [0, 0, 0]
        private var flipVelocities: [Float] = [0, 0, 0]
        var drag = CGSize.zero
        var reduceMotion = false
        var active = true
        var loading: Task<Void, Never>?
        var subscription: Cancellable?
        #if DEBUG
        private static var failNextLoad = ProcessInfo.processInfo.arguments.contains("-simulate-load-failure")
        #endif
        private let track = Entity()
        private var tapes: [Entity] = []
        private var phase: Float = 0
        private var reels: [[Entity]] = []
        private var reelAges = [Float](repeating: Float.greatestFiniteMagnitude, count: 3)
        private var reelSpeeds = [Float](repeating: 0, count: 3)
        private var reelAngles = [Float](repeating: 0, count: 3)
        private var tapAges = [Float](repeating: Float.greatestFiniteMagnitude, count: 3)
        private var spinAngles = [Float](repeating: 0, count: 3)
        private var spinStarts = [Float](repeating: 0, count: 3)
        private var spinAges = [Float](repeating: Float.greatestFiniteMagnitude, count: 3)
        private var x: Float = 0
        private var velocity: Float = 0
        private var tilt = SIMD2<Float>.zero
        private var tiltVelocity = SIMD2<Float>.zero

        func configure(_ view: ARView, onReady: @escaping () -> Void, onError: @escaping (String) -> Void) {
            let anchor = AnchorEntity(world: .zero)
            anchor.addChild(track)
            let camera = PerspectiveCamera()
            camera.camera.fieldOfViewInDegrees = 35
            camera.position = [0, 0, 5.4]
            anchor.addChild(camera)
            view.scene.addAnchor(anchor)
            loading = Task { [weak self, weak view] in
                guard let self, let view else { return }
                do {
                    #if DEBUG
                    if Self.failNextLoad {
                        Self.failNextLoad = false
                        throw CocoaError(.fileReadNoSuchFile)
                    }
                    #endif
                    guard let url = Bundle.main.url(forResource: "AnimatedCassette", withExtension: "usdz") else {
                        throw CocoaError(.fileNoSuchFile)
                    }
                    let source = try await Entity(contentsOf: url)
                    try Task.checkCancellation()
                    for theme in TapeTheme.allCases {
                        let texture = try await TextureResource(named: theme.texture + ".png")
                        try Task.checkCancellation()
                        var material = UnlitMaterial()
                        material.color = .init(texture: .init(texture))
                        let backTexture = try await TextureResource(named: theme.texture + "SideB.png")
                        try Task.checkCancellation()
                        var backMaterial = UnlitMaterial()
                        backMaterial.color = .init(texture: .init(backTexture))
                        let model = source.clone(recursive: true)
                        guard let leftReel = model.findEntity(named: "LeftReel"),
                              let rightReel = model.findEntity(named: "RightReel") else {
                            throw CocoaError(.coderReadCorrupt)
                        }
                        self.reels.append([leftReel, rightReel])
                        // Imported mesh is broad in X/Y after its nested USD transforms.
                        let bounds = model.visualBounds(relativeTo: nil)
                        let scale = 3.3 / max(bounds.extents.x, 0.0001)
                        let centered = Entity()
                        model.scale *= SIMD3<Float>(repeating: scale)
                        model.position = -bounds.center * scale
                        Self.apply(material, back: backMaterial, to: model)
                        centered.addChild(model)
                        let holder = Entity()
                        holder.position.x = Float(theme.rawValue) * 4.6
                        holder.addChild(centered)
                        self.track.addChild(holder)
                        self.tapes.append(centered)
                        print("Rewind loaded \(theme.name): bounds \(bounds.extents), center \(bounds.center)")
                    }
                    onReady()
                    self.subscription = view.scene.subscribe(to: SceneEvents.Update.self) { [weak self] event in
                        MainActor.assumeIsolated { self?.tick(Float(event.deltaTime)) }
                    }
                } catch is CancellationError { } catch {
                    self.track.children.removeAll()
                    self.tapes.removeAll()
                    self.reels.removeAll()
                    onError("Please reopen Rewind or try loading the cassette again.")
                    print("Rewind asset error: \(error)")
                }
            }
        }
        private static func apply(_ material: UnlitMaterial, back: UnlitMaterial, to entity: Entity) {
            if var model = entity.components[ModelComponent.self] {
                model.materials = model.materials.map { _ in entity.name.hasSuffix("SideB") ? back : material }
                entity.components.set(model)
            }
            for child in entity.children { apply(material, back: back, to: child) }
        }
        private func tick(_ delta: Float) {
            guard active else { return }
            let dt = min(delta, 1/30)
            let selectedPersonality = TapePersonality.all[selection]
            let targetX = -Float(selection) * 4.6
            let targetTilt = SIMD2<Float>(Float(max(-45, min(45, drag.height))) * 0.003,
                                          Float(max(-65, min(65, drag.width))) * 0.003)
            if reduceMotion {
                x = targetX; velocity = 0; tilt = .zero; tiltVelocity = .zero
            } else {
                phase += dt
                velocity += ((targetX - x) * 100 - velocity * 19) * dt
                x += velocity * dt
                tiltVelocity += ((targetTilt - tilt) * selectedPersonality.tiltStiffness - tiltVelocity * selectedPersonality.tiltDamping) * dt
                tilt += tiltVelocity * dt
            }
            track.position.x = x
            for (index, tape) in tapes.enumerated() {
                let personality = TapePersonality.all[index]
                let sideAngle: Float = sides[index] ? .pi : 0
                if reduceMotion {
                    flipAngles[index] = sideAngle
                    flipVelocities[index] = 0
                } else {
                    flipVelocities[index] += ((sideAngle - flipAngles[index]) * 120 - flipVelocities[index] * 22) * dt
                    flipAngles[index] += flipVelocities[index] * dt
                }
                if reduceMotion {
                    spinAngles[index] = 0
                    spinStarts[index] = 0
                    spinAges[index] = personality.spinDuration
                } else {
                    spinAges[index] = min(personality.spinDuration, spinAges[index] + dt)
                    spinAngles[index] = personality.spinAngle(from: spinStarts[index], at: spinAges[index])
                }
                if reduceMotion {
                    reelAges[index] = personality.reelDuration
                    reelSpeeds[index] = 0
                } else {
                    reelAges[index] = min(personality.reelDuration, reelAges[index] + dt)
                    let powered = reelAges[index] < personality.reelPoweredDuration
                    let targetSpeed: Float = powered ? personality.reelSpeed : 0
                    let response: Float = powered ? personality.reelAcceleration : personality.reelDeceleration
                    reelSpeeds[index] += (targetSpeed - reelSpeeds[index]) * (1 - exp(-response * dt))
                    if reelAges[index] >= personality.reelDuration { reelSpeeds[index] = 0 }
                    reelAngles[index] = (reelAngles[index] + reelSpeeds[index] * dt).truncatingRemainder(dividingBy: 2 * .pi)
                }
                for reel in reels[index] {
                    reel.orientation = simd_quatf(angle: reelAngles[index], axis: [0, 1, 0])
                }
                tapAges[index] = reduceMotion ? personality.tapDuration : min(personality.tapDuration, tapAges[index] + dt)
                let tapAge = tapAges[index]
                let press = personality.press(at: tapAge)
                tape.position.z = -personality.tapDepth * press
                tape.position.y = (reduceMotion ? 0 : sin(phase * personality.floatFrequency + Float(index) * 0.4) * personality.floatAmplitude) - 0.05 * press
                tape.orientation = simd_quatf(angle: -0.11 + tilt.x + personality.tapPitch * press, axis: [1,0,0])
                    * simd_quatf(angle: -0.10 + tilt.y + spinAngles[index] + flipAngles[index], axis: [0,1,0])
                    * simd_quatf(angle: -0.055, axis: [0,0,1])
            }
        }
    }
}
