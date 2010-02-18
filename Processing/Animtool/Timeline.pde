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


class Timeline {

  float scalePixelsPerSecond = 100; //the display "zoom"
  float timeOffset = 0; //the display "scroll" left-right
  float tailDisplaySeconds = 10;

  int heightInPixels;

  boolean highlight = false;
  
  int numDisplayPixelsPerCurveSample = 20;
  float minHandleTimeDifference = 0.01;

  Handle[] handle;
  int[] curHandle = {
    -1, -1      };

  /* interactMode:
   -1: none
   0: dragging easing handle
   1: dragging handle(s)
   2: drawing box
   */
  int interactMode = -1;
  float[] rangeSelectX = {
    0,0        };

  //timeline properties
  String name = "default"; //a visual unique identifier
  boolean looping = false;

  AnimationRecipient client;

  //generic display properties
  float maxValue = 1;
  float minValue = 0;

  //draw background/guides as separate PGraphics then composite into g
  public PGraphics g;
  PGraphics backdrop; //we ony draw the backdrop once
  PGraphics foreground; //the foreground gets drawn on all changes

  Timeline(int targetHeight) {

    client = new NullAnimationRecipient();

    //create end handles
    handle = new Handle[1];
    handle[0] = new Handle();
    handle[0].time = 0;
    handle[0].value = minValue + (maxValue-minValue)/2f;

    heightInPixels = targetHeight;

    //init + refresh all    
    initLayers();

  }

  private void initLayers() {
    float duration = handle[handle.length-1].time;

    //create the backdrop
    backdrop = createGraphics(ceil(timeToLocalX(duration+tailDisplaySeconds)), heightInPixels, P2D);

    //create the foreground
    foreground = createGraphics(ceil(timeToLocalX(duration+tailDisplaySeconds)), heightInPixels, P2D);

    //create the graphics object for comping the layers
    g = createGraphics(ceil(timeToLocalX(duration+tailDisplaySeconds)), heightInPixels, P2D);

    refreshAll();
  }

  private void updateForeground() {

    //redraw foreground
    foreground.beginDraw();
    foreground.background(0,0);

    //draw interpolated curve
    foreground.stroke(interpolationLineColor);
    foreground.strokeWeight(interpolationLineWeight);
    
    float handleX1, handleY1, handleX2, handleY2, t, val, pval, dispX, pdispX;
    int numSamples;
    //go through all the handles
    for (int i=0; i < handle.length-1; i++) {
      //pre-calc some values for efficiency
      handleX1 = timeToLocalX(handle[i].time);
      handleY1 = valueToLocalY(handle[i].value);
      handleX2 = timeToLocalX(handle[i+1].time);
      handleY2 = valueToLocalY(handle[i+1].value);

      //how many steps to inerpolate between handles?
      numSamples = ceil(dist(handleX1, handleY1, handleX2, handleY2) / float(numDisplayPixelsPerCurveSample));
      
      pdispX = handleX1;
      pval = handle[i].value;
      for (int step=1; step <= numSamples; step++) {
        t = (step/float(numSamples));
        dispX = lerp(handleX1, handleX2, t);
        val = getValueAtTime(lerp(handle[i].time, handle[i+1].time, t));
        foreground.line(pdispX, valueToLocalY(pval), dispX, valueToLocalY(val));
        pdispX = dispX;
        pval = val;
      }
    }
    //line to right edge
    foreground.line(timeToLocalX(handle[handle.length-1].time), valueToLocalY(handle[handle.length-1].value), foreground.width, valueToLocalY(handle[handle.length-1].value));
    


    //draw handles
    for (int i=0; i < handle.length; i++) {
      if (curHandle[0] != -1 && i >= curHandle[0] && i <= curHandle[1]) {
        if (keyFrameFill) foreground.fill(keyFrameFillSelectColor);
        else foreground.noFill(); 
        if (keyFrameStroke) foreground.stroke(keyFrameStrokeSelectColor); 
        else foreground.noStroke(); 
      } 
      else {
        if (keyFrameFill) foreground.fill(keyFrameFillColor);
        else foreground.noFill(); 
        if (keyFrameStroke) foreground.stroke(keyFrameStrokeColor); 
        else foreground.noStroke(); 
      }
      foreground.ellipse(timeToLocalX(handle[i].time), valueToLocalY(handle[i].value), keyFrameDiameter, keyFrameDiameter);
      
      //easing controls
      foreground.fill(easingHandleFillColor);
      foreground.line(timeToLocalX(handle[i].time) - keyFrameDiameter/2, valueToLocalY(handle[i].value),
                      timeToLocalX(handle[i].time) - (keyFrameDiameter/2 + handle[i].easeIn * easingDisplayRange), valueToLocalY(handle[i].value));
      foreground.ellipse(timeToLocalX(handle[i].time) - (keyFrameDiameter + handle[i].easeIn * easingDisplayRange), valueToLocalY(handle[i].value), keyFrameDiameter, keyFrameDiameter);
      foreground.line(timeToLocalX(handle[i].time) + keyFrameDiameter/2, valueToLocalY(handle[i].value),
                      timeToLocalX(handle[i].time) + (keyFrameDiameter/2 + handle[i].easeOut * easingDisplayRange), valueToLocalY(handle[i].value));
      foreground.ellipse(timeToLocalX(handle[i].time) + (keyFrameDiameter + handle[i].easeOut * easingDisplayRange), valueToLocalY(handle[i].value), keyFrameDiameter, keyFrameDiameter);
      
    }

    //dragging a selection box:
    if (interactMode == 2) {
      foreground.noStroke();
      foreground.fill(selectBoxColor);
      foreground.rect(timeToLocalX(rangeSelectX[0]), 0, timeToLocalX(rangeSelectX[1] - rangeSelectX[0]), foreground.height);
    }
    foreground.endDraw();

  }


