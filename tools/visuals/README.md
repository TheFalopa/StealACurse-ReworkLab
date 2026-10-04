# UI icons and VFX textures

Original, procedurally drawn source art for the HUD/store icons and the
Curse particle textures. No AI-generated or third-party images are used.

| Output | Generator | Preview |
| --- | --- | --- |
| `assets/ui/icons/*.png` (256 px) | `generate_ui_icons.py` | `assets/ui/icons/_preview.png` (24/48/96 px on dark) |
| `assets/vfx/textures/*.png` | `generate_vfx_textures.py` | `assets/vfx/textures/_preview.png` |

From the repository root (Python 3 + Pillow):

```powershell
python tools/visuals/generate_ui_icons.py            # all icons
python tools/visuals/generate_vfx_textures.py petal  # one texture
```

Uploaded image IDs live in `src/shared/VisualAssets.luau`, the only place the
game reads them from. A regenerated PNG must be re-uploaded (Studio asset
upload) and its new ID written there; old IDs keep working until replaced.
`_preview.png` sheets are review aids and are never uploaded.
