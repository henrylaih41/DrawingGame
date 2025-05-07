local ServerScriptService = game:GetService("ServerScriptService")
local ThemeService = require(ServerScriptService.modules.ThemeService)

local ThemeLoader = {}

function ThemeLoader:loadThemes()
    ThemeService:createTheme(
        "Mountains", 
        "",
        [[
        Score 1: Page mostly blank or random marks; no recognizable peaks; effort extremely low. Tip: Block in one big triangle so viewers see a mountain.
Score 2: Single rough triangle suggests a hill; missing snowcaps, ridges, or horizon; no color; empty sky. Add: more triangles and outline a horizon line.
Score 3: Basic mountain range (two–three peaks) drawn; uneven lines; one flat color; no depth; sky blank. Next: vary peak sizes and shade one side darker.
Score 4: Peaks show light vs. dark sides; simple snowcaps or trees added; two colors in use; background still bare. Improve: smooth outline and sketch clouds or a river.
Score 5: Three or more colors; clear shading, tree line, and light source; tiny background detail (sun) present; perspective off. Refine: fade colors toward base to add depth.
Score 6: Range has foreground and background peaks; blended colors or gradients; sky with clouds or birds; anatomy good but rocky texture rough. Polish: use broken lines for crags and add cast shadows.
Score 7: Dynamic composition—overlapping peaks, mist layers, river valley; consistent lighting; textures varied (rock, snow, forest); minor proportion slips. Push: soften distant mountains with lighter tones.
Score 8: High detail: crisp ridges, believable shadows, atmospheric depth; rich color blending; compelling background story (sunset hike, cabin). Tweak: highlight edge glow where sun hits peaks.
Score 9: Professional polish; dramatic lighting, foreground trees, midground lake, distant peaks; imaginative twist (crystal peaks, floating islands) executed smoothly; only tiny line bumps. Finish: erase stray marks, deepen reflections.
Score 10: Stunning masterpiece—flawless perspective, cinematic lighting, perfect textures from rocky scree to wispy clouds; captivating narrative scene; poster quality. Judges have no fixes—keep creating!
    ]],
        "Medium", 15, 
        "Server")
    ThemeService:createTheme(
        "Movie", 
        "",
        [[
Score 1: Mostly blank page or random marks—no movie vibe at all. Tip: Sketch a simple clapperboard so people know it’s film-related.
Score 2: Rough outline of one object (film reel, popcorn, etc.)—shape sloppy, no colour, empty background. Tip: Add a second cinema item and trace over lines for cleaner edges.
Score 3: Basic scene with 2–3 items (screen + seats, reel + tickets); flat single colour; no depth. Tip: Shade one side darker and place objects on a ground line for realism.
Score 4: Complete theatre or set: screen, seats, maybe a director’s chair; two colours; small details like play button; perspective off. Tip: Smooth outlines and add a simple backdrop (curtains, stars).
Score 5: Clear composition with characters watching or filming; three+ colours; light source hinted; tiny background detail (exit sign) present. Tip: Fade colour in distance to boost depth.
Score 6: Dynamic camera angle; blended colours or gradients; props (camera tripod, popcorn tubs); sky or wall texture; textures a bit rough. Tip: Use dot/line patterns for carpet, add shadows under chairs.
Score 7: Story moment (hero on red carpet, chase scene); consistent lighting; layered background (crowd, stage lights); minor anatomy slips. Tip: Soften far objects with lighter tones to show distance.
Score 8: High detail: crisp reels, believable shadows, atmospheric lighting (spotlights); rich colour blending; engaging action. Tip: Add rim-light glow on edges touched by spotlights.
Score 9: Pro-level polish; depth from foreground popcorn to distant screen; dramatic lighting (neon, lens flare); fun twist (retro 8-bit cinema) executed cleanly; only tiny line bumps. Tip: Erase stray marks, deepen reflections on shiny metal.
Score 10: Show-stopping masterpiece—flawless perspective, cinematic lighting, perfect textures from velvet seats to wispy smoke; scene tells a full story. Judges can’t suggest fixes—just keep rolling!
    ]],
        "Medium", 15, 
        "Server")
    ThemeService:createTheme(
        "Classroom", 
        "",
        [[
Score 1: Page nearly blank or random marks—nothing says “classroom.” Tip: Draw a big rectangle for the board so viewers know where the lesson happens.
Score 2: One rough object (desk, board, or book); shape wobbly, no color, empty background. Tip: Add a second object and trace over lines for cleaner edges.
Score 3: Two–three items (teacher desk + board + chair); flat single color; no depth or floor line. Tip: Shade one side darker and add a horizon line to ground items.
Score 4: Full room outline with several desks, windows, or door; two colors; small details like chalk. Perspective off. Tip: Smooth outlines and sketch posters, clocks, or a wastebasket for life.
Score 5: Clear layout—rows of desks, teacher’s area, light source hinted; three+ colors; tiny background detail (class rules poster). Tip: Fade color toward back of room to show depth.
Score 6: Depth shown: overlapping desks, blended colors or gradients; props (books, backpack); textures a bit rough. Tip: Add wood-grain lines on desks and shadows under chairs for realism.
Score 7: Story moment (student raising hand, teacher pointing at board); consistent lighting; layered background (windows with trees). Minor anatomy slips. Tip: Soften distant objects with lighter tones and refine hand shapes.
Score 8: High detail: neat desk rows, believable shadows, atmospheric light from windows; rich color blending; engaging scene. Tip: Add rim-light glow where sunlight hits edges and scribbles on notebooks.
Score 9: Pro polish; depth from foreground backpack to far bulletin board; dramatic lighting (sunbeams, projector glow); fun twist (futuristic smartboard) executed cleanly; only tiny line bumps. Tip: Erase stray marks, deepen reflections on glossy floors.
Score 10: Show-stopping masterpiece—flawless perspective, cinematic lighting, perfect textures from tiled ceiling to scuffed floor; scene tells a story (science experiment, group project). Judges can’t suggest fixes—keep shining!
    ]],
        "Medium", 15, 
        "Server")
    ThemeService:createTheme(
        "Sea", 
        "",
        [[
Score 1 - Page mostly blank or random marks; no playground vibe. Tip: Add one simple swing set outline so viewers know the theme.
Score 2 - Single rough structure (slide or swing) with wobbly lines; no color; empty background. Tip: Draw a ground line and color the main object.
Score 3 - Two or three items (slide + swing + seesaw); flat single color; no depth or sky. Tip: Shade undersides darker and add a horizon to anchor everything.
Score 4 - Full play area outline with several pieces; two-three colors; tiny detail like ladder rungs; perspective off. Tip: Smooth outlines and add grass or sandbox border.
Score 5 - Clear layout—multiple structures, kids’ path, hinted light source; three+ colors; small background (clouds, fence). Tip: Fade colors farther back to show distance.
Score 6 - Foreground structure big and detailed; textured ground (wood chips, grass); simple figures (kid or dog); shadows basic. Tip: Dot texture on ground and add shadow beneath each piece.
Score 7 - Story moment (child on swing, race down slide); consistent lighting; layered depth; minor shape slips. Tip: Soften far objects with lighter tones and refine figure limbs.
Score 8 - Detailed equipment with bolts, ropes, realistic shadows; rich color blending; extra scene element (water fountain, picnic table); tiny errors only. Tip: Brighten highlight edges on metal bars.
Score 9 - Pro polish; depth from foreground monkey bars to distant trees; dramatic lighting (sunset glow, lens flare); fun twist (space-themed play set) executed cleanly; minute line bumps. Tip: Erase stray marks and deepen reflections on shiny slides.
Score 10 - Masterpiece—flawless perspective, vibrant colors, cinematic lighting, perfect textures from rubber mat to leafy trees; scene tells a joyful story; nothing to fix—keep creating!
    ]],
        "Medium", 15, 
        "Server")
    ThemeService:createTheme(
        "Playground", 
        "",
        [[
Score 1 - Page mostly blank or random marks; no playground vibe. Tip: Add one simple swing set outline so viewers know the theme.
Score 2 - Single rough structure (slide or swing) with wobbly lines; no color; empty background. Tip: Draw a ground line and color the main object.
Score 3 - Two or three items (slide + swing + seesaw); flat single color; no depth or sky. Tip: Shade undersides darker and add a horizon to anchor everything.
Score 4 - Full play area outline with several pieces; two-three colors; tiny detail like ladder rungs; perspective off. Tip: Smooth outlines and add grass or sandbox border.
Score 5 - Clear layout—multiple structures, kids’ path, hinted light source; three+ colors; small background (clouds, fence). Tip: Fade colors farther back to show distance.
Score 6 - Foreground structure big and detailed; textured ground (wood chips, grass); simple figures (kid or dog); shadows basic. Tip: Dot texture on ground and add shadow beneath each piece.
Score 7 - Story moment (child on swing, race down slide); consistent lighting; layered depth; minor shape slips. Tip: Soften far objects with lighter tones and refine figure limbs.
Score 8 - Detailed equipment with bolts, ropes, realistic shadows; rich color blending; extra scene element (water fountain, picnic table); tiny errors only. Tip: Brighten highlight edges on metal bars.
Score 9 - Pro polish; depth from foreground monkey bars to distant trees; dramatic lighting (sunset glow, lens flare); fun twist (space-themed play set) executed cleanly; minute line bumps. Tip: Erase stray marks and deepen reflections on shiny slides.
Score 10 - Masterpiece—flawless perspective, vibrant colors, cinematic lighting, perfect textures from rubber mat to leafy trees; scene tells a joyful story; nothing to fix—keep creating!
    ]],
        "Medium", 15, 
        "Server")
    ThemeService:createTheme(
        "Playground", 
        "",
        [[
Score 1 - Page is mostly empty or scribbles; the playground idea hasn’t shown up yet.
Score 2 - We spot one playground thing (maybe a lonely swing or slide) but lines are super rough and no color yet.
Score 3 - Two or three simple pieces of gear appear—slide, swing, seesaw—colored with one shade. Shapes still wobbly, background blank.
Score 4 - Whole play space outlined: several structures and a ground line or sky. A couple of colors pop in; details are loose but clear.
Score 5 - Layout makes sense (rows of swings, sandbox corner). At least three colors, a hint of sunlight or shadows, and maybe grass or a fence.
Score 6 - Bigger variety: tall slide up front, smaller stuff behind. Ground texture (wood chips or grass dots), a kid or pet doodled in, colors blended a bit.
Score 7 - Scene tells a tiny story—friends racing down slides, kid mid-swing. Lighting looks consistent, and depth feels real even if proportions are off.
Score 8 - Good detail on equipment (chains, ladder rungs), fun extras like benches or trees, and smoother shading. The whole drawing feels lively.
Score 9 - Very polished: bold colors, clean lines, cool angle (bird’s-eye or low view). Maybe a twist—space-themed jungle gym or rainbow rubber floor. Only small slips visible.
Score 10 - Wow factor! Everything clicks: dynamic composition, bright yet balanced colors, playful textures, and a clear story that grabs attention immediately.
    ]],
        "Easy", 10, 
        "Server")

    ThemeService:createTheme(
        "Cat", 
        "",
        [[
Score 1 - Page nearly blank or random lines—no hint of a kitty. Tip: Draw one circle for the head and two triangles for ears so viewers spot a cat right away.
Score 2 - Basic cat outline (head + body blob); limbs or tail missing; no color; blank background. Tip: Add four legs and a tail, then trace lines for cleaner edges.
Score 3 - Full-body cat with head, body, tail, four legs; single flat color; shapes stiff; background empty. Tip: Curve the spine, bend the tail, and give the face two big eyes for life.
Score 4 - Cat pose looks natural; two–three colors (fur and eyes); tiny detail like whiskers; proportions off. Tip: Smooth outlines and add simple shading on one side for depth.
Score 5 - Clear coat pattern (stripes, spots) or shading; expressive face; small background hint (pillow, grass). Tip: Fade colors on belly and inner ears to add softness.
Score 6 - Dynamic pose—stretching, jumping, curled nap; fur texture implied with short strokes; background props (toy, window) present. Tip: Darken shadow under paws and highlight fur tips for shine.
Score 7 - Scene tells a story (cat pawing yarn, stalking butterfly); consistent lighting; layered depth; minor anatomy slips. Tip: Lighten distant objects and refine paw shapes with tiny claws.
Score 8 - Rich details: layered fur strokes, believable shadows, subtle color blending; environment (sunlit sill, moonlit roof) enhances mood. Tip: Add faint fur direction lines around joints and brighten eye highlights.
Score 9 - Polished composition—foreground whiskers sharp, midground cat body, soft background; dramatic lighting (sunbeam, neon glow); fun twist (cyber-cat armor) executed cleanly. Tip: Erase stray sketch marks and deepen reflections in eyes or metal.
Score 10 - Purr-fect masterpiece—flawless anatomy, silky fur rendering, cinematic lighting, engaging narrative; every element intentional from claw scratches to reflected highlights. Judges can’t suggest improvements—just keep prowling!
    ]],
        "Medium", 15, 
        "Server")
    ThemeService:createTheme(
        "Cat", 
        "",
        [[
Score 1 – Page pretty much blank or random scribbles—no cat energy yet.
Score 2 – One quick shape (circle + ears) hints at a kitty, but that’s it—no face, no color.
Score 3 – Full kitty outline (head, body, tail) appears. Lines shaky, no shading, background empty.
Score 4 – Kitty has a cute face and maybe whiskers or stripes. One or two colors pop in.
Score 5 – Pose feels natural (sitting, stretching). Three-ish colors, tiny detail like paw pads or a toy.
Score 6 – Fun vibe: playful tail curl, basic shading, small background (pillow, grass).
Score 7 – Story moment—cat chasing yarn or napping in sun. Colors blend a bit, lighting makes sense.
Score 8 – Nice fur texture or pattern, bright eyes, extra props (butterfly, window sill). Everything ties together.
Score 9 – Polished piece: clean lines, bold colors, cool angle (close-up or dramatic side view). Almost nothing looks off.
Score 10 – Total show-stopper—instantly reads “cat,” oozes personality, great colors and shading, feels ready for a poster.
    ]],
        "Easy", 10, 
        "Server")
    ThemeService:createTheme(
        "Cat", 
        "",
        [[
Score 1 – Page pretty much blank or random scribbles—no cat energy yet.
Score 2 – One quick shape (circle + ears) hints at a kitty, but that’s it—no face, no color.
Score 3 – Full kitty outline (head, body, tail) appears. Lines shaky, no shading, background empty.
Score 4 – Kitty has a cute face and maybe whiskers or stripes. One or two colors pop in.
Score 5 – Pose feels natural (sitting, stretching). Three-ish colors, tiny detail like paw pads or a toy.
Score 6 – Fun vibe: playful tail curl, basic shading, small background (pillow, grass).
Score 7 – Story moment—cat chasing yarn or napping in sun. Colors blend a bit, lighting makes sense.
Score 8 – Nice fur texture or pattern, bright eyes, extra props (butterfly, window sill). Everything ties together.
Score 9 – Polished piece: clean lines, bold colors, cool angle (close-up or dramatic side view). Almost nothing looks off.
Score 10 – Total show-stopper—instantly reads “cat,” oozes personality, great colors and shading, feels ready for a poster.
    ]],
        "Easy", 10, 
        "Server")
    ThemeService:createTheme(
        "Candies", 
        "",
        [[
Score 1 – Page mostly blank or random marks—no sugar rush yet.
Score 2 – One quick candy shape (maybe a circle with a wrapper twist) but no color or detail.
Score 3 – A few sweets show up—tiny lollipop, jellybean, gumdrop—flat single color, no background.
Score 4 – Candies are clearer with wrappers, stripes, or shine spots; two colors pop; lines still wobbly.
Score 5 – Mixed candy pile or neat row; three+ bright colors; little detail like sprinkle dots or swirls.
Score 6 – Fun vibe: glossy highlights, simple shadows, maybe a candy bowl or trick-or-treat bag.
Score 7 – Mini story—candy spilling, being unwrapped, or stacked into a tower; colors blend smoothly.
Score 8 – Tasty textures (sugar crystals, chocolate drizzle), playful background (confetti, stripes). Everything ties together sweetly.
Score 9 – Polished and vibrant: clean outlines, bold shading, cool angle (close-up gummy bear or rainbow candy path). Hardly any slips.
Score 10 – Mouth-watering masterpiece—instantly screams “candy shop,” killer color harmony, dynamic composition ready for a poster.
    ]],
        "Easy", 10, 
        "Server")
    ThemeService:createTheme(
        "Icecream", 
        "",
        [[
Score 1 – Page almost empty or random scribbles—no ice-cream flavor yet.
Score 2 – One rough cone or scoop shape appears, but no color or toppings.
Score 3 – Full cone (or cup) with a single scoop; flat color; background blank.
Score 4 – Extra scoops or simple toppings (cherry, syrup stripe); two colors pop; lines still shaky.
Score 5 – Clear dessert: waffle texture, melting edge, three+ bright colors; tiny detail like sprinkles.
Score 6 – Fun vibe: drippy syrup, simple shadow under cone, maybe a napkin or spoon nearby.
Score 7 – Mini story—ice-cream tipping over, being shared, or stacked high; colors blend smoothly.
Score 8 – Tasty textures (waffle crunch, creamy swirls, glossy syrup), playful background (sunburst, neon stripes). Everything ties together sweetly.
Score 9 – Polished and vibrant: clean outlines, bold highlights, cool angle (close-up drip or tall sundae tower). Hardly any slips.
Score 10 – Mouth-watering masterpiece—instantly screams “ice-cream parlor,” perfect color harmony, dynamic composition ready for a poster.
    ]],
        "Easy", 10, 
        "Server")
end

return ThemeLoader