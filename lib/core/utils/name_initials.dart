String nameInitials(String name, {String fallback = 'T'}) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty);
  if (parts.isEmpty) return fallback;
  final words = parts.toList();
  if (words.length == 1) {
    final word = words.first;
    return word.substring(0, word.length > 1 ? 2 : 1).toUpperCase();
  }
  return '${words.first[0]}${words.last[0]}'.toUpperCase();
}
