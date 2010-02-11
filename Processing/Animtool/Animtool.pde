/**
 * AnimTool, a generic keyframe timeline animation tool for driving anything you can animate.
 * Copyright (C) 2010 Jacob Tonski
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import processing.serial.*;

//set main window width, height
int WIDTH = 800;
int HEIGHT = 600;

//timeline display properties
int numInitialTimelines = 2;
Timeline[] timeline = {};
float[] timelineX = {};
float[] timelineY = {};
float[] timelineW = {};
float[] timelineH = {};

int timelineNativeWidth = WIDTH;
int timelineNativeHeight = 200;

//current timeline specifiers
int curTimeline = 0;
int curTimelineDisplayY = 0;

//time
float scalePixelsPerSecond = 100; //the display "zoom"
float scaleMin = 10;
float scaleMax = 1000;
float horizontalDisplayOffset = 0; //the display "scroll" left-right

//file operations
String curFilename = null;
int curFileVersionMajor = 0;
int curFileVersionMinor = 1;

//display animation properties
float displayMotionSpeed = 10;
float displayMotionAccel = 0;

//as long as the mouse is clicked, keep track of what timeline it was clicked in to start
int mouseInTimeline = -1;

//is a modifier key pressed? Shift, ctrl, option, etc...
int modifierKey = -1;

PlaybackThread player;


Serial serialPort;  // Create object from Serial class

AnimationRecipientFactory animRecipientFactory;

void setup() {
  size(WIDTH, HEIGHT);

  println(Serial.list());
  String portName = Serial.list()[0];
  //if serial port is found successfully, then use it. If not, then don't crash for crying out loud!
  //serialPort = new Serial(this, portName, 57600);


  animRecipientFactory = new AnimationRecipientFactory();
  timelineFont = loadFont(timelineFontFilename);

  while (timeline == null || timeline.length == 0) {
    loadFromFile();
    //addTimeline(numInitialTimelines);
  }

  curTimelineDisplayY = (HEIGHT - timelineNativeHeight)/2;
  timeline[curTimeline].highlight();


  player = new PlaybackThread();
  player.start();

}


void draw() {

  //testing:  
  
  if (serialPort != null && serialPort.available() > 0 ) {
    print( serialPort.readString() ); 
  }


  background(0);
  //if the current timeline's not where it should be, shift everything vertically.
  float displayTargetOffY = curTimelineDisplayY - timelineY[curTimeline];
  if (displayTargetOffY != 0) {
    for (int i=0; i < timeline.length; i++) {
      timelineY[i] += constrain(displayTargetOffY, -displayMotionSpeed, displayMotionSpeed);
    }
  }
  //if curTime is too close to screen edge, offset so that curTime is onscreen
  float curTimeX = scalePixelsPerSecond * player.getCurTime() + horizontalDisplayOffset;
  //moving left?
  float howFarOff = curTimeX - width*.1;
  if (howFarOff < 0 && player.getPlaybackRate() < 0) {
    horizontalDisplayOffset -= howFarOff;
    horizontalDisplayOffset = min(horizontalDisplayOffset, 0);
  }
  //moving right?
  howFarOff = width*.9 - curTimeX;
  if (howFarOff < 0 && player.getPlaybackRate() > 0) {
    horizontalDisplayOffset += howFarOff;
  }


  //draw timeline images
  for (int i=0; i < timeline.length; i++) {
    image(timeline[i].getDisplay(), timelineX[i] + horizontalDisplayOffset, timelineY[i], timeline[i].getWidth(), timelineH[i]);
  }

  //draw a top line
  stroke(borderStrokeColor);
  strokeWeight(1);
  line(0, timelineY[0], width, timelineY[0]);

  //draw time indicator
  noFill();
  stroke(timeIndicatorColor);
  float theTime = player.getCurTime();
  line(scalePixelsPerSecond * theTime + horizontalDisplayOffset, 0, scalePixelsPerSecond * theTime + horizontalDisplayOffset, height);
  
}


void mousePressed() {
  //which timeline are we in?
  mouseInTimeline = -1;
  //"inverse transform" of mouse (only accomodating horizontal Offset here)
  float mouseXTrans = mouseX - horizontalDisplayOffset;

  for (int i=0; i<timeline.length; i++) {
    //check for bounding box of 
    if (mouseXTrans > timelineX[i] && mouseXTrans < timelineX[i]+timelineW[i]
      && mouseY > timelineY[i] && mouseY < timelineY[i]+timelineH[i]) {
      //remember the current timeline as long as the mouse is clicked
      mouseInTimeline = i;          
      //tell the now current timeline the mouse was pressed
      timeline[mouseInTimeline].mousePressed(map(mouseXTrans, 
        timelineX[mouseInTimeline], timelineX[mouseInTimeline]+timelineW[mouseInTimeline], 0, timelineNativeWidth),
        map(mouseY, timelineY[mouseInTimeline],
        timelineY[mouseInTimeline]+timelineH[mouseInTimeline], 0, timelineNativeHeight), modifierKey);
      break;
    }
  }
}

void mouseDragged() {

  //"inverse transform" of mouse (only accomodating horizontal Offset here)  
  float mouseXTrans = mouseX - horizontalDisplayOffset;
  float pmouseXTrans = pmouseX - horizontalDisplayOffset;

  //tell the current timeline the mouse was dragged
  if (mouseInTimeline >= 0) {
    timeline[mouseInTimeline].mouseDragged(map(mouseXTrans, timelineX[mouseInTimeline], timelineX[mouseInTimeline]+timelineW[mouseInTimeline], 0, timelineNativeWidth),
    map(mouseY, timelineY[mouseInTimeline], timelineY[mouseInTimeline]+timelineH[mouseInTimeline], 0, timelineNativeHeight),
    map(pmouseXTrans, timelineX[mouseInTimeline], timelineX[mouseInTimeline]+timelineW[mouseInTimeline], 0, timelineNativeWidth),
    map(pmouseY, timelineY[mouseInTimeline], timelineY[mouseInTimeline]+timelineH[mouseInTimeline], 0, timelineNativeHeight),
    modifierKey);
  }
}

void mouseReleased() {
  //tell the timeline
  if (mouseInTimeline >= 0) {
    timeline[mouseInTimeline].mouseReleased(modifierKey);
  }
  //then we have no current timeline
  mouseInTimeline = -1;
}


void keyPressed() {

  if (key==CODED) {
    if (keyCode == SHIFT) {
      modifierKey = SHIFT;
    }
    else if (keyCode == UP) {
      selectPrevTimeline();
    }
    else if (keyCode == DOWN) {
      selectNextTimeline();
    }
    else if (keyCode == LEFT) {
      horizontalDisplayOffset += scalePixelsPerSecond/2; //SOMETHING, but it should be based on scale factor.
    }
    else if (keyCode == RIGHT) {
      horizontalDisplayOffset -= scalePixelsPerSecond/2; //SOMETHING, but it should be based on scale factor.
    }

  }

  //playback
  else if (key == 'j' || key == 'J') {
    //play backwards 
    player.setPlaybackRate(player.getPlaybackRate()-1);
  }
  else if (key == 'k' || key == 'K') {
    //stop
    player.setPlaybackRate(0);
  }
  else if (key == 'l' || key == 'L') {
    //play 1x
    player.setPlaybackRate(player.getPlaybackRate()+1);
  }

  //zoom
  else if (key == '-') {
    //zoom out 
    changeHorizontalScale(scalePixelsPerSecond * .8);
  }
  else if (key == '=' || key == '+') {
    //zoom in
    changeHorizontalScale(scalePixelsPerSecond * 1.25);
  }

  //delete
  else if (key == BACKSPACE || key == DELETE) {
    timeline[curTimeline].deleteSelection();
  }

  //
  else if (key == ' ') {
    calculateTimelineValues(player.getCurTime());
  }
  else if (key == 's') {
    saveToFile(false);
  }
  else if (key == 'S') {
    saveToFile(true);
  }
  else if (key == 'o') {
    loadFromFile();
  }
  else if (key == 'q') {
    shutdown();
  }
  /*
  else if (key == 'n') {
   addTimeline(1);
   }
   */


}

