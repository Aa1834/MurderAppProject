import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'node.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'story.dart';
import 'dart:async';


late Box<Person> personBox;
late Box<Clue> clueBox;
late Box<Room> roomBox;
late Box<Dialogue> dialogueBox;
int score=0;

class GameLogic {
  List<Person> people = [];
  List<Clue> clues = [];
  List<Room> rooms = [];
  List<Dialogue> dialogues = [];
  List<Clue> selectedClues = [];

  GameStory story = GameStory();

  GameLogic() {
    _loadData();
  }

  void _loadData() {
    people = personBox.values.toList();
    clues = clueBox.values.toList();
    rooms = roomBox.values.toList();
    dialogues = dialogueBox.values.toList();
    //print(story.getDialogues('Abdullah'));
    story.loadLists(people, clues, rooms,dialogues);
  }

  List<Clue> getSelectedClues() {
    return selectedClues;
  }

  void updateSelectedClues(List<Clue> clues) {
    selectedClues = clues;
  }

  void resetGame(BuildContext context){
    people.clear();
    clues.clear();
    rooms.clear();
    selectedClues.clear();
    story = GameStory();
    _loadData();
    Navigator.pushNamed(context,'/');
    CountDownTimer().resetTimer();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(PersonAdapter());
  Hive.registerAdapter(ClueAdapter());
  Hive.registerAdapter(RoomAdapter());
  Hive.registerAdapter(DialogueAdapter());

  personBox = await Hive.openBox<Person>('personBox');
  roomBox = await Hive.openBox<Room>('roomBox');
  clueBox = await Hive.openBox<Clue>('clueBox');
  dialogueBox = await Hive.openBox<Dialogue>('dialogueBox');

  try {
    String csv = 'people.csv';
    String csv2 = 'rooms.csv';
    String csv3 = 'clues.csv';
    String csv4 = 'dialogues.csv';
    String fileData = await rootBundle.loadString(csv);
    String fileData2 = await rootBundle.loadString(csv2);
    String filedata3 = await rootBundle.loadString(csv3);
    String filedata4 = await rootBundle.loadString(csv4);

    List<String> rows = fileData.split("\n");
    for (String row in rows) {
      List<String> itemInRow = row.split(",");
      if (itemInRow.length >= 2) {
        int personID = int.parse(itemInRow[0]);
        String name = itemInRow[1];
        Person person = Person(personID, name);
        personBox.put(name, person);
      }
    }

    List<String> rows1 = fileData2.split("\n");
    for (String row in rows1) {
      List<String> itemInRow = row.split(",");
      if (itemInRow.length >= 3) {
        int roomID = int.parse(itemInRow[0]);
        String roomName = itemInRow[1];
        int capacity = int.parse(itemInRow[2]);
        Room room = Room(roomID, roomName, capacity);
        roomBox.put(roomName, room);
      }
    }

    List<String> rows2 = filedata3.split("\n");
    for (String row in rows2) {
      List<String> itemInRow = row.split(",");
      if (itemInRow.length >= 2) {
        int clueID = int.parse(itemInRow[0]);
        String clueName = itemInRow[1];
        Clue clue = Clue(clueID, clueName);
        clueBox.put(clueName, clue);
      }
    }

    List<String> rows3 = filedata4.split("\n");
    for (String row in rows3) {
      List<String> itemInRow = row.split(",");
      if (itemInRow.length >= 5) {
        int personID = int.parse(itemInRow[0]);
        int roomID = int.parse(itemInRow[1]);
        int clueID = int.parse(itemInRow[2]);
        int sequenceOfDialogue = int.parse(itemInRow[3]);
        String dialogue = itemInRow[4];
        Dialogue text = Dialogue(personID, roomID, clueID, sequenceOfDialogue, dialogue);
        dialogueBox.put(dialogue, text);
      }
    }
  } catch (e) {
    print('Error loading CSV files: $e');
  }

  GameLogic gameLogic = GameLogic();
  //gameLogic.printLists();

  runApp(MyApp(gameLogic: gameLogic));
}

class MyApp extends StatelessWidget {
  final GameLogic gameLogic;
  const MyApp({Key? key, required this.gameLogic}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //home: CountDown(),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(),
        '/howToPlay': (context) => HowToPlayScreen(),
        '/startGame': (context) => GameScreen(gameLogic: gameLogic,),
        '/enterRoom': (context) => GameScreen(gameLogic: gameLogic,),
        '/kitchen': (context) => Rooms('Kitchen',gameLogic),
        '/livingRoom': (context) => Rooms('LivingRoom',gameLogic),
        '/hallway': (context) => Rooms('Hallway',gameLogic),
        '/summary' : (context) => Summary(),
      },
    );
  }
}

