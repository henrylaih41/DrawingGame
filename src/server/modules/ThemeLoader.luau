local ServerScriptService = game:GetService("ServerScriptService")
local ThemeService = require(ServerScriptService.modules.ThemeService)

local ThemeLoader = {}

function ThemeLoader:loadThemes()
    ThemeService:createTheme(
    "Naruto Uzumaki",
    "",
    [[
"Channel your inner shinobi and let the orange whirlwind fly! A solid Naruto drawing nails three signature cues: spiky blond hair, whisker marks, and his orange‑and‑black jumpsuit (headband optional but awesome). Go for energy over perfection—motion lines, swirling chakra, or ramen doodles crank up the hype. Markers, crayons, pencil—any tool works if the attitude screams “Believe It!”   

Score 1: Random scribble; no ninja traits at all.  
Score 2: Stick figure with maybe spiky hair—nothing else matches Naruto.  
Score 3: Basic body, hint of whiskers or orange but outfit/details off.  
Score 4: Recognizable silhouette, hair and jumpsuit blocks; proportions messy.  
Score 5: Clear Naruto—hair, whiskers, orange suit; simple color or shading.  
Score 6: Adds Leaf headband symbol or rasengan glow; cleaner lines.  
Score 7: Good anatomy, full colors, confident grin, small prop (ramen bowl).  
Score 8: Dynamic pose (running, rasengan), smooth shading, subtle background.  
Score 9: Near‑anime quality—folds, lighting, chakra aura, action backdrop.  
Score 10: Studio‑level illustration: perfect pose, textures, dramatic lighting, epic scene."
    ]],
    "Easy", 10,
    "Server")

ThemeService:createTheme(
    "Izuku Midoriya (Deku)",
    "",
    [[
"Go Plus Ultra! Deku means messy green curls, big freckled smile, teal hero suit, and comfy red kicks. Capture his determined vibe—pose him mid‑smash or studying notes. Small sparks of One‑For‑All energy (crackling lightning) earn bonus points, but clarity beats complexity.   

Score 1: Unclear doodle; can’t tell who it is.  
Score 2: Stick figure with green blob hair.  
Score 3: Curls + freckles OR teal suit, but not both.  
Score 4: Recognizable Deku, outfit blocky; anatomy off.  
Score 5: Correct hair, freckles, hero suit colors; basic pose.  
Score 6: Adds red boots or gloves, cleaner lines, slight shading.  
Score 7: Power lightning effects or notebook prop; good proportions.  
Score 8: Dynamic smash pose, motion blur, full shading.  
Score 9: Anime‑worthy lines, layered highlights, action background.  
Score 10: Professional splash‑page art—perfect foreshortening, lighting, effects."
    ]],
    "Easy", 10,
    "Server")

ThemeService:createTheme(
    "Monkey D. Luffy",
    "",
    [[
"Set sail for the Grand Line! Luffy’s essentials: straw hat, red vest, blue shorts, cheeky grin, and rubbery limbs. Exaggerate stretch poses—long arms or Gum‑Gum punch—because goofy action is his brand. A simple Jolly Roger or sunny sea backdrop scores bonus treasure.   

Score 1: Scribble; no pirate vibe.  
Score 2: Stick figure with random hat.  
Score 3: Hat + red vest OR big grin, but missing most.  
Score 4: Straw‑hat boy obvious, body stiff, colors rough.  
Score 5: Proper hat, vest, shorts, grin; simple coloring.  
Score 6: Rubber‑arm pose, shadow under hat, clearer lines.  
Score 7: Full color, chest scar, tiny background ship.  
Score 8: Action stretch, motion lines, water splash.  
Score 9: Detailed anatomy, shading, sky gradient, flag in wind.  
Score 10: Cinematic poster quality—dynamic lighting, full scene, wow factor."
    ]],
    "Easy", 10,
    "Server")

