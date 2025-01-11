import 'package:hive/hive.dart';
import 'node.dart';

late Box<Node> box;

Future<void> initializeBox() async {
  box = await Hive.openBox<Node>('decisionMap');
}

String questionPerson(String name) {
  Node? node = box.get(name);
  if (node != null) {
    return 'Questioning ${node.name}: ${node.dialogue}';
  } else {
    return 'Person not found.';
  }
}

String accusePerson(String name) {
  Node? node = box.get(name);
  if (node != null) {
    if (node.role == 'murderer') {
      return 'Accusing ${node.name}: ${node.dialogue}';
    } else {
      return 'You have failed. The murderer is not ${node.name}.';
    }
  } else {
    return 'Person not found.';
  }
}