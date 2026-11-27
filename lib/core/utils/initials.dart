/// "Alex Morgan" -> "AM". Empty names give "?".
String initialsOf(String first, String last) {
  final a = first.trim().isEmpty ? '' : first.trim()[0];
  final b = last.trim().isEmpty ? '' : last.trim()[0];
  final s = '$a$b'.toUpperCase();
  return s.isEmpty ? '?' : s;
}
