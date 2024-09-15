// ignore_for_file: library_private_types_in_public_api, non_constant_identifier_names, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:torch_light/torch_light.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_alarm_clock/flutter_alarm_clock.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:device_apps/device_apps.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mobile Assistant',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        fontFamily: 'Montserrat',
      ),
      home: const WelcomePage(),
    );
  }
}

// Welcome Page
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
          image: AssetImage('assets/images/ai_image_2.jpg'),
          fit: BoxFit.cover,
          ),
          ),
          child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/ai_image_2.jpg'),
                    fit: BoxFit.cover,
                  )
                )
              ),
              const Text(
                'AniBot 2.O welcomes you!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  fontFamily: "FontMain"
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AssistantPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(
                    color: Colors.deepPurple,
                    fontSize: 20,
                    fontFamily: "FontMain"
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      )
    );
  }
}

// Assistant Page
class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key});

  @override
  _AssistantPageState createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  final FlutterTts flutterTts = FlutterTts();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = "Press the button and start speaking";
  final List<String> _chatHistory = [];

  final model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: 'GEMINI_API_KEY',
  );

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _addToChat(String message, bool isUserMessage) {
    setState(() {
      _chatHistory.add(message);
    });
  }

  // Voice input
  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (val) {
          setState(() {
            _text = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              handleCommand(_text.toLowerCase());
            }
          });
        });
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  // Functions to handle voice commands and map them to actions
  void handleCommand(String command) async {
    if (command.contains("flashlight on")) {
      speak("Turning on the flashlight");
      toggleFlashlight(true);
    } else if (command.contains("flashlight off")) {
      speak("Turning off the flashlight");
      toggleFlashlight(false);
    } else if (command.contains("call")) {
      String? number = extractPhoneNumber(command);
      if (number != null) {
        speak("Calling $number");
        makeCall(number);
      } else {
        speak("Please provide a valid phone number.");
        setState(() {
          _text = "Please provide a valid phone number.";
        });
      }
    } else if (command.contains("youtube")) {
      openWebsite("https://www.youtube.com");
    } else if (command.contains("google")) {
      openWebsite("https://www.google.com");
    } else if (command.contains("open")) {
      openApp(command);
    } else if (command.contains("alarm")) {
      setAlarmFromSpeech(command);
    } else if (command.contains("system")) {
      openSystemApp(command);
    } else {
      final prompt = command;
      final response = await model.generateContent([Content.text(prompt)]);
      speak(response.text!);
      _addToChat(response.text!, false); // Assistant's response
    }
  }

  // Function to toggle flashlight
  void toggleFlashlight(bool turnOn) async {
    try {
      if (turnOn) {
        await TorchLight.enableTorch();
        setState(() {
          _text = "Flashlight is ON";
        });
      } else {
        await TorchLight.disableTorch();
        setState(() {
          _text = "Flashlight is OFF";
        });
      }
    } catch (e) {
      setState(() {
        _text = "Error toggling flashlight";
      });
    }
  }

  // Function to extract phone number from command
  String? extractPhoneNumber(String command) {
    RegExp phoneRegExp = RegExp(r'\d+');
    Iterable<Match> matches = phoneRegExp.allMatches(command);

    if (matches.isNotEmpty) {
      return matches.first.group(0);
    }
    return null;
  }

  // Function to make a call
  void makeCall(String number) async {
    bool? res = await FlutterPhoneDirectCaller.callNumber(number);
    if (res!) {
      setState(() {
        _text = "Calling $number";
      });
    } else {
      setState(() {
        _text = "Failed to make a call";
      });
    }
  }

  // Function to open a website
  void openWebsite(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
      speak("Opening website: $url");
      setState(() {
        _text = "Opening website: $url";
      });
    } else {
      speak("Could not open website");
      setState(() {
        _text = "Could not open website";
      });
    }
  }

  // Function to set an alarm using voice command
  void setAlarmFromSpeech(String command) {
    RegExp timeRegExp = RegExp(r'(\d+):(\d+)');
    Match? match = timeRegExp.firstMatch(command);

    if (match != null) {
      int hour = int.parse(match.group(1)!);
      int minute = int.parse(match.group(2)!);
      setAlarm(hour, minute);
    } else {
      speak("Please provide a valid time in HH:MM format.");
      setState(() {
        _text = "Please provide a valid time in HH:MM format.";
      });
    }
  }

  // Function to set an alarm at a specific time
  void setAlarm(int hour, int minute) {
    FlutterAlarmClock.createAlarm(hour: hour, minutes: minute);
    speak("Setting alarm for $hour:$minute");
    setState(() {
      _text = "Alarm set for $hour:$minute";
    });
  }

  // Function to open a user-installed app
  void openApp(String command) async {
    String appName = command.replaceAll("open ", "").trim();
    List<Application> apps = await DeviceApps.getInstalledApplications();
    Application? targetApp;

    for (var app in apps) {
      if (app.appName.toLowerCase().contains(appName.toLowerCase())) {
        targetApp = app;
        break;
      }
    }

    if (targetApp != null) {
      DeviceApps.openApp(targetApp.packageName);
      speak("Opening $appName");
      setState(() {
        _text = "Opening $appName";
      });
    } else {
      speak("App not found: $appName");
      setState(() {
        _text = "App not found: $appName";
      });
    }
  }

  // Function to open system apps
  void openSystemApp(String command) {
    if (command.contains("contacts")) {
      openAppByPackageName('com.android.contacts');
    } else if (command.contains("calculator")) {
      openAppByPackageName('com.android.calculator2');
    } else if (command.contains("settings")) {
      openAppByPackageName('com.android.settings');
    } else {
      speak("System app not found: $command");
      setState(() {
        _text = "System app not found: $command";
      });
    }
  }

  // Function to open app by package name
  void openAppByPackageName(String packageName) async {
    bool isOpened = await DeviceApps.openApp(packageName);
    if (isOpened) {
      speak("Opened system app.");
      setState(() {
        _text = "Opened system app.";
      });
    } else {
      speak("Could not open system app.");
      setState(() {
        _text = "Could not open system app.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AniBot 2.O',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: "FontMain"),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color.fromARGB(255, 182, 255, 252), Color.fromARGB(255, 64, 242, 251)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          )
        ),
      ),
      body: Container(
        color: Colors.black,
        child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _chatHistory.length,
              itemBuilder: (context, index) {
                bool isUserMessage = index % 2 == 0;
                return ChatBubble(
                  message: _chatHistory[index],
                  isUserMessage: isUserMessage,
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                onSubmitted: (value) {
                  _addToChat(value, true);
                  handleCommand(value.toLowerCase());
                },
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Type a message",
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          FloatingActionButton(
            onPressed: _listen,
            backgroundColor: _isListening ? Colors.red : Colors.blueAccent,
            child: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ChatBubble widget for displaying individual messages
Widget ChatBubble({required String message, required bool isUserMessage}) {
  return Align(
    alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      padding: const EdgeInsets.all(16.0),
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      decoration: isUserMessage
          ? const BoxDecoration( // Only add the bubble decoration for user messages
              color: Color.fromARGB(255, 43, 43, 43),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
            )
          : null, // No decoration for assistant messages
      child: Text(
        message,
        style: TextStyle(
          color: isUserMessage ? Colors.white : const Color.fromARGB(255, 255, 255, 255), // Different text color for assistant messages
        ),
      ),
    ),
  );
}


  // Function to speak out a given message
  Future<void> speak(String message) async {
    await flutterTts.speak(message);
  }
}
