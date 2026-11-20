/// Built-in lessons. Each lesson is a themed set of words and phrases; the
/// AI tutor builds exercises on top of them, and every item can be turned
/// into a flashcard.
class VocabItem {
  const VocabItem(this.es, this.en, {this.note});

  final String es;
  final String en;
  final String? note;
}

class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.emoji,
    required this.summary,
    required this.items,
  });

  final String id;
  final String title;
  final String emoji;
  final String summary;
  final List<VocabItem> items;
}

const lessons = <Lesson>[
  Lesson(
    id: 'greetings',
    title: 'Saludos',
    emoji: '👋',
    summary: 'Greetings, introductions and polite phrases',
    items: [
      VocabItem('Hola', 'Hello'),
      VocabItem('Buenos días', 'Good morning'),
      VocabItem('Buenas tardes', 'Good afternoon'),
      VocabItem('Buenas noches', 'Good evening / Good night'),
      VocabItem('¿Cómo estás?', 'How are you? (informal)'),
      VocabItem('¿Cómo está usted?', 'How are you? (formal)'),
      VocabItem('Me llamo…', 'My name is…'),
      VocabItem('Mucho gusto', 'Nice to meet you'),
      VocabItem('Por favor', 'Please'),
      VocabItem('Gracias', 'Thank you'),
      VocabItem('De nada', "You're welcome"),
      VocabItem('Hasta luego', 'See you later'),
    ],
  ),
  Lesson(
    id: 'food',
    title: 'La comida',
    emoji: '🍽️',
    summary: 'Ordering food and drinks',
    items: [
      VocabItem(
        'el agua',
        'water',
        note: 'Feminine, but takes "el" because it starts with a stressed a-',
      ),
      VocabItem('el pan', 'bread'),
      VocabItem('la carne', 'meat'),
      VocabItem('el pollo', 'chicken'),
      VocabItem('el pescado', 'fish (as food)'),
      VocabItem('la fruta', 'fruit'),
      VocabItem('el arroz', 'rice'),
      VocabItem('la cuenta', 'the bill'),
      VocabItem('Quisiera…', 'I would like…'),
      VocabItem('¿Qué me recomienda?', 'What do you recommend?'),
      VocabItem('Tengo hambre', "I'm hungry"),
      VocabItem('Está delicioso', "It's delicious"),
    ],
  ),
  Lesson(
    id: 'numbers',
    title: 'Los números',
    emoji: '🔢',
    summary: 'Numbers, prices and time',
    items: [
      VocabItem('uno', 'one'),
      VocabItem('dos', 'two'),
      VocabItem('tres', 'three'),
      VocabItem('cuatro', 'four'),
      VocabItem('cinco', 'five'),
      VocabItem('diez', 'ten'),
      VocabItem('veinte', 'twenty'),
      VocabItem('cien', 'one hundred'),
      VocabItem('¿Cuánto cuesta?', 'How much does it cost?'),
      VocabItem('¿Qué hora es?', 'What time is it?'),
      VocabItem('Son las tres', "It's three o'clock"),
    ],
  ),
  Lesson(
    id: 'travel',
    title: 'De viaje',
    emoji: '✈️',
    summary: 'Directions, transport and hotels',
    items: [
      VocabItem('¿Dónde está…?', 'Where is…?'),
      VocabItem('el baño', 'the bathroom'),
      VocabItem('la estación', 'the station'),
      VocabItem('el aeropuerto', 'the airport'),
      VocabItem('a la derecha', 'to the right'),
      VocabItem('a la izquierda', 'to the left'),
      VocabItem('todo recto', 'straight ahead'),
      VocabItem('cerca', 'near'),
      VocabItem('lejos', 'far'),
      VocabItem('Tengo una reserva', 'I have a reservation'),
      VocabItem('un billete', 'a ticket'),
    ],
  ),
  Lesson(
    id: 'verbs',
    title: 'Verbos esenciales',
    emoji: '🏃',
    summary: 'ser, estar, tener, ir, querer (present tense)',
    items: [
      VocabItem(
        'ser',
        'to be (identity, traits)',
        note: 'soy, eres, es, somos, son',
      ),
      VocabItem(
        'estar',
        'to be (states, location)',
        note: 'estoy, estás, está, estamos, están',
      ),
      VocabItem(
        'tener',
        'to have',
        note: 'tengo, tienes, tiene, tenemos, tienen',
      ),
      VocabItem('ir', 'to go', note: 'voy, vas, va, vamos, van'),
      VocabItem(
        'querer',
        'to want',
        note: 'quiero, quieres, quiere, queremos, quieren',
      ),
      VocabItem(
        'hablar',
        'to speak',
        note: 'hablo, hablas, habla, hablamos, hablan',
      ),
      VocabItem('comer', 'to eat', note: 'como, comes, come, comemos, comen'),
      VocabItem('vivir', 'to live', note: 'vivo, vives, vive, vivimos, viven'),
      VocabItem('Soy de…', "I'm from…"),
      VocabItem('Estoy cansado', "I'm tired"),
    ],
  ),
  Lesson(
    id: 'family',
    title: 'La familia',
    emoji: '👨‍👩‍👧',
    summary: 'Family members and describing people',
    items: [
      VocabItem('la madre', 'mother'),
      VocabItem('el padre', 'father'),
      VocabItem('el hermano', 'brother'),
      VocabItem('la hermana', 'sister'),
      VocabItem('el hijo', 'son'),
      VocabItem('la hija', 'daughter'),
      VocabItem('los abuelos', 'grandparents'),
      VocabItem('alto / alta', 'tall'),
      VocabItem('simpático / simpática', 'nice, friendly'),
      VocabItem('Tengo dos hermanos', 'I have two siblings'),
    ],
  ),
];
