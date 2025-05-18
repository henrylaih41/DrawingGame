local ServerScriptService = game:GetService("ServerScriptService")
local ThemeService = require(ServerScriptService.modules.ThemeService)

local ThemeLoader = {}

function ThemeLoader:loadThemes()
    -- =========================
    -- === 1. Bedroom Workspace ===
    -- =========================
    ThemeService:createTheme(
        "Bedroom Workspace",
        "",
        [[
"Personal study area. Easy grading focuses on basic shapes and recognizable furniture.
Score 1 Outline only; unrecognizable shapes.
Score 2 Bed or desk recognizable; minimal color.
Score 3 Basic perspective; simple colors.
Score 4 Add chair, monitor, or lamp; minimal shading.
Score 5 Consistent proportions; simple textures.
Score 6 Wall poster or shelves; light source implied.
Score 7 Floor pattern, window, or rug; basic shading.
Score 8 Neat arrangement of items; mild shadows.
Score 9 Texture on furniture, balanced composition.
Score 10 Polished room scene—clear perspective and good lighting."
        ]],
        "Easy", 20,
        "Server")

    -- =========================
    -- === 2. Coffee Shop ===
    -- =========================
    ThemeService:createTheme(
        "Coffee Shop",
        "",
        [[
"Cozy cafe environment. Easy scoring checks for tables, counter, and warm colors.
Score 1 Scribbles only; no clear objects.
Score 2 Table or counter outline; flat colors.
Score 3 Chairs and mugs recognizable; simple layout.
Score 4 Menu board or display case; minimal shading.
Score 5 Consistent proportions, light source clear.
Score 6 Windows or plants added; color variety.
Score 7 People seated, steam from cups, basic shadows.
Score 8 Wall art or shelves, floor texture.
Score 9 Textured furniture, balanced composition.
Score 10 Inviting cafe scene—good lighting and perspective."
        ]],
        "Easy", 20,
        "Server")

    -- =========================
    -- === 3. High School Classroom ===
    -- =========================
    ThemeService:createTheme(
        "High School Classroom",
        "",
        [[
"Familiar learning space. Easy grading focuses on desks, board, and windows.
Score 1 Empty room; unclear shapes.
Score 2 Teacher desk or chalkboard; flat color.
Score 3 Rows of desks; simple perspective.
Score 4 Posters or lockers; minimal shading.
Score 5 Consistent wall and floor lines.
Score 6 Students seated, books on desks.
Score 7 Window scene or clock; basic lighting.
Score 8 Noticeable shadows and highlights.
Score 9 Detailed furniture, balanced layout.
Score 10 Realistic classroom—clean lines and clear lighting."
        ]],
        "Easy", 20,
        "Server")

    -- =========================
    -- === 4. Grocery Store ===
    -- =========================
    ThemeService:createTheme(
        "Grocery Store",
        "",
        [[
"Aisles of products. Easy grading looks for shelves and shopping carts.
Score 1 Rectangle shapes only.
Score 2 Shelves or cart outline; flat shading.
Score 3 Produce section or signs; simple colors.
Score 4 Cash register or checkout lane.
Score 5 Consistent perspective of aisles.
Score 6 Variety of items on shelves.
Score 7 Shoppers pushing carts; basic shadows.
Score 8 Floor reflections, hanging lights.
Score 9 Detailed product labels, balanced space.
Score 10 Bustling grocery scene—clear layout and lighting."
        ]],
        "Easy", 20,
        "Server")

    -- =========================
    -- === 5. City Park Picnic ===
    -- =========================
    ThemeService:createTheme(
        "City Park Picnic",
        "",
        [[
"Outdoor meal under trees. Easy scoring checks for blanket, basket, and greenery.
Score 1 Blank field; no objects.
Score 2 Blanket outline; simple sky.
Score 3 Basket and food shapes; flat color.
Score 4 Trees or benches; minimal shading.
Score 5 Consistent horizon, path or pond.
Score 6 People sitting, simple shadows.
Score 7 Flowers, pets, or playground.
Score 8 Sunlight direction, varied colors.
Score 9 Textured grass and trees, balanced composition.
Score 10 Relaxing picnic scene—good perspective and lighting."
        ]],
        "Easy", 20,
        "Server")

    -- =========================
    -- === 6. Fast Food Meal ===
    -- =========================
    ThemeService:createTheme(
        "Fast Food Meal",
        "",
        [[
"Burger and fries style meal. Easy grading focuses on recognizable food shapes.
Score 1 Scribbles only; no food shapes.
Score 2 Burger or fries outline; flat color.
Score 3 Drink cup added; simple shading.
Score 4 Tray or table surface; ketchup or sauce.
Score 5 Consistent proportions, basic textures.
Score 6 Wrapper details, straw, napkin.
Score 7 Condiments or side items, basic reflections.
Score 8 Steam or melted cheese effect.
Score 9 Crisp textures and balanced composition.
Score 10 Tasty-looking meal—clear lighting and color."
        ]],
        "Easy", 20,
        "Server")

    -- =========================
    -- === 7. Movie Night at Home ===
    -- =========================
    ThemeService:createTheme(
        "Movie Night at Home",
        "",
        [[
"Watching films with snacks. Easy grading looks for couch, screen, and popcorn.
Score 1 Empty shapes; no clear setting.
Score 2 Couch or TV outline; flat color.
Score 3 Remote or snack bowl; simple perspective.
Score 4 Other furniture like coffee table.
Score 5 Consistent wall lines; simple shadows.
Score 6 People seated, blanket or pillows.
Score 7 Glow from screen, dim lighting.
Score 8 Additional decor such as posters.
Score 9 Textured fabric and balanced layout.
Score 10 Cozy movie scene—good lighting and detail."
        ]],
        "Easy", 20,
        "Server")

    -- =========================
    -- === 8. Pet Walking ===
    -- =========================
    ThemeService:createTheme(
        "Pet Walking",
        "",
        [[
"Taking a pet for a walk. Easy scoring checks for leash and simple background.
Score 1 Stick figures only.
Score 2 Pet shape and person; no detail.
Score 3 Leash visible; flat colors.
Score 4 Trees or houses along path.
Score 5 Consistent proportions; ground line.
Score 6 Collar or harness; basic shadows.
Score 7 Additional people or pets.
Score 8 Sky gradient, simple textures.
Score 9 Textured fur and clothing.
Score 10 Pleasant walk scene—balanced composition and lighting."
        ]],
        "Easy", 20,
        "Server")

    -- =========================
    -- === 9. Beach Day ===
    -- =========================
    ThemeService:createTheme(
        "Beach Day",
        "",
        [[
"Fun near the ocean. Easy grading focuses on sand, waves, and sun.
Score 1 Blank shoreline; no detail.
Score 2 Umbrella or towel; flat colors.
Score 3 Waves or surfboard; simple shading.
Score 4 Palm trees, shells, or beach ball.
Score 5 Horizon line and sun placement.
Score 6 People swimming, footprints.
Score 7 Shadows from umbrellas, color variety.
Score 8 Reflections on water, distant boats.
Score 9 Textured sand and water.
Score 10 Vibrant beach scene—clear lighting and perspective."
        ]],
        "Easy", 20,
        "Server")

    -- =========================
    -- === 10. Shopping Mall ===
    -- =========================
    ThemeService:createTheme(
        "Shopping Mall",
        "",
        [[
"Indoor mall with stores. Easy scoring checks for shop fronts and hallways.
Score 1 Blocky shapes only.
Score 2 Shop windows or sign; flat colors.
Score 3 Mannequins or posters; simple perspective.
Score 4 Floor tiles or escalator.
Score 5 Correct ceiling height; simple shadows.
Score 6 Shoppers walking, benches or plants.
Score 7 Store displays, bags in hand.
Score 8 Reflections on polished floor.
Score 9 Detailed signage and lighting effects.
Score 10 Bustling mall scene—good perspective and color."
        ]],
        "Easy", 20,
        "Server")

    -- =========================
    -- === 11. Skate Park ===
    -- =========================
    ThemeService:createTheme(
        "Skate Park",
        "",
        [[
"Ramps and rails for tricks. Medium grading checks motion, perspective, and detailed surroundings.
Score 1 Flat ground only; no features.
Score 2 Simple ramp shapes; rough lines.
Score 3 Rider outline on board; flat colors.
Score 4 Multiple ramps, basic perspective.
Score 5 Graffiti or fencing, simple shadows.
Score 6 Dynamic pose, wheels visible, ramp textures.
Score 7 Background buildings or trees, light source clear.
Score 8 Motion lines, crowd details, varied materials.
Score 9 Accurate perspective and shading across scene.
Score 10 Energetic skate park—polished action and environment."
        ]],
        "Medium", 20,
        "Server")

    -- =========================
    -- === 12. Soccer Match ===
    -- =========================
    ThemeService:createTheme(
        "Soccer Match",
        "",
        [[
"Competitive game in action. Medium scoring emphasizes player poses and field details.
Score 1 Doodle goal and field; no players.
Score 2 Players stick figures; flat green.
Score 3 Ball and goalposts defined; simple perspective.
Score 4 Two teams in position; minimal shading.
Score 5 Lines on field and crowd shapes.
Score 6 Dynamic kicking poses; jersey colors.
Score 7 Shadows on grass, motion cues, scoreboard.
Score 8 Detailed uniforms, audience reactions.
Score 9 Correct perspective and lighting throughout.
Score 10 Dramatic match scene—realistic movement and crowd energy."
        ]],
        "Medium", 20,
        "Server")

    -- =========================
    -- === 13. Music Festival Stage ===
    -- =========================
    ThemeService:createTheme(
        "Music Festival Stage",
        "",
        [[
"Outdoor concert with lights and crowd. Medium grading evaluates lighting effects and stage detail.
Score 1 Simple stage block; no instruments.
Score 2 Microphone or speakers; blank crowd.
Score 3 Band members shown; flat colors.
Score 4 Stage lights and screens; simple perspective.
Score 5 Audience silhouettes, minimal shading.
Score 6 Light beams, instrument detail, banners.
Score 7 Smoke effects or confetti, varied colors.
Score 8 Dynamic camera angle, hands in crowd.
Score 9 Strong lighting contrast, polished equipment.
Score 10 Festival atmosphere—vibrant lights and detailed performance."
        ]],
        "Medium", 20,
        "Server")

    -- =========================
    -- === 14. Arcade Hangout ===
    -- =========================
    ThemeService:createTheme(
        "Arcade Hangout",
        "",
        [[
"Row of game machines buzzing with players. Medium scoring covers reflections and neon glow.
Score 1 Empty room; no machines.
Score 2 Simple cabinet outlines; flat color.
Score 3 Players at machines, joystick shapes.
Score 4 Ticket counter or prize shelf; basic perspective.
Score 5 Screen graphics and buttons; slight glow.
Score 6 Varied cabinet designs, carpet texture.
Score 7 Reflective surfaces, overhead lights, crowd detail.
Score 8 Dynamic lighting from screens, scattered tickets.
Score 9 Accurate perspective and shading across floor.
Score 10 Immersive arcade scene—bright colors and lively atmosphere."
        ]],
        "Medium", 20,
        "Server")

    -- =========================
    -- === 15. City Bus Ride ===
    -- =========================
    ThemeService:createTheme(
        "City Bus Ride",
        "",
        [[
"Passengers traveling across town. Medium grading focuses on interior perspective and character details.
Score 1 Boxy bus shape; empty interior.
Score 2 Rows of seats; flat color.
Score 3 Simple driver and passengers; rough lines.
Score 4 Windows showing buildings; minimal shading.
Score 5 Handrails and signage; consistent proportions.
Score 6 Seated and standing figures, bag details.
Score 7 Shadows and reflections on windows.
Score 8 Dynamic viewpoint, outside scenery blurred.
Score 9 Polished character poses and lighting.
Score 10 Realistic transit scene—balanced perspective and atmosphere."
        ]],
        "Medium", 20,
        "Server")

    -- =========================
    -- === 16. Road Trip ===
    -- =========================
    ThemeService:createTheme(
        "Road Trip",
        "",
        [[
"Car journey through open landscape. Medium scoring highlights perspective, scenery, and motion.
Score 1 Plain car outline; featureless road.
Score 2 Wheels and windows; flat colors.
Score 3 Distant hills or signs; basic perspective.
Score 4 Driver and passengers; simple shading.
Score 5 Motion lines, lane markings, horizon.
Score 6 Luggage on roof or gas station, sky detail.
Score 7 Reflections on car, trailing dust.
Score 8 Dynamic angle, variety of scenery.
Score 9 Consistent perspective and lighting effects.
Score 10 Adventurous road trip—polished car and vibrant landscape."
        ]],
        "Medium", 20,
        "Server")

    -- =========================
    -- === 17. Gym Workout ===
    -- =========================
    ThemeService:createTheme(
        "Gym Workout",
        "",
        [[
"People exercising with equipment. Medium grading evaluates anatomy and machine detail.
Score 1 Empty room or stick figures.
Score 2 Dumbbell or treadmill shape; flat colors.
Score 3 One person lifting; simple background.
Score 4 Multiple machines and mats; minimal shading.
Score 5 Correct body proportions, mirror or clock.
Score 6 Sweat or effort cues, equipment labels.
Score 7 Reflections in mirrors, varied poses.
Score 8 Lighting from overhead fixtures, floor texture.
Score 9 Balanced composition with accurate anatomy.
Score 10 Dynamic workout scene—realistic figures and gym detail."
        ]],
        "Medium", 20,
        "Server")

    -- =========================
    -- === 18. Camping Trip ===
    -- =========================
    ThemeService:createTheme(
        "Camping Trip",
        "",
        [[
"Tents and campfire in nature. Medium scoring includes lighting from fire and layered scenery.
Score 1 Simple tent scribble; no background.
Score 2 Campfire or log seats; flat colors.
Score 3 Trees or mountains; basic perspective.
Score 4 People around fire; minimal shading.
Score 5 Sleeping bags, cooking gear, starry sky.
Score 6 Light glow on faces, smoke rising.
Score 7 Depth with foreground trees, path or water.
Score 8 Dynamic shadows, varied textures in foliage.
Score 9 Polished lighting and perspective across scene.
Score 10 Memorable camp moment—warm firelight and detailed surroundings."
        ]],
        "Medium", 20,
        "Server")

    -- =========================
    -- === 19. Amusement Park ===
    -- =========================
    ThemeService:createTheme(
        "Amusement Park",
        "",
        [[
"Thrilling rides and bright lights. Medium grading checks perspective, crowds, and motion effects.
Score 1 Random shapes; no rides.
Score 2 Ferris wheel or roller coaster outline; flat color.
Score 3 Ticket booth or path; simple perspective.
Score 4 Riders in seats, simple shading.
Score 5 Multiple attractions, color variety.
Score 6 Light strings, flags, or balloons, shadows.
Score 7 Crowd depth, reflections on metal.
Score 8 Dynamic angle, motion blur, smoke or sparks.
Score 9 Balanced composition with rich detail.
Score 10 Exciting park scene—vibrant lighting and energetic atmosphere."
        ]],
        "Medium", 20,
        "Server")

    -- =========================
    -- === 20. Rooftop Party ===
    -- =========================
    ThemeService:createTheme(
        "Rooftop Party",
        "",
        [[
"Night celebration above the city. Medium scoring emphasizes lighting, crowd detail, and skyline.
Score 1 Building roof outline only.
Score 2 Simple tables or speakers; flat colors.
Score 3 Guests standing; minimal background.
Score 4 City skyline hints; basic perspective.
Score 5 String lights or lanterns; simple shadows.
Score 6 Music equipment, food table, rooftop rails.
Score 7 Dynamic poses, colorful lighting, balloons.
Score 8 Skyline detail, starry sky, depth cues.
Score 9 Reflections on glass, balanced composition.
Score 10 Lively rooftop scene—polished lighting and city backdrop."
        ]],
        "Medium", 20,
        "Server")
end

return ThemeLoader
