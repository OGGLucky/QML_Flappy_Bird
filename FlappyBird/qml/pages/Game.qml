import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0

Page {
    id: gamePage
    width: Screen.width
    height: Screen.height

    property bool gameStarted: false
    property int score: 0
    property var mainMenuPage

    Image {
        id: background
        anchors.fill: parent
        source: "background.jpg"
        fillMode: Image.PreserveAspectCrop
    }

    Image {
        id: bird
        width: 80
        height: 80
        source: "bird.png"
        x: 100
        y: gamePage.height / 2 - height / 2

        property real velocity: 0
        property real gravity: 3
        property real jumpForce: -45

        Behavior on y {
            NumberAnimation { duration: 100 }
        }

        function update() {
            if (!gameStarted) return;
            velocity += gravity
            y += velocity

            if (y + height > gamePage.height) {
                y = gamePage.height - height
                velocity = 0
                gameOver()
            }

            if (y < 0) {
                y = 0
                velocity = 0
            }
        }

        function jump() {
            if (!gameStarted) return;
            velocity = jumpForce
        }
    }

    Rectangle {
        id: pipeContainer
        anchors.fill: parent
        color: "transparent"

        ListModel {
            id: pipeModel
        }

        Component {
            id: pipeComponent
            Rectangle {
                width: 120
                height: 400 + Math.random() * 300
                color: "green"
                x: gamePage.width
                y: 0

                property bool active: true
                property bool scored: false

                NumberAnimation on x {
                    from: gamePage.width
                    to: -width
                    duration: 2500
                    running: gameStarted
                    onStopped: {
                        active = false
                        for (var i = 0; i < pipeModel.count; i++) {
                            if (pipeModel.get(i).pipe === this) {
                                pipeModel.remove(i)
                                break
                            }
                        }
                    }
                }

                function checkCollision() {
                    if (!gameStarted) return;
                    var birdWidth = bird.width * 0.8
                    var birdHeight = bird.height * 0.8
                    var birdX = bird.x + (bird.width - birdWidth) / 2
                    var birdY = bird.y + (bird.height - birdHeight) / 2

                    if (birdX < x + width &&
                        birdX + birdWidth > x &&
                        birdY < y + height &&
                        birdY + birdHeight > y) {
                        gameOver()
                    }
                }

                function checkPassed() {
                    if (!gameStarted) return;
                    if (!scored && bird.x + bird.width > x + width) {
                        scored = true
                        if (!gameOverScreen.visible) {
                            score++
                        }
                    }
                }
            }
        }

        function addPipe() {
            if (!gameStarted) return;
            var upperPipe = pipeComponent.createObject(pipeContainer)
            var lowerPipe = pipeComponent.createObject(pipeContainer)

            if (upperPipe && lowerPipe) {
                var gapHeight = 200 + Math.random() * 200

                upperPipe.height = Math.max(300, gapHeight + Math.random() * 100)
                upperPipe.y = 0

                lowerPipe.height = gamePage.height - upperPipe.height - 200
                lowerPipe.y = upperPipe.height + 200

                pipeModel.append({ "pipe": upperPipe })
                pipeModel.append({ "pipe": lowerPipe })
            } else {
                console.error("Не удалось создать трубы")
            }
        }

        Timer {
            id: pipeSpawnTimer
            interval: 2000
            running: gameStarted
            repeat: true
            onTriggered: {
                pipeContainer.addPipe()
            }
        }
    }

    Timer {
        id: gameTimer
        interval: 20
        running: gameStarted
        repeat: true
        onTriggered: {
            bird.update()
            var scoredThisFrame = false;
            for (var i = 0; i < pipeModel.count; i++) {
                var pipe = pipeModel.get(i).pipe
                if (pipe.active) {
                    pipe.checkCollision()
                    if (!scoredThisFrame) {
                        pipe.checkPassed()
                        if (pipe.scored) {
                            scoredThisFrame = true;
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            bird.jump()
        }
    }

    Rectangle {
        id: gameOverScreen
        anchors.fill: parent
        color: "black"
        opacity: 0.7
        visible: false

        Text {
            id: gameOverText
            text: "Игра окончена"
            color: "white"
            font.pixelSize: 50
            anchors.centerIn: parent
        }

        Button {
            id: restartButton
            text: "Играть снова"
            anchors.top: gameOverText.bottom
            anchors.topMargin: 20
            anchors.horizontalCenter: parent.horizontalCenter
            onClicked: {
                restartGame()
            }
        }

        Button {
            id: exitButton
            text: "Выход в главное меню"
            anchors.top: restartButton.bottom
            anchors.topMargin: 20
            anchors.horizontalCenter: parent.horizontalCenter
            onClicked: {
                exitToMainMenu()
            }
        }
    }

    Text {
        id: scoreText
        text: "Очки: " + score
        font.bold: true
        color: "white"
        font.pixelSize: 50
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: 20
        anchors.leftMargin: 20
    }

    function gameOver() {
        gameTimer.stop()
        pipeSpawnTimer.stop()
        gameOverScreen.visible = true

        for (var i = 0; i < pipeModel.count; i++) {
            var pipe = pipeModel.get(i).pipe
            pipe.x = -pipe.width
            pipe.active = false
        }
        bird.velocity = 0

        updateHighScore()
    }

    function updateHighScore() {
        var db = LocalStorage.openDatabaseSync("FlappyBirdDB", "1.0", "Flappy Bird Database", 1000000);
        db.transaction(function(tx) {
            var rs = tx.executeSql('SELECT value FROM Settings WHERE name = "highScore"');
            var currentHighScore = parseInt(rs.rows.item(0).value);
            if (score > currentHighScore) {
                tx.executeSql('UPDATE Settings SET value = ? WHERE name = "highScore"', [score]);
                mainMenuPage.highScore = score;
                mainMenuPage.highScoreUpdated(score);
            }
        });
    }

    function restartGame() {
        gameOverScreen.visible = false
        score = 0
        bird.y = gamePage.height / 2 - bird.height / 2
        bird.velocity = 0
        pipeModel.clear()
        for (var i = 0; i < pipeContainer.children.length; i++) {
            pipeContainer.children[i].destroy()
        }
        gameStarted = true
        gameTimer.start()
        pipeSpawnTimer.start()
    }

    function exitToMainMenu() {
        pageStack.pop()
        mainMenuPage.loadHighScore()
    }

    Rectangle {
        id: countdownScreen
        anchors.fill: parent
        color: "black"
        opacity: 0.7
        visible: !gameStarted

        Text {
            id: countdownText
            text: "3"
            color: "white"
            font.pixelSize: 100
            anchors.centerIn: parent
        }

        Timer {
            id: countdownTimer
            interval: 1000
            running: !gameStarted
            repeat: true
            property int count: 3
            onTriggered: {
                count--
                countdownText.text = count.toString()
                if (count === 0) {
                    countdownTimer.stop()
                    countdownScreen.visible = false
                    gameStarted = true
                    gameTimer.start()
                    pipeSpawnTimer.start()
                }
            }
        }
    }
}
