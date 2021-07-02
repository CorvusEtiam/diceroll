# Plan

* Simulate rolling 5 dices and print points 
* Add Way to reroll dices
* [WIP] Add More players
    + Prompt for player name
    + Add Result table for players
* [WIP] Add computer simulated players
* [TODO] Print more stats for each roll
* [TODO] Handle more complex dice patterns
* [WIP] Add proper GUI -- maybe `raylib`?
    * Render Dices
    * On mouse click: reroll dice

# Turn

1. Game Starts Menu 
    a) Play game #2
    b) Exit 
2. When Play starts:
    a) PlayerTurn:
        + Roll dices
        + Draw Dices
        + Draw Roll button
    b) PlayerReroll:
        + Reroll dices
        + Draw Dices
    c) PlayerWon

    d) ComputerTurn

    e) 

# Gui Engine

* Label
* Button
* HBox
* VBox

## GuiRect

+ cut(side: Side, size: u32);
+ pad(size: Side)
+ border(size: u32)


