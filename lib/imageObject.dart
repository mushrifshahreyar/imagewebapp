class ImageObject {
  final String id;
  final String filename;

  ImageObject(this.id, this.filename);

  Map<String, String> toJson() => {
        'name': filename,
        'id': id,
      };
}
