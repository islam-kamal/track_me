String formatWhen(DateTime time) {
  final local = time.toLocal();
  final diff = DateTime.now().difference(local);
  if (diff.isNegative || diff.inSeconds < 45) {
    return 'Just now';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes} min ago';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours} h ago';
  }
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.month}/${local.day} $hour:$minute';
}

String formatHour(DateTime time) {
  final hour = time.toLocal().hour.toString().padLeft(2, '0');
  return '$hour:00';
}

bool isSameLocalDay(DateTime time, DateTime day) {
  final local = time.toLocal();
  final other = day.toLocal();
  return local.year == other.year &&
      local.month == other.month &&
      local.day == other.day;
}

String formatCoordinates(double latitude, double longitude) {
  return '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
}