void keyReleased() {
  if (key==CODED && keyCode == SHIFT) {
    modifierKey = -1;
  }
}

void selectNextTimeline() {
  timeline[curTimeline].noHighlight();
  curTimeline = constrain(curTimeline+1, 0, timeline.length-1);   
  timeline[curTimeline].highlight();
}

void selectPrevTimeline() {
  timeline[curTimeline].noHighlight();
  curTimeline = constrain(curTimeline-1, 0, timeline.length-1);
  timeline[curTimeline].highlight();
}

void changeHorizontalScale(float newScale) {
  scalePixelsPerSecond = constrain(newScale, scaleMin, scaleMax);
  //now update all the timelines
  for (int i=0; i < timeline.length; i++) {
    timeline[i].setScale(scalePixelsPerSecond); 
  }
}

void calculateTimelineValues(float time) {
  for (int i=0; i < timeline.length; i++) {
    float val = timeline[i].getValueAtTime(time);
    print(i + ": "+val+" ");
  }
  println();
}


void pushValuesAtTime(float time) {
  //TODO: check if we're running - if not, this may cause a crash during shutdown. 
  for (int i=0; i < timeline.length; i++) {
    if (timeline[i] != null) {
      timeline[i].pushValueAtTime(time);
    }
  }  
}

float getEndmostTime() {
  float endmostTime = 0;
  for (int i=0; i < timeline.length; i++) {
    float thisOne = timeline[i].getEndmostTime();
    if (thisOne > endmostTime) endmostTime = thisOne;
  } 
  return endmostTime;
}

