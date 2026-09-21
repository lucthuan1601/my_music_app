import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

class AudioPlayerManager {
  // 1. Khởi tạo Singleton
  static final AudioPlayerManager _instance = AudioPlayerManager._internal();
  factory AudioPlayerManager() => _instance;
  AudioPlayerManager._internal();

  final player = AudioPlayer();
  /// Stream chứa thông tin về thời lượng của bài hát
  ///Stream<DurationState>? durationState;

  BehaviorSubject<DurationState>? durationState;
  String currentSongUrl = "";

  /*
  void init({required String songUrl}) {
    // Chỉ khởi tạo lại nếu là bài hát mới
    if (currentSongUrl == songUrl) return;

    currentSongUrl = songUrl;
    durationState = Rx.combineLatest2<Duration, PlaybackEvent, DurationState>(
      player.positionStream,
      player.playbackEventStream,
          (position, playbackEvent) => DurationState(
        progress: position,
        buffered: playbackEvent.bufferedPosition,
        total: playbackEvent.duration,
      ),
    );
    player.setUrl(songUrl);
  }

   */

  void init({required String songUrl}) {
    // Nếu là bài hát mới, dispose stream cũ trước
    if (currentSongUrl != songUrl && durationState != null) {
      durationState?.close();
      durationState = null;
    } else if (currentSongUrl == songUrl) {
      return;
    }

    currentSongUrl = songUrl;
    durationState = BehaviorSubject<DurationState>();

    Rx.combineLatest2<Duration, PlaybackEvent, DurationState>(
      player.positionStream,
      player.playbackEventStream,
          (position, playbackEvent) => DurationState(
        progress: position,
        buffered: playbackEvent.bufferedPosition,
        total: playbackEvent.duration,
      ),
    ).listen((state) {
      if (!durationState!.isClosed) {
        durationState!.add(state);
      }
    });

    player.setUrl(songUrl);
  }


  void updateSongUrl (String url){
    init(songUrl: url);
  }

  void dispose() {
    durationState?.close();
    durationState = null;
  }

}



class DurationState {
  const DurationState({
    required this.progress,
    required this.buffered,
    this.total,
  });

  final Duration progress;
  final Duration buffered;
  final Duration? total;
}