  private void updateBackdrop() {
    backdrop.beginDraw();
    backdrop.textFont(timelineFont);
    backdrop.textAlign(LEFT);
    float descent = backdrop.textDescent();

    //background color
    if (highlight) {
      backdrop.background(highlightColor);
    } 
    else {
      backdrop.background(backgroundColor);
    }

    //horizontal guide lines
    backdrop.strokeWeight(1);
    backdrop.noFill();
    backdrop.stroke(guideLineColor);
    float stepSize = backdrop.height/float(numGuideLines-1);
    for (int i=0; i < numGuideLines; i++) {
      backdrop.line(0, stepSize*i, backdrop.width-1, stepSize*i);
    }

    //lower border
    backdrop.stroke(borderColor);
    backdrop.line(0, backdrop.height-1, backdrop.width-1, backdrop.height-1);
    backdrop.endDraw();

    //vertical guide lines
    backdrop.stroke(borderColor);
    backdrop.strokeWeight(1);
    backdrop.fill(borderColor);
    for (int i=1; i <= ceil(handle[handle.length-1].time); i++) {
      float pos = timeToLocalX(i);
      backdrop.line(pos, 0, pos, backdrop.height);
      backdrop.text(i, pos, backdrop.height-descent);
    }

    //value guides
    backdrop.text(int(maxValue), 5, valueToLocalY(maxValue) + backdrop.textAscent());
    backdrop.text(int(minValue), 5, valueToLocalY(minValue) - backdrop.textDescent());

    //label
    backdrop.text(name, 100, 5 + backdrop.textAscent());
  }

  private void recomposite() {
    g.beginDraw();
    g.image(backdrop, 0, 0);
    g.image(foreground, 0, 0);
    g.endDraw();
  }


  void refreshFore() {
    updateForeground();    
    recomposite();
  }

  void refreshBack() {
    updateBackdrop();
    recomposite();
  }

  void refreshAll() {
    updateBackdrop();
    updateForeground();
    recomposite();
  }



  void mousePressed(float localX, float localY, int modifier) {
    //if a SHIFT click, add a new keyframe handle
    if (modifier == SHIFT) {
      Handle newHandle = new Handle();
      newHandle.time = localXToTime(localX);
      newHandle.value = localYToValue(localY);
      curHandle[0] = curHandle[1] = addHandle(newHandle);
      interactMode = 1;
    } 
    else {
      //if a standard click, select or start a box drag
      //if hit test on a keyframe handle, make it curHandle
      for (int i=0; i < handle.length; i++) {
        //did we click on a keyframe handle?
        if (dist(timeToLocalX(handle[i].time), valueToLocalY(handle[i].value), localX, localY) <= keyFrameDiameter/2f) {
          interactMode = 1;
          //if no box, then
          if (i >= curHandle[0] && i <= curHandle[1]) {
            //then we've grabbed a handle in the current selection. Do nothing. Time to drag.
          }
          else {
            //we grabbed a handle outisde the current selection. Select this handle for drag.
            curHandle[0] = curHandle[1] = i;
          }
          break;
        }
        //did we click on an easeIn handle?
        else if(dist(timeToLocalX(handle[i].time) - (keyFrameDiameter + handle[i].easeIn * easingDisplayRange), valueToLocalY(handle[i].value), localX, localY) <= keyFrameDiameter/2f) {
          interactMode = 0;
          //select this handle
          //if it's the easeIn Handle, set it as curHandle[0].
          curHandle[0] = i;
          curHandle[1] = -1;
          break;
        }
        //did we click on an easeOut handle?
        else if(dist(timeToLocalX(handle[i].time) + (keyFrameDiameter + handle[i].easeOut * easingDisplayRange), valueToLocalY(handle[i].value), localX, localY) <= keyFrameDiameter/2f) {
          interactMode = 0;
          //select this handle
          //if it's the easeIn Handle, set it as curHandle[0].
          curHandle[0] = -1;
          curHandle[1] = i;
          break;
        }
      }

      //else start box drag (no curHandle)
      if (interactMode == -1) {
        interactMode = 2;
        rangeSelectX[0] = rangeSelectX[1] = localXToTime(localX);
      }
    }

    refreshFore();
  }


