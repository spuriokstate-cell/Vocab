/// Hand-checked word groups used to keep game questions fair.
library;

/// Words that sound alike. A listening question never offers a sound-alike of
/// the answer as a choice, and spelling-by-ear reads the example sentence so
/// the child knows which one is meant.
const List<List<String>> homophoneGroups = [
  ['there', 'their', "they're"], ['to', 'too', 'two'], ['by', 'buy'],
  ['for', 'four'], ['know', 'no'], ['knew', 'new'], ['right', 'write'],
  ['one', 'won'], ['sun', 'son'], ['our', 'hour'], ['eight', 'ate'],
  ['eye', 'i'], ['see', 'sea'], ['week', 'weak'], ['meat', 'meet'],
  ['dear', 'deer'], ['pair', 'pear'], ['bear', 'bare'], ['piece', 'peace'],
  ['blue', 'blew'], ['knight', 'night'], ['hole', 'whole'], ['sail', 'sale'],
  ['tail', 'tale'], ['road', 'rode'], ['plain', 'plane'], ['here', 'hear'],
  ['wood', 'would'], ['sent', 'cent'], ['break', 'brake'],
  ['threw', 'through'], ['be', 'bee'], ['so', 'sew'], ['toe', 'tow'],
  ['wait', 'weight'], ['way', 'weigh'], ['which', 'witch'],
  ['nose', 'knows'], ['its', "it's"], ['red', 'read'], ['wear', 'where'],
  ['mail', 'male'], ['flower', 'flour'], ['hair', 'hare'], ['heel', 'heal'],
  ['not', 'knot'], ['made', 'maid'], ['tied', 'tide'], ['desert', 'dessert'],
  ['lose', 'loose'], ['quite', 'quiet'], ['chose', 'choose'],
];

