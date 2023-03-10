import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:logger/logger.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  Future download({required String url}) async{
    var status = await Permission.storage.request();
    if(status.isGranted){
     // final baseStorage = await getExternalStorageDirectory();
     // Logger().wtf('baseStorage?.path  ${baseStorage?.path}');
     final directory = await getExternalStorageDirectory();
      String newPath = '';
      List<String>? folders = directory?.path.split('/');
      for (int i = 1; i < folders!.length; i++) {
        if (folders[i] != 'Android') {
          newPath += '/${folders[i]}';
        } else {
          break;
        }
      }
      newPath = '$newPath/';
      Logger().wtf('newPath  $newPath');
      await FlutterDownloader.enqueue(url: url,
          savedDir:newPath,
          showNotification: true,
          openFileFromNotification: true
      );
    }
  }

  final ReceivePort _port = ReceivePort();

  @override
  void initState() {
    super.initState();

    IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      String id = data[0];
      DownloadTaskStatus status = data[1];
      int progress = data[2];
      setState((){ });
    });

    FlutterDownloader.registerCallback(downloadCallback);
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    super.dispose();
  }

  @pragma('vm:entry-point')
  static void downloadCallback(String id, DownloadTaskStatus status, int progress) {
    final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
    send?.send([id, status, progress]);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Text('Download file'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          download(url: 'https://upload.wikimedia.org/wikipedia/commons/e/e4/GatesofArctic.jpg');
        },
        child: const Icon(Icons.download),
      ),
    );
  }
}
