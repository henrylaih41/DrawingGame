local ServerScriptService = game:GetService("ServerScriptService")
local ThemeService = require(ServerScriptService.modules.ThemeService)

local ThemeLoader = {}

function ThemeLoader:loadThemes()
    -- =========================
-- === 1. Skate Park =========
-- =========================
    ThemeService:createTheme(
        "Skate Park",
        "",
        [[
"Skateboarders catching air in the park. Easy mode focuses on energy and basic perspective.
Score 1  Random lines; no ramps or boards.
Score 2  Ramp shape and board; flat background.
Score 3  One rider drawn; colors basic.
Score 4  Multiple ramps, small crowd; simple shading.
Score 5  Proper board shape, rail or stairs.
Score 6  Show motion lines and shadows.
Score 7  Background buildings or trees; perspective aligned.
Score 8  Detailed skate gear and graffiti.
Score 9  Dynamic poses, layered depth, consistent lighting.
Score 10 Vibrant park scene with polished details."
        ]],
        "Easy", 20,
        "Server")

    -- =========================
-- === 2. Retro Arcade ========
-- =========================
    ThemeService:createTheme(
        "Retro Arcade",
        "",
        [[
"Step into a classic game hall. Easy scoring values recognizable machines and bright screens.
Score 1  Box shapes; no screens.
Score 2  Single cabinet outline; blank screen.
Score 3  Add joystick and buttons; simple color.
Score 4  Row of machines, gamer silhouette; shading minimal.
Score 5  Glowing screens, carpet pattern.
Score 6  Neon sign or token counter; perspective ok.
Score 7  Characters playing, screen graphics.
Score 8  Reflections, background posters, multiple colors.
Score 9  Depth and textures, consistent light.
Score 10 Immersive arcade with lively atmosphere."
        ]],
        "Easy", 20,
        "Server")

    -- =========================
-- === 3. Urban Graffiti Alley ==
-- =========================
    ThemeService:createTheme(
        "Urban Graffiti Alley",
        "",
        [[
"City alley covered in art. Easy grading checks wall perspective and graffiti style.
Score 1  Blank wall; no graffiti.
Score 2  Simple tag shapes; flat pavement.
Score 3  Add spray cans, minimal color.
Score 4  Perspective correct, small details.
Score 5  Layered graffiti text and shapes.
Score 6  Background buildings, light shading.
Score 7  Shadows, ground litter, more color.
Score 8  Character sketching, depth cues.
Score 9  Dynamic composition, textured bricks.
Score 10 Vibrant alley with rich graffiti art."
        ]],
        "Easy", 20,
        "Server")

    -- =========================
-- === 4. Fantasy Dragon Hatchery ==
-- =========================
    ThemeService:createTheme(
        "Fantasy Dragon Hatchery",
        "",
        [[
"Baby dragons emerging from eggs. Easy scoring looks for cute poses and warm lighting.
Score 1  Egg scribble; no dragon.
Score 2  Egg with cracks, nest lines.
Score 3  Baby dragon outline; plain background.
Score 4  Nest texture, simple shading.
Score 5  Multiple eggs, small props.
Score 6  Warm lighting, scales visible.
Score 7  Background cave or forest.
Score 8  Detailed hatchling expressions.
Score 9  Atmospheric depth, dynamic poses.
Score 10 Storybook hatchery with polished detail."
        ]],
        "Easy", 20,
        "Server")

    -- =========================
-- === 5. Magic Academy Classroom ==
-- =========================
    ThemeService:createTheme(
        "Magic Academy Classroom",
        "",
        [[
"Students practicing spells indoors. Easy guidelines emphasize layout and simple effects.
Score 1  Boxy room; no magic.
Score 2  Desks and chalkboard; flat color.
Score 3  Student outlines, simple wands.
Score 4  Books and potions on desks; shading minimal.
Score 5  Windows or banners added; perspective correct.
Score 6  Glowing spell effects, shadows.
Score 7  Background shelves or animals.
Score 8  Multiple light sources, textured surfaces.
Score 9  Detailed robes, dynamic composition.
Score 10 Enchanting classroom with rich color and depth."
        ]],
        "Easy", 20,
        "Server")

    -- =========================
