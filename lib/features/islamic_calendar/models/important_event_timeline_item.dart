class ImportantEventTimelineItem {
  const ImportantEventTimelineItem({
    required this.date,
    required this.event,
    required this.isSelectedDate,
  });

  final DateTime date;
  final String event;
  final bool isSelectedDate;
}
