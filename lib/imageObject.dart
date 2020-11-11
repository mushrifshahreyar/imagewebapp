class ImageObject {
  final String id;
  final String filename;
  dynamic metadata;

  ImageObject(this.id, this.filename, this.metadata);

  Map<String, String> toJson() => {
        'name': filename,
        'id': id,
      };
}
