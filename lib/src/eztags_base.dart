// TODO: Add documentation

import 'dart:typed_data';
import 'dart:convert';
import 'package:recase/recase.dart';
import 'imagedl.dart';
import 'bytestuff.dart';

const int _headerLength = 10;
const int _padding = 128;

// Tag type
enum TagType { title, artist, genre, album, year, artwork, track, duration }

extension _TagTypeExt on TagType {
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

TagType? tagTypeFromString(String type) {
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

class TagList extends Iterable {
  final _list = <Tag>[];
  TagList();

  bool _hasTagType(TagType type) {
    for (var frame in _list) {
      if (frame.type == type) return true;
    }
    return false;
  }

  static TagList fromList(List<Tag> tags) {
    final list = TagList();
    for (final frame in tags) {
      list.add(frame);
    }
    return list;
  }

  static TagList fromMap(Map<String, dynamic> tags) {
    final list = TagList();
    for (final frame in tags.entries) {
      TagType? type = tagTypeFromString(frame.key);
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

class Tag {
  final TagType type;
  dynamic data;
  Tag(this.type, this.data);

  Uint8List makeFrame(Uint8List code, List<int> data) {
    int length = data.length;
    final binary = Uint8List(4 + 4 + 2 + length); // header size + data size
    binary.setAll(0, code); // 4 bytes
    binary.setAll(4, numberToBytes(length));
    binary.setAll(8, [0x00, 0x00]); // 2 bytes of flags
    binary.setAll(10, data);

    return binary;
  }

  Uint8List get textFrame => makeFrame(type.code, [0x00] + latin1.encode(data));

  Uint8List get picFrame {
    final descriptionBin = latin1.encode("Artwork");
    final bin = Uint8List.fromList([0x00] + // uses ISO-8859 encoding
        latin1.encode(data.mimetype) +
        [0x00] +
        [0x03] + // cover (front)
        descriptionBin +
        [0x00] +
        data.binary);
    return makeFrame(type.code, bin);
  }

  Future<Uint8List?> get frame async {
    switch (type) {
      case TagType.title:
      case TagType.artist:
      case TagType.album:
      case TagType.year:
      case TagType.track:
      case TagType.duration:
        return textFrame;
      case TagType.genre:
        if (data != null) {
          data = ReCase(data).titleCase.toString();
          return textFrame;
        }
        break;
      case TagType.artwork:
        data = await downloadImage(data);
        return picFrame;
    }
    return null;
  }
}

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
