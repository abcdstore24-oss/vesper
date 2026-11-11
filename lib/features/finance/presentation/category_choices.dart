// What the user can choose for a category they create or restyle. The DAO
// only checks the SHAPE of an icon key and a colour; these lists are the UI's
// palettes (a UI concern, so they live here, next to category_display.dart).
//
// Registered in COMPONENTS.md.

/// Icon KEYS offered in the category sheet: the 20 non-system keys that
/// category_display.dart can draw, `tag` first (the default for a new
/// category). The six system keys (arrow_up_right, arrow_down_left,
/// hand_coins, handshake, trend_up, trend_down) are never offered. New keys
/// are not added here without adding them to category_display.dart first.
const List<String> categoryIconChoices = <String>[
  'tag',
  'fork_knife',
  'shopping_cart',
  'car',
  'receipt',
  'house',
  'shopping_bag',
  'heartbeat',
  'graduation_cap',
  'film_slate',
  'airplane',
  'repeat',
  'sparkle',
  'gift',
  'dots_three',
  'paw_print',
  'briefcase',
  'storefront',
  'piggy_bank',
  'arrow_u_up_left',
];

/// The 12 DISTINCT colours (opaque 0xFFRRGGBB) the built-in expense and
/// income categories use (category_seeder.dart), in order of first use. The
/// first one is the default for a new category. This is the one allowed
/// multi-colour exception (CLAUDE.md Section 3).
const List<int> categoryColorChoices = <int>[
  0xFFC97B84,
  0xFF8FB38A,
  0xFF6FA3A8,
  0xFFD9A066,
  0xFFC7826B,
  0xFFC98BB0,
  0xFF7FA6C9,
  0xFF7B8FC7,
  0xFFA68BC7,
  0xFF8C9A7E,
  0xFFB5A06A,
  0xFF9C95A8,
];
