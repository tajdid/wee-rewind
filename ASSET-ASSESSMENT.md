# Wee Interactions / 002 — Rewind

## Technical assessment

Recovered the original chat attachment (the supplied /mnt/data path does not exist on this Mac). USDZ contains scene.usdc and one 1024 × 512 JPEG. One Mesh, one material, one UV set (st0), 553 triangles. Hierarchy: scene → Meshes → Sketchfab_model → FBX transform → RootNode → cassette → cassette_cassette_0 → mesh. Y-up, centimeters, several nested conversion transforms. No separate shell, label or reel entities.

The UsdPreviewSurface uses a baked emissive atlas, metallic=1, roughness=1, no opacity map. Transparency, lighting and mechanical detail are painted into the atlas. A global tint would recolor every part. Alternate UV-compatible atlases are required for controlled themes. Original preserves the source artwork; Super Tape and Vintage modify shell and label regions while retaining detail. True translucent plastic, independent reels, and newly typeset labels would require geometry/UV work beyond Phase 1.

## Phase 1

1. Preserve USDZ and attribution; prepare two alternate atlases.
2. Load once, normalize visual bounds, retain mesh hierarchy and UVs, cache three unlit texture materials.
3. Non-AR RealityKit scene in SwiftUI, warm-paper background, oversized object and soft shadow.
4. Short drags tilt (clamped); deliberate horizontal swipes select an adjacent theme. Selection buttons and VoiceOver adjustable action provide alternatives. Spring return and transitions; one selection haptic.
5. Respect Reduce Motion, pause floating in background, expose load failure/retry.
6. Build for iOS Simulator and verify rendered orientation, themes and interactions.

## Source

Psx Style Cassette Tape by pixapexel. CC BY 4.0. See ATTRIBUTION.md.

## Milestone 2 — independent reel hubs

The source’s reel teeth/openings have real geometry but share one mesh with the shell. A cylindrical triangle partition now separates both inner hubs into named LeftReel and RightReel pivots. Pivot centers are fitted to the original opening extents; 6.7-unit radii keep the fixed outer rims and surrounding label stationary. Every cut vertex interpolates its original UV. The original source remains intact; AnimatedCassette.usdz is the attributed derivative used at runtime.

Result: 11,974 shell triangles, 406 left-hub triangles, 461 right-hub triangles (12,841 total). The partition preserves source surface area to a relative tolerance of 1e-6. Apple’s RealityKit USD validation succeeds. Extra tessellation permits accurate circular cuts without replacing the existing artwork.