  void mouseDragged(float localX, float localY, float plocalX, float plocalY, int modifier) {
    //selected the first point? It gets a special case:
    if (interactMode == 1 && (curHandle[0] == 0 && curHandle[1] == 0)) {
      handle[curHandle[0]].value = localYToValue(constrain(localY, 0, g.height));
    }
    else if (interactMode == 1 && curHandle[0] != -1) {
      //what's the upper and lower bound on handle values?
      float valueLowerBound = maxValue;
      float valueUpperBound = minValue;
      for (int i = curHandle[0]; i <= curHandle[1]; i++) {
        if (handle[i].value < valueLowerBound) valueLowerBound = handle[i].value;
        if (handle[i].value > valueUpperBound) valueUpperBound = handle[i].value;
      }

      //calculate constraints on change      
      float timeOffset = constrain(localXToTime(localX-plocalX), 
      minHandleTimeDifference + handle[curHandle[0]-1].time - handle[curHandle[0]].time, 
      curHandle[1] < handle.length-1 ? (handle[curHandle[1]+1].time - handle[curHandle[1]].time - minHandleTimeDifference) : Float.MAX_VALUE );
      float valueOffset = constrain(localYToValue(localY)-localYToValue(plocalY), 
      minValue - valueLowerBound, maxValue - valueUpperBound);

      //apply change
      for (int i=curHandle[0]; i <= curHandle[1]; i++) {
        handle[i].time += timeOffset;
        handle[i].value += valueOffset;
      }
    }
    else if (interactMode == 2) {
      rangeSelectX[1] = localXToTime(localX);
      updateRangeSelection();
    }
    else if (interactMode == 0) {
      if (curHandle[1] == -1 && curHandle[0] > -1) {
        handle[curHandle[0]].easeIn = constrain(handle[curHandle[0]].easeIn + (plocalX-localX) / easingDisplayRange, 0, 1);
      } else if (curHandle[0] == -1 && curHandle[1] > -1) {
        handle[curHandle[1]].easeOut = constrain(handle[curHandle[1]].easeOut + (localX-plocalX) / easingDisplayRange, 0, 1);
      } else {
       //error case
        println("ERROR setting easeIn/Out Handle"); 
      }
    }
    
    refreshFore();
  }


  void mouseReleased(int modifier) {

    if (interactMode == 2) {
      updateRangeSelection();
      rangeSelectX[0] = rangeSelectX[1] = -1;
    }

    if (interactMode == 0) {
      curHandle[0] = curHandle[1] = -1;
    }
    interactMode = -1;
    //if dragging handles, just keep the selection.

    refreshAll();
  }

  void deleteSelection() {
    removeHandle(curHandle[0], curHandle[1]);
    refreshFore();
  }

  void updateRangeSelection() {
    //sort the range select times
    float lowTime = min(rangeSelectX[0], rangeSelectX[1]);
    float highTime = max(rangeSelectX[0], rangeSelectX[1]);
    //select the handles which were picked by the box 
    //find the low end
    curHandle[0] = curHandle[1] = -1;
    for (int i = 1; i<handle.length-1; i++) {
      if (handle[i].time >= lowTime) {
        curHandle[0] = i;
        break;
      }
    }
    //now find the top end
    for (int i = handle.length-1; i > 0; i--) {
      if (handle[i].time <= highTime) {
        curHandle[1] = i;
        break;
      }
    }    
  }


  PGraphics getDisplay() {
    return g; 
  }

  //returns the index at which it's been added
  int addHandle(Handle newGuy) {


    //0 length case
    if (handle.length == 0) {
      handle = new Handle[1];
      handle[0] = newGuy;
      return 0;
    }

    //does it go before the first one?
    if (handle[0].compare(newGuy) < 0) {
      handle = (Handle[]) concat(new Handle[]{
        newGuy                        }
      , handle);
      return 0; 
    }

    //does it go after the last one?
    if (handle[handle.length-1].compare(newGuy) > 0) {
      handle = (Handle[]) append(handle, newGuy);
      initLayers();
      return handle.length-1;
    }

    //it goes somewhere in the middle...
    for (int i=1; i < handle.length; i++) {

      if (handle[i-1].compare(newGuy) >= 0 && handle[i].compare(newGuy) < 0) {
        //handle = (Handle[]) (splice(handle, newGuy, i+1));
        //splice isn't playing nice, so workaround.
        handle = (Handle[]) concat(append(subset(handle, 0, i), newGuy), subset(handle, i));
        return i;
      }
    }

    //shouldn't ever get here:
    return -1;
  }

