---
name: fs25-map-mod
description: Use when creating or modifying FS25 map mods, configuring map.xml, terrain, placeables, farmlands, ground types, or fruit types.
---

# FS25 Map Modding

## Overview

Guide for creating and configuring FS25 map mods — terrain, placeables, farmlands, and environment setup.

## When to Use

- Creating a new map mod
- Configuring terrain layers and ground types
- Setting up farmlands, placeables, or selling points
- Modifying environment settings (weather, seasons, growth)

## Map Structure

```
FS25_MapName/
  modDesc.xml
  map/
    map.xml                    # Main map configuration
    map.i3d                    # Scene graph (3D world)
    map01.i3d                  # Terrain
    map01_dem.png              # Height map (16-bit)
    map01_densityMap_fruits.gdm
    map01_densityMap_ground.gdm
    map01_densityMap_stones.gdm
    config/
      environment.xml          # Weather, daylight
      farmlands.xml            # Farmland parcels
      items.xml               # Savegame items
      placementCollisionMap.grle
      vehicles.xml             # Starting vehicles
    data/
      fruitTypes.xml           # Custom fruit types
      groundTypes.xml          # Terrain layers
```

## map.xml Key Sections

```xml
<map>
    <terrain rootNode="terrain"
             heightMapFilename="map01_dem.png"
             mapSize="2048"
             heightScale="255"
             unitsPerPixel="2" />

    <farmlands filename="config/farmlands.xml" />

    <vehicles filename="config/vehicles.xml" />
    <items filename="config/items.xml" />

    <placeables>
        <placeable filename="placeables/sellingStation.xml"
                   position="100 0 200" rotation="0 90 0" />
    </placeables>

    <environment filename="config/environment.xml" />
</map>
```

## Terrain

- **Height map**: 16-bit PNG, dimensions determine map size
- **Map size formula**: `pixels × unitsPerPixel = meters`
- **Common sizes**: 1024 (1km), 2048 (2km), 4096 (4km)
- **heightScale**: Max terrain height in meters

### Ground Types / Terrain Layers

Defined in `groundTypes.xml` or the map's custom `fruitTypes.xml`:
- Each layer has a diffuse, normal, and specular texture
- Layers are painted in the GIANTS Editor
- Maximum layers varies by map settings

## Farmlands

```xml
<farmlands>
    <farmland id="1" pricePerHa="50000" areaInHa="12.5"
              defaultFarmProperty="true" showOnMap="true" />
    <farmland id="2" pricePerHa="40000" areaInHa="8.0" />
</farmlands>
```

- Each farmland has a colored region on the `farmland.grle` info layer
- `defaultFarmProperty="true"` — owned at game start
- `npc="true"` — NPC-owned, cannot be purchased

## Placeables

Placeables are objects the player can build/place:
- Defined as separate XMLs with their own specializations
- Positioned in `map.xml` or placed by player in-game
- Base game placeables in `dataS/data/placeables/`
- Placeable specializations in `dataS/scripts/placeables/specializations/`

## XSD Schemas

The game ships XML Schema files (in the game's `shared/xml/schema/` directory) that define every valid element and attribute. Use these as the authoritative reference:

| Schema | Covers |
|---|---|
| `shared/xml/schema/mission00.xsd` | Map XML (map.xml) structure |
| `shared/xml/schema/farmlands.xsd` | Farmland definitions |
| `shared/xml/schema/fruitTypes.xsd` | Fruit type configuration |
| `shared/xml/schema/fields.xsd` | Field definitions |
| `shared/xml/schema/foliageType.xsd` | Foliage types |
| `shared/xml/schema/densityMapHeightTypes.xsd` | Density map height types |
| `shared/xml/schema/stones.xsd` | Stone system |
| `shared/xml/schema/aiSystem.xsd` | AI system paths |
| `shared/xml/schema/trafficSystem.xsd` | Traffic configuration |
| `shared/xml/schema/placeable.xsd` | Placeable XML structure |

When unsure about valid attributes or value ranges, read the XSD — it's more reliable than guessing from examples.

## Common Workflow

1. Check the XSD schema for valid attributes and structure
2. Start from a base game map as reference (`dataS/data/maps/`)
3. Export from GIANTS Editor with terrain and scene graph
4. Configure `map.xml` with terrain settings
5. Set up farmlands, selling points, and spawn points
6. Add custom ground types if needed
7. Test in-game, check `log.txt` for missing references
