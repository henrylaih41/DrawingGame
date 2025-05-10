local ServerScriptService = game:GetService("ServerScriptService")
local ThemeService = require(ServerScriptService.modules.ThemeService)

local ThemeLoader = {}

function ThemeLoader:loadThemes()
    -- =========================
-- === 1. Lighthouse =======
-- =========================
ThemeService:createTheme(
    "Lighthouse",
    "",
    [[
"Beacon of the coast! A hard-mode lighthouse piece must balance architectural precision with dramatic seascape lighting. **Core requirements:**  
1️⃣ *Structure Accuracy* – cylindrical or tapered tower, balcony (gallery), lantern room (glass top), and access door.  
2️⃣ *Context* – rocky outcrop or pier, visible waves, and sky condition (sunset, storm, night).  
3️⃣ *Light Interaction* – defined light beam or glow cone, correctly illuminating nearby rocks/water.  
4️⃣ *Atmospheric Story* – weather effects (spray, clouds, rain) or narrative element (keeper’s house, ship in distance).

Score 1 Random coast doodle; no tower.  
Score 2 Tower outline only; no balcony or glow; flat sea.  
Score 3 Tower w/ balcony OR lantern; perspective skewed; waves hinted.  
Score 4 Full tower pieces, horizon line, single light beam; colors flat; no shadows.  
Score 5 Correct proportions, textured brick/stripe, wave crests, basic light cone.  
Score 6 Rock texture, reflected beam on water, sky gradient, doorway detail.  
Score 7 Weather drama (storm clouds/rain), foam splash, multi-source shadows.  
Score 8 Golden-hour or moonlit palette, glass glare, subtle atmospheric depth.  
Score 9 Complex lighting (caustics, rim light on rocks), disciplined perspective, credible weather physics.  
Score 10 Publish-ready illustration—flawless architecture, cinematic lighting, rich textures, compelling narrative focal point."

    ]],
    "Hard", 20,
    "Server")

-- =========================
-- === 2. Spaceship =========
-- =========================
ThemeService:createTheme(
    "Spaceship",
    "",
    [[
"Command the void! Hard mode expects a **cohesive spacecraft design** rendered in believable three-dimensional space. **Must include:**  
1️⃣ *Readable Silhouette* – hull, thrusters, command bridge/cockpit, and antennae or weapon arrays.  
2️⃣ *Surface Detail* – panel lines, vents, rivets, or greebles across at least three hull zones.  
3️⃣ *Lighting Logic* – single key light (nearby star, explosion) with secondary rim or bounce; shadows follow.  
4️⃣ *Scene* – space backdrop with nebula, planet, or debris field conveying depth/scale.

Score 1 Random shape; no depth.  
Score 2 Blobby rocket; no detail; stars as dots.  
Score 3 Hull and engines, flat color; no shading; empty backdrop.  
Score 4 Perspective in place, two-tone shading; minimal panel lines.  
Score 5 Panel patterns, exhaust glow, gradient star field, basic rim light.  
Score 6 Complex greebles, lens-flare thrusters, foreground debris for parallax.  
Score 7 Consistent light falloff, planetary terminator glow, subtle bounce on hull.  
Score 8 Multiple material types (metal, glass), color temperature contrast, depth-of-field hint.  
Score 9 Dynamic camera angle, micro-detail crispness, atmospheric scattering or particle bloom.  
Score 10 AAA concept-art tier—innovative design, immaculate lighting, cinematic composition, storytelling action (e.g., battle, docking)."

    ]],
    "Hard", 20,
    "Server")

-- =========================
-- === 3. Rollercoaster ====
-- =========================
ThemeService:createTheme(
    "Rollercoaster",
    "",
    [[
"Feel the adrenaline! This hard-mode rollercoaster scene must capture **structural logic, motion, and crowd energy.**  
Requirements:  
1️⃣ *Track Geometry* – recognizable rails, support beams, and at least one inversion (loop, corkscrew) or steep drop.  
2️⃣ *Train* – visible cars with seats, safety harnesses, and riders (hands-up screams!).  
3️⃣ *Perspective* – dynamic angle (low worm’s-eye or aerial), coherent vanishing lines.  
4️⃣ *Environment* – theme-park context: queue fencing, signage, trees, or adjacent rides. Motion blur or speed lines expected.

Score 1 Lines on page; no rollercoaster shape.  
Score 2 Simple hill; no supports; blank cars.  
Score 3 Full loop + cars; riders faceless; perspective wobbly.  
Score 4 Supports added, cart wheels, basic crowd dots; flat colors.  
Score 5 Correct track thickness, rider poses, park props; motion lines.  
Score 6 Shadows under track, atmospheric haze, color-coded harnesses.  
Score 7 Dynamic POV, blurred background, lighting on metal beams.  
Score 8 Reflected sunlight, crowd reactions, detailed signage, depth layers.  
Score 9 Complex track path crossing, staged foreground objects, meticulous perspective.  
Score 10 Magazine-spread quality—immersive motion, flawless anatomy, stainless-steel reflections, vibrant park life."

    ]],
    "Hard", 20,
    "Server")