/// Families of words that could easily fit the same sentence. A wrong
/// choice is never taken from the same family as the answer: for
/// "My shoes are ___." offering "red" and "big" would make two answers
/// correct, so all describing words are one family.
const List<List<String>> confusableGroups = [
  // Describing words (colors, sizes, feelings, weather, qualities).
  ['red', 'blue', 'green', 'yellow', 'orange', 'pink', 'purple', 'brown',
   'black', 'white', 'gray', 'silver', 'big', 'small', 'little', 'large',
   'tiny', 'giant', 'long', 'short', 'tall', 'wide', 'thin', 'thick', 'fat',
   'happy', 'sad', 'glad', 'mad', 'angry', 'afraid', 'proud', 'excited',
   'silly', 'kind', 'nice', 'good', 'bad', 'great', 'fine', 'sorry',
   'thankful', 'hopeful', 'careful', 'helpful', 'useful', 'busy', 'sick',
   'ill', 'hungry', 'thirsty', 'hot', 'cold', 'cool', 'wet', 'dry', 'sunny',
   'rainy', 'cloudy', 'windy', 'muddy', 'dirty', 'clean', 'fast', 'quick',
   'slow', 'beautiful', 'pretty', 'ugly', 'wonderful', 'terrible',
   'important', 'special', 'simple', 'easy', 'hard', 'soft', 'loud', 'quiet',
   'noisy', 'silent', 'strong', 'weak', 'heavy', 'light', 'bright', 'dark',
   'new', 'old', 'young', 'sweet', 'sour', 'safe', 'dangerous', 'perfect',
   'correct', 'wrong', 'right', 'true', 'different', 'same', 'ready', 'free',
   'wild', 'fresh', 'smart', 'sharp', 'smooth', 'empty', 'full', 'deep',
   'plain', 'crazy', 'honest', 'merry', 'mild', 'poor', 'cheap', 'common',
   'friendly', 'funny', 'sudden', 'certain', 'necessary', 'interesting',
   'odd', 'awake', 'asleep', 'alone', 'alike', 'broken', 'flat', 'round',
   'square', 'hollow', 'wooden', 'tight', 'loose', 'high', 'low', 'near',
   'far', 'early', 'late', 'super', 'wise', 'brave', 'sure', 'whole',
   'single', 'double', 'fair', 'dear', 'lost', 'done', 'open', 'close',
   'best', 'better', 'worse', 'worst', 'latest', 'slowest', 'quickest',
   'happiest', 'nearest', 'toughest', 'louder', 'absent', 'present',
   'northern', 'clear', 'gone'],
  // Numbers, amounts and order.
  ['one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine',
   'ten', 'eleven', 'twelve', 'thirteen', 'fourteen', 'twenty', 'thirty',
   'forty', 'fifty', 'sixty', 'seventy', 'eighty', 'ninety', 'hundred',
   'thousand', 'million', 'dozen', 'few', 'many', 'several', 'some', 'any',
   'all', 'both', 'each', 'every', 'most', 'none', 'half', 'couple', 'more',
   'less', 'much', 'plenty', 'first', 'second', 'third', 'fourth', 'fifth',
   'seventh', 'eighth', 'tenth', 'last', 'next', 'once', 'twice'],
  // People and family.
  ['mom', 'dad', 'mother', 'father', 'sister', 'brother', 'uncle',
   'parents', 'family', 'friend', 'baby', 'child', 'children', 'kid',
   'boy', 'girl', 'man', 'woman', 'men', 'women', 'lady', 'person',
   'people', 'teacher', 'neighbor', 'son', 'wife', 'husband', 'king',
   'knight', 'clown', 'driver', 'leader', 'owner', 'reader', 'writer',
   'winner', 'visitor', 'fellow', 'maid', 'army', 'team', 'class', 'crowd'],
  // Animals.
  ['cat', 'dog', 'fox', 'hen', 'bird', 'fish', 'frog', 'ant', 'bat', 'bee',
   'owl', 'cow', 'goat', 'horse', 'mouse', 'mice', 'monkey', 'bear', 'lamb',
   'toad', 'puppy', 'kitten', 'bunny', 'goose', 'animal', 'pet'],
  // Food and drink.
  ['pie', 'cake', 'egg', 'corn', 'rice', 'bread', 'meat', 'candy', 'potato',
   'sandwich', 'butter', 'jelly', 'cherry', 'pear', 'bean', 'salt', 'sugar',
   'milk', 'water', 'orange', 'food', 'lunch', 'dinner', 'supper',
   'breakfast', 'meal', 'dessert', 'treat', 'cream', 'oil', 'soy', 'snack'],
  // Body.
  ['head', 'hand', 'foot', 'feet', 'leg', 'arm', 'eye', 'ear', 'nose',
   'mouth', 'lip', 'neck', 'knee', 'toe', 'heel', 'chin', 'cheek', 'hair',
   'teeth', 'tooth', 'thumb', 'finger', 'wrist', 'chest', 'skin', 'face',
   'body', 'throat', 'brain', 'heart', 'back'],
  // Clothes.
  ['hat', 'coat', 'shirt', 'pants', 'dress', 'skirt', 'socks', 'shoe',
   'boot', 'hood', 'collar', 'costume', 'clothes', 'tie', 'ring'],
  // Ways to travel.
  ['bus', 'truck', 'car', 'bike', 'bicycle', 'boat', 'ship', 'plane', 'jet',
   'train', 'wagon'],
  // Places.
  ['home', 'house', 'school', 'park', 'farm', 'barn', 'store', 'shop',
   'city', 'town', 'room', 'hall', 'yard', 'library', 'office', 'church',
   'bank', 'lake', 'river', 'ocean', 'hill', 'mountain', 'jungle', 'desert',
   'beach', 'shore', 'creek', 'brook', 'street', 'road', 'path', 'bridge',
   'country', 'state', 'county', 'world', 'land', 'camp', 'outside',
   'inside', 'there', 'here', 'away', 'closet', 'garden', 'kitchen'],
  // Things in a house or classroom.
  ['bed', 'table', 'chair', 'lamp', 'door', 'window', 'wall', 'floor',
   'stairs', 'box', 'bag', 'cup', 'dish', 'pan', 'spoon', 'fork', 'bottle',
   'glass', 'pillow', 'blanket', 'curtain', 'mirror', 'shelf', 'basket',
   'book', 'pen', 'pencil', 'crayon', 'paper', 'card', 'toy', 'ball', 'doll',
   'kite', 'drum', 'bell', 'phone', 'candle', 'broom', 'hammer', 'tool',
   'rope', 'string', 'wire', 'chain', 'stool', 'saucer', 'barrel', 'gift',
   'present', 'block', 'balloon', 'needle', 'nail', 'button'],
  // Pronouns.
  ['i', 'you', 'he', 'she', 'it', 'we', 'they', 'me', 'him', 'her', 'us',
   'them', 'my', 'your', 'his', 'its', 'our', 'their', 'mine', 'yours',
   'myself', 'ourselves', 'self', 'whom', 'who'],
  ['a', 'an', 'the', 'this', 'that', 'these', 'those'],
  // Position and direction words.
  ['in', 'on', 'at', 'by', 'to', 'from', 'into', 'under', 'over', 'above',
   'below', 'behind', 'beneath', 'near', 'with', 'off', 'up', 'down',
   'out', 'around', 'across', 'through', 'along', 'toward', 'upon',
   'between', 'among', 'against', 'beside', 'apart', 'ahead', 'for', 'of',
   'without', 'until', 'since', 'during', 'before', 'after', 'about',
   'back'],
  // Time words.
  ['morning', 'afternoon', 'evening', 'night', 'tonight', 'today',
   'tomorrow', 'yesterday', 'noon', 'day', 'week', 'month', 'year',
   'minute', 'hour', 'moment', 'now', 'then', 'soon', 'later', 'lately',
   'always', 'never', 'often', 'again', 'already', 'still', 'yet', 'ever',
   'awhile', 'spring', 'summer', 'fall', 'winter', 'season', 'holiday',
   'birthday', 'date', 'time', "o'clock"],
  // Action words that often swap: moving.
  ['run', 'walk', 'jump', 'hop', 'swim', 'ride', 'climb', 'crawl', 'dance',
   'play', 'race', 'rush', 'hurry', 'go', 'come', 'move', 'fly', 'drive',
   'sit', 'stand', 'stay', 'rest', 'sleep', 'skip', 'spin', 'chase',
   'follow', 'lead', 'leave', 'return', 'enter', 'visit'],
  // Eating and cooking.
  ['eat', 'drink', 'cook', 'bake', 'fry', 'boil', 'taste', 'bite', 'lick',
   'feed', 'stir', 'mix', 'pour'],
  // Looking and finding.
  ['see', 'look', 'watch', 'saw', 'seen', 'find', 'found', 'locate',
   'discover', 'notice', 'check'],
  // Talking.
  ['say', 'said', 'says', 'tell', 'told', 'ask', 'answer', 'talk', 'shout',
   'scream', 'call', 'sing', 'spoke', 'explain', 'read', 'spell', 'write',
   'print', 'draw', 'count', 'laugh', 'cry', 'greet'],
  // Feeling and wanting.
  ['like', 'love', 'enjoy', 'want', 'need', 'wish', 'hope', 'miss', 'care',
   'believe', 'think', 'know', 'guess', 'remember', 'forget', 'learn',
   'understand', 'expect', 'suppose', 'agree', 'worry'],
  // Giving and getting.
  ['give', 'gave', 'get', 'got', 'take', 'took', 'bring', 'brought', 'buy',
   'bought', 'sell', 'pay', 'paid', 'send', 'sent', 'lend', 'share', 'keep',
   'hold', 'carry', 'catch', 'throw', 'grab', 'pick', 'receive', 'win',
   'won', 'lose', 'have', 'has', 'had', 'make', 'made', 'build', 'built',
   'open', 'close', 'use', 'help', 'put', 'cut', 'clean', 'wash', 'fix'],
  ['can', 'could', 'will', 'would', 'should', 'must', 'may', 'might',
   'shall', 'cannot', "can't", "won't", "don't", "didn't", "doesn't",
   "isn't", "wasn't"],
  ['is', 'am', 'are', 'was', 'were', 'be', 'been'],
  ['and', 'or', 'but', 'so', 'because', 'if', 'than', 'then', 'when',
   'while', 'whether', 'where', 'what', 'why', 'how', 'which'],
  ['very', 'too', 'so', 'quite', 'really', 'truly', 'just', 'only',
   'almost', 'also', 'even', 'hardly', 'probably', 'perhaps', 'maybe',
   'finally', 'slowly', 'safely'],
];

