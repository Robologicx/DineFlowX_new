String getDirectImageUrl(String url) {
  // Example: https://drive.google.com/file/d/<FILE_ID>/view?usp=sharing
  final regExp = RegExp(r'd/([^/]+)/');
  final match = regExp.firstMatch(url);
  if (match != null && match.groupCount >= 1) {
    final fileId = match.group(1);
    return 'https://drive.google.com/uc?export=view&id=$fileId';
  }
  return url; // fallback in case format is already correct
}
