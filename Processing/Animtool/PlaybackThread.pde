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

class PlaybackThread extends Thread {

  PlaybackThread() {
    super("Playback Thread");
  }

  //playback
  float playbackRate = 0; //scalar on clock time
  float curTime = 0;

  long lastMillis = 0;
  long curMillis = 0;

  void setPlaybackRate(float rate) {
    playbackRate = rate;
    if (playbackRate == 0) {
      //"suspend" the thread.
    } 
  }

  float getPlaybackRate() {
    return playbackRate; 
  }

  float getCurTime() {
    return curTime; 
  }

  boolean running = true;
  void shutdown() {
    running = false;
  }

  void pushAnimation() {
    pushValuesAtTime(curTime);
    lastPushTime = curTime;
  }

  float lastPushTime = -1;
  void run() {
    while(running) {

      //update time counter
      curMillis = millis();
      curTime += (curMillis-lastMillis) * .001 * playbackRate;

      //if beyond edges, stop
      if (curTime < 0) { 
        curTime = 0;
        playbackRate = 0;
      }
      else if (curTime >= getEndmostTime()) {
        curTime = getEndmostTime();
        playbackRate = 0; 
      }

      //push animation data
      pushAnimation();

      //println("Playing servos at time " + curTime);

      lastMillis = curMillis;      

      if (running) {
        try {
          sleep(1000/servoNumUpdatesPerSecond);
        } 
        catch (Exception e) {
          println("We've got a problem in the playback thread!");
        }
      }

    }

  }
}


