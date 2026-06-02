/// Shared formatting utilities used across the application.
/// Centralizes common formatters to avoid code duplication.

/// Formats a numeric value into Indonesian Rupiah currency string.
/// Example: 50000 → 'Rp 50.000'
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

/// Formats an ISO date string into a human-readable Indonesian format.
/// Example: '2026-05-12T14:30:00Z' → '14:30 · 12 Mei 2026'
String formatDateTime(String raw) {
  try {
    final dt = DateTime.parse(raw);
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final month = months[dt.month - 1];
    return '$hour:$minute · $day $month ${dt.year}';
  } catch (e) {
    return raw;
  }
}

/// Formats a time string from a datetime value.
/// Example: '2026-05-12 14:30:00' → '14:30'
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
