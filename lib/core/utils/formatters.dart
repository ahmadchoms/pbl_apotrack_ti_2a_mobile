String formatRupiah(num value) {
  final str = value.toStringAsFixed(0);
  final buffer = StringBuffer();
  final len = str.length;
  for (int i = 0; i < len; i++) {
    if (i > 0 && (len - i) % 3 == 0) buffer.write('.');
    buffer.write(str[i]);
  }
  return 'Rp ${buffer.toString()}';
}

String formatDateTime(String raw) {
  try {
    final dt = DateTime.parse(raw);
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final month = months[dt.month - 1];
    return '$hour:$minute · $day $month ${dt.year}';
  } catch (e) {
    return raw;
  }
}

String formatTime(dynamic dateStr) {
  if (dateStr == null) return '--:--';
  final str = dateStr.toString();
  try {
    final dt = DateTime.parse(str);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    final parts = str.split(' ');
    if (parts.length >= 2) {
      final timeParts = parts[1].split(':');
      if (timeParts.length >= 2) return '${timeParts[0]}:${timeParts[1]}';
    }
    return str.length > 5 ? str.substring(0, 5) : str;
  }
}
