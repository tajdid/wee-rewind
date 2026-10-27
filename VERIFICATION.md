# Verification — 27 October 2026

## Passed

- Xcode 27.1 Debug build for iPhone 18 Pro / iOS 27.0 Simulator, arm64, code signing disabled: BUILD SUCCEEDED.
- Installed and launched final app in the simulator; USDZ and all three texture materials load and render.
- Inspected final Original, Super Tape and Vintage renders; saved screenshots in Screenshots/.
- Horizontal swipes select Original → Super Tape → Vintage. Reverse swipe returns to Super Tape.
- Swipe beyond Vintage remains on Vintage; no out-of-range selection.
- Theme buttons update the selected label, subtitle, palette and page indicator.
- Short vertical drag preserves theme selection; release returns to resting orientation.
- Info sheet displays creator, CC BY 4.0, source/licence links and adaptation notice; Done dismisses.
- Accessibility tree exposes cassette name/count as an adjustable control and marks the selected theme button.
- Bundled USDZ checksum equals the recovered original attachment:
  b13b115bf5664340275099bb1f6454a5d0ca1562f1b485c265706925c5a8864d

## Implementation checks, not device-tested

- Reduce Motion path snaps selection and disables floating/tilt.
- Scene-phase handling stops motion updates while inactive.
- Async loading cancellation, loading progress and failure/retry state are implemented.

## Remaining physical-device checks

Haptic feel, sustained frame pacing, VoiceOver gesture operation and Reduce Motion behavior should be checked on an iPhone. No physical-device installation or signing team was configured. iPad/landscape layout and iOS 18 runtime compatibility have not been exercised. The initial interaction verification above was manual; automated coverage was added in the later icon and QA pass below.

## Spin transition update

- Rebuilt successfully with Xcode 27.1 and relaunched in iPhone 18 Pro Simulator.
- Removed the main-screen “WEE INTERACTIONS” and “002 / REWIND” header. Series identity remains in project documentation and About.
- Selected all themes and switched back; inspected recorded frames showing the cassette turning through edge-on and face-on orientations, then settling.
- Spin follows navigation direction, lasts 0.9 seconds and composes with drag tilt and the existing spring slide. Reduce Motion bypasses it.
- Updated screenshots and Preview.png; SpinTransition.mp4 contains a short simulator recording.

## Slower spring finish

- Updated the main turn from 0.9 to 1.25 seconds, with a 0.5-second damped angular spring finish. The initial overshoot is about 3.4 degrees, followed by a much smaller rebound.
- Xcode simulator build succeeded; launched and exercised forward and reverse selection in the simulator. Reduce Motion still clears the spin and spring immediately.
- New simulator recording: SpinSpringTransition.mp4.

## Single turn, stronger bounce, name and copy update

- Increased the settling overshoot to 0.14 radians (about 8°), with a 0.65-second damped finish. Each entry starts one revolution; returning during an active turn continues it rather than adding another.
- Theme names now fade/rise into a fixed-height slot, respecting Reduce Motion.
- Verified the new tagline and browse hint in the running simulator, and the “Made by Tajdid Rahman” credit in About.
- Exercised rapid Super Tape → Vintage → Super Tape selection.
- Made About scrollable after noticing truncation at the medium sheet height.

## Physical iPhone installation

- Device build signed successfully using the existing development team.
- Installed bundle studio.weeinteractions.Rewind on Taj’s iPhone 17 Pro (iOS 27.0.1).
- Device tooling confirmed that Rewind launched successfully.
- Haptic feel and on-device interaction quality remain for hands-on review.

## Tap to wake — milestone 1

- Simulator and signed device builds succeeded.
- Added an exclusive tap/drag gesture: tap the cassette’s central stage area to dip, tilt and spring home over 0.85 seconds. Drag wins once movement exceeds 3 points; horizontal swiping still changes themes.
- Repeated taps use a 0.35-second cooldown and bounded per-tape impulse; tap response composes with theme spin.
- Verified touch taps preserve theme selection and a subsequent swipe changes Original to Super Tape in the simulator. Inspected recording frames; small press/return accompanies the unchanged theme.
- VoiceOver exposes a default wake action; Reduce Motion suppresses spatial tap animation but retains haptics. These accessibility paths were inspected in code; hands-on VoiceOver and haptic feel remain for device review.

## Milestone 2 — moving reels

- Simulator build succeeded; installed and launched only in iPhone 18 Pro Simulator. Physical phone was not updated.
- AnimatedCassette.usdz passes usdchecker --arkit. Preparation asserts nonempty shell/hubs and conserved triangle surface area.
- Inspected the source derivative at rest and during rotation. Tightened hub cuts after finding a rotating orange label sliver in the first draft. Final cuts preserve stationary labels and outer rims.
- Tapped Original, Super Tape and Vintage; both hubs rotate independently from the shell, including during the cassette’s entrance motion. Inspected simulator screenshots and recorded a preview.
- Repeated taps retain reel angle and re-accelerate the current speed. Runtime applies exponential acceleration/deceleration and stops the hubs after 2.8 seconds. Reduce Motion cancels the reel motion; inactive scene updates remain paused. These paths were checked in source; no physical-device haptic/performance claims are made.
- Source USDZ and creator/CC BY 4.0 credit retained; app and attribution document now disclose geometry separation.

