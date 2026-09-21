import 'dart:async';
import 'dart:ffi';
import 'dart:math';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../data/model/song.dart';
import 'audio_player_manager.dart';

class NowPlaying extends StatelessWidget {
  const NowPlaying({super.key, required this.songs, required this.playingSong});

  final Song playingSong;
  final List<Song> songs;

  @override
  Widget build(BuildContext context) {
    return NowPlayingPage(songs: songs, playingSong: playingSong);
  }
}

class NowPlayingPage extends StatefulWidget {
  const NowPlayingPage({
    super.key,
    required this.songs,
    required this.playingSong,
  });

  final Song playingSong;
  final List<Song> songs;

  @override
  State<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends State<NowPlayingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late AudioPlayerManager _audioPlayerManager;
  late int _selectedItemIndex;
  late Song _song;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<void>? _sequenceStateSubscription;
  late LoopMode _loopMode;

  bool _isShuffle = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 12000),
    );

    _audioPlayerManager = AudioPlayerManager();
    _audioPlayerManager.init(songUrl: widget.playingSong.source);

    // Lắng nghe trạng thái để xoay đĩa và auto-next song
    _playerStateSubscription = _audioPlayerManager.player.playerStateStream
        .listen((playerState) {
          if (mounted) {
            if (playerState.playing &&
                playerState.processingState != ProcessingState.completed) {
              _animationController.repeat();
            } else if (playerState.processingState ==
                ProcessingState.completed) {
              // Bài hát kết thúc, tự động chuyển sang bài tiếp theo
              _animationController.stop();
              _setNextSong();
            } else {
              _animationController.stop();
            }
          }
        });

    _selectedItemIndex = widget.songs.indexOf(widget.playingSong);
    _song = widget.playingSong;
    _loopMode = LoopMode.off;
  }

  // Thêm didUpdateWidget để xử lý khi widget được rebuild với props khác
  @override
  void didUpdateWidget(NowPlayingPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Nếu bài hát thay đổi, reset animation controller
    if (oldWidget.playingSong != widget.playingSong) {
      _animationController.stop();
      _animationController.reset();
      _playerStateSubscription?.cancel();

      _audioPlayerManager.init(songUrl: widget.playingSong.source);

      _playerStateSubscription = _audioPlayerManager.player.playerStateStream
          .listen((playerState) {
            if (mounted) {
              if (playerState.playing &&
                  playerState.processingState != ProcessingState.completed) {
                _animationController.repeat();
              } else if (playerState.processingState ==
                  ProcessingState.completed) {
                // Bài hát kết thúc, tự động chuyển sang bài tiếp theo
                _animationController.stop();
                _setNextSong();
              } else {
                _animationController.stop();
              }
            }
          });

      _selectedItemIndex = widget.songs.indexOf(widget.playingSong);
      setState(() {
        _song = widget.playingSong;
      });
    }
  }

  //Các thành phần có trong trang now playing
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const delta = 64;
    final radius = (screenWidth - delta) / 2;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Now playing'),
        trailing: const Icon(Icons.more_horiz),
      ),
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_song.album),
              const SizedBox(height: 10),
              const Text('_____'),
              const SizedBox(height: 48),
              RotationTransition(
                turns: Tween(
                  begin: 0.0,
                  end: 1.0,
                ).animate(_animationController),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: FadeInImage.assetNetwork(
                    placeholder: 'assets/images/itun.jpg',
                    image: _song.image,
                    width: screenWidth - delta,
                    height: screenWidth - delta,
                    imageErrorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/itun.jpg',
                        width: screenWidth - delta,
                        height: screenWidth - delta,
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 64, bottom: 16),
                child: SizedBox(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.share_outlined),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      Column(
                        children: [
                          Text(
                            _song.title,
                            style: Theme.of(context).textTheme.bodyMedium!
                                .copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .color,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _song.artist,
                            style: Theme.of(context).textTheme.bodyMedium!
                                .copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .color,
                                ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.favorite_outline),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  top: 24,
                  left: 24,
                  right: 24,
                  bottom: 16,
                ),
                child: _progressBar(),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  top: 24,
                  left: 24,
                  right: 24,
                  bottom: 16,
                ),
                child: _mediaButtons(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //Thanh trạng thái phát nhạc
  StreamBuilder<DurationState> _progressBar() {
    return StreamBuilder<DurationState>(
      stream: _audioPlayerManager.durationState,
      builder: (context, snapshot) {
        final durationState = snapshot.data;
        final progress = durationState?.progress ?? Duration.zero;
        final buffered = durationState?.buffered ?? Duration.zero;
        final total = durationState?.total ?? Duration.zero;
        return ProgressBar(
          progress: progress,
          total: total,
          buffered: buffered,
          onSeek: _audioPlayerManager.player.seek,
        );
      },
    );
  }

  //xử lý phát nhạc
  StreamBuilder<PlayerState> _playButton() {
    return StreamBuilder(
      stream: _audioPlayerManager.player.playerStateStream,
      builder: (context, snapshot) {
        final playState = snapshot.data;
        final processingState = playState?.processingState;
        final playing = playState?.playing;
        if (processingState == ProcessingState.loading) {
          return Container(
            margin: const EdgeInsets.all(8),
            width: 48,
            height: 48,
            child: const CircularProgressIndicator(),
          );
        } else if (playing != true) {
          return MediaButtonControl(
            function: () {
              _audioPlayerManager.player.play();
            },
            icon: Icons.play_arrow,
            color: Colors.deepOrange,
            size: 48,
          );
        } else if (processingState != ProcessingState.completed) {
          return MediaButtonControl(
            function: () {
              _audioPlayerManager.player.pause();
            },
            icon: Icons.pause,
            color: Colors.deepOrange,
            size: 48,
          );
        } else {
          return MediaButtonControl(
            function: () {
              _audioPlayerManager.player.seek(Duration.zero);
            },
            icon: Icons.replay,
            color: Colors.deepOrange,
            size: 48,
          );
        }
      },
    );
  }

  // Bài hát tiếp theo
  void _setNextSong() {
    if (_isShuffle) {
      var random = Random();
      _selectedItemIndex = random.nextInt(widget.songs.length);
    } else if (_selectedItemIndex < widget.songs.length - 1) {
      ++_selectedItemIndex;
    } else if (_loopMode == LoopMode.all &&
        _selectedItemIndex == widget.songs.length - 1) {
      _selectedItemIndex = 0; // Quay lại bài đầu tiên nếu đang ở bài cuối cùng
    }
    if (_selectedItemIndex >= widget.songs.length) {
      _selectedItemIndex =
          _selectedItemIndex % widget.songs.length; // Đảm bảo chỉ số hợp lệ
    }
    final nextSong = widget.songs[_selectedItemIndex];
    _audioPlayerManager.updateSongUrl(nextSong.source);
    _animationController.reset();
    setState(() {
      _song = nextSong;
    });
    // Auto play bài tiếp theo
    _audioPlayerManager.player.play();
  }

  // Bài hát liền trước
  void _setPrevSong() {
    if (_isShuffle) {
      var random = Random();
      _selectedItemIndex = random.nextInt(widget.songs.length);
    } else if (_selectedItemIndex > 0) {
      --_selectedItemIndex;
    } else if (_loopMode == LoopMode.all && _selectedItemIndex == 0) {
      _selectedItemIndex =
          widget.songs.length -
          1; // Quay lại bài cuối cùng nếu đang ở bài đầu tiên
    }
    if (_selectedItemIndex < 0) {
      _selectedItemIndex =
          (-1 * _selectedItemIndex) %
          widget.songs.length; // Đảm bảo chỉ số hợp lệ
    }
    final prevSong = widget.songs[_selectedItemIndex];
    _audioPlayerManager.updateSongUrl(prevSong.source);
    _animationController.reset();
    setState(() {
      _song = prevSong;
    });
  }

  IconData _repeatingIcon() {
    return switch (_loopMode) {
      LoopMode.one => Icons.repeat_one,
      LoopMode.all => Icons.repeat,
      _ => Icons.repeat,
    };
  }

  Color? _getRepeatingIconColor() {
    return _loopMode == LoopMode.off ? Colors.grey : Colors.deepOrange;
  }

  void _setRepeatOption() {
    if (_loopMode == LoopMode.off) {
      _loopMode = LoopMode.one;
    } else if (_loopMode == LoopMode.one) {
      _loopMode = LoopMode.all;
    } else {
      _loopMode = LoopMode.off;
    }
    setState(() {
      _audioPlayerManager.player.setLoopMode(_loopMode);
    });
  }

  void _setShuffle() {
    setState(() {
      _isShuffle = !_isShuffle;
    });
  }

  Color? _getShuffeColor() {
    return _isShuffle ? Colors.deepOrange : Colors.grey;
  }

  //Các nút điều khiển bài hát
  Widget _mediaButtons() {
    return SizedBox(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          MediaButtonControl(
            function: _setShuffle,
            icon: Icons.shuffle,
            color: _getShuffeColor(),
            size: 24,
          ),
          MediaButtonControl(
            function: _setPrevSong, //Nút phát bài trước đó
            icon: Icons.skip_previous,
            color: Colors.deepOrange,
            size: 36,
          ),
          _playButton(), //Nút phát nhạc
          MediaButtonControl(
            function: _setNextSong, //Nút phát bài tiếp theo
            icon: Icons.skip_next,
            color: Colors.deepOrange,
            size: 36,
          ),
          MediaButtonControl(
            function: _setRepeatOption, //Nút lặp lại bài hát
            icon: _repeatingIcon(),
            color: _getRepeatingIconColor(),
            size: 24,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _sequenceStateSubscription?.cancel();
    _animationController.stop();
    _animationController.dispose();
    //_audioPlayerManager.player.dispose(); // Cần đóng trình phát nhạc
    super.dispose();
  }
}

class MediaButtonControl extends StatefulWidget {
  const MediaButtonControl({
    required this.function,
    required this.icon,
    required this.color,
    required this.size,
  });

  final void Function()? function;
  final IconData icon;
  final double? size;
  final Color? color;

  @override
  State<StatefulWidget> createState() => _MediaButtonControlState();
}

class _MediaButtonControlState extends State<MediaButtonControl> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: widget.function,
      icon: Icon(widget.icon),
      iconSize: widget.size,
      color: widget.color ?? Theme.of(context).colorScheme.primary,
    );
  }
}