ThemeService:createTheme(
    "Goku",
    "",
    [[
"Time to power up! Goku rocks spiky black (or Super Saiyan gold) hair, orange gi, blue undershirt, and that chill‑yet‑tough grin. Show motion—charging Ki, flying, or a Kamehameha. Aura glows or cratered ground boost the wow, but a clean base pose is plenty for mid scores.   

Score 1: Random lines; unrecognizable.  
Score 2: Stick man with spiky hair.  
Score 3: Orange outfit OR hair right, not both.  
Score 4: Recognizable Goku; messy body; flat color.  
Score 5: Proper gi, hair, wristbands; basic shading.  
Score 6: Adds blue undershirt symbol, better proportions.  
Score 7: Aura outline, darker shading, confident stance.  
Score 8: Action beam or flight pose, glowing effects.  
Score 9: Sharp anatomy, layered highlights, cracked ground.  
Score 10: Full anime shot—dramatic light, energy flares, epic backdrop."
    ]],
    "Easy", 10,
    "Server")

ThemeService:createTheme(
    "Pikachu",
    "",
    [[
"Bring on the cute! Key bits: chubby yellow body, pointy ears with black tips, red cheeks, thunder‑bolt tail, and bright eyes. Simple shapes rule—make it adorable rather than perfect. Lightning bolts, Poké Ball, or grass field are sweet extras.   

Score 1: Scribble; no Pokémon vibe.  
Score 2: Yellow blob with ears.  
Score 3: Ears + cheeks but tail wrong shape.  
Score 4: Recognizable Pikachu; messy lines; flat yellow.  
Score 5: Right proportions, tail, cheeks; neat outline.  
Score 6: Adds shading or small Poké Ball.  
Score 7: Cute pose (jumping), spark effects, smooth color fill.  
Score 8: Thunder attack, detailed highlights, background patch.  
Score 9: Near‑official art—soft gradients, crisp edges, scenery.  
Score 10: Merch‑ready illustration—perfect lighting, textures, dynamic scene."
    ]],
    "Easy", 10,
    "Server")

ThemeService:createTheme(
    "Levi Ackerman",
    "",
    [[
"Humanity’s coolest captain! Levi’s trademarks: under‑cut black hair, calm gray eyes, Survey Corps cape, and dual blades. Focus on sharp angles and poised stance—he’s all precision. Background rooftops or ODM gear cables look awesome but aren’t essential for mid scores.   

Score 1: Random figure; no match.  
Score 2: Stick soldier with sword.  
Score 3: Cape or blades present, rest generic.  
Score 4: Recognizable Levi; basic uniform, stiff pose.  
Score 5: Right hairstyle, cloak, twin blades; simple shading.  
Score 6: Adds Scouts emblem or determined eyes, cleaner lines.  
Score 7: Dynamic mid‑air slice, motion lines, cape flow.  
Score 8: ODM gear detail, city skyline, sharper shadows.  
Score 9: Realistic anatomy, textured fabric, smoke effects.  
Score 10: Panel‑quality art—cinematic lighting, full 3‑D depth."
    ]],
    "Easy", 10,
    "Server")

ThemeService:createTheme(
    "SpongeBob SquarePants",
    "",
    [[
"Who lives in a pineapple under the sea? Make your sponge bright yellow, squishy with holes, white shirt, red tie, brown shorts, and forever‑happy face. Wavy outlines and bubbly backgrounds feel extra ocean‑y. Don’t fuss over perfect squares—goofy charm wins.   

Score 1: Scribble; no sponge shape.  
Score 2: Yellow blob; eyes uneven.  
Score 3: Square body + tie but little else.  
Score 4: Recognizable SpongeBob; messy color; limbs odd.  
Score 5: Clear shape, outfit correct; neat linework.  
Score 6: Adds freckles or big toothy grin, subtle shading.  
Score 7: Jellyfish net, bubbles, or krabby patty prop.  
Score 8: Dynamic pose, wavy outlines, ocean floor bits.  
Score 9: Clean cartoon style, highlights, textured holes.  
Score 10: Episode‑ready art—vibrant colors, background scene, polished finish."
    ]],
    "Easy", 10,
    "Server")