-- =========================
-- === 4. Observatory ======
-- =========================
ThemeService:createTheme(
    "Observatory",
    "",
    [[
"Eyes on the cosmos! Deliver a **scientifically-plausible observatory** with convincing architecture and night-sky integration.  
Key items:  
1️⃣ *Dome Structure* – hemispherical roof, slit opening/shutter, rotating base.  
2️⃣ *Primary Telescope* – optical tube, mount, and eyepiece/camera rig; correct pivot.  
3️⃣ *Interior vs Exterior* – choose one but light convincingly (red safe lights inside or moonlit exterior).  
4️⃣ *Context* – mountainous or remote hilltop, starry sky with Milky Way or aurora; subtle light pollution gradient.

Score 1 Building blob; no dome.  
Score 2 Dome and telescope, but perspective off, no context.  
Score 3 Correct dome slit, simple tripod, star dots; flat lighting.  
Score 4 Stone/metal texture, shadows, background peaks.  
Score 5 Lens glass sheen, red interior glow or moon rim, sky gradient.  
Score 6 Star density variation, Milky Way bands, atmospheric perspective on mountains.  
Score 7 Instrument cables, access stairs, light spill on ground.  
Score 8 Subtle reflection in lens, sky color shift, mist/fog layer.  
Score 9 Astro-photography realism—accurate star colors, detailed mount, architectural precision.  
Score 10 Masterpiece—cinematic nightscape, impeccable lighting physics, tactile textures, narrative element (astronomer at console)."

    ]],
    "Hard", 20,
    "Server")

-- =========================
-- === 5. Submarine ========
-- =========================
ThemeService:createTheme(
    "Submarine",
    "",
    [[
"Deep-sea stealth! A hard submarine scene needs **technical hull detail** and **underwater atmosphere**.  
Mandatory:  
1️⃣ *Hull Form* – hydrodynamic cylinder, conning tower (sail), dive planes, propeller or pump-jet.  
2️⃣ *Lighting* – limited ambient light, headlamps or floodlights casting volumetric beams; caustics on metal.  
3️⃣ *Environment* – depth cues: blue-green gradient, particulate silt, sea life or seafloor.  
4️⃣ *Scale Reference* – diver, ROV, or comparison fauna to show size.

Score 1 Oval blob; no water cues.  
Score 2 Cylinder + tower; flat blue background.  
Score 3 Propeller, fins, headlights; shading basic; no particles.  
Score 4 Metal gradient, bubble stream, silhouette fish.  
Score 5 Volumetric beams, sediment cloud, subtle caustics.  
Score 6 Pressure hull panel lines, rivets, foreground coral or wreckage.  
Score 7 Accurate light attenuation, fauna schooling, reflection on hull.  
Score 8 Dynamic camera angle, depth-of-field blur, color cast realism.  
Score 9 Detailed textures, sonar pings/glow logos, balanced composition.  
Score 10 Film-concept quality—photoreal metals, rich particulate depth, compelling narrative (rescue, exploration)."

    ]],
    "Hard", 20,
    "Server")

-- =========================
-- === 6. Windmill =========
-- =========================
ThemeService:createTheme(
    "Windmill",
    "",
    [[
"Capture the turning sails! Hard mode demands architectural understanding and motion portrayal.  
Checklist:  
1️⃣ *Structure* – stone or wooden tower, rotating cap, four sails with lattice frames.  
2️⃣ *Mechanics* – gear housing or interior view through door; pivot beams visible.  
3️⃣ *Environment* – rural landscape (fields, canal) or dramatic weather.  
4️⃣ *Motion* – angled sails, blur streaks, shadow orientation matching sun.

Score 1 Tower doodle; no sails.  
Score 2 Tower + sails; incorrect proportion; blank fields.  
Score 3 Proper sail number, door, horizon; flat colors.  
Score 4 Material texture (stone, wood), cast shadows, sky gradient.  
Score 5 Gear hint, grass sway, blur on tips, reflected light.  
Score 6 Perspective accuracy, flower/field detail, light direction consistent.  
Score 7 Weather element (storm clouds, sunset bloom), strong rim light.  
Score 8 Interior cog view or cutaway, atmospheric depth fog.  
Score 9 Fine lattice detail, moving grain dust, balanced composition.  
Score 10 Storybook art—perfect mechanics, cinematic lighting, dynamic landscape narrative."

    ]],
    "Hard", 20,
    "Server")

