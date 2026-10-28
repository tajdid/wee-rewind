# Rewind
### Wee Interactions / 002

**Press play on a simpler time.**

A small SwiftUI interaction design experiment about making a digital object feel tactile. Browse three cassette tapes, drag to tilt them, and tap to flip from Side A to Side B. Spring motion, spinning reels, a mechanical click and a soft haptic give each gesture a little weight.

<p>
  <img src="CompactLayout.png" alt="Rewind showing the Original cassette on Side A in its compact layout" width="280">
  <img src="SideB.png" alt="The cassette flipped to Side B, with a handwritten label and a revealed fictional memory" width="280">
</p>

Built for iOS with **SwiftUI + RealityKit**. The experience runs locally, with bundled artwork and sound. It is a cassette interaction study; it does not play music or connect to a streaming service.

## Try the interaction

- **Swipe to browse** Original, Super Tape and Vintage, or choose a tape using the buttons below it. The collection stops at either end.
- **Drag to tilt** the cassette, then release to let it settle.
- **Tap to flip** between Side A and Side B. The cassette dips, its reels accelerate and coast, and a short fictional memory appears after the turn.
- **Open About** for credits and the persistent Sound effects toggle.

Each tape remembers its side while you browse during the session. Switching tapes clears the caption; the next tap reveals the memory for the newly selected side. All six memories are authored vignettes.

## The design experiment

Rewind explores how a shared interaction can take on a subtly different character through timing and feedback.

| Tape | Character |
| --- | --- |
| **Original** | Soft, gently springy motion |
| **Super Tape** | Quicker turns and a tighter settle |
| **Vintage** | Calmer floating, slower reels and a more relaxed return |

Browsing introduces the selected cassette with one full turn and a small spring finish. Tapping adds a half-turn flip, a restrained dip, reel motion and feedback. These movements compose, so a tap can happen while a browse transition is still settling. Repeated taps restart the reel impulse without resetting its angle.

Handwritten Side B labels and a compact caption reveal complete the interaction. The layout expands with the memory instead of reserving an empty text area.

VoiceOver exposes the current tape and side, a flip action and adjustable browsing. Reduce Motion removes spatial animation and keeps caption transitions simple. These paths are implemented; hands-on accessibility checks remain part of the verification work.

## Run locally

1. Clone the repository:

   ```sh
   git clone https://github.com/tajdid/wee-rewind.git
   cd wee-rewind
   open Rewind.xcodeproj
   ```

2. Select the **Rewind** scheme and an **iPhone simulator**.
3. Choose **Product → Run**.

You need macOS with Xcode and an iOS Simulator runtime. The deployment target is **iOS 18.0**; the repository's recorded build environment is **Xcode 27.1 / iOS 27.0 Simulator**. iOS 18 runtime compatibility has not been exercised in the verification record.

There are **no third-party app dependencies**, API keys or backend services to configure. The generated models, textures and click sound are already bundled; asset preparation scripts are optional.

For a physical iPhone, select your own development team under **Signing & Capabilities**. The app bundle identifier is `studio.weeinteractions.Rewind`. Although the project also targets iPad, iPad and landscape layouts have not been verified.

For gesture tuning, horizontal browsing requires a drag more horizontal than vertical by a factor of 1.3, plus either over 65 points of travel or a flick over 24 points with projected travel over 140 points. Accepted taps have a 0.35-second cooldown. Memory reveals wait 480 ms and check the current theme, side and app state before appearing.

## Inside the project

| File | Responsibility |
| --- | --- |
| [RewindApp.swift](Rewind/RewindApp.swift) | SwiftUI layout, gestures, theme and side state, memory reveals, audio and About |
| [CassetteScene.swift](Rewind/CassetteScene.swift) | RealityKit non-AR scene, async loading, spring motion, flips and independent reels |
| [TapePersonality.swift](Rewind/TapePersonality.swift) | Shared motion curves and per-tape timing, sound rate and haptic intensity |
| [Resources](Rewind/Resources/) | Source and adapted USDZ models, six texture atlases and the click sound |
| [RewindUITests](RewindUITests/RewindUITests.swift) | Interaction, navigation, retry and sound-preference UI tests |
| [Tools](Tools/) | Asset preparation, asset validation and focused motion checks |

The scene loads one model asynchronously, clones it for the three themes and caches their materials. Each tape has independent flip and reel state. Motion pauses while the app is inactive or About is open; loading includes progress, cancellation and retry handling.

The original cassette uses a baked photographic texture: its transparent appearance is painted into the artwork. The animated derivative separates the inner reel hubs from the shell and gives back-facing surfaces readable Side B artwork. The source USDZ is preserved unchanged.

Audio uses a preloaded `AVAudioPlayer` on a dedicated serial queue. Its ambient session is configured to respect silent mode and mix with other audio. The app stores the sound preference locally; it makes no network requests.

## Checks and current limits

The [verification record](VERIFICATION.md) documents successful simulator builds and manual interaction checks. It also records automated passes for theme/side coverage, navigation boundaries, memory cancellation and load retry on iPhone 18 Pro and iPhone 17e simulators.

The final sound-switch persistence test passed on iPhone 18 Pro. The full suite has not yet been rerun on both simulators after that control changed. Hands-on VoiceOver, largest text sizes, Reduce Motion, physical haptic/audio quality and sustained performance remain to be checked.

To run the UI suite, choose **Product → Test** with the **Rewind** scheme and an iPhone simulator.

Run the focused motion checks from the repository root:

```sh
swiftc Rewind/TapePersonality.swift Tools/check_personalities.swift -o /tmp/check-rewind
/tmp/check-rewind
```

These check single-turn bounds, spring continuity, final rest, bounded dip and restrained sound/haptic variation.

Validate bundled assets with Python 3 (standard library only):

```sh
python3 Tools/check_assets.py
```

This checks the app icon, six texture atlas dimensions, original-model checksum and click audio format and levels. The adapted USDZ also passed Apple's `usdchecker --arkit` validation in the recorded QA pass.

Asset preparation uses Apple's USD tools; `make_side_b.py` also requires Pillow and the macOS fonts named in the script. See [ASSET-ASSESSMENT.md](ASSET-ASSESSMENT.md) for asset details and [Design/AppIcon.md](Design/AppIcon.md) for the icon workflow. Demo recordings remain local and are excluded from Git.

## Credits

Made by **Tajdid Rahman** as part of **Wee Interactions**.

Cassette model: [“Psx Style Cassette Tape” by pixapexel](https://sketchfab.com/3d-models/psx-style-cassette-tape-f56e93a81751426e90f772c29039bd08), licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Rewind adapts the geometry, themed texture atlases and Side B artwork. The mechanical click was synthesized for this project without third-party samples.

See [ATTRIBUTION.md](ATTRIBUTION.md) for asset credits and adaptations, and [SOUND-SOURCES.md](SOUND-SOURCES.md) for sound provenance and replacement guidance.