## Milestone 3 — interaction sound

- Simulator build succeeded; installed/launched only in Simulator. Physical iPhone not updated.
- TapeClick.wav validated with afinfo: 145 ms, mono 48 kHz, 16-bit PCM. Synthesis checks peak below clipping and a zero initial sample; source peak 0.45.
- Exercised tap activation and the About Sound effects toggle; verified on/off accessibility values. Mute gates playback in the accepted tap action while preserving motion/haptics.
- AVAudioPlayer preloads the bundled asset; ambient session category selected. Backgrounding and muting call stop. Actual loudness, haptic/audio alignment and the physical phone silent switch remain for an explicitly requested device review.
- Current audio is synthesized original material, with reproducible generation and no downloaded third-party samples. Sources and per-file licence guidance recorded in SOUND-SOURCES.md.

## Milestone 4 — subtle tape personalities

- Xcode simulator build succeeded. Installed/launched only in Simulator; physical phone not updated.
- Compared tap, reel motion and drag return on Original, Super Tape and Vintage in the running simulator, then exercised quick re-entry and a reverse horizontal swipe. Theme names and selection stayed correct. Recorded PersonalitiesPreview.mp4.
- Standalone checks compile the actual TapePersonality.swift with Tools/check_personalities.swift. All three pass: a single turn in either direction, no extra revolution or large reverse turn, continuity at the spring boundary, negligible final residual, zero final tap displacement, bounded dip, and sound/haptic variations within 5%.
- Original remains softly springy; Super Tape settles faster; Vintage settles more slowly with calmer floating and reels. Shared collection slide and gesture thresholds remain consistent.
- Per-theme click playback rates are configured at 1.00/1.04/0.96 with identical gain; haptic intensities are 0.65/0.69/0.61 with the same soft style. Haptic feel cannot be verified in Simulator and remains for a later authorized physical-device review. Reduce Motion and mute remain shared paths; no claim of new physical-device testing.

## Reveal a memory

- Simulator build succeeded; installed/launched only in iPhone 18 Pro Simulator. Physical phone not updated.
- Tapped all three themes and checked their complete captions and layout in screenshots/accessibility text. No clipping or navigation overlap observed at the tested default simulator text size.
- Repeated tap preserves the current caption. Selecting another tape or swiping to it clears the old caption and restores that tape’s normal subtitle.
- Exercised a tap immediately followed by a different selection; the destination shows its own normal subtitle rather than a stale delayed memory.
- The 200 ms reveal uses a cancellable SwiftUI task plus a current-selection guard. About/background changes cancel pending work. Reduce Motion removes offset animation; VoiceOver combines and announces the memory once. Those latter paths were inspected in source, not hands-on accessibility-tested.
- Preview recording: MemoryRevealPreview.mp4. Still: MemoryReveal.png.

## Compact reveal and Side B

- Final simulator build succeeded; derivative passes usdchecker --arkit. Original USDZ preserved. No physical-phone build, install or launch was performed.
- Removed the fixed 76-point memory slot and verified compact normal subtitles on Side A. Reveal uses intrinsic text height with animated parent layout. Inspected compact and expanded screenshots with all controls visible.
- Tapped Original, Super Tape and Vintage to Side B; checked B marks and readable, theme-specific handwritten notes. Corrected face assignment and custom-note orientation during visual QA.
- Tapped back to Side A and verified distinct Side A memories. Tested repeated reversals and browsing back to an already-flipped tape: side persists, stale caption clears, the next reveal matches the current side.
- Half-turn spring composes with full-turn browse transitions, tilt, reels and the tap dip. Reduce Motion snaps side angles; caption tasks check current theme and side. Accessibility labels include Side A/B and flip instructions. Accessibility motion paths were reviewed in source, not hands-on VoiceOver-tested.
- Recorded SideBPreview.mp4; saved CompactLayout.png and SideB.png.


## App icon and automated QA pass

- Added an opaque 1024-pixel cassette app icon and warm launch background. Inspected the installed icon on the simulator Home Screen.
- Automated tests passed for all three themes and both sides, delayed-memory cancellation, collection boundaries and load-failure retry on iPhone 18 Pro and iPhone 17e simulators.
- Replaced the sound control with a native UISwitch after automated touch reliability failures. Its preference-persistence test passed on iPhone 18 Pro after the fix; the complete suite has not yet been rerun on both devices with this final control.
- Fixed cancelled-drag reset, retry accessibility, movement behind About, and audio preparation on the main thread. Audio preparation/playback now use a dedicated serial queue.
- Debug builds passed with the final sound control. A Release build passed earlier in this QA pass, before the final sound-control and launch-background changes.
- Focused motion checks and ARKit USD validation passed. Tools/check_assets.py validates icon dimensions/opacity, all six atlas dimensions, original-model checksum and click format/levels.
- Hands-on VoiceOver, largest text sizes, Reduce Motion and physical haptic/audio quality remain outside this pass. The physical phone was not updated.
- Demo video export remains in progress and is not included in this commit.
