---
name: fs25-texture-guide
description: Use when working with FS25 textures, DDS formats, normal maps, specular maps, texture naming conventions, or resolution guidelines.
---

# FS25 Texture Guide

## Overview

Texture conventions and formats for FS25 modding. GIANTS Engine uses DDS textures with specific format requirements.

## When to Use

- Creating or converting textures for a mod
- Choosing the right DDS format
- Setting up material textures (diffuse, normal, specular)
- Debugging texture issues (pink/missing textures)

## DDS Formats

| Texture Type | Format | Suffix | Notes |
|---|---|---|---|
| **Diffuse/Albedo** | BC1 (DXT1) or BC3 (DXT5) | `_diffuse` | BC3 if alpha needed |
| **Normal map** | BC5 (ATI2/3Dc) | `_normal` | 2-channel (RG), NOT BC1 |
| **Specular/Gloss** | BC1 (DXT1) or BC3 (DXT5) | `_specular` | R=specular, A=gloss (if BC3) |
| **Mask/Alpha** | BC4 (ATI1) | varies | Single channel |

**Important**: Normal maps MUST be BC5. Using BC1/DXT1 for normals causes visible banding artifacts.

## Naming Conventions

```
myVehicle_diffuse.dds
myVehicle_normal.dds
myVehicle_specular.dds
myVehicle_vmask.dds         # vehicle color mask
myVehicle_dirt.dds           # dirt overlay
```

Base game patterns:
- `store_` prefix for shop images
- `_ao` suffix for ambient occlusion
- `_vmask` for vehicle color mask (paintable areas)

## Resolution Guidelines

| Asset Type | Typical Resolution |
|---|---|
| Large vehicle | 2048×2048 or 4096×4096 |
| Small implement | 1024×1024 or 2048×2048 |
| Placeable building | 2048×2048 |
| UI icon / store image | 256×256 or 512×512 |
| Terrain layer | 1024×1024 (tiling) |

- Always use power-of-two dimensions (256, 512, 1024, 2048, 4096)
- Generate mipmaps for all 3D textures
- Store images do NOT need mipmaps

## Material Setup in I3D

```xml
<Material name="vehicleMat" materialId="1"
          customShaderId="2" customShaderVariation="colorMask">
    <Texture fileId="1" />        <!-- _diffuse.dds -->
    <Normalmap fileId="2" />      <!-- _normal.dds -->
    <Glossmap fileId="3" />       <!-- _specular.dds -->
</Material>
```

### Shader Variations

| Variation | Use Case |
|---|---|
| `default` | Standard opaque material |
| `colorMask` | Paintable vehicle (uses vmask) |
| `alphaTest` | Cutout transparency (foliage, fences) |
| `alphaBlend` | Smooth transparency (glass) |
| `mirror` | Reflective surfaces |

## Color Mask (Vehicle Painting)

The `_vmask.dds` texture controls which areas are paintable:
- **R channel**: Primary color area
- **G channel**: Secondary color area (if supported)
- **B channel**: Tertiary / detail area
- White = fully paintable, Black = not paintable

## Common Issues

| Problem | Cause | Fix |
|---|---|---|
| Pink/magenta texture | Missing or wrong file path | Check `<Files>` paths in I3D |
| Blurry at distance | Missing mipmaps | Regenerate DDS with mipmaps |
| Normal map looks flat | Wrong format (BC1 instead of BC5) | Re-export as BC5 |
| Shiny/dark patches | Wrong specular format | Check specular is proper format |
| Texture seams | UV island padding too small | Add 4-8px padding between UV islands |

## Tools

- **GIANTS Editor**: Built-in texture preview and material editing
- **Paint.NET / GIMP**: With DDS plugin for texture creation
- **texconv** (DirectXTex): Command-line DDS conversion
- **Compressonator** (AMD): DDS compression with preview
