import 'dart:io';
import 'dart:typed_data';

import 'package:eztags/eztags.dart';

void main() async {
  // tags from map (recommended)
  final tagsMap = TagList.fromMap({
    "title": "Snow (Hey Oh)",
    "artist": "Red Hot Chilli Peppers",
    "album": "Stadium Arcadium",
    "genre": "Alternative Rock",
    "artwork":
        "https://i.discogs.com/2k0D3eVBULh37nXGG1T6shlOcuxrwCc8tJ7kWpM3was/rs:fit/g:sm/q:90/h:530/w:600/czM6Ly9kaXNjb2dz/LWRhdGFiYXNlLWlt/YWdlcy9SLTUwMDU3/NzEtMTQyNDc4MzQ3/NS0yNTkyLmpwZWc.jpeg",
    "year": "2006"
  });
  
  // tags from list
  final tagsList = TagList.fromList([
    Tag(TagType.title, "Snow (Hey Oh)"),
    Tag(TagType.artist, "Red Hot Chilli Peppers"),
    Tag(TagType.album, "Stadium Arcadium"),
    Tag(TagType.genre, "Alternative Rock"),
    Tag(TagType.artwork, "discogs.com/2k0D3eVBULh37nXGG1T6shlOcuxrwCc8tJ7kWpM3was/rs:fit/g:sm/q:90/h:530/w:600/czM6Ly9kaXNjb2dz/LWRhdGFiYXNlLWlt/YWdlcy9SLTUwMDU3/NzEtMTQyNDc4MzQ3/NS0yNTkyLmpwZWc.jpeg"),
  ]);

  // tags manually
  final tagsManual = TagList();
  tagsManual.add(Tag(TagType.title, "Snow (Hey Oh)"));
  tagsManual.add(Tag(TagType.artist, "Red Hot Chilli Peppers"));
  tagsManual.add(Tag(TagType.album, "Stadium Arcadium"));
  tagsManual.add(Tag(TagType.genre, "Alternative Rock"));
  tagsManual.add(Tag(TagType.artwork,
      "https://i.discogs.com/2k0D3eVBULh37nXGG1T6shlOcuxrwCc8tJ7kWpM3was/rs:fit/g:sm/q:90/h:530/w:600/czM6Ly9kaXNjb2dz/LWRhdGFiYXNlLWlt/YWdlcy9SLTUwMDU3/NzEtMTQyNDc4MzQ3/NS0yNTkyLmpwZWc.jpeg"));
  tagsManual.add(Tag(TagType.year, "2006"));

  // add to file manually
  Uint8List binary = await makeId3v2(tagsMap);
  File("file.mp3").writeAsBytesSync(binary);

  // add to file automatically
  addTagsToFile(tagsMap, 'file.mp3');
}
