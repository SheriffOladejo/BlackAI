import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signalai/util/hex_color.dart';
import 'package:signalai/view/analysis_loading.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();

}

class _HomeScreenState extends State<HomeScreen> {

  late File imageFile;

  bool is_loading = false;

  Future<void> showImageSourceDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Select Image Source"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text('Gallery'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    if (Platform.isAndroid) {
                      getImageAndroid();
                    }
                    else {
                      await getImage();
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.folder),
                  title: Text('File Manager'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await getFile();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (is_loading) {
      return LoadingAnalysisScreen(filepath: imageFile.path, callback: (){
        setState(() {
          is_loading = false;
        });
      });
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Image.asset("asset/image/chart.png", fit: BoxFit.fill, width: 24, height: 24,),
            Container(width: 5,),
            const Text("Market Analyzer", style: TextStyle(
                fontFamily: 'inter-bold',
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.w500
            ),),
          ],
        ),
        centerTitle: false,
      ),
      body: Container(
        padding: const EdgeInsets.all(15),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                "Upload or take a photo of a candlestick chart image for analysis.\n\nFor optimal analysis, ensure your chart image is clear, well-lit and displays as much information as possible.",
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    fontFamily: 'inter-regular'
                ),
              ),
            ),
            Container(height: 40,),
            InkWell(
              onTap: () => showImageSourceDialog(),
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 50,
                color: Colors.black,
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset("asset/image/upload.png", width: 20, height: 20,),
                    Container(width: 5,),
                    const Text("Upload Image", style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'inter-medium',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),)
                  ],
                ),
              ),
            ),
            Container(height: 20,),
            InkWell(
              onTap: () async {
                openCamera();
              },
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 50,
                color: HexColor("32BC9B"),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt, color: Colors.black,),
                    Container(width: 5,),
                    const Text("Take Photo", style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'inter-medium',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> openCamera() async {
    final bool hasPermission = await checkCameraPermission(); // Changed from gallery to camera
    if (!hasPermission) {
      if (mounted) {
        await requestCameraPermission(context); // Changed from gallery to camera
      }
      return;
    }

    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(source: ImageSource.camera);

    if (pickedImage != null) {
      imageFile = File(pickedImage.path);
      setState(() {
        is_loading = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to take picture")),
      );
    }
  }

  Future<void> getImage() async {
    final bool hasPermission = await checkGalleryPermission();
    if (!hasPermission) {
      if (mounted) {
        await requestGalleryPermission(context);
      }
      return;
    }

    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      imageFile = File(pickedImage.path);
      setState(() {
        is_loading = true;
      });
    }
    else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to select image")),
      );
    }
  }

  Future<void> getImageAndroid() async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      imageFile = File(pickedImage.path);
      setState(() {
        is_loading = true;
      });
    }
  }

  Future<bool> checkGalleryPermission() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.isDenied) {
        // For Android 13+
        if (await Permission.photos.isDenied) {
          return false;
        }
        return await Permission.storage.request().isGranted;
      }
      return true;
    } else {
      return await Permission.photos.status.isGranted;
    }
  }

  Future<bool> checkCameraPermission() async {
    return await Permission.camera.status.isGranted;
  }

  Future<void> requestGalleryPermission(BuildContext context) async {
    if (Platform.isAndroid) {
      // Request storage permission for Android
      final status = await Permission.storage.request();
      if (status != PermissionStatus.granted) {
        if (mounted) {
          if (status == PermissionStatus.permanentlyDenied) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Storage permission is required to access photos.")),
            );
            await openAppSettings();
          }
        }
      }
    } else {
      // iOS uses photos permission
      final status = await Permission.photos.request();
      if (status != PermissionStatus.granted) {
        if (mounted) {
          if (status == PermissionStatus.permanentlyDenied) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Photos permission is required to access photos.")),
            );
            await openAppSettings();
          }
        }
      }
    }
  }

  Future<void> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        if (status == PermissionStatus.permanentlyDenied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Camera permission is required to take pictures.")),
          );
          await openAppSettings();
        }
      }
    }
  }

  Future<bool> isValid() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('user_email');
    if (savedEmail == null) return false;

    final snapshot = await FirebaseDatabase.instance
        .ref('users/${savedEmail.replaceAll(".", "")}')
        .get();

    if (!snapshot.exists) return false;

    final data = snapshot.value as Map;
    final expiry = data['expiry'] ?? 0;

    return DateTime.now().millisecondsSinceEpoch < expiry;
  }

  Future<void> getFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'mp4', 'mov', 'mp3', 'txt', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile platformFile = result.files.first;

        if (platformFile.path != null) {
          File selectedFile = File(platformFile.path!);
          imageFile = selectedFile;
          setState(() {
            is_loading = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking files: ${e.toString()}')),
        );
      }
      print('Error picking files: $e');
    }
  }

  @override
  void initState () {
    super.initState();
    init();
  }

  Future<void> init () async {
    try {
      await setupPushNotifications();
    }
    catch (e) {
      print("Error occurred: $e");
    }

    final r = (await FirebaseDatabase.instance.ref('appsettings/apikey').get()).value == true;
    final v = await isValid();

    if (!r && !v) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => ApiDialog(),
      );
    }
  }

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> setupPushNotifications() async {

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await flutterLocalNotificationsPlugin.initialize(settings);

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    String? token = await messaging.getToken();
    if (token != null) {
      await _saveTokenToFirebase(token);
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> _saveTokenToFirebase(String token) async {

    final prefs = await SharedPreferences.getInstance();

    final savedEmail = prefs.getString('user_email');

    if (savedEmail != null && savedEmail.isNotEmpty) {
      await FirebaseDatabase.instance.ref('users/${savedEmail.replaceAll(".", "")}').update(
          {'token': token});
    }
  }

  Future<void> _showNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Important Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      playSound: true,
    );

    if (notification != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: android?.smallIcon,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    }
  }

  @pragma('vm:entry-point')
  Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    await _showNotification(message);
  }

}

