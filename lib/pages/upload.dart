import 'package:flutter/material.dart';
import 'package:fodome/widgets/header.dart';

class Upload extends StatefulWidget {
  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(
        context,
        titleText: "Upload Post",
        fontSize: 30.0,
      ),
      body: Text(
        "Upload",
        style: TextStyle(fontSize: 30.0),
      ),
    );
  }
}
