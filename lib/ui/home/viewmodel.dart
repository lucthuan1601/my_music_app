import 'dart:async';

import 'package:my_music_app/data/repository/repository.dart';

import '../../data/model/song.dart';

class MusicAppViewModel {
  StreamController<List<Song>> songStream = StreamController();


  void loadSongs(){
    final repository = DefaultRepository();
    repository.loadData().then((song)=>songStream.add(song!));
  }


}