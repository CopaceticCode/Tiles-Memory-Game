import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Game',
      theme: ThemeData(
        brightness: Brightness.dark,
      ),
      home: GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int boxes = 6;
  double waitTime = 0.5; // Time in seconds
  List<List<int>> topLeft = List.generate(32, (_) => [0, 0]);
  int wins = 0;
  int losses = 0;
  bool gameActive = false;
  bool showNumbers = false;
  bool drawn = false;
  int startTime = 0;
  int correctNumbers = 0;
  List<int> potentialPair = [0, 0];
  bool reselect = false;
  List<int> possibleX = List.filled(4, 0);
  List<int> possibleY = List.filled(8, 0);

  @override
  void initState() {
    super.initState();
    reset();
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.black, // Set background color to black
    body: Padding(
      padding: const EdgeInsets.all(20.0), // Add equal padding of 20 pixels
      child: Stack(
        // mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Align(
            alignment: Alignment.topRight,
            // Add an IconButton with a question mark icon
            child: IconButton(
              icon: Icon(Icons.help_outline, color: Colors.white), // Question mark icon
              onPressed: () {
                // Show dialog with a text message and an okay button
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      backgroundColor: Colors.black, // Dialog background color
                      title: Text(
                        'Limited-Hold Memory',
                        style: TextStyle(color: Colors.white), // Dialog title text color
                      ),
                      content: Text(
                        '\nSelect the number of tiles to appear and the duration they will stay visible. Tap the tiles in numerical order. '
                        '\n\nThis game uses present working memory, which is theorized to have decreased in early hominids as an evolutionary tradeoff for complex language skills. However, human brains are large and adaptive.'
                        '\n\nChimpanzees are reported to have performed 80% with 8 numbers at .21 seconds while humans scored up to 80% with 6 numbers at .21 seconds.',
                        style: TextStyle(color: Colors.white), // Dialog content text color
                      ),
                      actions: <Widget>[
                        // Okay button
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close the dialog
                          },
                          child: Text(
                            'Okay',
                            style: TextStyle(color: Colors.white), // Button text color
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          if (!gameActive)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () => decrementValue('boxes'),
                        icon: Icon(Icons.arrow_left, size: 30),
                      ),
                      Column(
                        children: [
                          Text(
                            '${boxes} tiles',
                            style: TextStyle(
                              fontSize: 18, // tiles font size
                              color: Colors.white, // Set text color to white
                            ),
                          ),
                          Container(
                            width: 200,
                            child: Slider(
                              value: boxes.toDouble(),
                              min: 1,
                              max: 32,
                              divisions: 31,
                              onChanged: (value) => setState(() => boxes = value.toInt()),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => incrementValue('boxes'),
                        icon: Icon(Icons.arrow_right, size: 30),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () => decrementValue('time'),
                        icon: Icon(Icons.arrow_left, size: 30),
                      ),
                      Column(
                        children: [
                          Text(
                            '${waitTime.toStringAsFixed(1)} seconds',
                            style: TextStyle(
                              fontSize: 18, // seconds font size
                              color: Colors.white,
                            ), // Set text color to white
                          ),
                          Container(
                            width: 200,
                            child: Slider(
                              value: waitTime,
                              min: 0.1,
                              max: 10.0,
                              divisions: 49,
                              label: "${waitTime.toStringAsFixed(2)} sec",
                              onChanged: (value) => setState(() => waitTime = value),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => incrementValue('time'),
                        icon: Icon(Icons.arrow_right, size: 30),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: startGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(12, 57, 59, 1), // Set the background color to a darker shade of blue
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)), // Make the button round
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10), // Increase padding for width
                    ),
                    child: Text('Start', style: TextStyle(fontSize: 24, color: Colors.white70)), // adjust the text
                  ),
                  if (wins > 0 || losses > 0)
                    Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: Text(
                          wins > 0 ? 'Completed successfully in ${getElapsedTime()} seconds' : 'Failed in ${getElapsedTime()} seconds',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (gameActive)
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1,
              ),
              itemCount: 32,
              itemBuilder: (context, index) {
                int tileNumber = getTileNumber(index);
                return GestureDetector(
                  onTap: () => handleTap(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: tileNumber > 0 ? Colors.white : Colors.black,
                      border: Border.all(color: Colors.black, width: 1), // Add border
                    ),
                    padding: EdgeInsets.all(4),
                    child: Center(
                      child: Text(
                        showNumbers && tileNumber > 0 ? '$tileNumber' : '',
                        style: TextStyle(fontSize: 32, color: Colors.black),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    ),
  );
}


  String getElapsedTime() => ((DateTime.now().millisecondsSinceEpoch - startTime) / 1000.0).toStringAsFixed(2);

  int getTileNumber(int index) {
    for (int i = 0; i < boxes; i++) {
      if (index == topLeft[i][0] * 8 + topLeft[i][1]) {
        return i + 1;
      }
    }
    return 0;
  }

  void startGame() {
    setState(() {
      gameActive = true;
      showNumbers = true;
      startTime = DateTime.now().millisecondsSinceEpoch;
      shuffleBoxes();
      wins = 0;
      losses = 0;
    });
    Future.delayed(Duration(milliseconds: (waitTime * 1000).toInt()), () { // Corrected time conversion here
      setState(() {
        showNumbers = false;
        drawn = true;
      });
    });
  }


  void handleTap(int index) {
    int tileNumber = getTileNumber(index);
    if (gameActive && tileNumber == correctNumbers + 1) {
      setState(() {
        correctNumbers++;
        if (correctNumbers == boxes) {
          win();
        }
      });
    } else if (gameActive && tileNumber > 0) {
      lose();
    }
  }

  void shuffleBoxes() {
    Random rng = Random();
    Set<int> usedPositions = Set();
    int newPosition;
    for (int i = 0; i < boxes; i++) {
      do {
        newPosition = rng.nextInt(32);
      } while (!usedPositions.add(newPosition));
      topLeft[i] = [newPosition ~/ 8, newPosition % 8];
    }
  }

  void win() {
    setState(() {
      wins++;
      reset();
    });
  }

  void lose() {
    setState(() {
      losses++;
      reset();
    });
  }

  void reset() {
    setState(() {
      correctNumbers = 0;
      gameActive = false;
      drawn = false;
      showNumbers = false;
      topLeft = List.generate(32, (_) => [0, 0]); // Reset positions
    });
  }

  void decrementValue(String type) {
    setState(() {
      if (type == 'boxes') {
        boxes = boxes > 1 ? boxes - 1 : 1;
      } else if (type == 'time') {
        waitTime = waitTime > 0.1 ? waitTime - 0.1 : 0.1;
      }
    });
  }

  void incrementValue(String type) {
    setState(() {
      if (type == 'boxes') {
        boxes = boxes < 32 ? boxes + 1 : 32;
      } else if (type == 'time') {
        waitTime = waitTime < 5.0 ? waitTime + 0.1 : 5.0;
      }
    });
  }
}
