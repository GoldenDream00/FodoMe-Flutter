import 'package:fodome/models/user.dart';
// ignore: unused_import
import 'package:fodome/widgets/header.dart';

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:fodome/pages/home.dart';
import 'package:fodome/widgets/progress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as Im;
import 'package:uuid/uuid.dart';
import 'package:geocoding/geocoding.dart';

// import 'package:cached_network_image/cached_network_image.dart';

final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
  primary: Colors.deepOrange,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8.0),
  ),
);
final DateTime timestamp = DateTime.now();
firebase_storage.FirebaseStorage storage =
    firebase_storage.FirebaseStorage.instance;
final ImagePicker _picker = ImagePicker();

class Upload extends StatefulWidget {
  final User? currentUser;

  Upload({this.currentUser});
  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload>
    with AutomaticKeepAliveClientMixin<Upload> {
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController quantityController = TextEditingController();
  TextEditingController shelflifeController = TextEditingController();
  TextEditingController locationController = TextEditingController();

  // String downloadUrl = "";
  PickedFile? file;
  bool isUploading = false;
  String postId = Uuid().v4();
  var image;

  handleTakePhoto() async {
    Navigator.pop(context);
    PickedFile? file = await _picker.getImage(
      source: ImageSource.camera,
      maxHeight: 675,
      maxWidth: 960,
    );
    setState(() {
      this.file = file;
      if (file != null) {
        this.image = File(file.path);
      }
    });
  }

  handleChooseFromGallery() async {
    Navigator.pop(context);
    PickedFile? file = await _picker.getImage(source: ImageSource.gallery);
    setState(() {
      this.file = file;
      if (file != null) {
        this.image = File(file.path);
      }
    });
  }

  selectImage(parentContext) {
    return showDialog(
        context: parentContext,
        builder: (context) {
          return SimpleDialog(
            title: Text("Create Post"),
            children: <Widget>[
              SimpleDialogOption(
                  child: Text("Photo with Camera"), onPressed: handleTakePhoto),
              SimpleDialogOption(
                  child: Text("Image from Gallery"),
                  onPressed: handleChooseFromGallery),
              SimpleDialogOption(
                child: Text("Cancel"),
                onPressed: () => Navigator.pop(context),
              )
            ],
          );
        });
  }

  Widget buildSplashScreen() {
    return Container(
      color: Theme.of(context).accentColor.withOpacity(0.6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SvgPicture.asset('assets/images/upload.svg', height: 260.0),
          Padding(
            padding: EdgeInsets.only(top: 20.0),
            child: ElevatedButton(
              child: Text(
                "Upload Food Image",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.0,
                ),
              ),
              style: raisedButtonStyle,
              onPressed: () => selectImage(context),
            ),
          ),
        ],
      ),
    );
  }

  clearImage() {
    setState(() {
      file = null;
    });
  }

  compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Im.Image? imageFile = Im.decodeImage(image.readAsBytesSync());
    final compressedImageFile = File('$path/img_$postId.jpg')
      ..writeAsBytesSync(Im.encodeJpg(imageFile!, quality: 85));
    setState(() {
      image = compressedImageFile;
    });
  }

  Future<String> uploadImage(imageFile) async {
    firebase_storage.Reference ref = storage.ref().child('post_$postId.jpg');
    firebase_storage.UploadTask uploadTask = ref.putFile(imageFile);
    print('File Uploaded');
    var imageUrl = await (await uploadTask).ref.getDownloadURL();
    String url = imageUrl.toString();
    return url;
  }

  createPostInFirestore(
      {required String mediaUrl,
      String? location,
      String? title,
      String? description,
      String? quantity,
      String? shelfLife}) {
    postsRef.doc(currentUser!.id).collection("userPosts").doc(postId).set({
      "postId": postId,
      "ownerId": currentUser!.id,
      "username": currentUser!.username,
      "mediaUrl": mediaUrl,
      "description": description,
      "location": location,
      "timestamp": timestamp,
      "likes": {},
      "title": title,
      "shelfLife": shelfLife,
      "quantity": quantity,
    });

    timelineRef.add({
      "postId": postId,
      "ownerId": currentUser!.id,
      "username": currentUser!.username,
      "displayName": currentUser!.displayName,
      "mediaUrl": mediaUrl,
      "description": description,
      "location": location,
      "timestamp": timestamp,
      "title": title,
      "shelfLife": shelfLife,
      "quantity": quantity,
      "isVerified": false,
    });
  }

  handleSubmit() async {
    setState(() {
      isUploading = true;
    });
    compressImage();
    String mediaUrl = await uploadImage(image);
    // print("IMAGEEEEEEEE");
    // print(image);
    // print("MEDIA");
    // print(mediaUrl);
    createPostInFirestore(
      mediaUrl: mediaUrl,
      location: locationController.text,
      title: titleController.text,
      description: descriptionController.text,
      quantity: quantityController.text,
      shelfLife: shelflifeController.text,
    );
    locationController.clear();
    titleController.clear();
    descriptionController.clear();
    quantityController.clear();
    shelflifeController.clear();

    setState(() {
      file = null;
      isUploading = false;
      postId = Uuid().v4();
    });
  }

  Scaffold buildUploadForm() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white70,
        leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: clearImage),
        title: Text(
          "Post Details",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () => handleSubmit(),
            // isUploading
            //     ? null
            //     : () {
            //         handleSubmit();
            //       },
            child: Text(
              "Post",
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
                fontSize: 20.0,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          isUploading ? linearProgress() : Text(""),
          Container(
            height: 220.0,
            width: MediaQuery.of(context).size.width * 0.8,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: FileImage(image),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 10.0),
          ),
          ListTile(
            leading: Text(
              "Title:",
              style: TextStyle(fontSize: 17.0),
            ),
            title: Container(
              width: 250.0,
              child: TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: "Enter a title...",
                  // border: InputBorder.none,
                ),
              ),
            ),
          ),
          ListTile(
            leading: Text(
              "Description:",
              style: TextStyle(fontSize: 17.0),
            ),
            title: Container(
              width: 250.0,
              child: TextField(
                controller: descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: "Enter a description...",
                  // border: InputBorder.none,
                ),
              ),
            ),
          ),
          ListTile(
            leading: Text(
              "Quantity:",
              style: TextStyle(fontSize: 17.0),
            ),
            title: Container(
              width: 250.0,
              child: TextField(
                controller: quantityController,
                decoration: InputDecoration(
                  hintText: "Enter details about weight and quantity...",
                  // border: InputBorder.none,
                ),
              ),
            ),
          ),
          ListTile(
            leading: Text(
              "Shelf Life:",
              style: TextStyle(fontSize: 17.0),
            ),
            title: Container(
              width: 250.0,
              child: TextField(
                controller: shelflifeController,
                decoration: InputDecoration(
                  hintText: "Best time to eat before expiry...",
                  // border: InputBorder.none,
                ),
              ),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(
              Icons.pin_drop,
              color: Colors.orange,
              size: 35.0,
            ),
            title: Container(
              width: 250.0,
              child: TextField(
                controller: locationController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Where was this photo taken?",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Container(
            width: 200.0,
            height: 100.0,
            alignment: Alignment.center,
            child: ElevatedButton.icon(
              label: Text(
                "Use Current Location",
                style: TextStyle(color: Colors.white),
              ),
              style: raisedButtonStyle,
              // color: Colors.blue,
              onPressed: () {
                getUserLocation();
              },
              icon: Icon(
                Icons.my_location,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  getUserLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks = await GeocodingPlatform.instance
        .placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark placemark = placemarks[0];
    String completeAddress =
        // ${placemark.subThoroughfare} ${placemark.thoroughfare},
        '${placemark.subLocality} ${placemark.locality}, ${placemark.subAdministrativeArea}, ${placemark.administrativeArea} ${placemark.postalCode}, ${placemark.country}';
    print(completeAddress);
    // String formattedAddress = "${placemark.locality}, ${placemark.country}";
    locationController.text = completeAddress;
    ;
  }

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return file == null ? buildSplashScreen() : buildUploadForm();
  }

  // @override
  // // TODO: implement wantKeepAlive
  // bool get wantKeepAlive => throw UnimplementedError();
}
