local ServerScriptService = game:GetService("ServerScriptService")
local ThemeService = require(ServerScriptService.modules.ThemeService)

local ThemeLoader = {}

function ThemeLoader:loadThemes()
ThemeService:createTheme(
    "Galaxy",
    "",
    [[
"Paint the vastness of space! A strong galaxy must blend at least **three distinct colors** (e.g., purple, blue, pink), include a **dense star field** (20 + varied-size dots), and feature **one focal object** (spiral arm, glowing planet, comet, or nebula core). Smooth gradients, color harmony, and depth stacking matter. Extra touches—constellation shapes, lens flares, or a tiny spaceship—push scores higher.

Score 1: Dark scribble; <10 stars; no color depth.  
Score 2: Black sky w/ sparse stars; one flat color patch.  
Score 3: Two-tone cloud + 20 stars; focal object missing or crude.  
Score 4: Three blended colors, 30 stars, simple planet; edges rough.  
Score 5: Smooth blend (≥3 colors), 40 stars, crisp planet/comet outline.  
Score 6: Spiral or nebula core with soft glow, layered star density, subtle shadows.  
Score 7: Consistent light source, rim-lit planet, color gradients refined, minor lens flare.  
Score 8: Multi-layer dust clouds, distant galaxy cores, faint constellation lines.  
Score 9: Polished depth, pinpoint highlights, atmospheric haze, tiny spacecraft/astronaut.  
Score 10: Poster-quality vista—flawless gradients, balanced composition, wow-factor depth."
    ]],
    "Medium", 15,
    "Server")

-- === Dragon (medium) ===
ThemeService:createTheme(
    "Dragon",
    "",
    [[
"Summon a legendary beast! Required: recognizable **head, torso, limbs, wings/fins**, and **tail**; at least **three areas of texture** (scales, belly plates, membrane veins); plus a **context cue** (fire, smoke, treasure, or sky). Anatomy and motion count. Western or Eastern style okay—just keep horns and menace clear.

Score 1: Vague creature; limbs/wings missing.  
Score 2: Full outline but stiff; no textures; flat color.  
Score 3: Clear wings, claws, tail; one-tone shading; no context.  
Score 4: Two-tone body, scale dots, smoke or flames added.  
Score 5: Proper limb joints, basic shadows, glowing eyes OR treasure pile.  
Score 6: Gradient body, defined belly plates, smoke swirl, simple background.  
Score 7: Dynamic pose (flying, lunging), fire breath, light-source consistency.  
Score 8: Scale patterns, atmospheric depth, background terrain (mountains/sky).  
Score 9: Intricate textures, rim lighting, foreground elements (knight, castle).  
Score 10: Cinematic scene—perfect anatomy, rich textures, multi-layer lighting."
    ]],
    "Medium", 15,
    "Server")

-- === Cyberpunk (medium) ===
ThemeService:createTheme(
    "Cyberpunk",
    "",
    [[
"Neon nights & future grunge. Must show: **two neon color families**, **recognizable tech (cyborg limb, holo ad, drone, or hover car)**, and **urban depth** (at least two building layers). Rain reflections and cable webs add mood. Composition should feel crowded yet readable.

Score 1: Flat skyline; no neon or tech.  
Score 2: One neon sign; plain buildings; perspective off.  
Score 3: Two neon hues, dark alley, weak tech hint.  
Score 4: Glow signage, cyborg/vehicle silhouette, basic rain streaks.  
Score 5: Multi-layer buildings, visor/circuit lines, reflective puddles.  
Score 6: Consistent light bloom, misty fog, cables or vents, color harmony.  
Score 7: Dynamic angle, holo projections, signage depth, minor crowd silhouettes.  
Score 8: Polished reflections, light scattering, detailed gear, balanced palette.  
Score 9: Atmospheric smog, complex perspective, chrome highlights, bustling details.  
Score 10: Movie-poster quality—flawless neon, intricate depth, cinematic lighting."
    ]],
    "Medium", 15,
    "Server")

-- === Volcano (medium) ===
ThemeService:createTheme(
    "Volcano",
    "",
    [[
"Feel the heat! Must include: **clearly defined cone**, **lava flow or explosive column**, **ash/smoke plume**, and **reflected light** on surrounding terrain or sky. Reds, oranges, and yellows should have visible gradient. Dynamic motion earns big points.

Score 1: Basic cone; no lava.  
Score 2: Cone + red streak; no plume; flat shading.  
Score 3: Lava river + smoke cloud; gradient minimal.  
Score 4: Flow glow, cracked ground texture; plume shaded.  
Score 5: Ember spray, reflected light on clouds/rocks, color blend smooth.  
Score 6: Flow curves, ash shading, minor background silhouettes (trees/people).  
Score 7: Eruption blast, debris arcs, sky color transition (sunset/night).  
Score 8: Atmospheric lighting, layered smoke, lava lighting edges of rocks.  
Score 9: Realistic lava texture, depth shadows, dynamic composition.  
Score 10: Blockbuster eruption—multi-layer lighting, debris, polished detail."
    ]],
    "Medium", 15,
    "Server")

-- === Rainbow (medium) ===
ThemeService:createTheme(
    "Rainbow",
    "",
    [[
"Spread color joy! Medium level expects **seven clean stripes in correct order**, **visible gradient or blending within each band**, and **a setting** (clouds, landscape, or subject interacting with the rainbow). Creativity still rocks, but precision matters.

Score 1: Random color mix; wrong order.  
Score 2: 4 – 5 stripes; jagged edges.  
Score 3: Seven stripes but wobbly; no setting.  
Score 4: Correct stripes, simple clouds, minimal shading.  
Score 5: Smooth edges, gradient in bands, background sky or hill.  
Score 6: Soft edge feathering, reflections (water/puddles), sparkle accents.  
Score 7: Double rainbow or curved perspective, detailed clouds, light rays.  
Score 8: Creative integration (wings, spiral road), consistent lighting.  
Score 9: Seamless gradient, atmospheric depth, subtle shadows/highlights.  
Score 10: Greeting-card art—flawless blend, scenic environment, magical polish."
    ]],
    "Medium", 15,
    "Server")

