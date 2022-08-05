import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'imagedl.dart';
import 'bytestuff.dart';

const int _headerLength = 10;
const int _padding = 128;

String _toTitleCase(String s) {
  final result = StringBuffer();
  bool lastWasSpace = true;
  for (int i = 0; i < s.length; i++) {
    if (s[i] == ' ') {
      result.write(' ');
      lastWasSpace = true;
      continue;
    }
    if (lastWasSpace) {
      result.write(s[i].toUpperCase());
    } else {
      result.write(s[i].toLowerCase());
    }
    lastWasSpace = false;
  }
  return result.toString();
}

/// Tag type, self explanatory
enum TagType { title, artist, genre, album, year, artwork, track, duration }

extension _TagTypeExt on TagType {
  /// Returns the binary code of each tag type, which will be written to the file
  Uint8List get code {
    switch (this) {
      case TagType.title:
        return latin1.encode("TIT2");
      case TagType.artist:
        return latin1.encode("TPE1");
      case TagType.genre:
        return latin1.encode("TCON");
      case TagType.album:
        return latin1.encode("TALB");
      case TagType.year:
        return latin1.encode("TYER");
      case TagType.artwork:
        return latin1.encode("APIC");
      case TagType.track:
        return latin1.encode("TRCK");
      case TagType.duration:
        return latin1.encode("TLEN");
    }
  }
}

TagType? _tagTypeFromString(String type) {
  switch (type) {
    case "title":
      return TagType.title;
    case "artist":
      return TagType.artist;
    case "genre":
      return TagType.genre;
    case "album":
      return TagType.album;
    case "year":
      return TagType.year;
    case "artwork":
      return TagType.artwork;
    case "track":
      return TagType.track;
    case "duration":
      return TagType.duration;
  }
  return null;
}

/// List of tags. Does not allow for multiple tags with the same type
class TagList extends Iterable {
  final _list = <Tag>[];
  TagList();

  bool _hasTagType(TagType type) {
    for (var frame in _list) {
      if (frame.type == type) return true;
    }
    return false;
  }

  /// Transfers a list of tags to a TagList object.
  /// All this will do is remove all tags with the same [type].
  static TagList fromList(List<Tag> tags) {
    final list = TagList();
    for (final frame in tags) {
      list.add(frame);
    }
    return list;
  }

  /// Transfers a map of tags to a TagList object.
  /// It will read for keys `"title"`, `"artist"` and so on and add them to the list
  /// as [Tag]s
  static TagList fromMap(Map<String, String> tags) {
    final list = TagList();
    for (final frame in tags.entries) {
      TagType? type = _tagTypeFromString(frame.key);
      if (type == null) continue;
      list.add(Tag(type, frame.value));
    }
    return list;
  }

  void add(Tag frame) {
    if (!_hasTagType(frame.type)) {
      _list.add(frame);
    }
  }

  void remove(Tag frame) {
    _list.remove(frame);
  }

  @override
  Iterator get iterator => _list.iterator;
}

/// Represents an ID3v2 tag, the class you will be using the most with this library.
/// [type] represents a tag type, and [data] represents the tag's data.
/// A tag of type [TagType.artwork] has data which represents a URL to an image
/// A tag of type [TagType.duration] has data which represents the track's duration in milliseconds
/// The other tags are represented by strings which will get encoded into ISO 8859-1/Latin-1.
/// Examples of frames are (title, Numb), (genre, Alternative Rock), or (artwork, <link to image>)
class Tag {
  final TagType type;
  String data;
  Tag(this.type, this.data);

  Uint8List _makeFrame(Uint8List code, List<int> data) {
    int length = data.length;
    final binary = Uint8List(4 + 4 + 2 + length); // header size + data size
    binary.setAll(0, code); // 4 bytes
    binary.setAll(4, numberToBytes(length));
    binary.setAll(8, [0x00, 0x00]); // 2 bytes of flags
    binary.setAll(10, data);

    return binary;
  }

  Uint8List _textFrame(String data) =>
      _makeFrame(type.code, [0x00] + latin1.encode(data));

  Uint8List _picFrame(Image image) {
    final descriptionBin = latin1.encode("Artwork");
    final bin = Uint8List.fromList([0x00] + // uses ISO-8859 encoding
        latin1.encode(image.mimetype) +
        [0x00] +
        [0x03] + // cover (front)
        descriptionBin +
        [0x00] +
        image.binary);
    return _makeFrame(type.code, bin);
  }

  /// Returns the binary representation of a frame.
  ///
  /// You probably shouldn't be using this as an end user, but it's an option.
  Future<Uint8List> get frame async {
    switch (type) {
      case TagType.title:
      case TagType.artist:
      case TagType.album:
      case TagType.year:
      case TagType.track:
      case TagType.duration:
        return _textFrame(data);
      case TagType.genre:
        return _textFrame(_toTitleCase(data));
      case TagType.artwork:
        return _picFrame(await downloadImage(data));
    }
  }
}

/// Returns the complete binary representation of an ID3v2 tag. This should be
/// written in the first bytes of an audio file. An example of tagging an MP3 file is:
///
/// ```dart
/// final mp3content = File("music.mp3").readAsBytesSync();
/// final tagsBinary = await makeId3v2(tags);
/// final taggedFile = File("taggedMusic.mp3");
/// taggedFile.writeAsBytesSync(tagsBinary + mp3content);
/// ```
Future<Uint8List> makeId3v2(TagList tags) async {
  if (tags.isEmpty) return Uint8List(0);
  List<int> id3list = [];

  // header
  id3list.addAll([
    0x49, 0x44, 0x33, // ID3
    0x03, 0x00, // v2.3
    0x00, // no flags
    0xff, 0xff, 0xff, 0xff // temporary size
  ]); // 10 header bytes

  for (final tag in tags) {
    if (tag.data == null) continue;
    Uint8List? bin = await tag.frame;
    if (bin != null) {
      id3list.addAll(bin);
    }
  }

  final tagLen = id3list.length + _padding;
  final id3 = Uint8List(tagLen + _headerLength);
  id3.setAll(0, id3list);
  id3.setRange(6, 10, Uint28.fromInt(tagLen).bytes);

  return id3;
}

Future<void> addTagsToFile(TagList tags, String filename) async {
  final tagsBinary = await makeId3v2(tags);
  final mp3contents = File(filename).readAsBytesSync();
  File(filename).writeAsBytesSync(tagsBinary + mp3contents);
}
