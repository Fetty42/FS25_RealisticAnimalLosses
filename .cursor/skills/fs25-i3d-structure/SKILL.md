---
name: fs25-i3d-structure
description: Use when working with I3D files, understanding the I3D scene graph, node types, materials, shapes, user attributes, collision flags, or transform hierarchy.
---

# FS25 I3D File Structure

## Overview

I3D is GIANTS Engine's XML-based scene format. Understanding its structure is essential for all FS25 modding.

## When to Use

- Reading or editing `.i3d` files
- Understanding the scene graph hierarchy
- Configuring materials, shapes, or collision masks
- Debugging node references and paths

## I3D Coordinate System

I3D uses **Y-up, right-handed** coordinates:
- X = right
- Y = up
- Z = forward

Rotations are in degrees, stored as `rx ry rz`.

## File Structure

```xml
<?xml version="1.0" encoding="iso-8859-1"?>
<i3D name="myObject" version="1.6">
    <Asset /> <!-- metadata -->

    <Files>
        <File fileId="1" filename="textures/diffuse.dds" />
        <File fileId="2" filename="textures/normal.dds" />
    </Files>

    <Materials>
        <Material name="myMat" materialId="1">
            <Texture fileId="1" />
            <Normalmap fileId="2" />
        </Material>
    </Materials>

    <Shapes>
        <Shape shapeId="1" name="mesh" ... />
    </Shapes>

    <Scene>
        <TransformGroup name="root" nodeId="1">
            <Shape name="visual" nodeId="2" shapeId="1" materialIds="1" />
            <TransformGroup name="collisions" nodeId="3" />
        </TransformGroup>
    </Scene>
</i3D>
```

## Node Types

| Node Type | XML Tag | Purpose |
|---|---|---|
| **TransformGroup** | `<TransformGroup>` | Empty transform (grouping, reference points) |
| **Shape** | `<Shape>` | Visible mesh with geometry and material |
| **Light** | `<Light>` | Light source |
| **Camera** | `<Camera>` | Camera viewpoint |
| **Dynamic** | `<Dynamic>` | Physics-enabled rigid body |
| **TerrainTransformGroup** | `<TerrainTransformGroup>` | Terrain node |

## Common Attributes

All nodes share:
```xml
<TransformGroup name="myNode" nodeId="42"
                translation="1.0 2.0 3.0"
                rotation="0 90 0"
                scale="1 1 1"
                visibility="true"
                clipDistance="300"
                objectMask="0xFFFF" />
```

## Node Path Indexing

Nodes are referenced by path from root:
- `0>` — first root child
- `0>0|1` — root child 0, then child index 0, then child index 1
- `0>2|0|3` — root child 0 (skip 2), child 0, child 3

The `>` separates root index, `|` separates child indices.

## Materials

```xml
<Material name="vehicleMat" materialId="1"
          diffuseColor="1 1 1 1" specularColor="1 1 1"
          customShaderId="2" customShaderVariation="colorMask">
    <Texture fileId="1" />            <!-- diffuse/albedo -->
    <Normalmap fileId="2" />          <!-- normal map -->
    <Glossmap fileId="3" />           <!-- specular/gloss -->
    <CustomParameter name="colorMat0" value="0.5 0.1 0.1 1" />
</Material>
```

## Shapes

Shapes reference external `.i3d.shapes` binary files containing vertex/index data:
```xml
<Shape shapeId="1" name="bodyShape"
       castsShadows="true" receiveShadows="true"
       nonRenderable="false" decalLayer="0" />
```

## User Attributes

Custom key-value data on nodes, read by Lua scripts:
```xml
<TransformGroup name="fillVolume" nodeId="50">
    <UserAttribute>
        <Attribute name="fillType" type="string" value="wheat" />
        <Attribute name="capacity" type="float" value="50000" />
    </UserAttribute>
</TransformGroup>
```

## Collision Flags

Collision filtering uses bitmasks:

| Flag | Bit | Common Use |
|---|---|---|
| STATIC_WORLD | 0 | Static geometry |
| DYNAMIC_OBJECT | 1 | Moving objects |
| VEHICLE | 2 | Vehicles |
| PLAYER | 3 | Player character |
| TRIGGER | 4 | Trigger volumes |
| FILLABLE | 5 | Fillable volumes |
| TREE | 9 | Trees |

```xml
<Shape collisionMask="0x3" ... />  <!-- collides with STATIC_WORLD + DYNAMIC_OBJECT -->
```

## XSD Schema

The I3D format has a full XML Schema definition (in the game's `shared/xml/schema/` directory):

| Schema | Covers |
|---|---|
| `shared/xml/schema/i3d-1.6.xsd` | Complete I3D file structure — all node types, attributes, materials, shapes |

This is the authoritative reference for every valid I3D element and attribute. When unsure about attribute names, types, or valid values, read the XSD.

## Quick Reference

| Task | Where to Look |
|---|---|
| Node types & attributes | I3D `<Scene>` section, or `i3d-1.6.xsd` |
| Material setup | I3D `<Materials>` section |
| Texture references | I3D `<Files>` section |
| Node path for XML config | Count child indices in scene hierarchy |
| Collision setup | `collisionMask` attribute + `dataS/scripts/CollisionFlag.lua` |
| Valid attributes/values | `shared/xml/schema/i3d-1.6.xsd` |
