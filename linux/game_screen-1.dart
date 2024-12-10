import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  @override
  void initState() {
    super.initState();
    fetchJumbledWord();
  }

  // Fetch a new jumbled word from the backend
  Future<void> fetchJumbledWord() async {
    const apiUrl = "http://localhost:5000/api/start-round";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          jumbledWord = data['jumbled'];
          token = data['token'];
          userInput = "";
          feedback = "";
        });
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

  // Validate user input
  Future<void> validateInput() async {
    const apiUrl = "http://localhost:5000/api/validate";
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userInput": userInput, "token": token}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['isCorrect']) {
          setState(() {
            score += 1;
            feedback = "Correct!";
          });
          await fetchJumbledWord(); // Load next word
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

  // Reset user input
  void resetInput() {
    setState(() {
      userInput = "";
      feedback = "";
    });
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
                  // Automatically validate when input length matches the jumbled word length
                  if (userInput.length == jumbledWord.length) {
                    validateInput();
                  }
                });
              },
              decoration: InputDecoration(
                hintText: "Enter your word",
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: resetInput,
                  child: Text("Reset"),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              "Score: $score",
              style: TextStyle(fontSize: 24, color: Colors.green),
            ),
            SizedBox(height: 10),
            Text(
              feedback,
              style: TextStyle(
                fontSize: 20,
                color: feedback == "Correct!" ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