ThemeService:createTheme(
    "Patrick Star",
    "",
    [[
"Best buddy vibes! Patrick is a pink starfish with sleepy eyes, goofy smile, and green‑purple swim trunks. Keep shapes soft and fun—he’s all about laid‑back cheer. Sea rocks, ice‑cream cones, or a confused expression earn bonus chuckles.   

Score 1: Doodle; star shape unclear.  
Score 2: Pink star outline only.  
Score 3: Star + shorts, face missing or off.  
Score 4: Recognizable Patrick; flat pink; limbs odd.  
Score 5: Correct body, trunks, happy face; neat lines.  
Score 6: Adds belly button or drool, simple shading.  
Score 7: Funny pose, prop (cone), background bubble.  
Score 8: Bold outlines, smooth colors, rock seat.  
Score 9: Cartoon‑show polish, light gradients, ocean floor detail.  
Score 10: Poster‑quality finish—glossy highlights, full scenery, comedic sparkle."
    ]],
    "Easy", 10,
    "Server")

ThemeService:createTheme(
    "Scooby‑Doo",
    "",
    [[
"Ruh‑roh! Scooby is a lanky brown Great Dane with black spots, blue collar, and SD tag. Capture his long snout, goofy grin, and wagging tail. Bonus snacks: Scooby Snacks box, ghost silhouette, or Shaggy cameo.   

Score 1: Scribble; no dog vibe.  
Score 2: Brown blob dog.  
Score 3: Dog shape + collar, missing spots/tag.  
Score 4: Recognizable Scooby; body parts off‑scale.  
Score 5: Proper shape, collar, grin; simple colors.  
Score 6: Adds spots or SD tag, cleaner outline.  
Score 7: Fun pose (tip‑toe scared), light shading.  
Score 8: Ghost background, motion lines, shine in eyes.  
Score 9: Smooth cartoon style, texture, haunted backdrop.  
Score 10: Animation‑cel level—dynamic lighting, spooky scene, polished details."
    ]],
    "Easy", 10,
    "Server")

ThemeService:createTheme(
    "Mickey Mouse",
    "",
    [[
"The true OG! Key icons: big round ears, red shorts with white buttons, yellow shoes, white gloves. Keep lines smooth and eyes cheerful. Retro pie‑eyes, magic sparkles, or Castle backdrop can level‑up but aren’t required for mid scores.   

Score 1: Random circles; unclear.  
Score 2: Two‑circle head only.  
Score 3: Head + shorts, missing shoes/gloves.  
Score 4: Recognizable Mickey; rough lines; flat color.  
Score 5: Full outfit, neat proportions; simple shading.  
Score 6: Adds gloves shine, smile angle, tidy linework.  
Score 7: Fun pose (wave), small sparkle, background gradient.  
Score 8: Classic steamboat or castle hint, smoother colors.  
Score 9: Disney‑short caliber, subtle shadows, clean edges.  
Score 10: Theme‑park poster—perfect curves, lighting, magical backdrop."
    ]],
    "Easy", 10,
    "Server")

ThemeService:createTheme(
    "Tom and Jerry",
    "",
    [[
"Chaotic cat‑and‑mouse duo! Draw gray Tom (big ears, long tail) and brown Jerry (tiny, round ears) mid‑chase. Cartoon action—cheese wedge, frying pan, or dust trails—sells the gag. Don’t worry about perfect anatomy; playful motion rules.   

Score 1: Scribble; can’t tell who’s who.  
Score 2: One animal blob; missing other.  
Score 3: Both present but basic stick figures.  
Score 4: Recognizable duo; stiff poses; flat color.  
Score 5: Clear Tom & Jerry, fun expressions; neat lines.  
Score 6: Motion lines or prop (cheese) added; shading basic.  
Score 7: Dynamic chase pose, background floor/house.  
Score 8: Impact effects, layered colors, dust clouds.  
Score 9: TV‑short quality, detailed fur, polished action scene.  
Score 10: Cinematic still—perfect timing, lighting, full environment."
    ]],
    "Easy", 10,
    "Server")