-- === Samurai (medium) ===
ThemeService:createTheme(
    "Samurai",
    "",
    [[
"Honor & steel. Must show **kabuto or headband crest**, **layered armor plates with laces**, **katana with guard detail**, and **context element** (torii gate, cherry blossoms, rival warrior). Pose and cloth flow count.

Score 1: Stick figure w/ sword.  
Score 2: Armor blob; no plate detail.  
Score 3: Helmet crest, sword, basic armor; flat color.  
Score 4: Layered plates, tied sash, cherry petals; shading minimal.  
Score 5: Proper limb proportion, simple background, light-source obvious.  
Score 6: Cloth folds, blade reflection, petals or gate, depth shadows.  
Score 7: Dynamic stance, accurate plate lacing, balanced midtones.  
Score 8: Atmospheric lighting, fabric patterns, ground reflections.  
Score 9: Intricate armor texture, cinematic depth, compositional balance.  
Score 10: Art-print scene—perfect anatomy, textures, dramatic lighting."
    ]],
    "Medium", 15,
    "Server")

-- === Mirage (medium) ===
ThemeService:createTheme(
    "Mirage",
    "",
    [[
"Desert illusions. Must include **two dune layers**, **clear heat-wave distortion** (wavy lines, color shift), and **false oasis or city** with reflection. Color gradient sky (warm to cool) is expected.

Score 1: Dune scribble; no mirage.  
Score 2: Simple dune + vague water spot.  
Score 3: Heat lines, oasis shape; gradient rough.  
Score 4: Two dune layers, pool reflection, footprints or cactus.  
Score 5: Strong shimmer, fading edges, traveler silhouette.  
Score 6: Multiple dunes, sun glare, color transition smooth.  
Score 7: Distorted reflection detail, dust swirls, sky haze.  
Score 8: Subtle foreground shadows, atmospheric depth, cloud wisps.  
Score 9: Realistic shimmer, balanced palette, composition depth.  
Score 10: Dream-scene masterpiece—flawless distortion, rich textures, cinematic desert."
    ]],
    "Medium", 15,
    "Server")

-- === Steampunk (medium) ===
ThemeService:createTheme(
    "Steampunk",
    "",
    [[
"Gear-powered retro-future. Medium demands **visible interconnected gears/pistons**, **Victorian fashion element** (top hat, corset, waistcoat), **steam or smoke**, and **copper/brass highlights**. Airship or cog-filled skyline adds depth.

Score 1: Random gear shapes.  
Score 2: Goggles + gear; no steam.  
Score 3: Outfit w/ goggles, gears, brown palette; flat shading.  
Score 4: Brass tones, steam puff, basic piping.  
Score 5: Interlocking gears, leather straps, reflective metal spots.  
Score 6: Smoke curls, warm light bloom, simple background machinery.  
Score 7: Airship or clock-tower backdrop, multiple metal textures, dynamic pose.  
Score 8: Complex mechanism, polished reflections, depth fog.  
Score 9: Intricate clockwork, textured leather, moody atmosphere.  
Score 10: Concept-art brilliance—rich detail, cohesive lighting, immersive scene."
    ]],
    "Medium", 15,
    "Server")

-- === Nebula (medium) ===
ThemeService:createTheme(
    "Nebula",
    "",
    [[
"Cosmic gas clouds. Must show **minimum three color transitions**, **star density variation** (tiny specks + bright cores), and **depth illusion** (foreground cloud vs distant glow). One silhouetted object (planet, ship) boosts score.

Score 1: Color blotches; no stars.  
Score 2: Two-color cloud, sparse dots.  
Score 3: Three colors, bright core, basic stars.  
Score 4: Soft gradients, star cluster, faint dark pockets.  
Score 5: Layered wisps, highlight edges, planet rim.  
Score 6: Lens flare, shooting star, depth shading.  
Score 7: Dust lanes, color harmony, subtle transparency.  
Score 8: Glowing rim light, varied star sizes, balanced composition.  
Score 9: Hubble-photo vibe—rich depth, nuanced hues, crisp edges.  
Score 10: Gallery piece—flawless blend, luminous highlights, immersive depth."
    ]],
    "Medium", 15,
    "Server")

-- === Circus (medium) ===
ThemeService:createTheme(
    "Circus",
    "",
    [[
"Big-top excitement. Require **striped main tent**, **at least one performer or trained animal**, **audience or decoration** (banners/confetti), and **dynamic lighting** (spotlight or night glow). Colors should be bright and balanced.

Score 1: Tent scribble; nothing else.  
Score 2: Tent + clown; dull colors.  
Score 3: Bright tent stripes, performer, balloons; flat shading.  
Score 4: Spotlights, audience silhouettes, basic depth.  
Score 5: Two active acts (e.g., trapeze + clown), confetti, neat outlines.  
Score 6: Detailed costumes, balanced color palette, ground shadows.  
Score 7: Motion blur, atmospheric haze, textured fabrics.  
Score 8: Multi-ring layout, polished lighting, crowd detail.  
Score 9: Festival poster vibe—rich light effects, detailed props/costumes.  
Score 10: Celebration masterpiece—vibrant lights, full crowd, flawless composition."
    ]],
    "Medium", 15,
    "Server")
end

return ThemeLoader