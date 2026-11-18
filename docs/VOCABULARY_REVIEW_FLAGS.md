# Vocabulary Review Flags

These entries were **not changed**. They need a parent's decision. To approve a fix, edit the entry in `assets/vocabulary/grade1.json` or `grade2.json` and run `python3 tool/validate_vocabulary.py` again.

## 1. Example sentence does not contain the exact word (17)

The fill-in-the-blank engine only blanks the exact word, so these are **left out of Fill in the Blanks** until approved. All other activities use them normally.

| Id | Word | Example in PDF | Suggested replacement (needs approval) |
|---|---|---|---|
| g1_0152 | thumb | Give me a thumbs up! | Hold up your thumb. |
| g2_0036 | eye | I have brown eyes. | Close one eye and wink. |
| g2_0135 | block | I built a tower with blocks. | Put the red block on top. |
| g2_0212 | nail | Paint my nails pink. | Dad hit the nail with a hammer. |
| g2_0222 | wheel | A bike has two wheels. | The front wheel is flat. |
| g2_0266 | pound | The puppy weighs ten pounds. | This bag of apples weighs one pound. |
| g2_0363 | spot | A ladybug has black spots. | The puppy has a black spot. |
| g2_0424 | boot | Wear boots in the snow. | I can't find my left boot. |
| g2_0425 | root | Roots drink water for the plant. | The root grows under the ground. |
| g2_0499 | potato | I like baked potatoes. | I ate a baked potato. |
| g2_0529 | curtain | Close the curtains at night. | Close the curtain at night. |
| g2_0540 | taste | This cake tastes yummy. | Taste the soup before you add salt. |
| g2_0622 | brick | The house is made of bricks. | He laid one brick at a time. |
| g2_0727 | manner | Use good manners at the table. | She spoke in a kind manner. |
| g2_0751 | wing | The bird flapped its wings. | The bird hurt its wing. |
| g2_0779 | ton | An elephant weighs tons! | The big truck carried a ton of rocks. |
| g2_0788 | bean | I like green beans. | I planted a bean seed. |

## 2. Word appears more than once in its example (2)

Handled automatically: every occurrence becomes a blank and the child answers once.

| Id | Word | Example |
|---|---|---|
| g1_0004 | as | She is as tall as her brother. |
| g1_0312 | lip | I put lip balm on my lip. |

## 3. Words that sound like another word in the list (30 groups)

Handled automatically: listening activities read the example sentence for context and never offer a sound-alike word as a wrong choice.

- there / their / they're
- to / too / two
- by / buy
- for / four
- know / no
- knew / new
- right / write
- one / won
- sun / son
- our / hour
- eight / ate
- eye / I
- week / weak
- meat / meet
- pair / pear
- piece / peace
- blue / blew
- knight / night
- hole / whole
- sail / sale
- road / rode
- plain / plane
- wood / would
- sent / cent
- break / brake
- threw / through
- be / bee
- way / weigh
- red / read
- made / maid