ThemeService:createTheme(
    "Raven (Teen Titans Go!)",
    "",
    [[
"Embrace the dark‑but‑cool vibe. Raven sports a purple cloak with hood, pale skin, and red gem on her forehead. Focus on calm floating pose or spell casting. Dark aura or “Azarath Metrion Zinthos” text boosts mystic points.   

Score 1: Scribble; no character link.  
Score 2: Purple blob with eyes.  
Score 3: Cloak + gem, missing face details.  
Score 4: Recognizable Raven; flat colors; stiff pose.  
Score 5: Proper cloak, gem, pale face; clean lines.  
Score 6: Adds shadow wings or book, simple shading.  
Score 7: Hovering pose, magic circle, gradient cloak.  
Score 8: Spell energy, starry backdrop, layered colors.  
Score 9: Show‑quality style, soft highlights, moody lighting.  
Score 10: Poster‑grade art—dynamic magic, full environment, pro polish."
    ]],
    "Easy", 10,
    "Server")

ThemeService:createTheme(
    "Robin (Teen Titans Go!)",
    "",
    [[
"Ready to lead the Titans! Robin rocks spiky black hair, green domino mask, red‑yellow‑green suit with “R” badge, and bo staff. Show action—jump kick, birdarang throw, or serious stance. Starfire hearts cameo optional but epic.   

Score 1: Scribble; who even is this?  
Score 2: Stick hero with mask blob.  
Score 3: Mask + red suit, missing logo or colors.  
Score 4: Recognizable Robin; lines rough; flat color.  
Score 5: Proper costume, mask, badge; neat outline.  
Score 6: Adds bo staff or cape motion; shading light.  
Score 7: Dynamic pose, motion swoosh, background blur.  
Score 8: Birdarang trail, crisp colors, glow.  
Score 9: TV‑episode still—highlights, detailed folds, scene depth.  
Score 10: Comic‑cover art—dramatic lighting, action splash, perfect finish."
    ]],
    "Easy", 10,
    "Server")

ThemeService:createTheme(
    "Kim Possible",
    "",
    [[
"So not the drama! Kim sports fiery red hair, black crop‑top, green cargo pants, gloves, and grappling hook. Capture her confident spy‑stance or mid‑flip kick. Simple background (mission screen or beep communicator) adds extra style.   

Score 1: Scribble; no spy vibe.  
Score 2: Stick girl with ponytail.  
Score 3: Red hair + crop‑top, rest off.  
Score 4: Recognizable Kim; colors flat; pose stiff.  
Score 5: Proper outfit, hair bounce; neat lines.  
Score 6: Adds gadget (hook), shading basic.  
Score 7: Action pose, motion swoosh, background hint.  
Score 8: Dynamic kick, tech HUD, layered colors.  
Score 9: Cartoon‑network quality, light gradients, detailed gear.  
Score 10: Poster‑worthy—cinematic lighting, full spy scene, polished finish."
    ]],
    "Easy", 10,
    "Server")

ThemeService:createTheme(
    "Ben Tennyson (Ben 10)",
    "",
    [[
"It’s Hero Time! Ben’s staples: messy brown hair, black‑and‑white tee or green jacket, and the Omnitrix on his wrist glowing green. Show him transforming, checking alien menu, or striking hero pose. Alien silhouettes in background boost cosmic cred.   

Score 1: Random kid doodle.  
Score 2: Stick figure with watch blob.  
Score 3: Hair + Omnitrix, outfit off.  
Score 4: Recognizable Ben; flat color; anatomy off.  
Score 5: Correct watch, shirt/jacket, hair; clean lines.  
Score 6: Watch glow, basic shading, confident stance.  
Score 7: Transformation silhouette, motion lines, background flash.  
Score 8: Alien outline, layered highlights, nebula backdrop.  
Score 9: Show‑style polish, dynamic lighting, detailed watch.  
Score 10: Box‑art level—perfect pose, energy burst, full scene."
    ]],
    "Easy", 10,
    "Server")
end

return ThemeLoader