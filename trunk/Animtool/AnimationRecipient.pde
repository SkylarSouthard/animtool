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


//This interface allows a Timeline to talk to a consumer of the timeline's data.
//examples might be a servo motor, a network client, or some software plugin

interface AnimationRecipient {
  
  //every AnimationRecipient should specify a type name
  public String typeName = "";
  
  //for Timeline:
  public float getMinValue();
  public float getMaxValue();
  public float getMaxValueChangePerSecond();
  
  //PUSH value with a timeline timestamp
  public void setTimeValue(float timeStamp, float value);
  
  //for saving to a file:
  public String getPropertiesSaveString();
  //for display in a UI:
  public String getPropertiesDisplayString();
  
  //set properties based on string, formatted by getPropertiesSaveString
  public boolean setPropertiesFromString(String input);
  
  public void shutdown();
}

class NullAnimationRecipient implements AnimationRecipient {
  
  public String typeName = "Null";
    
  //for Timeline:
  public float getMinValue() {return 0;}
  public float getMaxValue() {return 1;}
  public float getMaxValueChangePerSecond() {return Float.MAX_VALUE;} //don't limit
  
  //DO THE MAGIC
  //push value with a timeline timestamp
  public void setTimeValue(float timeStamp, float value) {
    //do nothing
  }
  
  //INPUT/OUTPUT
  //for saving to a file:
  public String getPropertiesSaveString() {return "type=Null;";}
  //for display in a UI:
  public String getPropertiesDisplayString() {return getPropertiesSaveString();}
  
  //set properties based on string, formatted by getPropertiesSaveString
  public boolean setPropertiesFromString(String input) {return true;}
  
  void shutdown() {}
}

class AnimationRecipientFactory {
  public AnimationRecipient getNewAnimationRecipientFromString(String theString) {
    //TODO: handle types other than servo!
    Servo s = new Servo(theString);
    return s;
  }
}