void saveToFile(boolean doSaveAs) {

  if (curFilename == null) doSaveAs = true;

  //get a filename?
  if (doSaveAs) {
    curFilename = selectOutput();
  }

  if (curFilename == null) {
    println("ERROR: No file selected to save.");
    return;
  }

  //ok to save.
  String[] data = new String[timeline.length+1];
  for (int i=0; i < timeline.length; i++) {
    data[i+1] = timeline[i].saveToString();
  }

  //file header
  data[0] = "Animtool fileformat " + curFileVersionMajor + '.' + curFileVersionMinor;
  //data[0] += ""; //add display properties on first line: timeline height
  saveStrings(curFilename, data);
  println("Saved to "+curFilename);  
}


void loadFromFile() {

  curFilename = selectInput();

  //TODO: check that the file is valid?
  File f = new File(curFilename);
  if (!f.canRead() || !f.isFile()) {
    println("Tried to load an invalid file.");
    return;
  } 
  else {
    f = null;
  }

  String[] data = split(join(loadStrings(curFilename), ""), '&');

  //first line is file header. Rest are timeline data, one each line

    timeline = new Timeline[0];

  int newTimelineCounter = 0;
  for (int i=1; i < data.length; i++) {
    if (data[i].length() == 0) continue;
    addTimeline(1);
    timeline[newTimelineCounter].loadFromString(data[i]);
    timeline[newTimelineCounter].refreshAll();
    newTimelineCounter++;
  }

  selectPrevTimeline();

}

//TODO:
//add a keystroke to create a new timeline, rather than copy/paste in the saved file...

void addTimeline(int howMany) {
  int oldSize = timeline.length;
  int newSize = oldSize + howMany;
  timeline = (Timeline[]) expand(timeline, newSize);
  timelineX = expand(timelineX, newSize);
  timelineY = expand(timelineY, newSize);
  timelineW = expand(timelineW, newSize);
  timelineH = expand(timelineH, newSize);

  for (int i=oldSize; i < newSize; i++) {
    timeline[i] = new Timeline(timelineNativeHeight);
    timelineX[i] = 0;
    timelineY[i] = (i+1) * timelineNativeHeight;
    timelineW[i] = width;
    timelineH[i] = timelineNativeHeight;
  }

}

void shutdown() {
  player.shutdown();
  for (int i=0; i < timeline.length; i++) {
    timeline[i].shutdown();
  }
  exit();
}





