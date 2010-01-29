/**
    AnimTool, a generic keyframe timeline animation tool for driving anything you can animate.
    Copyright (C) 2010 Jacob Tonski

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/


class Servo implements AnimationRecipient {

  public String typeName = "Servo";

  //servo properties
  int pin = 2;
  int minPulse = 600;
  int maxPulse = 1500;
  int minAngle = 0;
  int maxAngle = 180;
  float maxSpeed = .2; //seconds per 60 degrees (as spec'ed on servo city)

  Servo(String initString) {
    setPropertiesFromString(initString);
  }

  //for Timeline:
  public float getMinValue() {
    return minAngle;
  }
  public float getMaxValue() {
    return maxAngle;
  }

  public float getMaxValueChangePerSecond() { 
    //divide 60 by maxSpeed, 
    //because maxSpeed is spec'ed on common servos as (time per 60 degrees)
    return 60/maxSpeed; 
  }

  //DO THE MAGIC
  //push value with a timeline timestamp
  public void setTimeValue(float timeStamp, float value) {

    //TODO:
    //based on Angle/Pulse properties, create a serial message
    //println("Push Value on pin "+pin+": " + (minAngle + value / (maxAngle - minAngle)));
    //int val = int(minAngle + (value / float(maxAngle - minAngle)));
    int val = floor(value);
    int p = floor(pin);
    //println("Writing pin " + pin + " @ " +  val);
    serialPort.write("s");
    serialPort.write(str(p));
    serialPort.write(",");
    serialPort.write(str(val));
    serialPort.write("\n");

  }

  //INPUT/OUTPUT
  //for saving to a file:
  public String getPropertiesSaveString() {
    return "type="+typeName+", pin="+pin+", minPulse="+minPulse+", maxPulse="+maxPulse+", minAngle="+minAngle+", maxAngle="+maxAngle+", maxSpeed="+maxSpeed;
  }

  //for display in a UI:
  public String getPropertiesDisplayString() {
    return getPropertiesSaveString();
  }

  //set properties based on string, formatted by getPropertiesSaveString
  public boolean setPropertiesFromString(String input) {
    //println("Servo from String: " + input);
    String[] data = split(input, ',');
    for (int i=0; i < data.length; i++) {
      String[] thisData = split(data[i], '=');
      if      (thisData[0].indexOf("type") >= 0);
      else if (thisData[0].indexOf("pin") >= 0) pin = int(thisData[1]);
      else if (thisData[0].indexOf("minPulse") >= 0) minPulse = int(thisData[1]);
      else if (thisData[0].indexOf("maxPulse") >= 0) maxPulse = int(thisData[1]);
      else if (thisData[0].indexOf("minAngle") >= 0) minAngle = int(thisData[1]);
      else if (thisData[0].indexOf("maxAngle") >= 0) maxAngle = int(thisData[1]);
      else if (thisData[0].indexOf("maxSpeed") >= 0) maxSpeed = float(thisData[1]);
      else {
        println("Servo: Error setting properties from string: " + thisData[0]+"="+thisData[1]);
        //return false; 
      }
    }
    tellArduinoAboutMe();

    return true;
  }


  void tellArduinoAboutMe() {
    
    println("Hey Arduino!  ...  " + getPropertiesSaveString());
    
    serialPort.write("a"); // init message
    serialPort.write(str(pin));
    serialPort.write(",");
    serialPort.write(str(minPulse)); //send minPulse 
    serialPort.write(",");
    serialPort.write(str(maxPulse)); //send maxPulse
    serialPort.write("\n");
  } 
  
  void shutdown() {
    serialPort.write("d");
    serialPort.write(str(pin));
    serialPort.write("\n");
  }

}

