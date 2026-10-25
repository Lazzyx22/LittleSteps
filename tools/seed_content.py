"""Regenerate only the original demo catalog; the app reads JSON, not this script."""
import json
from pathlib import Path

subjects = [("english", "English", "ABC"), ("maths", "Maths", "123"), ("hindi", "Hindi", "अ"), ("science", "Science & Nature", "☘"), ("world", "World Around Us", "◎"), ("life", "Life Skills", "♡"), ("stories", "Stories", "▤"), ("art", "Art & Creativity", "✎")]
topics, lessons = [], []
def quiz(prompt, choices, correct=0, explanation="Let's look together."):
    return {"type": "imageChoice", "question": {"prompt": prompt, "answers": [{"id": str(i), "text": c} for i,c in enumerate(choices)], "correctId": str(correct), "explanation": explanation}}
def lesson(id, subject, title, band, text, question, extra=None):
    topics.append({"id": id, "subjectId": subject, "title": title})
    lessons.append({"id": id, "subjectId": subject, "topicId": id, "title": title, "ageBands": [band], "objectives": [text], "difficulty": 1 if band == 'preschool3' else 2, "estimatedMinutes": 3, "steps": [{"type": "story" if subject == 'stories' else 'animation', "text": text}, question, *(extra or []), {"type": "offlineActivity", "text": "Tell someone what you discovered."}]})
