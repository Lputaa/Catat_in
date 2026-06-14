class TimeGap {

  final DateTime start;
  final DateTime end;

  const TimeGap({
    required this.start,
    required this.end,
  });

  Duration get duration =>
      end.difference(start);
}