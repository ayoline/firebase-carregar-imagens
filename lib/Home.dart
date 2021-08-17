import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart';
import 'api/firebase_api.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  ImagePicker imagePicker = ImagePicker();
  File? imagemSelecionada;
  UploadTask? task;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Selecionar imagem"),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton.icon(
              onPressed: () {
                _recuperarImagem(true);
              },
              icon: Icon(Icons.photo_camera_outlined),
              label: Text("Camera"),
            ),
            ElevatedButton.icon(
              onPressed: () {
                _recuperarImagem(false);
              },
              icon: Icon(Icons.add_photo_alternate_outlined),
              label: Text("Galeria"),
            ),
            imagemSelecionada == null
                ? Container()
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Image.file(imagemSelecionada!),
                  ),
            ElevatedButton.icon(
              onPressed: () {
                _uploadImagem();
              },
              icon: Icon(Icons.cloud_upload_outlined),
              label: Text("Upload Storage"),
            ),
            // Mostra o progresso do upload da imagem para o Firebase
            task != null ? buildUploadStatus(task!) : Container(),
          ],
        ),
      ),
    );
  }

  Widget buildUploadStatus(UploadTask task) => StreamBuilder<TaskSnapshot>(
        stream: task.snapshotEvents,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final snap = snapshot.data!;
            final progress = snap.bytesTransferred / snap.totalBytes;
            final percentage = (progress * 100).toStringAsFixed(2);

            return Text(
              "$percentage %",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            );
          } else {
            return Container();
          }
        },
      );

  Future _uploadImagem() async {
    if (imagemSelecionada == null) return;

    final caminhoImagem = basename(imagemSelecionada!.path);
    final destination = "fotos/$caminhoImagem";

    task = FirebaseApi.uploadFile(destination, imagemSelecionada!);
    setState(() {});

    // Printa o endereço completo da imagem que foi subida
    if (task == null) return;

    final snapshot = await task!.whenComplete(() {});
    final urlDownload = await snapshot.ref.getDownloadURL();

    print("Download-link: $urlDownload");
  }

  _recuperarImagem(bool daCamera) async {
    final XFile? imagemTemporaria;
    if (daCamera) {
      // camera
      imagemTemporaria = await imagePicker.pickImage(
        source: ImageSource.camera,
      );
    } else {
      // galeria
      imagemTemporaria = await imagePicker.pickImage(
        source: ImageSource.gallery,
      );
    }
    if (imagemTemporaria != null) {
      File imagemCortada = await _cortarImagem(File(imagemTemporaria.path));
      setState(() {
        imagemSelecionada = File(imagemCortada.path);
      });
    }
  }

  _cortarImagem(File imagemTemporaria) async {
    return await ImageCropper.cropImage(
        sourcePath: imagemTemporaria.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9,
        ]);
  }
}
