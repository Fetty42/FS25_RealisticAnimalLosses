---
name: fs25-vehicle-mod
description: Use when creating or modifying FS25 vehicle mods, configuring vehicle XML, specializations, attacherJoints, wheels, movingTools, movingParts, lights, or sounds.
---

# FS25 Vehicle Modding

## Overview

Guide for creating and configuring FS25 vehicle mods via `vehicle.xml` and associated specializations.

## When to Use

- Creating a new vehicle mod
- Configuring vehicle XML (wheels, joints, animations, lights, sounds)
- Understanding specialization configuration
- Debugging vehicle behavior

## Vehicle XML Structure

```xml
<vehicle type="myVehicleType">
    <annotation />
    <base>
        <typeDesc>l10n_typeDesc_car</typeDesc>
        <speedLimit value="50" />
    </base>

    <components>
        <component node="0>" mass="2000" centerOfMass="0 0.8 0" />
        <component node="0>1" mass="500" />
        <joint component1="0" component2="1" node="jointNode"
               rotLimit="0 0 0" transLimit="0 0 0" />
    </components>

    <i3dMappings>
        <i3dMapping id="myNode" node="0>0|1" />
    </i3dMappings>

    <motorized>
        <motor torqueCurve="..." />
    </motorized>

    <wheels>
        <wheel node="wheelNode" driveNode="wheelDriveNode"
               radius="0.55" width="0.4" mass="50"
               isLeft="true" hasTireTracks="true"
               repr="wheelRepr" />
    </wheels>

    <attacherJoints>
        <attacherJoint node="attacherNode" jointType="implement"
                       upperTransLimit="0 0.1 0" lowerTransLimit="0 -0.1 0" />
    </attacherJoints>

    <attachable>
        <inputAttacherJoint node="inputNode" jointType="implement" />
    </attachable>
</vehicle>
```

## Key Specializations

### Movement & Physics

| Specialization | Purpose |
|---|---|
| `Motorized` | Engine, transmission, fuel |
| `Drivable` | Steering, brakes, cruise control |
| `Wheels` | Wheel configuration, physics |
| `ArticulatedAxis` | Articulated steering |
| `CCTDrivable` | Character controller movement |

### Attachments

| Specialization | Purpose |
|---|---|
| `AttacherJoints` | Defines where implements attach TO this vehicle |
| `Attachable` | Defines how this implement attaches to vehicles |
| `ConnectionHoses` | Hydraulic/electric hose connections |
| `PowerConsumer` | PTO power requirements |

### Animation & Visuals

| Specialization | Purpose |
|---|---|
| `AnimatedVehicle` | Animation clips and sequences |
| `Cylindered` | movingTools (user-controlled) and movingParts (IK-driven) |
| `Lights` | Light configuration and states |
| `Dashboard` | Dashboard gauges and indicators |
| `Wipers` | Windshield wipers |

### Work Functions

| Specialization | Purpose |
|---|---|
| `FillUnit` | Fill volumes (fuel, grain, etc.) |
| `Dischargeable` | Unloading/discharge |
| `Combine` | Harvesting |
| `Plow` | Plowing |
| `SowingMachine` | Seeding |
| `Sprayer` | Spraying/fertilizing |
| `FrontLoaderAttacher` | Front loader arm |

## Components & Joints

Components are rigid bodies connected by joints:
- `component1` / `component2`: 0-based indices into root-level `<component>` nodes
- `rotLimit`: rotation limits in radians (x y z)
- `transLimit`: translation limits in meters (x y z)
- `rotMinLimit` / `rotMaxLimit`: asymmetric rotation limits

## movingTools vs movingParts

| | movingTool | movingPart |
|---|---|---|
| **Control** | Player-controlled (input) | Automatic (IK-driven) |
| **Config** | `rotationAxis`, `rotSpeed`, `rotMin`/`rotMax` | `referencePoint`, `limitedAxis` |
| **Use case** | Boom arm, bucket tilt | Hydraulic pistons, linkage arms |

## i3dMappings

Maps friendly names to I3D node paths:
```xml
<i3dMappings>
    <i3dMapping id="boom" node="0>0|2|0" />
</i3dMappings>
```

Path format: `rootIndex>child|child|child` (pipe-separated child indices)

## XSD Schemas

The game ships XML Schema files (in the game's `shared/xml/schema/` directory) that define every valid attribute and element. Use these as the authoritative reference:

| Schema | Covers |
|---|---|
| `shared/xml/schema/vehicle.xsd` | Full vehicle XML structure |
| `shared/xml/schema/wheel.xsd` | Wheel configuration |
| `shared/xml/schema/connectionHoses.xsd` | Hose connections |
| `shared/xml/schema/attacherJointTopArm.xsd` | Top arm setup |
| `shared/xml/schema/vehicle_sounds.xsd` | Sound configuration |
| `shared/xml/schema/conditionalAnimation.xsd` | Conditional animations |
| `shared/xml/schema/crawler.xsd` | Tracked vehicle crawlers |
| `shared/xml/schema/powerTakeOff.xsd` | PTO connections |
| `shared/xml/schema/dashboardCompounds.xsd` | Dashboard elements |

When unsure about valid attributes or value ranges, read the XSD — it's more reliable than guessing from examples.

## Common Workflow

1. Check the XSD schema for valid attributes and structure
2. Search `dataS/scripts/vehicles/specializations/` for the relevant specialization source
3. Check how base game vehicles configure that specialization in their XML
4. Base game vehicle XMLs are in `dataS/data/vehicles/`
5. Mirror the same XML structure in your mod
