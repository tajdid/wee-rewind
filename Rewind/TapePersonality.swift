import Foundation

/// Small variations around one shared interaction language, in seconds/radians.
struct TapePersonality {
    let turnDuration: Float
    let settleDuration: Float
    let overshoot: Float
    let tapDuration: Float
    let tapDamping: Float
    let tapFrequency: Float
    let tapDepth: Float
    let tapPitch: Float
    let tiltStiffness: Float
    let tiltDamping: Float
    let reelPoweredDuration: Float
    let reelCoastDuration: Float
    let reelSpeed: Float
    let reelAcceleration: Float
    let reelDeceleration: Float
    let floatAmplitude: Float
    let floatFrequency: Float
    let soundRate: Float
    let hapticIntensity: Float
    let nameDuration: Double

    var spinDuration: Float { turnDuration + settleDuration }
    var reelDuration: Float { reelPoweredDuration + reelCoastDuration }

    static let original = TapePersonality(
        turnDuration: 1.25, settleDuration: 0.65, overshoot: 0.14,
        tapDuration: 0.92, tapDamping: 7.6, tapFrequency: 16,
        tapDepth: 0.36, tapPitch: 0.16, tiltStiffness: 160, tiltDamping: 23,
        reelPoweredDuration: 1.1, reelCoastDuration: 1.7, reelSpeed: 6.8,
        reelAcceleration: 12, reelDeceleration: 4.5,
        floatAmplitude: 0.035, floatFrequency: 1.4,
        soundRate: 1, hapticIntensity: 0.65, nameDuration: 0.46)

    static let superTape = TapePersonality(
        turnDuration: 1.15, settleDuration: 0.55, overshoot: 0.12,
        tapDuration: 0.78, tapDamping: 9.2, tapFrequency: 18,
        tapDepth: 0.34, tapPitch: 0.15, tiltStiffness: 180, tiltDamping: 25,
        reelPoweredDuration: 1.05, reelCoastDuration: 1.55, reelSpeed: 7.2,
        reelAcceleration: 14, reelDeceleration: 5,
        floatAmplitude: 0.031, floatFrequency: 1.5,
        soundRate: 1.04, hapticIntensity: 0.69, nameDuration: 0.42)

    static let vintage = TapePersonality(
        turnDuration: 1.35, settleDuration: 0.75, overshoot: 0.12,
        tapDuration: 1.02, tapDamping: 7.1, tapFrequency: 14,
        tapDepth: 0.34, tapPitch: 0.14, tiltStiffness: 145, tiltDamping: 23,
        reelPoweredDuration: 1.15, reelCoastDuration: 1.85, reelSpeed: 6.4,
        reelAcceleration: 10, reelDeceleration: 4,
        floatAmplitude: 0.029, floatFrequency: 1.25,
        soundRate: 0.96, hapticIntensity: 0.61, nameDuration: 0.50)

    static let all: [TapePersonality] = [.original, .superTape, .vintage]

    func press(at age: Float) -> Float {
        guard age >= 0, age < tapDuration else { return 0 }
        return exp(-tapDamping * age) * sin(tapFrequency * age)
    }

    func spinAngle(from start: Float, at age: Float) -> Float {
        guard start != 0, age < spinDuration else { return 0 }
        let end = start > 0 ? -overshoot : overshoot
        if age < turnDuration {
            let progress = max(0, age) / turnDuration
            let eased = progress * progress * (3 - 2 * progress)
            return start * (1 - eased) + end * eased
        }
        let progress = (age - turnDuration) / settleDuration
        return end * exp(-4.5 * progress) * (cos(9 * progress) + 0.5 * sin(9 * progress))
    }
}
