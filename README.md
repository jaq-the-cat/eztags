Pure-Dart package that takes in tags and outputs the full binary version as a
complete ID3v2.3 tag, or puts them in a file directly.

## Features
This package is simple and easy to use, and can easily be used to add a number
of ID3 tags to any type of file.

## Getting started
To get started, make a `List` or `Map` of tags and convert them into a `TagList`
with `TagList.fromList()` or `TagList.fromMap()`.

Then you can simply use the `makeId3v2` function to convert all that information
into the ID3v2 binary format, or skip that step and add the tags to a file
immediately with `addTagsToFile()`.

## Usage

```dart
// Get tags from some API, or input them manually
final tags = {
  "title": "Snow (Hey Oh)",
  "artist": "Red Hot Chilli Peppers",
  "album": "Stadium Arcadium",
  "genre": "Alternative Rock",
  "artwork": "https://i.discogs.com/2k0D3eVBULh37nXGG1T6shlOcuxrwCc8tJ7kWpM3was/rs:fit/g:sm/q:90/h:530/w:600/czM6Ly9kaXNjb2dz/LWRhdGFiYXNlLWlt/YWdlcy9SLTUwMDU3/NzEtMTQyNDc4MzQ3/NS0yNTkyLmpwZWc.jpeg",
  "year": "2006"
}

// Get the binary tags
Uint8List binary = await makeId3v2(TagList.fromMap(tags));

// or

makeId3v2(TagList.fromMap(tags)).then((binary) {
  ...
});


// Add them to the file
addTagsToFile(TagList.fromMap(tags), 'file.mp3');
```

## Additional information

This package's source code is located in
[my github](https://github.com/jaq-the-cat/eztags).

You can contribute any time
and I will probably notice right away. File issues
as you see fit, I don't really mind, just don't spam my inbox, ok? :D