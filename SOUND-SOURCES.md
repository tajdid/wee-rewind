# Rewind sound direction

Use a small, dry plastic mechanism click, about 80–200 ms long. Avoid long rewind effects or continuous motor/hiss loops for this milestone. Suggested searches: cassette button, tape deck play, plastic latch, mechanical switch.

## Places to look

- Freesound: https://freesound.org/ — best starting point for real cassette recordings. Filter for CC0 where possible. Each sound has its own licence; CC BY needs attribution, and CC BY-NC restricts commercial use. Official guide: https://freesound.org/help/faq/#licenses
- Pixabay cassette collection: https://pixabay.com/sound-effects/search/cassette-player/ — convenient previews and downloads. Content licence summary: https://pixabay.com/service/license-summary/
- Record your own cassette deck or plastic latch close up in a quiet room. A short original recording can give Rewind a more distinctive sound.

When choosing a recording, retain the sound title, creator, original page and licence with the downloaded file. The current app does not bundle any downloaded stock sounds.

## Current milestone

TapeClick.wav is an original procedural sound created for Rewind: a short plastic strike with a quieter latch transient, no third-party samples. Mono 48 kHz, 16-bit PCM, 145 ms. Its deterministic synthesis script is Tools/make_click.py. The source peak is 0.45; in-app playback gain is 0.42.

The sound is preloaded with AVAudioPlayer and starts from the same accepted tap action as motion and haptics. Existing 0.35-second tap throttling prevents a burst of overlapping clicks. The ambient audio category respects silent mode and mixes with other audio. Backgrounding or switching off Sound effects stops playback. There is no microphone permission, stream or background audio mode.

To replace the sound, trim a chosen recording, convert it to mono PCM WAV, and replace Rewind/Resources/TapeClick.wav. Keep the resource name unchanged; update ATTRIBUTION.md and the in-app credit when the recording’s licence requires attribution. Tune playback volume on an iPhone after an explicitly requested device update.

Apple category reference: https://developer.apple.com/library/archive/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/AudioSessionCategoriesandModes/AudioSessionCategoriesandModes.html