class Summary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Game Score"),
          automaticallyImplyLeading: false,
          backgroundColor: Colors.blue,
        ),
        body:ScoreWidget()
    );
  }
}
// Timer class below:
class CountDownTimer {
  List<Clue> selectedClues = [];
  Person? selectedPerson;
  int wrongAnswer = 0;
  static final CountDownTimer _instance = CountDownTimer._internal();
  factory CountDownTimer() => _instance;
  CountDownTimer._internal();
  int timeLeft =300; //  seconds
  Timer? _timer;
  int points = 1000;
  final StreamController<int> _timeController = StreamController<int>.broadcast();
  Stream<int> get timeStream => _timeController.stream;

  void startCountDown(VoidCallback onTimeEnd) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft <= 0 || points<=0) {timer.cancel();onTimeEnd();}
      else {timeLeft--;_timeController.add(timeLeft);
      if (timeLeft % 60 == 0) { points -= 50;
      score = points;
      if (points <= 0) {
        points = 0;
        score = points;
        timer.cancel();
        onTimeEnd();
      };
      if (timeLeft <= 0 && selectedPerson == null) {
        points = 0;
        score = points;
        timer.cancel();
        onTimeEnd();
      }
      };
      }
    });
  }

  void pauseTimer(){
    _timer?.cancel();
  }

  void unpauseTimer(VoidCallback onTimeEnd){
    startCountDown(onTimeEnd);
  }

  void resetTimer(){
    _timer?.cancel();
    timeLeft = 300;
    points = 1000;
    _timeController.add(timeLeft);
  }

  void destroy() {
    _timer?.cancel();
    _timeController.close();
  }
}

class ScoreWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
        child:Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("gameOver.jpg"),
                fit: BoxFit.cover,
              ),
            ),
            child:Column(
                children:[
                  Text(
                    'Your Score: ${CountDownTimer().points}',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/');
                      CountDownTimer().resetTimer();
                    },
                    child: const Text('Home'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                            color: Colors.white
                        )
                    ),
                  )
                ])
        )
    );
  }
}

class CountDownTimerWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: CountDownTimer().timeStream,
      initialData: CountDownTimer().timeLeft,
      builder: (context, snapshot) {
        int timeLeft = snapshot.data ?? 0;
        return Center(
          child: Text(
            'Time Left: ${timeLeft ~/ 60}:${(timeLeft % 60).toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 18),
          ),
        );
      },
    );
  }
}

