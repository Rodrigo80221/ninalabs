void main() {
  Map<String, dynamic> json = {
    'ImagemDeAbertura': [{'url': 'hello'}]
  };
  
  final openingImage = json['ImagemDeAbertura'] ?? json['field_6964823'] as List?;
  
  try {
    if (openingImage != null && openingImage.isNotEmpty) {
      print(openingImage.first['url']);
    }
  } catch (e) {
    print('Error: $e');
  }
}