/// Words that a child can recognise from a picture. Emoji are drawn by the
/// device's own emoji font, so no image files are needed. Only emoji from
/// Unicode 11 or earlier are used, so they show on older Windows 10 PCs.
const Map<String, String> pictureWords = {
  'cat': '🐱', 'dog': '🐶', 'fox': '🦊', 'hen': '🐔', 'bus': '🚌',
  'sun': '☀️', 'truck': '🚚', 'car': '🚗', 'rain': '🌧️', 'moon': '🌙',
  'bird': '🐦', 'house': '🏠', 'ball': '⚽', 'ant': '🐜', 'bat': '🦇',
  'cake': '🎂', 'tree': '🌳', 'fish': '🐟', 'frog': '🐸', 'milk': '🥛',
  'bike': '🚲', 'bed': '🛏️', 'hat': '🎩', 'box': '📦', 'foot': '🦶',
  'hand': '✋', 'leg': '🦵', 'eye': '👁️', 'nose': '👃', 'ear': '👂',
  'bee': '🐝', 'boat': '⛵', 'horse': '🐴', 'goat': '🐐', 'pie': '🥧',
  'cow': '🐄', 'owl': '🦉', 'baby': '👶', 'book': '📖', 'school': '🏫',
  'cloud': '☁️', 'king': '🤴', 'bone': '🦴', 'ice': '🧊', 'corn': '🌽',
  'leaf': '🍃', 'rice': '🍚', 'shirt': '👕', 'mouse': '🐭', 'ship': '🚢',
  'gift': '🎁', 'crayon': '🖍️', 'shoe': '👟', 'pen': '🖊️', 'bell': '🔔',
  'drum': '🥁', 'bear': '🐻', 'snow': '❄️', 'heart': '❤️', 'cherry': '🍒',
  'candy': '🍬', 'egg': '🥚', 'wool': '🧶', 'lamb': '🐑', 'church': '⛪',
  'monkey': '🐒', 'ocean': '🌊', 'pencil': '✏️', 'hammer': '🔨',
  'sandwich': '🥪', 'balloon': '🎈', 'phone': '📱', 'spoon': '🥄',
  'broom': '🧹', 'clown': '🤡', 'flower': '🌸', 'potato': '🥔',
  'water': '💧', 'brain': '🧠', 'storm': '⛈️', 'candle': '🕯️',
  'plane': '✈️', 'tooth': '🦷', 'orange': '🍊', 'pear': '🍐', 'bread': '🍞',
  'kite': '🪁', 'door': '🚪', 'lamp': '💡',
  'train': '🚆', 'smile': '😀',
  'chair': '🪑', };