class HomePage extends StatelessWidget {
  final gameLogic = GameLogic();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Murder Mystery Game'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue,
      ),
      body: Center( child:Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("background.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                CountDownTimer().startCountDown(() {
                  Navigator.pushNamed(context, '/summary');
                });
                Navigator.pushNamed(context, '/startGame');
              },
              child: Text('Start Game'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  textStyle: TextStyle(
                      color: Colors.white
                  )
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/howToPlay');
              },
              child: const Text('How to Play'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                      color: Colors.white
                  )
              ),
            )
          ],
        ),
      ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  final GameLogic gameLogic;
  GameScreen({required this.gameLogic});
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  List<Clue> selectedClues = [];
  Person? selectedPerson;
  @override
  void initState() {
    super.initState();
    selectedClues = widget.gameLogic.getSelectedClues();
  }

  void _showAccuseDialog() {
    if (selectedClues.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('No Clues Selected'),
            content: const Text('You need to find clues before accusing someone. Search every room to find the clues.'),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      return;
    }
    List<Person> people = widget.gameLogic.people;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        Person? selectedPerson;
        return AlertDialog(
          title: const Text('Accuse'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<Person>(
                hint: const Text('Select a person to accuse'),
                value: selectedPerson,
                onChanged: (Person? newValue) {
                  setState(() {
                    selectedPerson = newValue;
                  });
                },
                items: people.map((Person person) {
                  return DropdownMenuItem<Person>(
                    value: person,
                    child: Text(person.name),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Accuse'),
              onPressed: () {
                if (selectedPerson != null) {
                  bool isCorrectPerson = _validatePerson(selectedPerson!);
                  bool areCluesCorrect = _validateClues(selectedClues);

                  String message;
                  if (isCorrectPerson && areCluesCorrect) {
                    message = 'You have correctly identified the culprit and the clues!';
                  } else if (!isCorrectPerson) {
                    message = 'You selected the wrong person.';
                    CountDownTimer().wrongAnswer++;
                    CountDownTimer().points -=200;
                    if (CountDownTimer().wrongAnswer == 5){
                      CountDownTimer().points = 0;
                    }
                  } else {
                    message = 'You selected the wrong clues.';
                  }
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Result'),
                        content: Text(message),
                        actions: [
                          TextButton(
                            child: const Text('OK'),
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).pop();
                              if (isCorrectPerson && areCluesCorrect) {
                                Navigator.pushNamed(context, '/summary');
                              }
                            },
                          ),
                        ],
                      );
                    },
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  bool _validatePerson(Person person) {
    return (widget.gameLogic.story.murderName== person.name);
  }

  bool _validateClues(List<Clue> clues) {
    List<String> stringClues=[];
    for (var clue in clues) {
      stringClues.add(clue.clueName.replaceAll('\r', ''));
    }
    return stringClues.contains("Knife") && stringClues.contains("Notebook") && stringClues.contains("Phone");
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Screen'),
        backgroundColor: Colors.blue,
        actions: [
          CountDownTimerWidget(),
          IconButton(
            icon: const Icon(Icons.restart_alt, semanticLabel: "Restart",),
            onPressed: (){
              setState((){
                widget.gameLogic.resetGame(context);
              });
            },
          ),
        ],
      ),
      body: Flexible(child: ListView(
        scrollDirection: Axis.vertical,
        children: [
          Expanded(
            flex:3,
            child: Card(
              clipBehavior: Clip.hardEdge,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/kitchen_screen.png',
                    height: 200,
                    width: 200,
                  ),
                  ElevatedButton(
                    child: const Text('Kitchen'),
                    onPressed: () {
                      Navigator.pushNamed(context, '/kitchen');
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        textStyle: TextStyle(
                            color: Colors.white
                        )
                    ),
                  )
                ],
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              elevation: 5,
              margin: const EdgeInsets.all(10),
            ),
          ),
          Expanded(
            flex:3,
            child: Card(
              clipBehavior: Clip.hardEdge,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/Hallway_screen.png',
                    height: 200,
                    width: 200,
                  ),
                  ElevatedButton(
                    child: const Text('Hallway'),
                    onPressed: () {
                      Navigator.pushNamed(context, '/hallway');
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        textStyle: TextStyle(
                            color: Colors.white
                        )
                    ),
                  )
                ],
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              elevation: 5,
              margin: const EdgeInsets.all(10),
            ),
          ),
          Expanded(
            flex:3,
            child: Card(
              clipBehavior: Clip.hardEdge,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/living_room_screen_pic.png',
                    height: 200,
                    width: 200,
                  ),
                  ElevatedButton(
                      child: const Text('Living Room'),
                      onPressed: () {
                        Navigator.pushNamed(context, '/livingRoom');
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          textStyle: TextStyle(
                              color: Colors.white
                          )
                      )
                  ),
                ],
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              elevation: 5,
              margin: EdgeInsets.all(10),
            ),
          ),
          ElevatedButton(
              onPressed: _showAccuseDialog,
              child: const Text('Accuse'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                      color: Colors.white
                  )
              )
          ),
        ],
      ),
      ),
    );
  }
}

class Rooms extends StatefulWidget {
  final String roomName;
  final GameLogic gameLogic;

