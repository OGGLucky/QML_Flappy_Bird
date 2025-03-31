import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0

Page {
    id: mainMenuPage

    property int highScore: 0

    signal highScoreUpdated(int score)

    Component.onCompleted: {
        loadHighScore()
    }

    function loadHighScore() {
        var db = LocalStorage.openDatabaseSync("FlappyBirdDB", "1.0", "Flappy Bird Database", 1000000);
        db.transaction(function(tx) {
            tx.executeSql('CREATE TABLE IF NOT EXISTS Settings(name TEXT, value TEXT)');
            var rs = tx.executeSql('SELECT value FROM Settings WHERE name = "highScore"');
            if (rs.rows.length > 0) {
                highScore = parseInt(rs.rows.item(0).value);
            } else {
                tx.executeSql('INSERT INTO Settings VALUES("highScore", "0")');
            }
            highScoreUpdated(highScore);
        });
    }

    function resetHighScore() {
        var db = LocalStorage.openDatabaseSync("FlappyBirdDB", "1.0", "Flappy Bird Database", 1000000);
        db.transaction(function(tx) {
            tx.executeSql('UPDATE Settings SET value = "0" WHERE name = "highScore"');
            highScore = 0;
            highScoreUpdated(highScore);
        });
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: "Flappy Bird"
            }

            Text {
                id: highScoreText
                text: "Рекорд: " + highScore
                font.bold: true
                color: "white"
                font.pixelSize: 50
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Button {
                text: "Начать игру"
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("Game.qml"), { mainMenuPage: mainMenuPage })
                }
            }

            Button {
                text: "Сбросить рекорд"
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    resetHighScore()
                }
            }
        }
    }

    onHighScoreUpdated: {
        highScoreText.text = "Рекорд: " + score;
    }
}
