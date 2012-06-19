/****************************************************************************
**
** Copyright (C) 2012 Nokia Corporation and/or its subsidiary(-ies).
** Contact: http://www.qt-project.org/
**
** This file is part of the QtQml module of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:LGPL$
** GNU Lesser General Public License Usage
** This file may be used under the terms of the GNU Lesser General Public
** License version 2.1 as published by the Free Software Foundation and
** appearing in the file LICENSE.LGPL included in the packaging of this
** file. Please review the following information to ensure the GNU Lesser
** General Public License version 2.1 requirements will be met:
** http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html.
**
** In addition, as a special exception, Nokia gives you certain additional
** rights. These rights are described in the Nokia Qt LGPL Exception
** version 1.1, included in the file LGPL_EXCEPTION.txt in this package.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU General
** Public License version 3.0 as published by the Free Software Foundation
** and appearing in the file LICENSE.GPL included in the packaging of this
** file. Please review the following information to ensure the GNU General
** Public License version 3.0 requirements will be met:
** http://www.gnu.org/copyleft/gpl.html.
**
** Other Usage
** Alternatively, this file may be used in accordance with the terms and
** conditions contained in a signed written agreement between you and Nokia.
**
**
**
**
**
**
** $QT_END_LICENSE$
**
****************************************************************************/

import QtQuick 2.0
import "content" as Content
import "content/snake.js" as Logic

Rectangle {
    id: screen;
    SystemPalette { id: activePalette }
    color: activePalette.window
    property bool activeGame: false

    property int gridSize : 34
    property int margin: 4
    property int numRowsAvailable: Math.floor((height-32-2*margin)/gridSize)
    property int numColumnsAvailable: Math.floor((width-2*margin)/gridSize)

    property int lastScore : 0

    property int score: 0;
    property int heartbeatInterval: 200
    property int halfbeatInterval: 160

    width: 480
    height: 750

    property int direction
    property int headDirection

    property variant head;

    Content.HighScoreModel {
        id: highScores
        game: "Snake"
    }

    Timer {
        id: heartbeat;
        interval: screen.heartbeatInterval;
        running: screen.activeGame
        repeat: true
        onTriggered: { Logic.move() }
    }
    Timer {
        id: halfbeat;
        interval: screen.halfbeatInterval;
        repeat: true
        running: heartbeat.running
        onTriggered: { Logic.moveSkull() }
    }
    Timer {
        id: startNewGameTimer;
        interval: 700;
        onTriggered: { Logic.startNewGame(); }
    }

    Timer {
        id: startHeartbeatTimer;
        interval: 1000 ;
        onTriggered: { screen.state = "running"; screen.activeGame = true; }
    }

    Image{
        id: pauseDialog
        z: 1
        source: "content/pics/pause.png"
        anchors.centerIn: parent;
        //opacity is deliberately not animated
        opacity: 0 //Was !Qt.application.active && activeGame, but application doesn't work (QTBUG-23331)
    }

    Image {

        Image {
            id: title
            source: "content/pics/snake.jpg"
            fillMode: Image.PreserveAspectCrop
            anchors.fill: parent
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            Column {
                spacing: 140
                anchors.verticalCenter: parent.verticalCenter;
                anchors.left:  parent.left;
                anchors.right:  parent.right;

                Text {
                    color: "white"
                    font.pointSize: 48
                    font.italic: true;
                    font.bold: true;
                    text: "Snake"
                    anchors.horizontalCenter: parent.horizontalCenter;
                }

                Text {
                    color: "white"
                    font.pointSize: 24
                    anchors.horizontalCenter: parent.horizontalCenter;
                    //horizontalAlignment: Text.AlignHCenter
                    text: "Last Score:\t" + screen.lastScore + "\nHighscore:\t" + highScores.topScore;
                }
            }
        }

        source: "content/pics/background.png"
        fillMode: Image.PreserveAspectCrop

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: toolbar.top

        Rectangle {
            id: playfield
            border.width: 1
            border.color: "white"
            color: "transparent"
            anchors.horizontalCenter: parent.horizontalCenter
            y: (screen.height - 32 - height)/2;
            width: screen.numColumnsAvailable * screen.gridSize + 2*screen.margin
            height: screen.numRowsAvailable * screen.gridSize + 2*screen.margin


            Content.Skull {
                id: skull
            }

            MouseArea {
                anchors.fill: parent
                onPressed: {
                    if (screen.state == "") {
                        Logic.startNewGame();
                        return;
                    }
                    if (direction == 0 || direction == 2)
                        Logic.scheduleDirection((mouseX > (head.x + head.width/2)) ? 1 : 3);
                    else
                        Logic.scheduleDirection((mouseY > (head.y + head.height/2)) ? 2 : 0);
                }
            }
        }

    }

    Rectangle {
        id: progressBar
        opacity: 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        color: "transparent"
        border.width: 2
        border.color: "#221edd"
        x: 50
        y: 50
        width: 200
        height: 30
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 40

        Rectangle {
            id: progressIndicator
            color: "#221edd";
            width: 0;
            height: 30;
        }
    }

    Rectangle {
        id: toolbar
        color: activePalette.window
        height: 32; width: parent.width
        anchors.bottom: screen.bottom

        Content.Button {
            id: btnA; text: "New Game"; onClicked: Logic.startNewGame();
            anchors.left: parent.left; anchors.leftMargin: 3
            anchors.verticalCenter: parent.verticalCenter
        }

        Content.Button {
            text: "Quit"
            anchors { left: btnA.right; leftMargin: 3; verticalCenter: parent.verticalCenter }
            onClicked: Qt.quit();
        }

        Text {
            color: activePalette.text
            text: "Score: " + screen.score; font.bold: true
            anchors.right: parent.right; anchors.rightMargin: 3
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    focus: true
    Keys.onSpacePressed: Logic.startNewGame();
    Keys.onLeftPressed: if (state == "starting" || direction != 1) Logic.scheduleDirection(3);
    Keys.onRightPressed: if (state == "starting" || direction != 3) Logic.scheduleDirection(1);
    Keys.onUpPressed: if (state == "starting" || direction != 2) Logic.scheduleDirection(0);
    Keys.onDownPressed: if (state == "starting" || direction != 0) Logic.scheduleDirection(2);

    states: [
        State {
            name: "starting"
            PropertyChanges {target: progressIndicator; width: 200}
            PropertyChanges {target: title; opacity: 0}
            PropertyChanges {target: progressBar; opacity: 1}
        },
        State {
            name: "running"
            PropertyChanges {target: progressIndicator; width: 200}
            PropertyChanges {target: title; opacity: 0}
            PropertyChanges {target: skull; row: 0; column: 0; }
            PropertyChanges {target: skull; spawned: 1}
        }
    ]

    transitions: [
        Transition {
            from: "*"
            to: "starting"
            NumberAnimation { target: progressIndicator; property: "width"; duration: 1000 }
            NumberAnimation { property: "opacity"; duration: 200 }
        },
        Transition {
            to: "starting"
            NumberAnimation { target: progressIndicator; property: "width"; duration: 1000 }
            NumberAnimation { property: "opacity"; duration: 200 }
        }
    ]

}
