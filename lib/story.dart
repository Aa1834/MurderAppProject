import 'dart:math';
import 'node.dart';
class GameStory {
  List<Person> people = [];
  List<Clue> clues = [];
  List<Room> rooms = [];
  List<Dialogue> dialogues = [];
  Map<String, String> personLocationMap = {};
  Map<String, String> personLocationIDs = {};
  String murderName='';

  void loadLists(List<Person> valPerson, List<Clue> valClue, List<Room> valRoom, List<Dialogue> valDialogue) {
    people = valPerson;
    clues = valClue;
    rooms = valRoom;
    dialogues = valDialogue;
    allocatePeopleToRooms();
    printAllocations();
  }

  List<List<String>> nodeAllocations = [
    []
  ]; // List of lists of people allocated to each room (2d array/matrix).

  void allocatePeopleToRooms() {
    nodeAllocations = List.generate(rooms.length, (_) => []);
    Random random = Random();
    List<int> personIndices = List.generate(people.length, (index) => index);
    personIndices.shuffle(random);


    for (int i = 0; i < people.length; i++) {
      int roomIndex = i % rooms.length;
      nodeAllocations[roomIndex].add(people[personIndices[i]].name);
    }

    for (int i = 0; i < rooms.length; i++) {
      var n = 0;
      for (var person in nodeAllocations[i]) {
        String personKey = '${rooms[i].roomName}Person$n';
        print(personKey);
        personLocationMap[personKey] = person;
        n = n + 1;
      }
      print('Node Allocations: $nodeAllocations');
      print('Person Location Map: $personLocationMap');
    }
  }

  void printAllocations() {
    for (int i = 0; i < nodeAllocations.length; i++) {
      for (int p = 0; p < nodeAllocations[i].length; p++) {
        String key = '${i}_$p';
        String person = nodeAllocations[i][p];
        personLocationIDs[key] = person;
      }
    }
    personLocationIDs.forEach((key, value) {
    });
  }

  List<String> getPeopleInRoom(String roomName) {
    // Need room name
    int roomIndex = rooms.indexWhere((room) => room.roomName == roomName);
    if (roomIndex != -1) {
      return nodeAllocations[roomIndex];
    }
    return [];
  }

  int getRoomID(String personName) {
    for (int i = 0; i < nodeAllocations.length; i++) {
      if (nodeAllocations[i].contains(personName)) {
        return i+1;
      }
    }
    return -1;
  }

  String getDialogues(String personName, int roomID) {
    personName = personName.replaceAll('\r', '');
    List<Dialogue> personDialogues = [];
    String toReturn="";
    for (var dialogue in dialogues) {
      if (dialogue.roomID == roomID) {
        String key = '${roomID - 1}_${dialogue.personID - 1}';
        String? personInRoom = personLocationIDs[key];
        if(key=='1_1') {
          murderName = personInRoom!;
        }
        personInRoom = personInRoom?.replaceAll("\r", "");
        if (personInRoom == personName && dialogue.sequenceOfDialogue >= 0) {
          Dialogue processedDialogue = populateNameInDialogue(dialogue);
          personDialogues.add(processedDialogue);
          toReturn+=  dialogue.dialogue + '\n\n';
        }
      }
    }
    return toReturn;
  }

// populate person name in dialogue string
  Dialogue populateNameInDialogue(var dialogue) {
    String processedDialogue = dialogue.dialogue.toString();
    RegExp regExp = RegExp(r'\(([^)]+)\)');
    Iterable<Match> matches = regExp.allMatches(processedDialogue);
    for (var match in matches) {
      String personField = match.group(1)!;
      if (personLocationMap.containsKey(personField)) {
        String personName = personLocationMap[personField]!;
        processedDialogue = processedDialogue.replaceFirst('($personField)', personName);
        processedDialogue = processedDialogue.replaceAll('\r', '');
      }
    }
    dialogue.dialogue = processedDialogue;
    return dialogue;
  }
}