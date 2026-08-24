# Per-make car/motorbike SVG silhouettes

Drop finished files here named `{make_id}.svg` (ids below, matching
`assets/data/car_makes.json` / `motorbike_makes.json`). After adding a
file, also add its id to `makeIdsWithDedicatedIcon` in
`lib/shared/models/car_make_icons.dart` — the app only references a
make-specific asset once its id is in that set, so an added file with no
matching set entry is inert (safe), and a set entry with no matching file
would crash on load (so always add both together).

## Style spec — match the existing category art in `assets/images/cars/`

- `viewBox="0 0 200 100"`, `fill="none"` on the root `<svg>`.
- Side-profile line art only — no fills except low-opacity (`0.4`–`0.7`)
  accent shapes for windows/tank/etc, same as the existing files.
- Stroke color `#3ECFBF` throughout (the app's teal accent) — do not use
  any other color; the app doesn't re-tint at render time.
- Stroke widths: `2.5` for the main body outline, `2` for secondary
  details (window line, tank/seat hump), `1.5` for faint accent lines,
  `stroke-linecap="round"` and `stroke-linejoin="round"` on those.
- Roughly centered in the viewBox, similar scale/proportion to the
  existing files (car body spans ~x14–186, wheels centered at y≈74,
  radius 8; motorbike wheels radius 14).

## Car make ids (37)

toyota, honda, suzuki, ford, chevrolet, bmw, mercedes, audi, volkswagen,
hyundai, kia, nissan, mazda, subaru, mitsubishi, lexus, porsche, tesla,
jeep, ram, dodge, gmc, land_rover, jaguar, volvo, peugeot, renault, fiat,
skoda, seat, mini, alfa_romeo, mg, byd, tata, mahindra, haval

## Motorbike make ids (17)

honda_moto, yamaha_moto, suzuki_moto, kawasaki_moto, bajaj_moto,
hero_moto, tvs_moto, royal_enfield_moto, harley_davidson_moto,
ducati_moto, bmw_moto, ktm_moto, triumph_moto, vespa_moto, benelli_moto,
cfmoto_moto, aprilia_moto
