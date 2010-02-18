#include <Servo.h> 
#define numServos 12

Servo myservo[numServos];  // create servo object to control a servo 
int myServoPos[numServos];
int myServoMinPulse[numServos];
int myServoMaxPulse[numServos];
boolean myServoPending[numServos];
boolean myServoChanged[numServos];

int timeOut = 2000; //.5 second timeout on lost serial communications
int blinkPin = 13;
char buffer[256]; // a text receive buffer
int args[5]; //size = max num of args something sends.

boolean debug = false;

void setup() 
{ 
  pinMode(blinkPin, OUTPUT);

  for (int i=0; i < numServos; i++) {
    myServoPending[i] = false;
    myServoChanged[i] = false;
  }

  Serial.begin(57600);

  blink(4, 150);
} 

int angle = 0;
void loop() 
{ 
  int debugControl = analogRead(0);
  if (debugControl > 512) debug = true;
  else debug = false;
 
  //force debug 
  debug = true;

  while (Serial.available() > 0) {
    char nextChar = Serial.read();
    if (debug) Serial.print(nextChar);
    if (debug) Serial.print(": ");
    
    switch(nextChar) {
    case 'a':
      handleAttach();
      break;
    case 's':
      handleSet();
      break;
    case 'd':
      handleDetach();
      break;
    default:
      //lose this char, keep looking for a good one.
      if (debug) Serial.println("Skipped that char.");
      break;
    }
  }


  //now update all the servos
  for (int i=0; i < numServos; i++) {
    if (myServoChanged[i]) {
      if (!myservo[i].attached() && myServoPending[i]) {
        //we're good to go. do the attach.
        myservo[i].attach(i, myServoMinPulse[i], myServoMaxPulse[i]);
        myServoPending[i] = false;
        if (debug) {
            Serial.print("Servo attach to pin ");
            Serial.print(i);
          if (myservo[i].attached()) {
            Serial.println(" SUCCESSFUL.");
          }
          else {
            Serial.println(" FAILED.");
          }
        }
      }
      if (myservo[i].attached()) {
        myservo[i].write(myServoPos[i]); // sets the servo position according to the scaled value 
        myServoChanged[i] = false;
        if (debug) {
          Serial.print("Set servo ");
          Serial.print(i);
          Serial.print("@");
          Serial.println(myServoPos[i]);
        }
      }
    }

  }


} 


boolean getArgs(int numArgs) {
  int argCounter = 0;
  int bufferCounter = 0;
  buffer[0] = 0;

  //as long as we've not timed out:
  long start = millis();
  while ((millis() - start) < timeOut) {
    //if there's another char:
    if (Serial.available() > 0) {
      //grab next available char
      char nextChar = Serial.read();
      if (debug) Serial.print(nextChar);
      //if it's a delimeter, convert current arg and go to next arg
      if (nextChar == ',' || nextChar == '\n') {
        args[argCounter++] = atoi(buffer);
        bufferCounter = 0;
        //if we've got em all, return succesfully
        if (argCounter >= numArgs) return true;
      } 
      else {
        //stuff it in the buffer.
        buffer[bufferCounter++] = nextChar;
        //preemptively write the null terminator (keep treating it as a complete string)
        buffer[bufferCounter] = 0;
      }
    }
  }
  //if we ended up here, we timed out. Return unsuccessfully.
  if (debug) {
   Serial.println("TIMED OUT"); 
  }
  return false;


}


void handleAttach() {
  if (debug) Serial.print("Handling Attach Command:");

  if (getArgs(3)) {
    if (args[0] >= numServos || args[0] < 0) {
     if (debug) {
      Serial.print("Cannot attach servo ");
      Serial.print(args[0]);
      Serial.println(". Valid range is 0-11.");
     } 
    }
    //if we got here, then we can attach the servo.
    myServoMinPulse[args[0]] = args[1];
    myServoMaxPulse[args[0]] = args[2];
    myServoPending[args[0]] = true;

    //if previously attached, detach now, then reattach later.
    if (myservo[args[0]].attached()) {
      myservo[args[0]].detach();
    }

    if (debug) {    
      Serial.print(":Success: ");
      Serial.print(args[0]);
      Serial.print("@");
      Serial.print(args[1]);
      Serial.print(",");
      Serial.print(args[2]);
    }
  }
  else {
    if (debug) Serial.print("FAILED"); 
  }
  if (debug) Serial.println();

}

void handleSet() {
  if (debug) Serial.print("Handling Set Command:");
  if (getArgs(2)) {
    myServoPos[args[0]] = args[1];
    myServoChanged[args[0]] = true;
    if (debug) {
      Serial.print(":Success: ");
      Serial.print(args[0]);
      Serial.print("@");
      Serial.print(args[1]);
    }
  }
  else {
    if (debug) Serial.print("FAILED");     
  }
  if (debug) Serial.println();

}

void handleDetach() {
  if (debug) Serial.print("Handling Detach Command:");
  if (getArgs(1)) {
    if (myservo[args[0]].attached()) {
      myservo[args[0]].detach();
      myServoPending[args[0]] = false;
    }
    if (debug) {
      Serial.print(":Success: ");
      Serial.print(args[0]);
      //blink(3, 300);
    }
  }
  else {
    if (debug) Serial.print("FAILED");     
  }
  if (debug) Serial.println();

}

void blink(int numBlinks, int onOffTime) {
  for (int i=0 ; i < numBlinks; i++) {
    digitalWrite(blinkPin, HIGH);
    delay(onOffTime);
    digitalWrite(blinkPin, LOW);
    delay(onOffTime);
  }
}












