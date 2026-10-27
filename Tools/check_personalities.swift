// Run with swiftc Rewind/TapePersonality.swift Tools/check_personalities.swift -o /tmp/check-rewind
import Foundation

@main
struct CheckPersonalities {
    static func main() {
        for (index, profile) in TapePersonality.all.enumerated() {
            for direction: Float in [-1, 1] {
                let start = direction * 2 * Float.pi
                precondition(abs(profile.spinAngle(from: start, at: 0) - start) < 0.00001)
                precondition(profile.spinAngle(from: start, at: profile.spinDuration) == 0)
                precondition(profile.spinAngle(from: start, at: profile.spinDuration + 10) == 0)
                // No extra revolution, and no large reverse turn during settling.
                for sample in 0...3000 {
                    let age = profile.spinDuration * Float(sample) / 3000
                    let angle = direction * profile.spinAngle(from: start, at: age)
                    precondition(angle <= 2 * .pi + 0.0001 && angle >= -profile.overshoot - 0.0001)
                    precondition(angle.isFinite)
                }
                // The transition into the spring must not jump or kick suddenly.
                let epsilon: Float = 0.0001
                let before = profile.spinAngle(from: start, at: profile.turnDuration - epsilon)
                let at = profile.spinAngle(from: start, at: profile.turnDuration)
                let after = profile.spinAngle(from: start, at: profile.turnDuration + epsilon)
                precondition(abs(before - at) < 0.0001 && abs(after - at) < 0.0001)
                precondition(abs(profile.spinAngle(from: start, at: profile.spinDuration - epsilon)) < 0.002)
            }
            precondition(profile.press(at: 0) == 0)
            precondition(profile.press(at: profile.tapDuration) == 0)
            precondition(profile.press(at: profile.tapDuration + 10) == 0)
            let peakDepth = (0...1000).map { abs(profile.press(at: Float($0) / 1000) * profile.tapDepth) }.max()!
            precondition(peakDepth < 0.20) // Keep the dip restrained in scene units.
            precondition(abs(profile.soundRate - 1) <= 0.05)
            precondition(abs(profile.hapticIntensity - 0.65) <= 0.05)
            print("Personality \(index): one turn, continuous settle, bounded dip/audio/haptics passed")
        }
        precondition(TapePersonality.superTape.spinDuration < TapePersonality.original.spinDuration)
        precondition(TapePersonality.vintage.spinDuration > TapePersonality.original.spinDuration)
        print("All personality contracts passed")
    }
}
