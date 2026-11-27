# V0.9.0.4 — Art direction, checkpoint (not final)

Premium stylized 2D casual puzzle: round, legible silhouettes, warm and approachable characters, restrained light and clear playfield. The existing 12 project-authored vector animals remain the starting point; this checkpoint **does not claim a completed 12-character redesign**.

## Working visual rules
- Canvas portrait 720×1280; retain safe gameplay readability, with 120 Hz physics and unchanged collision radii.
- Warm diffuse key light from upper left, soft shading towards lower right; no hard glow over eyes or gameplay danger line.
- Existing character vector viewBox 512×512, centered pivot (256,256); nominal outline 8 units (1.56% of design width), face stroke 7–10 units. Source silhouettes remain within their existing collision disk; no shape or physics scaling.
- Character dark brown `#553e39` outlines/eyes, soft white highlights, modest cheek color, differentiated species palettes. Forest sage and cream, Safari warm gold/orange, Snow pale blue/white are the direction, not proof that theme redesign is implemented.
- Typography should use the bundled DejaVu Sans; retain Azerbaijani Ə/ə, İ/ı, Ö/ö, Ü/ü, Ğ/ğ, Ç/ç, Ş/ş. Existing icon lock and localized text communicate undiscovered states without relying only on color.
- Spacing target: consistent 8-unit multiples and mobile-friendly tap targets; existing screens have not all been migrated to a shared token system. Minimize blur, particles and motion when Reduced Effects is enabled.

Source-of-truth and provenance: `ASSET_MANIFEST.json`, `ASSET_LICENSES.md`, `tools/generate_animal_vectors.py` and `tools/generate_expression_vectors.py`. Agent-authored vector modifications, no external image-generation service; applicable provider terms remain unknown and commercial use is BLOCKED. Human art direction review is still needed.
