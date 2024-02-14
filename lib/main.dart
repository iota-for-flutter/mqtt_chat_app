import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mime/mime.dart';
import 'package:mqtt_chat_app/my_dropdown_button.dart';
import 'package:mqtt_chat_app/my_elevated_button.dart';
import 'package:mqtt_chat_app/my_text_field.dart';
import 'package:mqtt_chat_app/text_preferences.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'ffi.dart';

void main() {
  initializeDateFormatting().then((_) => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
        home: ChatPage(),
      );
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  List<types.Message> _messages = [];

  // These variables are stored in the Text Preferences as closing action
  types.User _user = types.User(id: const Uuid().v4());
  String _nodeUrl = '';
  String _dropdownNodeUrl = '';
  String _tag = '';

  final tagTextController = TextEditingController();
  final userNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    //_loadMessages();
    _setupLogger();
    _onOpeningOrResumingApp();
//    _callFfiGreet();
  }

  // See https://www.youtube.com/watch?v=JyapvlrmM24
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) return;

    final isBackground = state == AppLifecycleState.paused;

    if (isBackground) {
      _onPausingOrClosingApp();
    } else {
      _onOpeningOrResumingApp();
    }
  }

  Future<void> _onOpeningOrResumingApp() async {
    print("APP IS OPENING OR RESUMING");

    String tag = await TextPreferences.getTag();
    String nodeUrl = await TextPreferences.getNodeUrl();
    String id = await TextPreferences.getUserId();
    String firstName = await TextPreferences.getUserFirstname();
    String lastName = await TextPreferences.getUserLastname();
    setState(() {
      _tag = tag;
      _nodeUrl = nodeUrl;
      _dropdownNodeUrl = nodeUrl;
      _user = types.User(
        id: id,
        firstName: firstName,
        lastName: lastName,
      );
      tagTextController.text = tag;
      userNameController.text = lastName;
    });

    _setupMqttAndSubscribeForTag();
  }

  void _onPausingOrClosingApp() {
    print("APP IS PAUSING OR CLOSING");

    _storePreferences();
    _unsubscribeMqtt();
  }

  void _storePreferences() {
    TextPreferences.setTag(_tag);
    TextPreferences.setNodeUrl(_nodeUrl);
    TextPreferences.setUserId(_user.id);
    //TextPreferences.setUserFirstname(_user.firstName ?? 'Alice');
    TextPreferences.setUserLastname(_user.lastName ?? 'Bob');
  }

  void _takeoverDrawerData() {
    if (scaffoldKey.currentState!.isDrawerOpen) {
      scaffoldKey.currentState!.closeDrawer();
      //close drawer, if drawer is open
    }

    // Short validation for empty fields
    if (tagTextController.text == '' || userNameController.text == '') {
      return;
    }

    bool tagWasChanged = false;
    bool nodeUrlWasChanged = false;
    setState(() {
      tagWasChanged = _tag != tagTextController.text;
      _tag = tagTextController.text;

      nodeUrlWasChanged = _nodeUrl != _dropdownNodeUrl;
      _nodeUrl = _dropdownNodeUrl;

      _user = _user.copyWith(lastName: userNameController.text);

      _messages = [];
    });

    _storePreferences();

    if (tagWasChanged || nodeUrlWasChanged) {
      _unsubscribeMqtt();
      if (tagWasChanged) {
        _subscribeForTag();
      } else {
        _setupMqttAndSubscribeForTag();
      }
    }
  }

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) => Scaffold(
        key: scaffoldKey,
        body: SafeArea(
          child: Chat(
            theme: const DefaultChatTheme(
              //primaryColor: Color.fromARGB(255, 0, 224, 202),
              primaryColor: Color.fromARGB(255, 0, 200, 200),
              inputBackgroundColor: Color.fromARGB(255, 60, 60, 60),
            ),
            messages: _messages,
            onAttachmentPressed: null, //_handleAttachmentPressed,
            onMessageTap: null, //_handleMessageTap,
            onPreviewDataFetched: null, //_handlePreviewDataFetched,
            onSendPressed: _handleSendPressed,
            showUserAvatars: true,
            showUserNames: true,
            user: _user,
          ),
        ),
        appBar: AppBar(
          title: Text('MQTT Chat: $_tag'),
          backgroundColor: const Color.fromARGB(255, 0, 200, 200),
        ),
        drawer: Drawer(
          width: 360,
          backgroundColor: const Color.fromARGB(255, 99, 99, 99),
          child: SizedBox(
            height: 500,
            child: ListView(
              // Important: Remove any padding from the ListView.
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 60, 60, 60),
                  ),
                  child: Column(
                    children: [
                      Image.asset(
                        "assets/smr.png",
                        height: 90.0,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Settings',
                        style: TextStyle(
                          color: Color.fromARGB(255, 255, 255, 255),
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                MyDropdownButton(
                    title: "Network",
                    items: const [
                      'https://api.testnet.shimmer.network',
                      'https://api.shimmer.network'
                    ],
                    currentValue: _dropdownNodeUrl,
                    onChanged: (String? newValue) {
                      setState(() {
                        _dropdownNodeUrl = newValue!;
                      });
                    }),
                MyTextField(
                  title: "Channel / Tag",
                  controller: tagTextController,
                ),
                MyTextField(
                  title: "Username",
                  controller: userNameController,
                ),
                const SizedBox(
                  height: 10.0,
                ),
                MyElevatedButton(
                  label: "Save",
                  onPressed: _takeoverDrawerData,
                ),
              ],
            ),
          ),
        ),
      );

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  void _handleAttachmentPressed() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: SizedBox(
          height: 144,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleImageSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Photo'),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleFileSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('File'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      final message = types.FileMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        mimeType: lookupMimeType(result.files.single.path!),
        name: result.files.single.name,
        size: result.files.single.size,
        uri: result.files.single.path!,
      );

      _addMessage(message);
    }
  }

  void _handleImageSelection() async {
    final result = await ImagePicker().pickImage(
      imageQuality: 70,
      maxWidth: 1440,
      source: ImageSource.gallery,
    );

    if (result != null) {
      final bytes = await result.readAsBytes();
      final image = await decodeImageFromList(bytes);

      final message = types.ImageMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        height: image.height.toDouble(),
        id: const Uuid().v4(),
        name: result.name,
        size: bytes.length,
        uri: result.path,
        width: image.width.toDouble(),
      );

      _addMessage(message);
    }
  }

  void _handleMessageTap(BuildContext _, types.Message message) async {
    if (message is types.FileMessage) {
      var localPath = message.uri;

      if (message.uri.startsWith('http')) {
        try {
          final index =
              _messages.indexWhere((element) => element.id == message.id);
          final updatedMessage =
              (_messages[index] as types.FileMessage).copyWith(
            isLoading: true,
          );

          setState(() {
            _messages[index] = updatedMessage;
          });

          final client = http.Client();
          final request = await client.get(Uri.parse(message.uri));
          final bytes = request.bodyBytes;
          final documentsDir = (await getApplicationDocumentsDirectory()).path;
          localPath = '$documentsDir/${message.name}';

          if (!File(localPath).existsSync()) {
            final file = File(localPath);
            await file.writeAsBytes(bytes);
          }
        } finally {
          final index =
              _messages.indexWhere((element) => element.id == message.id);
          final updatedMessage =
              (_messages[index] as types.FileMessage).copyWith(
            isLoading: null,
          );

          setState(() {
            _messages[index] = updatedMessage;
          });
        }
      }

      await OpenFilex.open(localPath);
    }
  }

  void _handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    final index = _messages.indexWhere((element) => element.id == message.id);
    final updatedMessage = (_messages[index] as types.TextMessage).copyWith(
      previewData: previewData,
    );

    setState(() {
      _messages[index] = updatedMessage;
    });
  }

  void _handleSendPressed(types.PartialText message) {
    // final textMessage = types.TextMessage(
    //   author: _user,
    //   createdAt: DateTime.now().millisecondsSinceEpoch,
    //   id: const Uuid().v4(),
    //   text: message.text,
    // );

    // _addMessage(textMessage);
    _callFfiPublishMessage(_tag, message.text);
  }

  void _loadMessages() async {
    final response = await rootBundle.loadString('assets/messages.json');
    final messages = (jsonDecode(response) as List)
        .map((e) => types.Message.fromJson(e as Map<String, dynamic>))
        .toList();

    setState(() {
      _messages = messages;
    });
  }

  // ------------------------------------------------------------------

  types.TextMessage createTextMessage(
      String userId, String user, String newMessage, int timeMillis) {
    print("UserID: $userId, User: $user, Message: $newMessage");
    final userObject = types.User(
      id: userId,
      lastName: user,
    );
    final textMessage = types.TextMessage(
      author: userObject,
      createdAt: timeMillis,
      id: userId, //const Uuid().v4(),
      text: newMessage,
    );
    return textMessage;
  }

  Future<void> _callFfiGreet() async {
    final receivedText = await api.greet();
    print(receivedText);
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: receivedText,
    );

    _addMessage(textMessage);
  }

  Future<void> _callFfiPublishMessage(String tag, String message) async {
    final receivedBlockId = await api.publishMessage(
        tag: tag,
        userId: _user.id,
        user: _user.lastName ?? "",
        message: message);

    if (receivedBlockId == "0x00") {
      print("PUBLISHING THE MESSAGE FAILED");
    } else {
      print("MESSAGE WAS PUBLISHED SUCCESSFULLY IN BLOCK ID $receivedBlockId");
      // To check the block_id use tangle explorer
      // -> For the Shimmer TESTNET the url is:
      // https://explorer.shimmer.network/testnet/block/{receivedBlockId}
    }

    //tag, _user.id, _user.firstName, message);
  }

  Future<void> _setupLogger() async {
    await api.rustSetUp();

    api.createLogStream().listen((event) {
      if (event.tag == _tag) {
        _addMessage(createTextMessage(
            event.userId, event.user, event.msg, event.timeMillis));
      } else {
        prints(
            'LOG FROM RUST: ${event.level} ${event.tag} ${event.userId} ${event.user} ${event.msg} ${event.timeMillis}');
      }
    });
  }

  //https://stackoverflow.com/questions/49138971/logging-large-strings-from-flutter
  // void prints(var s1) {
  //   String s = s1.toString();
  //   debugPrint(s, wrapWidth: 1024);
  // }
  void prints(var s1) {
    String s = s1.toString();
    final pattern = RegExp('.{1,800}');
    pattern.allMatches(s).forEach((match) => print(match.group(0)));
  }

  Future<void> _setupMqttAndSubscribeForTag() async {
    String responseText = await api.setupMqtt(
      nodeUrl: _nodeUrl,
    );
    print(responseText);

    _subscribeForTag();
  }

  Future<void> _subscribeForTag() async {
    try {
      await api.subscribeForTag(tag: _tag);
    } on FfiException catch (e) {
      print(
          'FfiException was catched in main._subscribeForTag() -> Exception is: $e');
    }
  }

  Future<void> _unsubscribeMqtt() async {
    await api.unsubscribe();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
