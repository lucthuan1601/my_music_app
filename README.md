# My Music App

Ứng dụng nghe nhạc được xây dựng bằng **Flutter**.  
Dự án hiển thị danh sách bài hát từ file JSON và phát nhạc trực tuyến từ nguồn URL.

## Giới thiệu

`my_music_app` là một ứng dụng mobile với giao diện đơn giản, gồm các tab chính:

- **Home**: Danh sách bài hát
- **Discovery**: Khám phá
- **Account**: Tài khoản người dùng
- **Settings**: Cài đặt

Ứng dụng sử dụng:
- `just_audio` để phát nhạc
- `http` để tải dữ liệu
- `rxdart` để xử lý luồng dữ liệu
- `audio_video_progress_bar` để hiển thị thanh tiến trình bài hát

## Tính năng chính

- Hiển thị danh sách bài hát từ `assets/songs.json`
- Hiển thị ảnh bài hát từ URL, có ảnh thay thế từ `assets/images/itun.jpg`
- Phát nhạc trực tuyến
- Mở màn hình đang phát nhạc
- Giao diện tab điều hướng bằng `CupertinoTabScaffold`
- Hỗ trợ hiển thị tiến trình phát nhạc

## Cấu trúc thư mục chính

```text
lib/
├── main.dart
├── data/
│   ├── model/
│   ├── repository/
│   └── source/
└── ui/
    ├── discovery/
    ├── home/
    ├── now_playing/
    ├── settings/
    └── user/

assets/
├── songs.json
└── images/
    └── itun.jpg# my_music_app

Yêu cầu hệ thống
Flutter SDK ^3.13.2 hoặc tương thích
Dart SDK theo cấu hình trong pubspec.yaml
Thiết bị giả lập hoặc thiết bị thật để chạy ứng dụng


Clone dự án hoặc mở dự án trong IDE, sau đó chạy:
flutter pub get
Chạy ứng dụng
flutter run
Nếu muốn chạy trên web:
flutter run -d chrome
Build bản release
Android
flutter build apk
iOS
flutter build ios
Tài nguyên sử dụng
Danh sách bài hát: assets/songs.json
Ảnh mặc định: assets/images/itun.jpg
Ghi chú
Dữ liệu bài hát hiện được lấy từ file JSON trong thư mục assets
File JSON đang chứa các thông tin như: title, artist, source, image, duration
Ứng dụng có thể cần kết nối Internet để tải ảnh và phát nhạc từ URL
Công nghệ sử dụng
Flutter
Dart
Material / Cupertino UI
just_audio
rxdart
http
audio_video_progress_bar