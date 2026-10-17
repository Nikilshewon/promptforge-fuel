# PromptForge Fuel

Modern fuel system for **Qbox, QBCore, ESX or standalone** with neon 3D pump text, a tablet-style purchase UI and a physical fuel hose.

**Author:** PromptForge

## Features
- Neon 3D text above every pump (colour-cycling, pulsing glow + coloured light), and live neon text over the car while refuelling
- Tablet UI: real vehicle picture, gradient tank ring, 4 fuel types with sliders and 25/50/75/MAX buttons, cash/bank payment
- Physical hose: nozzle in hand, rope from pump to nozzle, nozzle plugs into the fuel cap, hose snaps back if you walk too far
- RPM and vehicle-class based fuel consumption, engine cut-off at 0%, low fuel warning
- Server-side pricing and payment (charged only for litres actually pumped)
- Electric vehicles, bikes, boats and aircraft excluded
- Gas station blips
- `LegacyFuel` compatible exports

## Requirements
- A framework (optional, auto-detected): [qbx_core](https://github.com/Qbox-project/qbx_core), [qb-core](https://github.com/qbcore-framework/qb-core) or [es_extended](https://github.com/esx-framework/esx_core). With none installed it runs **standalone** (free refuelling).
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_target](https://github.com/overextended/ox_target)

## Install
1. Put the `promptforge-fuel` folder in your `resources` folder.
2. Remove any other fuel script (LegacyFuel, ox_fuel, ...).
3. Add to `server.cfg` after the requirements:
   ```
   ensure ox_lib
   ensure qbx_core   # or qb-core / es_extended (skip for standalone)
   ensure ox_target
   ensure promptforge-fuel
   ```

## Frameworks
`Config.Framework = 'auto'` detects Qbox, QBCore or ESX at runtime. Force one with `'qbox'`, `'qbcore'`, `'esx'` or `'standalone'`.
- Qbox / QBCore / ESX: cash or bank is charged, server-side.
- Standalone: no money system, refuelling is free and the payment selector is hidden.

## Usage
1. Park next to a pump with the engine off, then use the ox_target option **Use Fuel Pump**.
2. Pick a fuel type, set litres (slider or quick buttons), choose Cash or Bank, press **PURCHASE**.
3. Press **X** to stop early. You only pay for what was pumped.

## Configuration (`config.lua`)
| Option | What it does |
|---|---|
| `Config.PumpModels` | Pump props that get the target + neon text |
| `Config.FuelTypes` | Fuel names, price per litre, card colour |
| `Config.Text` | Neon text font, height, colours, cycle speed, light |
| `Config.Hose` | Nozzle model, rope length, max distance, hand/cap attach offsets |
| `Config.Consumption` / `ClassMultiplier` | How fast fuel drains |
| `Config.TankSize` | Tank litres per vehicle class |
| `Config.RefuelRate` | Litres per second |
| `Config.VehicleImageURL` | Source for car pictures in the UI |
| `Config.Blips` | Station blips |

### Car pictures
The UI tries `web/img/<spawnname>.png` first, then `Config.VehicleImageURL`, then a built-in silhouette. Add PNGs to `web/img/` for custom vehicles.

### Nozzle looks crooked at the fuel cap?
Tune `Config.Hose.cap` (`rx`, `ry`, `rz` and the x/y/z offsets).

## Exports (client)
```lua
exports['promptforge-fuel']:GetFuel(vehicle)        -- 0.0 - 100.0
exports['promptforge-fuel']:SetFuel(vehicle, 75.0)
-- also available as exports['LegacyFuel'] (resource uses `provide 'LegacyFuel'`)
```
Fuel is also stored on the vehicle statebag: `Entity(vehicle).state.fuel`.

## Credits
Made by **PromptForge**. Resource name: `promptforge-fuel`.
