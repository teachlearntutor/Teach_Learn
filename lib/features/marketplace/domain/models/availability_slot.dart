import 'marketplace_types.dart';

class AvailabilitySlot {
  const AvailabilitySlot({
    required this.weekday,
    required this.startMinute,
    required this.endMinute,
  }) : assert(startMinute >= 0),
       assert(endMinute <= 1440),
       assert(startMinute < endMinute);

  final Weekday weekday;
  final int startMinute;
  final int endMinute;
}