  Rooms(this.roomName, this.gameLogic);
  @override
  _RoomsState createState() => _RoomsState();
}

class _RoomsState extends State<Rooms> {
  int currentSequence = 0;
  List<Clue> selectedClues= []; //User's selected clues list

  void _updateSelectedClues(List<Clue> clues) {
    setState(() {
      selectedClues = clues;
    });
  }
  @override
  Widget build(BuildContext context) {
    List<String> peopleInRoom = widget.gameLogic.story.getPeopleInRoom(widget.roomName);
    List<Clue> allClues = widget.gameLogic.clues;
    int crossAxisCount = (MediaQuery.of(context).size.width / 200).floor();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomName),
        backgroundColor: Colors.blue,
        actions: [
          CountDownTimerWidget(),
          IconButton(
            icon: const Icon(Icons.restart_alt, semanticLabel: "Restart",),
            onPressed: (){
              setState((){
                widget.gameLogic.resetGame(context);
              });
            },
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(0.0),
              width: 80.0,
              height: 80.0,
            ), //Container
          ),
          Expanded(
            child: Center(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 10.0,
                  mainAxisSpacing: 5.0,
                  childAspectRatio: 3.0,
                ),
                itemCount: peopleInRoom.length,
                itemBuilder: (context, i) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          color: Colors.white, fontSize: 20,
                        )
                    ),
                    onPressed: () {
                      String personName = peopleInRoom[i];
                      int roomID = widget.gameLogic.story.getRoomID(personName);
                      if (roomID != -1) {
                        String dialogues = widget.gameLogic.story.getDialogues(personName, roomID);
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return StatefulBuilder(
                              builder: (context, setState) {
                                return Dialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.0),
                                  ),
                                  child: DefaultTabController(
                                    length: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(30.0), // Increase padding here
                                      child: Column(
                                        children: [
                                          const TabBar(tabs: [Tab(text: 'Dialogues'), Tab(text: 'Clues'),],),
                                          Expanded(
                                            child: TabBarView(
                                              children: [
                                                // Dialogues Tab
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Dialogues for $personName',
                                                      style: const TextStyle(
                                                        fontSize: 24.0,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 20.0),
                                                    Expanded(
                                                      child: SingleChildScrollView(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [Text(dialogues)],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                // Clues Tab
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'Select Clues:',
                                                      style: TextStyle(
                                                        fontSize: 20.0,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: ListView(
                                                        children: allClues.map((clue) {
                                                          return CheckboxListTile(
                                                            title: Text(clue.clueName),
                                                            value: widget.gameLogic.selectedClues.contains(clue),
                                                            onChanged: (bool? value) {
                                                              setState(() {
                                                                if (value == true) {
                                                                  if (widget.gameLogic.selectedClues.length < 3) {
                                                                    widget.gameLogic.selectedClues.add(clue);
                                                                  }
                                                                } else {
                                                                  widget.gameLogic.selectedClues.remove(clue);
                                                                }
                                                                _updateSelectedClues(widget.gameLogic.selectedClues);
                                                              });
                                                            },
                                                          );
                                                        }).toList(),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          TextButton(
                                            child: const Text('Close'),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      } else {
                        print('Person not found.');
                      }
                    },
                    child: Container(
                      alignment: Alignment.center,
                      child: Text(peopleInRoom[i]),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HowToPlayScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How to Play'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 24.0),
                child: Text('There has been a murder in a house and we need your help to find the murderer.'),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 24.0),
                child: Text('1) Start the game by clicking the start button, once you do, you will find yourself in the house. Click on the rooms to enter and interview each person.'),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 24.0),
                child: Text('2) Search for clues by interviewing people. Top tip: Keep an eye out what each person in each room says and verify their claims based on the statements given by other people.'),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 24.0),
                child: Text('3) You can select a maximum of up to 3 clues. Once you have done so, you will be able to accuse a person in any room. Choose wisely. You only have 5 chances to accuse someone else it is game over. This will decrease the longer you take and/or for each incorrect clue/accusation.'),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 24.0),
                child: Text('4) Remember, you will be timed as soon as you start a game. You lose 50 points every minute. For every incorrect accusation/clues, you will lose 200 points.'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}