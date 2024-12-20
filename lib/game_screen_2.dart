import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  String jumbledWord = "";
  String token = "";
  String userInput = "";
  int score = 0;
  String feedback = "";
  int timeLeft = 10; // Initial time limit
  Timer? timer;

  @override
  void initState() {
    super.initState();
    fetchJumbledWord();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  // Fetch a new jumbled word from the backend
  Future<void> fetchJumbledWord() async {
    const apiUrl = "http://3.108.40.149:5000/api/start-round";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          jumbledWord = data['jumbled'];
          token = data['token'];
          timeLeft = data['timeLimit'];
          userInput = "";
          feedback = "";
        });
        startTimer(); // Start countdown for the round
      } else {
        throw Exception("Failed to fetch jumbled word");
      }
    } catch (error) {
      setState(() {
        feedback = "Error fetching word. Please try again!";
      });
      print("Error: $error");
    }
  }

  // Start the timer for the round
  void startTimer() {
    timer?.cancel();
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (timeLeft > 0) {
        setState(() {
          timeLeft--;
        });
      } else {
        timer.cancel();
        validateInput(forceTimeout: true);
      }
    });
  }

  // Validate user input
  Future<void> validateInput({bool forceTimeout = false}) async {
    if (forceTimeout && userInput.isEmpty) {
      setState(() {
        feedback = "Time's up! Try again.";
      });
      return;
    }

    const apiUrl = "http://3.108.40.149:5000/api/validate";
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userInput": userInput, "token": token, "timeTaken": 10 - timeLeft}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['isCorrect']) {
          setState(() {
            score += (data['score'] as num).toInt();
            feedback = "Correct! +${data['score']} points";
          });
          await fetchJumbledWord(); // Load the next word
        } else {
          setState(() {
            feedback = "Incorrect. Try again!";
          });
        }
      } else {
        throw Exception("Validation failed");
      }
    } catch (error) {
      setState(() {
        feedback = "Error validating input. Please try again!";
      });
      print("Error: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Word Jumble Game"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              jumbledWord.isNotEmpty ? jumbledWord : "Loading...",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            SizedBox(height: 20),
            TextField(
              onChanged: (value) {
                setState(() {
                  userInput = value.toUpperCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Enter your word",
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: validateInput,
              child: Text("Submit"),
            ),
            SizedBox(height: 20),
            Text(
              "Score: $score",
              style: TextStyle(fontSize: 24, color: Colors.green),
            ),
            SizedBox(height: 10),
            Text(
              "Time Left: $timeLeft seconds",
              style: TextStyle(fontSize: 20, color: Colors.red),
            ),
            SizedBox(height: 10),
            Text(
              feedback,
              style: TextStyle(
                fontSize: 20,
                color: feedback.startsWith("Correct") ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
