import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

// import 'detector_view.dart';
import 'detector_view.dart';
import 'painters/text_detector_painter.dart';

class TextRecognizerView extends StatefulWidget {
  @override
  State<TextRecognizerView> createState() => _TextRecognizerViewState();
}

class _TextRecognizerViewState extends State<TextRecognizerView> {
  var _script = TextRecognitionScript.latin;
  var _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;

  String? _text;
  List<String> lines = [];
  String? dataFromImage;
  List<String> keywords = ["Nguyen ", "Le ", "Tran ", 'Vo '];
  String? issueDate;
  String? expirationDate;
  String? cardName;
  String? cardNumber;

  var _cameraLensDirection = CameraLensDirection.back;

  @override
  void dispose() async {
    _canProcess = false;
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        DetectorView(
          title: 'xxxxx',
          customPaint: _customPaint,
          text: _text,
          lines: lines,
          dataFromImage: dataFromImage,
          onImage: _processImage,
          initialCameraLensDirection: _cameraLensDirection,
          onCameraLensDirectionChanged: (value) => _cameraLensDirection = value,
        ),
      ]),
    );
  }

  String? findMatchingLine(List<String> inputList, List<String> keywords) {
    for (String input in inputList) {
      for (String keyword in keywords) {
        if (input.toUpperCase().contains(keyword.toUpperCase())) {
          return input;
        }
      }
    }
    return null; // Trả về null nếu không tìm thấy
  }

  String? findATMCardNumbers(List<String> inputList) {
    for (String input in inputList) {
      // Sử dụng biểu thức chính quy để kiểm tra xem dòng có đúng định dạng số thẻ ATM hay không
      if (RegExp(r'^\d{16}$').hasMatch(input.replaceAll(" ", ""))) {
        return input;
      }
    }
    return null;
  }

  void findDate(List<String> inputList) {
    issueDate = null;
    expirationDate = null;
    for (String input in lines) {
      // Sử dụng biểu thức chính quy để kiểm tra xem dòng có đúng định dạng "MM/YY" không
      RegExp dateRegex = RegExp(r'\b(\d{1,2}/\d{2})\b');
      Iterable<Match> matches = dateRegex.allMatches(input);

      for (Match match in matches) {
        String matchedDate = match.group(0)!;

        // Chuyển đổi định dạng "MM/YY" thành đối tượng DateTime
        try {
          DateTime date = DateTime(
              DateTime.now().year,
              int.parse(matchedDate.split("/")[0]),
              int.parse(matchedDate.split("/")[1]));

          if (issueDate == null) {
            issueDate = matchedDate;
          } else
            expirationDate ??= matchedDate;
        } catch (e) {
          // Bỏ qua các giá trị không hợp lệ
        }
      }
      expirationDate ??= issueDate;
    }
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
      _text = '';
      lines = [];
    });
    final recognizedText = await _textRecognizer.processImage(inputImage);
    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {
      final painter = TextRecognizerPainter(
        recognizedText,
        inputImage.metadata!.size,
        inputImage.metadata!.rotation,
        _cameraLensDirection,
      );
      _customPaint = CustomPaint(painter: painter);
    } else {
      lines = recognizedText.text.split('\n');
      debugPrint('longnq xxxx $lines');

      String? cardName = findMatchingLine(lines, keywords);

      // if (result != null) {
      //   debugPrint("Dòng chứa tên người dùng: $result");
      // } else {
      //   debugPrint("Không tìm thấy dòng chứa tên người dùng.");
      // }

      String? cardNumber = findATMCardNumbers(lines);

      // if(atmNumber != null) {
      //   debugPrint("Số thẻ ATM: $atmNumber");
      // } else {
      //   debugPrint("Không tìm thấy số ATM");
      // }

      findDate(lines);

      // _text = 'Recognized text:\n\n${recognizedText.text}';
      // _text = 'Recognized text____ : ${recognizedText.text}';
      dataFromImage = recognizedText.text;
      _text =
          'Thông tin thẻ: \n\n Tên chủ thẻ: $cardName  \n\n Số thẻ: $cardNumber  \n\n Ngày phát hành: $issueDate \n\n Ngày hết hạn: $expirationDate ';
      // TODO: set _customPaint to draw boundingRect on top of image
      _customPaint = null;
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }
}