  //remove handle
  boolean removeHandle(int index) {
    return removeHandle(index, index); 
  }
  boolean removeHandle(int startIndex, int endIndex) {
    int lowIndex = min(startIndex, endIndex);
    int highIndex = max(startIndex, endIndex);
    //error handling - be sure the request isn't the first handle, or past the end.
    if (lowIndex <= 0 || highIndex > handle.length-1) return false;
    handle = (Handle[]) concat(subset(handle, 0, lowIndex), subset(handle, highIndex+1));
    //update selection
    curHandle[0] = curHandle[1] = -1;
    interactMode = -1;

    if (highIndex >= handle.length) initLayers();

    return true;
  }

  float localXToTime(float xVal) {
    return xVal / scalePixelsPerSecond;
  }


  float timeToLocalX(float time) {
    return time * scalePixelsPerSecond;
  }

  float timeToMaximumPixelSize(float time) {
    //accessing "global" scaleMax from main here
    return time * scaleMax; 
  }


  float localYToValue(float localY) {
    return map(localY, 0, g.height, maxValue, minValue);
  }


  float valueToLocalY(float value) {
    return map(value, minValue, maxValue, g.height, 0);
  }


  void setScale(float pixPerSecond) {
    scalePixelsPerSecond = pixPerSecond;
    initLayers();
  }


  void highlight() {
    highlight = true; 
    refreshBack();
  }


  void noHighlight() {
    highlight = false; 
    refreshBack();
  }


  int getWidth() {
    return g.width; 
  }


  void pushValueAtTime(float time) {
    client.setTimeValue(time, getValueAtTime(time));
  }

  //this currently only does linear interp
  //TODO: add easing
  float getValueAtTime(float time) {
    if (time >= handle[handle.length-1].time) return handle[handle.length-1].value;
    else if (time <= handle[0].time) return handle[0].value;
    //work backwards from the next to last handle.
    //when the requested time is later than this handle, find the interpolated value
    float interpTimePercent;
    for (int i= handle.length-2; i >= 0; i--) {
      if (time > handle[i].time) {
        //then it's between this time and the next.
        interpTimePercent = getEasingValue(norm(time, handle[i].time, handle[i+1].time), handle[i].easeOut, handle[i+1].easeIn);
        return (handle[i].value + ((handle[i+1].value - handle[i].value) * interpTimePercent));
      }
      else if (time == handle[i].time) {
        return handle[i].value;
      }
    }

    //should never get here!
    println("ERROR in Timeline.getValueAtTime(): didn't find appropriate handles.");
    return 0;
  }


  /**
   * getEasingValue: transform t with easeOut/In controls.
   * With a linear t input [0..1] outputs a range of values [0..1]
   * with acceleartion on either or both ends.
   * e.g. if easeOut=1 && easeIn = 0 calculated t values will change slowly and then speed up
   */
  float getEasingValue(float t, float easeOut, float easeIn) {
    float start = -HALF_PI + ((1-easeOut) * PI/2.001f);
    float end  =  HALF_PI - ((1-easeIn) * PI/2.001f); 
    return norm(sin(start + t*(end-start)), sin(start), sin(end));
  }



  String saveToString() {
    //save last view info?

    //save data
    String result = "\n&"+ name + ";\n";
    result += client.getPropertiesSaveString() + ";\n";
    for (int i=0; i<handle.length; i++) {
      result += (i==0 ? "" : ";  ") + handle[i].time +", "+handle[i].value +", "+handle[i].easeIn +", "+handle[i].easeOut + "   ";
    }
    return result;
  }
  

  boolean loadFromString(String input) {
    //println("loadFromString: " + input);
    String[] data = split(input, ';');

    //first is name
    name = data[0];

    //next is client data
    client = animRecipientFactory.getNewAnimationRecipientFromString(data[1]);

    //got client - get info from it.
    maxValue = client.getMaxValue();
    minValue = client.getMinValue();

    //the remaining items are handles
    handle = new Handle[0];
    for (int i=2; i < data.length; i++) {
      String[] handleData = split(data[i], ',');
      //println(handleData); // print out handle
      Handle h = new Handle();
      h.time = float(handleData[0]);
      h.value = float(handleData[1]);
      h.easeIn = float(handleData[2]);
      h.easeOut = float(handleData[3]);
      addHandle(h);
    }

    initLayers();

    return true;
  }

  void shutdown() {
    client.shutdown();
  }

  float getEndmostTime() {
    return handle[handle.length-1].time; 
  }
}