-- === 6. Futuristic Hoverboard Race ==
-- =========================
    ThemeService:createTheme(
        "Futuristic Hoverboard Race",
        "",
        [[
"High-speed competition on hoverboards. Medium mode demands motion and tech detail.
Score 1  Scribble shapes; no riders.
Score 2  Single board outline; plain ground.
Score 3  Rider posture awkward, limited color.
Score 4  Multiple racers, basic perspective.
Score 5  Speed lines, simple track or city skyline.
Score 6  Lighting effects on boards, shadows.
Score 7  Background crowd or obstacles, dynamic angle.
Score 8  Detailed gear, reflections, sense of motion.
Score 9  Atmospheric depth with lights and particles.
Score 10 High-energy race scene, polished anatomy, complex shading."
        ]],
        "Medium", 20,
        "Server")

    -- =========================
-- === 7. K-Pop Concert ==========
-- =========================
    ThemeService:createTheme(
        "K-Pop Concert",
        "",
        [[
"Colorful performers on stage. Medium scoring checks crowd energy and lighting.
Score 1  Stick figures; no stage.
Score 2  Stage outline with speakers; flat color.
Score 3  Performers drawn, minimal lighting.
Score 4  Audience row, simple background.
Score 5  Spotlights, microphone stands, perspective solid.
Score 6  Colorful outfits, glow sticks, stage effects.
Score 7  Depth with crowd silhouettes, dynamic poses.
Score 8  Screens or pyrotechnics, multiple light sources.
Score 9  Detailed expressions, textured costumes, atmospheric haze.
Score 10 Concert poster quality with dramatic lighting and energy."
        ]],
        "Medium", 20,
        "Server")

    -- =========================
-- === 8. Superhero Hangout ======
-- =========================
    ThemeService:createTheme(
        "Superhero Hangout",
        "",
        [[
"Heroes relaxing between missions. Easy scoring values costumes and basic setting.
Score 1  Generic shapes; no characters.
Score 2  Single hero silhouette; plain room.
Score 3  Group outline, minimal furniture.
Score 4  Emblems and color on suits; shading basic.
Score 5  Background monitors or gadgets.
Score 6  Consistent perspective, dynamic poses.
Score 7  Lighting highlights, hero props.
Score 8  Detailed costumes, small sidekicks.
Score 9  Depth layering, reflections, color harmony.
Score 10 Comic-ready hero lounge with polished detail."
        ]],
        "Easy", 20,
        "Server")

    -- =========================
-- === 9. Street Food Market ====
-- =========================
    ThemeService:createTheme(
        "Street Food Market",
        "",
        [[
"Busy vendors cooking outdoors. Easy guidelines focus on crowd layout and warm color.
Score 1  Empty street; no stalls.
Score 2  Simple stall shapes, people missing.
Score 3  Add vendor and food signs, basic color.
Score 4  Multiple stalls, shading minimal.
Score 5  Food detail, crowd silhouettes.
Score 6  Warm lighting, tents or umbrellas.
Score 7  Depth with tables and chairs.
Score 8  Steam or smoke effects, color variety.
Score 9  Textured ground and stalls, dynamic scene.
Score 10 Bustling market with vibrant atmosphere."
        ]],
        "Easy", 20,
        "Server")


    -- =========================
-- === 10. Music Festival Stage ===
-- =========================
    ThemeService:createTheme(
        "Music Festival Stage",
        "",
        [[
"Outdoor concert packed with fans. Medium mode requires complex lighting and perspective.
Score 1  Simple stage line; no equipment.
Score 2  Speakers and mic stands; flat color.
Score 3  Performers outlined, minimal backdrop.
Score 4  Crowd shapes and simple shading.
Score 5  Lighting rigs, banners, perspective set.
Score 6  Colorful stage lights, instrument details.
Score 7  Audience hands raised, depth layering.
Score 8  Smoke effects, multiple performers, dynamic angles.
Score 9  Rich textures, complex lighting, balanced composition.
Score 10 Concert scene worthy of promotional art."
        ]],
        "Medium", 20,
        "Server")

    -- =========================
