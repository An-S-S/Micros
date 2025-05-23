# Import standard python modules.
import sys
import time
import serial
import json
import os

# This example uses the MQTTClient instead of the REST client
from Adafruit_IO import MQTTClient
from Adafruit_IO import Client, Feed

# holds the count for the feed
run_count = 0

def cargar_configuracion():
    try:
        with open('config.json', 'r') as f:
            config = json.load(f)
            return config
    except FileNotFoundError:
        print("Error: Archivo config.json no encontrado.")
        sys.exit(1)
    except KeyError as e:
        print(f"Error: Clave faltante en config.json: {e}")
        sys.exit(1)

# Set to your Adafruit IO username and key.
# Remember, your key is a secret,
# so make sure not to publish it when you publish this code!
config = cargar_configuracion()
ADAFRUIT_IO_USERNAME = config["ADAFRUIT_IO_USERNAME"]
ADAFRUIT_IO_KEY = config["ADAFRUIT_IO_KEY"]

# Set to the ID of the feed to subscribe to for updates.
FEED_ID_receive = 'Counter_TX'
FEED_ID_receive1 = 'M1'
FEED_ID_receive2 = 'M2'
FEED_ID_receive3 = 'M3'
FEED_ID_receive4 = 'M4'

FEED_ID_Send = 'Counter_RX'
FEED_ID_Send1 = 'Estado_M1'
FEED_ID_Send2 = 'Estado_M2'
FEED_ID_Send3 = 'Estado_M3'
FEED_ID_Send4 = 'Estado_M4'

# Define "callback" functions which will be called when certain events 
# happen (connected, disconnected, message arrived).
def connected(client):
    # Subscribe to changes on a feed named Counter.
    print('Subscribing to Feed {0}'.format(FEED_ID_receive))
    client.subscribe(FEED_ID_receive)
    client.subscribe(FEED_ID_receive1)
    client.subscribe(FEED_ID_receive2)
    client.subscribe(FEED_ID_receive3)
    client.subscribe(FEED_ID_receive4)
    print('Waiting for feed data...')

def disconnected(client):
    sys.exit(1)

def message(client, feed_id, payload):
    print('Feed {0} received new value: {1}'.format(feed_id, payload))
    valor = int(payload)
    posicion_servo = int((14 / 180) * valor + 4)

    #//////////////////////////////////////////////////////////////////////////
    if (feed_id == "M1"):
        mensaje = "M1 " + str(posicion_servo) + "#"
        miarduino.write(bytes(mensaje, 'utf-8'))
        print('Sendind data back: {0}'.format(payload))
        client.publish(FEED_ID_Send1, payload)
    if (feed_id == "M2"):
        mensaje = "M2 " + str(posicion_servo) + "#"
        #mensaje = "M2 " + payload + "#"
        miarduino.write(bytes(mensaje, 'utf-8'))
        print('Sendind data back: {0}'.format(payload))
        client.publish(FEED_ID_Send2, payload)
    if (feed_id == "M3"):
        mensaje = "M3 " + str(posicion_servo) + "#"
        #mensaje = "M3 " + payload + "#"
        miarduino.write(bytes(mensaje, 'utf-8'))
        print('Sendind data back: {0}'.format(payload))
        client.publish(FEED_ID_Send3, payload)
    if (feed_id == "M4"):
        mensaje = "M4 " + str(posicion_servo) + "#"
        #mensaje = "M4 " + payload + "#"
        miarduino.write(bytes(mensaje, 'utf-8'))
        print('Sendind data back: {0}'.format(payload))
        client.publish(FEED_ID_Send4, payload)

miarduino = serial.Serial(port='COM4', baudrate=9600, timeout=0.1)
# Create an MQTT client instance.
client = MQTTClient(ADAFRUIT_IO_USERNAME, ADAFRUIT_IO_KEY)

# Setup the callback functions defined above.
client.on_connect = connected
client.on_disconnect = disconnected
client.on_message = message

# Connect to the Adafruit IO server.
client.connect()

# The first option is to run a thread in the background so you can continue
# doing things in your program.
client.loop_background()

while True:
    #print('Running "main loop" ')
    time.sleep(3)