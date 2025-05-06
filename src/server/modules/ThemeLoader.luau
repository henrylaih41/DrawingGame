local ServerScriptService = game:GetService("ServerScriptService")
local ThemeService = require(ServerScriptService.modules.ThemeService)

local ThemeLoader = {}

function ThemeLoader:loadThemes()
    ThemeService:createTheme(
        "Dog", 
        "Draw your favorite dog!",
        [[
    Score 1: Page is almost blank or random lines that don't look like a dog. Little to no effort or recognisable subject.
    Score 2: Rough dog blob, missing face or legs. Dog attempt exists but is barely formed.
    Score 3: Basic dog outline (head + body) but off-balance; one flat color. Dog shape is there but details and proportions are weak.
    Score 4: Clear dog silhouette with simple face; stiff pose; few colors. Recognisable dog, minor mistakes, limited detail.
    Score 5: Well-proportioned dog, basic fur texture or spots; maybe a ground line. Solid effort with correct parts, some personality showing.
    Score 6: Balanced body, hints of a real breed, clean lines, 2+ colors, small background (e.g., grass). Good fundamentals plus extra touches.
    Score 7: Expressive face, dynamic pose, shading or bold line weight; fun add-ons (collar, toy). Strong anatomy and creativity working together.
    Score 8: Strong breed likeness, smooth shading/fur strokes, cool backdrop that tells a mini-story. Skilled technique and thoughtful scene.
    Score 9: Spot-on anatomy, consistent light source, rich textures, engaging action (frisbee catch). Nearly professional quality with depth and motion.
    Score 10: Perfect proportions, polished highlights/shadows, detailed environment, wow-factor originality. Professional-level finish—nothing to fix!]],
        "Medium", 15, 
        "Server")
    ThemeService:createTheme(
        "Dog", 
        "Draw your favorite dog!",
        [[
    Score 1: Page is blank or only squiggles. Boost: draw one big circle for the head.
    Score 2: Stick dog: four lines and a blob. Boost: add two floppy ears and a tail.
    Score 3: Dog shape but parts funny sizes. Boost: make head smaller than body; give four paws.
    Score 4: Dog outline plus face dots. No color. Boost: color the body one solid shade.
    Score 5: Easy-to-spot breed (long ears = beagle). Boost: bend legs or tail so it looks alive.
    Score 6: Dog is running, sitting, or jumping. Boost: add one simple shadow under the paws.
    Score 7: Happy face—tongue out or big smile. Boost: shade light side and dark side a little.
    Score 8: Fun angle—dog looking up or sideways. Boost: add fur dots or spots on the coat.
    Score 9: Lots of fur detail and shiny eyes. Boost: clean up shaky lines around paws.
    Score 10: Looks like a poster—perfect pup with background (park or bed). Boost: keep going—you nailed it!
        ]],
        "Easy", 10, 
        "Server")
    ThemeService:createTheme(
        "Superhero", 
        "Draw a superhero!",
        [[
        Score 1: Page mostly blank or random marks. No clear hero or effort shown.
    Score 2: Rough stick-figure with hint of cape or mask. Subject exists but anatomy and costume are missing.
    Score 3: Basic human outline, stiff stance, single color. Hero shape visible, but poor proportions and flat look.
    Score 4: Recognisable silhouette with simple emblem; minimal face detail. Clearer form yet little motion or shading.
    Score 5: Well-proportioned body, two-color suit, flat background line. Solid fundamentals; starts feeling “comic.”
    Score 6: Balanced muscles, slight action pose, 3+ colors, skyline or burst. Adds energy and palette variety.
    Score 7: Dynamic foreshortened pose, emblem pops, basic shadows/highlights. Shows depth and bold movement.
    Score 8: Cohesive color scheme, functional costume parts, city scene hints. Strong design sense and storytelling.
    Score 9: Consistent light source, muscle shading, dramatic perspective, action lines. Near-pro finish with texture and drama.
    Score 10: Perfect anatomy, polished highlights, intricate background, fresh heroic concept. Professional quality—nothing left to improve!
        ]],
        "Medium", 15, 
        "Server")
    ThemeService:createTheme(
        "Superhero", 
        "Draw a superhero!",
        [[
    Score 1: Blank page or random lines. Boost: sketch one big stick figure first.
    Score 2: Stick person, no costume. Boost: add a cape or mask so we know it’s a hero.
    Score 3: Hero outline but odd sizes. Boost: make head smaller than chest; add two fists.
    Score 4: Clear costume shape, no color. Boost: fill suit with one bold color.
    Score 5: Iconic bits—logo, mask, or cape flap. Boost: tilt body like it’s flying or landing.
    Score 6: Action pose—punch, jump, or flight. Boost: add one simple shadow on ground.
    Score 7: Power effect—lightning, fire, or glow. Boost: shade light side and dark side a little.
    Score 8: Cool angle—hero leaping toward us. Boost: add small background (city roof, sky).
    Score 9: Extra detail—muscle lines, armor shine. Boost: clean shaky edges and refine logo.
    Score 10: Poster-ready: perfect hero, cool backdrop, wow factor. Boost: keep it up—you’re a comic pro!
        ]],
        "Easy", 10, 
        "Server")
    ThemeService:createTheme(
        "Cartoon & Anime Characters", 
        "Bring your favorite Cartoon & Anime heroes to life!",
        [[
        Score 1: Empty page or random scribbles. No shapes link to any known character; very limited effort, color, or detail.
    Score 2: Rough stick-figure or blob that might be a character. Key parts missing (e.g., no face or limbs), single dull color, messy lines, little time spent.
    Score 3: Basic silhouette hints at someone—“oh, that could be Pikachu”—but features are off-proportion. Minimal colors, lines shaky, no background.
    Score 4: Core traits are present (e.g., big round ears, spiky anime hair) and body is sized okay. Flat colors fill most shapes, with tiny details still wrong or missing.
    Score 5: Clearly that character! Full flat color palette, complete outfit or symbols, but shading is absent and pose feels stiff. Minor proportion slip-ups (one arm longer, etc.).
    Score 6: Good likeness in a simple action pose—Naruto running, SpongeBob waving. Flat colors plus light highlights; background is a single shape or gradient. Anatomy mostly correct.
    Score 7: Dynamic expression or motion, accurate costume logos, clean linework, basic cel-shading. Small background element (rocks, clouds) supports story. Everything feels balanced.
    Score 8: Strong resemblance with confident line weight, layered lighting or shadows, and a creative twist (e.g., Ladybug mid-flip with motion streaks). Background adds depth without clutter.
    Score 9: Polished detail—foreshortening, gradient color blends, reflective eyes. Background tells a mini-story (Luffy on a pirate ship deck). Only tiny inconsistencies keep it from perfect.
    Score 10: Studio-quality poster. Flawless anatomy, perspective, and proportions; rich multi-layer shading; energetic background fully integrated. Personal flair shines yet the character is instantly recognizable. Total wow factor.
        ]],
        "Medium", 15, 
        "Server")
    ThemeService:createTheme(
        "Fantasy Creatures", 
        "From mighty dragons to sparkly unicorns—unleash every beast from your imagination!",
        [[
    Score 1: Bare page or random doodles. Almost no effort, no link to a creature. Tip: Start with big shapes first—head, body, wings.
    Score 2: Rough stick-figure beast with missing parts. Key features absent; scribbly lines, one flat color. Tip: Add the main traits (horns, tail, claws) before coloring.
    Score 3: Basic outline suggests “dragon-ish” but parts float or overlap odd. Proportions way off; colors few; background empty. Tip: Use guidelines (ovals & lines) so wings attach logically.
    Score 4: Clear creature silhouette plus two signature features (e.g., mer-tail + seashell bra). Shapes mostly right but flat color blocks; no shading. Tip: Clean up linework and fill every shape fully.
    Score 5: Definitely a fantasy beast with full colors, simple pose. Complete anatomy yet stiff; tiny detail slips (feet too small). Tip: Try a slight bend in the spine or wing angle for motion.
    Score 6: Action pose—griffin mid-pounce! Flat colors + light highlights. Good proportions; hint of background sky or cave. Tip: Add one light source to pop shadows.
    Score 7: Dynamic expression, clean line weight, two-step shading (light & mid-tone). Small background element that fits story. Overall balance; only minor line wiggles. Tip: Increase contrast between light and shadow for depth.
    Score 8: Confident perspective (foreshortened claws), layered lighting, creative twist (lava dragon with ember glow). Background adds depth without stealing focus. Polished look but a few edges muddy. Tip: Add texture (scales, feathers) with tiny strokes.
    Score 9: Near-professional detail—gradient blends, reflections in eyes, atmospheric background. Only micro errors. Feels alive; story clear (phoenix bursting from ashes). Tip: Tidy stray pixels and refine textures.
    Score 10: “Poster-ready” masterpiece. Flawless anatomy, rich multi-layer shading, epic background fully integrated. Wow factor off the charts. Nothing distracts; personal style shines yet creature is unmistakable.
        ]],
        "Medium", 15, 
        "Server")
    ThemeService:createTheme(
        "Sports", 
        "Ready, set, draw — capture the thrill of the game in one epic sketch!",
        [[
    Score 1: Nearly blank paper or loose scribbles. Effort is almost zero; nothing sports-related pops out. Quick win: block in one big action pose first—stick figures are okay!
    Score 2: Single stick figure holding a ball; no background. Idea is there but details missing—no goal, net, or gear. Quick win: add one key prop (hoop, goalpost) and basic uniform lines.
    Score 3: Basic body plus one sports item, but limbs bend oddly or overlap. Proportions off; action feels frozen; one flat color max. Quick win: use simple motion lines (swoosh, dash) and two solid colors.
    Score 4: Full figure with jersey, ball, and rough background (field outline). Forms recognizable yet stiff; coloring patchy; no shadows. Quick win: clean up line weight and fill every shape edge to edge.
    Score 5: Clear athlete pose—soccer kick, slam dunk, sprinter start. Complete uniform colors and equipment; minor limb size slip-ups. Quick win: tilt the torso or limb for a sense of speed.
    Score 6: Action vibe: player mid-air, skateboard tilt, water splash. Flat colors plus light highlights; quick crowd or court lines. Quick win: drop a single light source to cast simple shadows.
    Score 7: Dynamic expression—grit face, victory yell. Clean line weight; two-step shading. Balanced composition; background element (scoreboard, stadium lights) matches story. Quick win: increase contrast between highlight and shadow for pop.
    Score 8: Strong perspective—foreshortened arm for the dunk, curved fish-eye rink. Layered lighting, sweat shine, motion streaks. Polished but a few edges wobbly; colors blend smoothly. Quick win: add texture (grass blades, court wood grain) in small strokes.
    Score 9: Near-pro detail—gradient skin tones, reflective gear, blurred crowd. Atmosphere (dust, stadium glow) supports action. One or two tiny anatomy glitches keep it shy of perfect. Quick win: sharpen tricky joints (elbows, knees) and tidy stray pixels.
    Score 10: “Poster-ready” highlight reel. Flawless anatomy, dramatic perspective, rich multi-layer shading.
        ]],
        "Medium", 15, 
        "Server")
    ThemeService:createTheme(
        "Food", 
        "Dish out delicious art—make every bite look too tasty to resist!",
        [[
    Score 1: Almost blank page or random lines. No clear food, zero effort. Tip: sketch a big outline first—circle for plate or crust.
    Score 2: Lonely blob with one color; maybe it’s bread? Idea exists but features missing (no toppings, no plate). Tip: add at least one key food detail—pepperoni spots, straw, frosting swirl.
    Score 3: Basic outline hints at pizza or donut, but shapes uneven, colors flat. Proportions off; no shading; background empty. Tip: use two colors and clean edges to make it recognizable.
    Score 4: Full dish silhouette with a few toppings or textures. Forms mostly right yet stiff; patchy coloring; no shadows. Tip: fill every shape edge-to-edge and thicken line weight.
    Score 5: Clear snack—burger layers, sushi filling, ice-cream scoops. Complete colors; simple pose on plate; minor size slips. Tip: tilt or stack items for extra dimension.
    Score 6: Action vibe: cheese stretch, soda fizz, steam curls. Flat colors plus light highlights; quick tablecloth or tray line. Tip: pick one light source and add simple shadows underneath.
    Score 7: Tasty textures—melting cheese, sprinkled sugar, shiny glaze. Clean lines; two-step shading. Balanced composition with small background (checkered napkin, café counter). Tip: increase contrast between highlight and shadow to pop flavor.
    Score 8: Confident perspective—overhead sushi platter, angled milkshake glass. Layered lighting; creative twist (galaxy-swirl ice cream). Polished but a few uneven edges; colors blend smoothly. Tip: add tiny surface textures (sesame seeds, bubbles) for realism.
    Score 9: Near-pro detail—gradient sauce drips, reflections on glass, steam glow. Background story (bakery shelf, picnic grass). One or two tiny proportion slips keep it shy of perfect. Tip: tighten tricky curves (plate rim, cup lip) and erase stray marks.
    Score 10: “Menu-ready” masterpiece. Flawless shapes, rich multi-layer shading, appetizing highlights. Background fully integrated (rustic board, café vibe). Instant wow—viewers feel hungry. Personal style shines yet food is crystal clear. Tip: keep cooking—this belongs in a cookbook!
        ]],
        "Medium", 15, 
        "Server")
    ThemeService:createTheme(
        "Food", 
        "Dish out delicious art—make every bite look too tasty to resist!",
        [[
        Score 1: Blank page or random squiggles. Boost: draw one clear food shape first—circle, triangle, or bun.
    Score 2: Blob that might be bread. Boost: add one key detail (pepperoni dot, straw, cherry).
    Score 3: Food outline but wobbly sizes. Boost: make outline smooth; add two colors.
    Score 4: Clear shape plus face dots or topping spots. No color fill. Boost: color the whole thing one solid shade.
    Score 5: Easy-to-spot snack (slice of pizza, donut ring). Boost: stack layers or tilt slice for life.
    Score 6: Action! Cheese stretch, soda fizz, steam curl. Boost: drop one simple shadow under the food.
    Score 7: Texture pop—sprinkles, sesame seeds, glaze shine. Boost: shade light side and dark side a bit.
    Score 8: Fun angle—overhead plate or tilted milkshake glass. Boost: add small background (table line, tray).
    Score 9: Extra detail—dripping sauce, shiny glass, crisp edges. Boost: clean shaky lines and refine toppings.
    Score 10: Menu-ready masterpiece with cute backdrop (picnic cloth, café counter). Boost: keep cooking—you nailed the wow!
        ]],
        "Easy", 10, "Server")
     ThemeService:createTheme(
        "Emotions", 
        "",
        [[
Score 1: Blank page or random lines. Boost: start with one circle for a face.
Score 2: Plain stick head, no expression. Boost: add eyes, mouth, and eyebrows.
Score 3: Expression exists but looks off (mixed signals). Boost: make mouth bigger and match eyebrows.
Score 4: Clear happy/sad/angry face, no color. Boost: fill the face with one solid shade.
Score 5: Emotion easy to spot plus one prop (tear, sweat, heart). Boost: tilt the head or body to add drama.
Score 6: Action—laughing open mouth, angry fist, shocked hands. Boost: drop one simple shadow under the figure.
Score 7: Extra clues—speech bubble, emoji symbols, motion lines. Boost: shade light side and dark side a little.
Score 8: Fun angle—face looking up, down, or sideways. Boost: add tiny background (rain for sad, sun for joy).
Score 9: Detail—shiny tears, blushing cheeks, vein pop. Boost: clean shaky lines and refine props.
Score 10: Poster-ready emotion scene with full backdrop. Boost: keep it up—you made us feel something!
        ]],
        "Medium", 15, 
        "Server")
     ThemeService:createTheme(
        "Emotions", 
        "",
        [[
Score 1: Blank page. Boost: draw a face.
Score 2: Plain face, no feeling. Boost: add a smile or frown.
Score 3: Small smile/frown, hard to spot. Boost: make the mouth huge.
Score 4: Clear happy / sad / angry face. Boost: add eyebrows.
Score 5: Face + one extra sign (tear, heart, sweat). Boost: tilt the head.
Score 6: Body shows feeling (jump, slump). Boost: add one shadow.
Score 7: Motion lines or speech bubble. Boost: shade one side darker.
Score 8: Fun angle (looking up / down). Boost: tiny background (sun, rain).
Score 9: Cool details (blush, shiny tears). Boost: clean shaky lines.
Score 10: Whole scene screams the emotion. Boost: keep it—awesome!
        ]],
        "Easy", 10, 
        "Server")
     ThemeService:createTheme(
        "Nature", 
        "",
        [[
Score 1: Blank page. Boost: draw a tree trunk.
Score 2: One shape, no clue (blob). Boost: add leaves or a sun.
Score 3: Simple tree or hill, wobbly. Boost: smooth the outline.
Score 4: Clear tree / mountain / river. Boost: add a second object (cloud, flower).
Score 5: Two nature items, no color. Boost: fill each with one solid shade.
Score 6: Colors + small detail (sun rays, petals). Boost: drop a light shadow.
Score 7: Motion lines (wind, water flow). Boost: shade one side darker.
Score 8: Fun angle—bird's-eye or side view. Boost: add tiny background shapes (distant hills).
Score 9: Extra texture—bark lines, ripples. Boost: clean shaky edges.
Score 10: Whole scene feels alive—balanced, colorful sky & ground. Boost: keep it—beautiful work!
        ]],
        "Easy", 10, 
        "Server")
     ThemeService:createTheme(
        "Nature", 
        "",
        [[
Score 1 - The page is nearly blank or covered in unrelated doodles. No identifiable landscape elements. Demonstrates minimal effort and zero understanding of natural forms.
Score 2 - One crude shape suggests a hill or tree-blob, but proportions are wildly off; horizon missing; no color logic. Lines are scratchy, perspective ignored. Add basic ground–sky division and distinct shapes to move up.
Score 3 - Basic skyline appears: ground line, sun, lone tree. Forms are flat, colors single-tone, no texture or light source. Depth is absent. Work on overlapping shapes and varied greens or browns.
Score 4 - Scene contains at least three nature elements (e.g., tree, river, mountain). Proportions mostly sensible, but values remain flat; sky may be one solid blue. No atmospheric perspective yet. Introduce gradual color shifts and foreground shadows.
Score 5 - Clear composition: foreground, midground, background separated by size or value. Simple lighting—light side vs. shade—gives volume. Water reflects some sky color; foliage shows texture strokes. Perspective still stiff, but viewer “believes” the space.
Score 6 - Intentional focal point (waterfall, lone maple) guides the eye. Lighting direction consistent; cast shadows match objects. Color palette shows harmony—cool distant mountains, warm near rocks. Depth hints via softer edges in the distance.
Score 7 - Dynamic atmosphere: mist, wind lines, or cloud layering adds mood. Textures differentiate bark, grass, and water ripples. Overlaps and diminishing sizes create convincing spatial scale. Minor perspective slips keep it from pro tier.
Score 8 - Advanced depth: aerial perspective fades far colors; foreground details crisp. Light behaves realistically on varied surfaces (specular lake highlight, translucent leaves). Composition uses rule-of-thirds or leading lines. Color temperature shifts enhance story (e.g., sunset glow).
Score 9 - Near-professional polish. Subtle gradients, reflected light, secondary color bounces. Complex textures—moss, rock strata—retain clarity without clutter. Atmospheric effects (rain shafts, dust motes) support narrative. Only tiny inaccuracies in anatomy of trees or rock forms remain.
Score 10 - Portfolio-ready masterpiece. Flawless perspective; layered lighting including rim or back-light. Depth of field implied through edge softness. Color harmony feels cinematic; values balanced for readability. Every texture—frothy water, craggy cliffs, wispy clouds—reads true yet shows artist’s style. Scene tells a clear story (calm dawn, raging storm) with zero weak spots.
        ]],
        "Hard", 20, 
        "Server")
     ThemeService:createTheme(
        "Dinosaurs", 
        "",
        [[
Use this dino-themed rubric to score drawings from beginners to next-level paleo-artists. Judges look for recognizable anatomy, creative flair, color work, backgrounds, and storytelling. Start each critique with a positive note, point to one clear improvement, and cheer the artist onward—the goal is growth, not perfection.
Score 1: Canvas mostly blank or random marks; no recognizable dinosaur; minimal effort shown. To improve, sketch a simple dinosaur outline and focus on connecting head, body, and tail so viewers know what it is.
Score 2: Simple outline suggests a dinosaur shape but it's extremely rough; limbs or head missing, no colors, background empty, and little detail. Try adding all major body parts and trace over lines for cleaner edges.
Score 3: Basic dinosaur form complete with head, body, tail, and at least two legs; shapes uneven, single flat color, background empty, details minimal. Next, refine proportions and add a second color or pattern for liveliness.
Score 4: Dinosaur has full body parts and small details like teeth or plates; at least two colors used; proportions off and background still blank. Work on balancing limb sizes and introduce a simple backdrop such as rocks or plants.
Score 5: Dinosaur shows clear proportions, three or more colors, added textures like lines or spots; tiny background element (grass) present; minor perspective issues remain. Enhance depth with thin-to-thick line variation and a larger setting behind the creature.
Score 6: Dinosaur in a dynamic pose with correct limb count; light shading or gradient attempts; background contains two elements (trees, volcano); overall balance good yet somewhat rough. Polish by smoothing gradients and adding shadows beneath feet for realism.
Score 7: Dinosaur well-proportioned, lively pose, expressive face and eyes; consistent shading; at least three background items create a scene; creativity shows (feathers, armor). Push farther with lighting direction and subtle highlights on scales.
Score 8: Highly detailed dinosaur with textures like scales and claws, accurate perspective; rich color blending; cohesive background storytelling (chasing prey, roaring on cliff); very minor anatomy inaccuracies. Sharpen detail on focal points and refine sky or ground textures.
Score 9: Professional-level polish; dynamic composition shows foreground, midground, background depth; moody lighting; imaginative twist (neon T-rex, cyber stegosaurus) executed cleanly; only tiny flaws in line smoothness. Finalize by erasing stray marks and enhancing reflections or motion effects.
Score 10: Jaw-dropping masterpiece: flawless anatomy, vibrant blended colors, expert shading and highlights, cinematic story scene; every element intentional, from tiny claw scratches to atmospheric fog; poster quality. Judges struggle to suggest improvements—just keep shining!
        ]],
        "Medium", 15, 
        "Server")
end

return ThemeLoader