class HizbPart {
  final String id;
  final String title;
  final String? subtitle;
  final String content;

  const HizbPart({
    required this.id,
    required this.title,
    this.subtitle,
    required this.content,
  });
}