-- === 11. Cosplay Convention ===
-- =========================
    ThemeService:createTheme(
        "Cosplay Convention",
        "",
        [[
"Fans dressed as favorite characters. Medium scoring checks costume detail and crowd layout.
Score 1  Stick figure; no costumes.
Score 2  Booth outlines, plain background.
Score 3  Attendees in simple outfits; minimal color.
Score 4  Vendor tables, signage, basic shading.
Score 5  Accurate costumes, props, perspective correct.
Score 6  Crowd variety, lighting consistent.
Score 7  Background banners, textured floor.
Score 8  Detailed characters, dynamic poses.
Score 9  Depth of field with crowd, reflection on props.
Score 10 Showcase-level scene with vibrant energy."
        ]],
        "Medium", 20,
        "Server")

    -- =========================
-- === 12. Robot Companion Workshop ===
-- =========================
    ThemeService:createTheme(
        "Robot Companion Workshop",
        "",
        [[
"Building friendly robots in a shop. Medium mode emphasizes machinery and light sources.
Score 1  Boxes and gears; no robot.
Score 2  Simple robot shape; flat shading.
Score 3  Workbench and tools, limited color.
Score 4  Multiple robot parts, perspective aligned.
Score 5  Cable detail, small screens or monitors.
Score 6  Light sources, shadows, metal textures.
Score 7  Technician figure, dynamic layout.
Score 8  Moving arms or sparks, layered background.
Score 9  Intricate mechanical detail, color harmony.
Score 10 Polished workshop scene with lively storytelling."
        ]],
        "Medium", 20,
        "Server")

    -- =========================
-- === 13. Virtual Reality Battle ===
-- =========================
    ThemeService:createTheme(
        "Virtual Reality Battle",
        "",
        [[
"Gamers dueling inside a digital arena. Medium scoring values special effects and action poses.
Score 1  Random shapes; no characters.
Score 2  Headset outlines, plain grid.
Score 3  Two players facing off, simple color.
Score 4  Weapons or spells, basic shading.
Score 5  Virtual arena features, perspective set.
Score 6  Light effects, dynamic poses, shadows.
Score 7  Background spectators or interface graphics.
Score 8  Particle effects, motion blur, depth.
Score 9  Detailed armor and environment, color contrast.
Score 10 Intense VR clash with refined lighting."
        ]],
        "Medium", 20,
        "Server")

    -- =========================
-- === 14. Cyberpunk Street Market ===
-- =========================
    ThemeService:createTheme(
        "Cyberpunk Street Market",
        "",
        [[
"Neon-lit vendors in a futuristic alley. Medium guidelines cover atmosphere and crowded layouts.
Score 1  Boxy stalls; dull colors.
Score 2  Neon sign shapes, blank street.
Score 3  Vendors and shoppers, minimal shading.
Score 4  Perspective lines, simple reflections.
Score 5  Glowing lights, cables, color variety.
Score 6  Fog or rain effects, layered depth.
Score 7  Holograms, cluttered props, strong contrast.
Score 8  Dynamic viewpoint, detailed costumes.
Score 9  Rich textures, atmospheric lighting, balanced layout.
Score 10 Cinematic cyberpunk scene bursting with detail."
        ]],
        "Medium", 20,
        "Server")

    -- =========================
-- === 15. Haunted Carnival =======
-- =========================
    ThemeService:createTheme(
        "Haunted Carnival",
        "",
        [[
"Abandoned rides with ghostly vibes. Medium scoring looks for eerie lighting and detailed props.
Score 1  Tent scribble; no eerie feel.
Score 2  Ferris wheel outline, flat background.
Score 3  Ghost shapes, minimal shading.
Score 4  Broken rides, dim lights.
Score 5  Accurate perspective, spooky color palette.
Score 6  Fog effects, detailed props, shadows.
Score 7  Creepy characters, layered depth.
Score 8  Dramatic lighting, tattered banners.
Score 9  Complex textures, chilling mood.
Score 10 Poster-worthy haunted carnival scene."
        ]],
        "Medium", 20,
        "Server")

    -- =========================