-- =========================
-- === 7. Pyramid ==========
-- =========================
ThemeService:createTheme(
    "Pyramid",
    "",
    [[
"Monument of the ancients. Hard grading looks for **geometric precision** and **environmental storytelling.**  
Essentials:  
1️⃣ *Structure* – accurate triangular faces, aligned bricks/blocks, visible erosion or sand buildup.  
2️⃣ *Lighting* – harsh desert sun, sharp shadows, heat haze.  
3️⃣ *Surroundings* – dunes, obelisks, sphinx, or excavation gear.  
4️⃣ *Sky* – gradient (dawn, dusk) or stellar night with Orion’s Belt alignment.

Score 1 Triangle blob; no depth.  
Score 2 Block lines, flat sand, bright sky; no shading.  
Score 3 Two pyramid faces visible, basic shadow.  
Score 4 Brick texture, dune lines, warm palette.  
Score 5 Sunlit rim, long cast shadows, wind-trace ripples.  
Score 6 Foreground artifact (statue, dig tools), heat shimmer.  
Score 7 Complex erosion detail, sky gradient, dust motes.  
Score 8 Night scene with star alignment or torch light, depth layering.  
Score 9 Photoreal textures, atmospheric perspective, storytelling (explorers, caravan).  
Score 10 Museum-poster quality—flawless geometry, master lighting, immersive desert narrative."

    ]],
    "Hard", 20,
    "Server")

-- =========================
-- === 8. Ferriswheel ======
-- =========================
ThemeService:createTheme(
    "Ferriswheel",
    "",
    [[
"Sky-high carnival lights! Hard mode emphasizes **engineering accuracy** and **night-time illumination.**  
Must include:  
1️⃣ *Wheel Framework* – radial spokes, central hub, A-frame supports, cross-bracing.  
2️⃣ *Gondolas* – evenly spaced cabins with windows/doors, at least some occupants.  
3️⃣ *Lighting* – LED strips or bulb chains following spokes/rim, glow reflecting on metal.  
4️⃣ *Park Setting* – ticket booth, crowd, other rides blurred.

Score 1 Circle; no spokes/cabins.  
Score 2 Spokes present, cabins blocks; flat lighting.  
Score 3 Proper supports, even cabins, simple bulbs.  
Score 4 Metal shading, crowd silhouettes, sky gradient.  
Score 5 Reflected light, cabin windows/glare, balanced perspective.  
Score 6 Motion blur on rim, foreground bokeh lights, accurate shadows.  
Score 7 Complex crowd, lens flare, color harmony.  
Score 8 Atmospheric haze, depth layering, detailed booth signage.  
Score 9 Precision engineering lines, dynamic composition, polished reflections.  
Score 10 Festival-poster finish—immaculate lighting, depth, vibrant storytelling."

    ]],
    "Hard", 20,
    "Server")

-- =========================
-- === 9. Greenhouse =======
-- =========================
ThemeService:createTheme(
    "Greenhouse",
    "",
    [[
"Grow with the glow! Hard guidelines focus on **transparent structure** and **lush interior biodiversity.**  
Requirements:  
1️⃣ *Architecture* – glass panels, steel/aluminum framework, roof vents.  
2️⃣ *Botany* – at least five plant types (vines, flowers, potted trees) with distinct leaf shapes.  
3️⃣ *Lighting* – noon sun or artificial grow lights casting colored highlights through glass.  
4️⃣ *Micro-climate Details* – mist/fog, water hoses, hanging planters, gardener or tools.

Score 1 Box shape; no glass cues.  
Score 2 Panel grid, generic plants, flat color.  
Score 3 Light refraction lines, two plant varieties, perspective uneven.  
Score 4 Leaf type variety, basic reflections, interior shadows.  
Score 5 Sunbeam shafts, soil texture, tool bench.  
Score 6 Condensation droplets on glass, color bounce from leaves.  
Score 7 Depth rows, mist spray, insect or butterfly, light gradient.  
Score 8 Translucent glass reflections, soft-focus background beds.  
Score 9 Detailed leaf veins, multi-source lighting, balanced composition.  
Score 10 Botanical-magazine quality—hyper-real glass, lush biodiversity, story element (researcher, rare bloom)."

    ]],
    "Hard", 20,
    "Server")

-- =========================
-- === 10. Aquarium ========
-- =========================
ThemeService:createTheme(
    "Aquarium",
    "",
    [[
"Underwater showcase! Hard mode demands **convincing water optics** and **ecosystem richness.**  
Include:  
1️⃣ *Tank Structure* – glass walls, silicone seams, lighting hood.  
2️⃣ *Aquascape* – substrate, rocks/driftwood, live plants, at least five fish species with accurate shapes.  
3️⃣ *Optical Effects* – light caustics on substrate, subtle distortion/refraction through glass, surface ripples.  
4️⃣ *Viewer Context* – human silhouette, info panel, room reflections.

Score 1 Fish bowl doodle.  
Score 2 Rect tank, few fish; no water effects.  
Score 3 Substrate + plants, simple lighting; glass lines flat.  
Score 4 Species variety, accurate colors, rock layout.  
Score 5 Light rays, shadow gradient, subtle glass reflection.  
Score 6 Caustic patterns, bubble stream, viewer silhouette.  
Score 7 Refraction distortion, background signage glare.  
Score 8 Dynamic fish poses, depth-of-field, balanced composition.  
Score 9 Photoreal texture, convincing optics, storytelling (feeding, research).  
Score 10 Show-poster excellence—perfect water physics, rich ecosystem, immersive lighting and reflections."

    ]],
    "Hard", 20,
    "Server")
end

return ThemeLoader