/// The families each word belongs to (a word can be in more than one).
final Map<String, Set<int>> confusableIndex = () {
  final m = <String, Set<int>>{};
  for (var i = 0; i < confusableGroups.length; i++) {
    for (final w in confusableGroups[i]) {
      m.putIfAbsent(w, () => <int>{}).add(i);
    }
  }
  return m;
}();

/// The kind of word in each family above (same order):
/// A = describing word, N = naming word, V = action word,
/// T = time word, F = small helper word.
const List<String> confusableKinds = [
  'A', 'F', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'F', 'F', 'F', 'T', 'V', 'V', 'V', 'V', 'V', 'V', 'F', 'F', 'F', 'F',
];

/// The kinds of a word, or an empty set if it isn't in any family.
Set<String> wordKinds(String w) => {
      for (final i in confusableIndex[w.toLowerCase()] ?? const <int>{})
        confusableKinds[i],
    };

final Map<String, int> homophoneIndex = {
  for (var i = 0; i < homophoneGroups.length; i++)
    for (final w in homophoneGroups[i]) w: i,
};

/// True if [a] and [b] sound the same (and are different words).
bool soundsAlike(String a, String b) {
  final x = homophoneIndex[a.toLowerCase()];
  return x != null && x == homophoneIndex[b.toLowerCase()];
}

/// True if [a] and [b] could easily both fit the same sentence.
bool easilyConfused(String a, String b) {
  final x = confusableIndex[a.toLowerCase()];
  final y = confusableIndex[b.toLowerCase()];
  return x != null && y != null && x.any(y.contains);
}