-- === 16. Mermaid Lagoon =======
-- =========================
    ThemeService:createTheme(
        "Mermaid Lagoon",
        "",
        [[
"Underwater paradise for merfolk. Easy grading checks fluid shapes and bright colors.
Score 1  Blob shapes; no mermaid.
Score 2  Mermaid outline, flat water.
Score 3  Simple coral or rocks, minimal color.
Score 4  Flowing hair, basic shading.
Score 5  Multiple mermaids or fish.
Score 6  Sunlight rays, seaweed detail.
Score 7  Bubbles and shells, perspective.
Score 8  Water reflections, vibrant palette.
Score 9  Textured scales and environment.
Score 10 Enchanting lagoon with polished lighting."
        ]],
        "Easy", 20,
        "Server")

    -- =========================
-- === 17. Space Exploration Rover ==
-- =========================
    ThemeService:createTheme(
        "Space Exploration Rover",
        "",
        [[
"Mechanical rover exploring another planet. Medium scoring highlights machinery and atmosphere.
Score 1  Circle or box; no wheels.
Score 2  Rover outline, plain terrain.
Score 3  Wheels and antenna, simple color.
Score 4  Tracks or rocks, perspective okay.
Score 5  Planet horizon, shading direction.
Score 6  Dust effects, panel detail.
Score 7  Background stars or distant base.
Score 8  Reflections on metal, dynamic angle.
Score 9  Intricate machinery, atmospheric depth.
Score 10 Professional sci-fi scene with realistic lighting."
        ]],
        "Medium", 20,
        "Server")

    -- =========================
-- === 18. Zombie Survival Base ===
-- =========================
    ThemeService:createTheme(
        "Zombie Survival Base",
        "",
        [[
"Defenders hold off the undead. Medium mode focuses on tension and environmental detail.
Score 1  Square fort; no zombies.
Score 2  Simple barricade, flat color.
Score 3  Survivors with weapons, minimal shading.
Score 4  Zombies approaching, perspective correct.
Score 5  Lighting from fires or lamps, debris.
Score 6  Layered defenses, texture detail.
Score 7  Dynamic poses, ominous sky.
Score 8  Blood splatters, fog or smoke.
Score 9  Balanced composition with depth.
Score 10 Intense survival scene with dramatic lighting."
        ]],
        "Medium", 20,
        "Server")

    -- =========================
-- === 19. Road Trip Adventure ===
-- =========================
    ThemeService:createTheme(
        "Road Trip Adventure",
        "",
        [[
"Friends driving across the country. Easy scoring values fun details and simple perspective.
Score 1  Box car; blank road.
Score 2  Car with wheels, simple line horizon.
Score 3  Add driver and passenger; basic color.
Score 4  Road signs or scenery; shading minimal.
Score 5  Consistent perspective, sky gradient.
Score 6  Luggage on roof, roadside details.
Score 7  Depth with background mountains or city.
Score 8  Motion lines, reflections, small animals.
Score 9  Textured car and environment, balanced composition.
Score 10 Fun road trip scene with vibrant detail."
        ]],
        "Easy", 20,
        "Server")

    -- =========================
-- === 20. Gaming Stream Setup ===
-- =========================
    ThemeService:createTheme(
        "Gaming Stream Setup",
        "",
        [[
"Desk ready for live streaming. Easy grading checks perspective and equipment detail.
Score 1  Monitor outline; no desk.
Score 2  Desk shape, chair scribble.
Score 3  Keyboard and mouse added; flat color.
Score 4  Streaming camera or mic, simple shading.
Score 5  Background posters, correct perspective.
Score 6  RGB lighting, wire details, shadows.
Score 7  Multiple screens, chat overlay hint.
Score 8  Character with headset, depth cues.
Score 9  Reflections on monitors, textured equipment.
Score 10 Professional streaming setup with balanced lighting."
        ]],
        "Easy", 20,
        "Server")
end

return ThemeLoader
