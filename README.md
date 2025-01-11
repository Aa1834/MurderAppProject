# firstapp

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## The Database

The entities of the database include:
- Node (this can be either a witness, a murderer, or a suspect)
- Clues
- Rooms
This part will be in CSV

The relationship between the entities are as describes below:
To make the code dynamic the relationships will be established in Dart. Not in database.
- One room has one or many people (e.g. witness,murderer,suspect)
- One person is in one room
- One room has one or many clues
- 

witnesses
clues
Murderer 
rooms  
suspects


## Node class:
- string name


1) Get database
2) Have algorithm
The database will contain the nodes representing the rooms, people and clues. 

When starting app, LOAD/READ the data in the boxes/tables 

Make map of person with location 
value = Randomperson(1,2)
g

generate random number which refers to person and location to a Map

Assigning People and clues to a room dynamically which changes each time we start the game.
Make the graph structure establishing links/routes
Dialogues***
People can move to different rooms () which is event based. 

Game logic:

1) We are reading the string dialogue which is ready by the characters in this game starting off with introductory dialogues
2) The dialogues need to have links e.g. what dialogue leads to conditional progression of other character's dialogues and hints to location of clues
3) 