p, g = 'preschool3', 'grade2'
lesson('colors', 'art', 'A pocket of colors', p, 'Red, blue and yellow brighten our day. A red kite, blue sky, yellow sun!', quiz('Which one is red?', ['🔴 Red', '🔵 Blue'], explanation='The red circle is the color of our kite.'), [{"type":"coloring", "text":"Give the round balloon a color."}])
lesson('shapes', 'maths', 'Shape picnic', p, 'A circle is round. A square has four equal sides. A triangle has three sides.', quiz('Find the triangle', ['△ Triangle', '○ Circle'], explanation='Count the three sides of △.'), [{"type":"matching", "text":"Tap a shape, then its name.", "pairs":{"△":"Triangle", "□":"Square", "○":"Circle"}}, {"type":"tracing", "text":"Start at the dot and trace a circle.", "path":"circle"}])
lesson('counting', 'maths', 'Five tiny steps', p, 'Count with me: 1, 2, 3, 4, 5. Five toes take five tiny steps.', quiz('1  ?  3 — what is missing?', ['2', '4'], explanation='Say one, TWO, three.'), [{"type":"dragDrop", "text":"Put the fruit in the basket.", "categories":{"Apple":"Basket", "Banana":"Basket"}}])
lesson('animals', 'science', 'Little animal friends', p, 'A dog says woof. A cat says meow. An elephant has a long trunk.', quiz('Who has a long trunk?', ['Elephant', 'Cat'], explanation='An elephant uses its trunk to reach and drink.'), [{"type":"matching", "text":"Match the grown-up and baby.", "pairs":{"Dog":"Puppy", "Cat":"Kitten"}}])
lesson('habits', 'life', 'Bubble hands', p, 'Wet your hands. Add soap. Rub palms, backs, fingers and thumbs. Rinse and dry. Ask an adult to help.', quiz('What helps wash our hands?', ['Soap', 'Sand'], explanation='Soap and water wash our hands.'), [{"type":"offlineActivity", "text":"Wash your hands with an adult. Sing a short song while you rub."}])
lesson('feelings', 'life', 'Feelings have names', p, 'Happy, sad and angry are feelings. Every feeling is welcome. Take a slow breath and tell a trusted grown-up.', quiz('A smile can show…', ['Happy', 'Sad'], explanation='A smile often shows happiness. People can show feelings differently.') )
lesson('abc', 'english', 'Letters on a walk', p, 'A is for ant. B is for boat. C is for cup. Let us find A, B and C.', quiz('Which letter starts boat?', ['B', 'A'], explanation='Boat begins with B.'), [{"type":"tracing", "text":"Follow the letter-like mountain path.", "path":"letter"}, {"type":"tracing", "text":"Follow the line.", "path":"line"}])
lesson('hindi_p', 'hindi', 'अ से अनार — demo', p, 'अ से अनार। This is a small Hindi letter demo. Ask an adult to read it with you.', quiz('Find अ', ['अ', 'ब'], explanation='अ is the first choice.'))
lesson('world_p', 'world', 'Our nearby park', p, 'Trees give shade. Paths help us walk through the park. Stay near your grown-up.', quiz('Where can a tree give shade?', ['Park', 'Cup'], explanation='A tree can grow in a park.'))
lesson('story_p', 'stories', 'The little paper boat', p, 'A paper boat rested in a bowl. Mira gave it a tiny leaf passenger. Together they imagined a quiet lake.', quiz('Who rode in the paper boat?', ['A leaf', 'A bus'], explanation='The tiny leaf was the passenger.'))
grade_content = [
('nouns','english','Name detectives','A noun names a person, place, animal or thing. Garden and rabbit are nouns.','Which word is a noun?',['Garden','Jump'], 'Garden names a place.'),
('verbs','english','Words that move','A verb tells what someone does. Birds glide. Children read. Glide and read are verbs.','Which word is an action?',['Read','Book'], 'Read tells what someone does.'),
('reading','english','A seed for Noor','Noor planted a seed in a small pot. Each morning she checked the soil. When it felt dry, she added water. A green shoot appeared.','Why did Noor add water?',['The soil felt dry','The pot was loud'], 'The passage says she watered when the soil felt dry.'),
('place','maths','Tens and ones','The number 34 has 3 tens and 4 ones. Three bundles of ten make thirty.','How many tens are in 34?',['3','4','7'], '34 is 30 + 4, so it has three tens.'),
('addition','maths','Add the garden pebbles','There are 12 pebbles near a pot and 5 near a tree. Together there are 17.','12 + 5 = ?',['17','15','7'], '12 plus 5 is 17.'),
('subtraction','maths','Sharing pencils','There are 18 pencils. We give 6 to a friend. 12 pencils remain.','18 − 6 = ?',['12','24','14'], 'Taking six from eighteen leaves twelve.'),
('patterns','maths','A growing trail','Look at 2, 4, 6, 8. Each number grows by two.','What comes next: 2, 4, 6, 8, …?',['10','9','12'], 'Add two to eight to get ten.'),
('plants','science','A plant from roots to leaves','Roots take in water. The stem supports the plant. Leaves help it make food using light.','Which part takes in water?',['Roots','Flower','Petal'], 'Roots take water from the soil.'),
('water','science','A drop on a journey','Water can be liquid, solid ice, or water vapor in the air. We can save water by closing a running tap.','What is solid water called?',['Ice','Steam','Sand'], 'Frozen water is ice.'),
('weather','science','Sky notebook','Weather describes conditions such as sunny, cloudy, rainy or windy. Notice the sky with an adult.','Moving air is called…',['Wind','Rock','Soil'], 'Wind is air in motion.'),
('road','life','Pause at the road','Stop away from the edge. Cross at a marked crossing with a trusted adult. Look and listen; keep checking while crossing.','Who should help you cross?',['A trusted adult','A passing pet'], 'Ask a trusted adult to help you cross safely.'),
('emotions','life','A pause for feelings','When a task feels hard, pause, breathe slowly and ask for help. Feelings give us clues about what we need.','What can help when frustrated?',['Pause and ask for help','Hide every feeling'], 'A pause and support can help us try again.'),
('hindi_g','hindi','शब्दों की छोटी दुनिया — demo','पानी means water. पेड़ means tree. This is a Unicode demonstration, not a complete Hindi curriculum.','Which word means water?',['पानी','पेड़'], 'पानी means water.'),
('world_g','world','People who help','Librarians help us find books. Gardeners care for plants. We can thank people who help our community.','Who helps us find library books?',['Librarian','Pilot'], 'A librarian helps readers find books.'),
('story_g','stories','The shared shade','Asha and Dev built a small shade for their seedlings. Asha tied the sticks while Dev held them steady. Together they finished before the hot afternoon.','How did they finish the shade?',['They worked together','They hid the sticks'], 'Each child helped with a different part.'),
('art_g','art','A circle can become…','A circle can become a planet, a fruit or a balloon. Choose a color and invent a story about your picture.','Which tool can add color?',['A crayon','A ruler only'], 'A crayon can add color to a picture.'),
]
for id,subject,title,text,prompt,answers,explanation in grade_content:
    extras=[]
    if id=='nouns': extras=[{"type":"dragDrop", "text":"Sort words into noun and verb.", "categories":{"Garden":"Noun", "Rabbit":"Noun", "Run":"Verb", "Sing":"Verb"}}]
    if id=='plants': extras=[{"type":"matching", "text":"Match each plant part to its job.", "pairs":{"Roots":"Take in water", "Stem":"Support", "Leaves":"Make food"}}]
    if id=='art_g': extras=[{"type":"coloring", "text":"Invent a balloon color."}]
    lesson(id, subject, title, g, text, quiz(prompt, answers, explanation=explanation), extras)
catalog={"version":1,"subjects":[dict(zip(['id','title','symbol'],s)) for s in subjects],"topics":topics,"lessons":lessons}
Path('assets/content/catalog.json').write_text(json.dumps(catalog, ensure_ascii=False, indent=2), encoding='utf-8')
print(f'Wrote {len(lessons)} original demo lessons')
