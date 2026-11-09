import sys
from PyQt5.QtWidgets import QApplication, QWidget, QPushButton, QLineEdit, QVBoxLayout

# get basic Qt app prepared
app = QApplication(sys.argv)
window = QWidget()
layout = QVBoxLayout()


# prepare the Resonance driver
from resonance_foreign_driver import Driver
driver = Driver("PyGame")

# some basic data subscribers
def messageCallback(msg, timestamp):
    print(msg, timestamp)
driver.inputMessageStream("in_message", messageCallback)
driver.inputDataStream("in_data", messageCallback)


# basic message stream
send_msg = driver.outputMessageStream("out_message")

textbox1 = QLineEdit("Some message")
button1 = QPushButton('Send message')

def on_button1_clicked():
    send_msg(textbox1.value())

button1.clicked.connect(on_button1_clicked)
layout.addWidget(textbox1)
layout.addWidget(button1)


# get ready to run
window.setLayout(layout)
window.show()
app.exec()