class ApiDialog extends StatefulWidget {
  @override
  _ApiDialogState createState() => _ApiDialogState();
}

class _ApiDialogState extends State<ApiDialog> {
  final emailCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  bool submitted = false;
  String selectedPlan = 'monthly';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Subscribe to Access',
        style: TextStyle(
          fontSize: 18,
          color: Colors.black87,
          fontFamily: 'inter-bold',
        ),
      ),
      content: submitted
          ? const Text(
        "We will verify and grant access shortly via email.",
        style: TextStyle(
          fontSize: 16,
          color: Colors.black87,
          fontFamily: 'inter-regular',
        ),
      )
          : SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Choose a subscription plan:",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontFamily: 'inter-regular',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildPlanCard('monthly', '\$9.99 / month')),
                const SizedBox(width: 10),
                Expanded(child: _buildPlanCard('yearly', '\$99.99 / year')),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              "Pay to this USDT address:",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontFamily: 'inter-regular',
              ),
            ),
            const SelectableText(
              "0xd34ee46804bee4115f0fa7b65805c2fe1b4f8439",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontFamily: 'inter-regular',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Your Email'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: addressCtrl,
              decoration: const InputDecoration(labelText: 'Your USDT Sending Address'),
            ),
          ],
        ),
      ),
      actions: submitted
          ? []
          : [
        TextButton(
          child: const Text("Submit"),
          onPressed: _handleSubmit,
        ),
      ],
    );
  }

  Widget _buildPlanCard(String plan, String label) {
    final isSelected = selectedPlan == plan;
    return InkWell(
      onTap: () => setState(() => selectedPlan = plan),
      child: Card(
        color: isSelected ? Colors.teal[100] : Colors.grey[200],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontFamily: 'inter-regular',
                fontSize: 16,
                color: isSelected ? Colors.teal[900] : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final email = emailCtrl.text.trim();
    final senderAddr = addressCtrl.text.trim();

    if (email.isEmpty || senderAddr.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);

    await FirebaseDatabase.instance.ref('users/${email.replaceAll(".", "")}').set({
      "usdtAddress": senderAddr,
      "expiry": 0,
      "selectedPlan": selectedPlan,
    });

    await sendSubscriptionEmail('moh2shd2@gmail.com', senderAddr);
    await sendSubscriptionEmail('sherifffoladejo@gmail.com', senderAddr);

    setState(() => submitted = true);
  }

  Future<void> sendSubscriptionEmail(String email, String usdtAddr) async {
    final serviceId = 'service_skt3zqe';
    final templateId = 'template_qzmzbut';
    final userId = 'FvxhUj5HhyPhGWKMw'; // Get these from EmailJS dashboard

    final response = await http.post(
      Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': userId,
        'template_params': {
          'email': email,
          'senderAddress': usdtAddr,
          'time': DateTime.now().toIso8601String(),
          'amount': selectedPlan == 'monthly' ? "\$9.99" : "\$99.99",
          'planType': selectedPlan == 'monthly' ? 'monthly' : 'yearly'
        }
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send email: ${response.body}');
    }
  }

  Future<void> init () async {
    final prefs = await SharedPreferences.getInstance();

    final savedEmail = prefs.getString('user_email');

    if (savedEmail != null && savedEmail.isNotEmpty) {
      emailCtrl.text = savedEmail.toString();
    }
    setState(() {

    });
  }

  @override
  void initState () {
    super.initState();
    init();
  }

}



