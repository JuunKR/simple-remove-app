import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: "갤러리앱", home: const GalleryScreen());
  }
}

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final List<Uint8List?> _thumbnailDataList = [];
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  AssetPathEntity? _album;

  int _currentPage = 0;
  final int _pageSize = 60;
  late int _maxThumbnailCount;

  @override
  void initState() {
    super.initState();
    _initAlbum();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 300 &&
          !_isLoading) {
        _loadMorePhotos();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("내 갤러리 ${_thumbnailDataList.length}")),
      body: _buildBody(),
    );
  }

  Future<void> _initAlbum() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final albums = await PhotoManager.getAssetPathList(type: RequestType.image);
    if (albums.isNotEmpty) {
      _album = albums.first;
      _loadMorePhotos();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMorePhotos() async {
    if (_album == null) return;

    setState(() {
      _isLoading = true;
    });

    final media = await _album!.getAssetListPaged(
      page: _currentPage,
      size: _pageSize,
    );
    if (media.isEmpty) {
      _isLoading = false;
      return;
    }
    _currentPage++;
    final List<Uint8List?> newThumbnails = [];
    for (var entity in media) {
      final thumbData = await entity.thumbnailData;
      newThumbnails.add(thumbData);
    }
    setState(() {
      _thumbnailDataList.addAll(newThumbnails);
      _maxThumbnailCount = _pageSize * 5;
      if (_thumbnailDataList.length > _maxThumbnailCount) {
        _thumbnailDataList.removeRange(0, _pageSize);
      }
      _isLoading = false;
    });
  }

  Widget _buildBody() {
    if (_isLoading && _thumbnailDataList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_thumbnailDataList.isEmpty) {
      return const Center(child: Text("사진이 없거나 권한이 거부되었습니다."));
    }

    return GridView.builder(
      controller: _scrollController,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _thumbnailDataList.length,
      itemBuilder: (context, index) {
        final thumbData = _thumbnailDataList[index];
        if (thumbData != null) {
          return Image.memory(thumbData, fit: BoxFit.cover);
        } else {
          return Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.grey[300]),
            child: const Text("loading..."),
          );
        }
      },
    );
  }
}
