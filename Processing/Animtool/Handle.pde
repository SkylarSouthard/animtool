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


class Handle {

  public float time;
  public float value;

  public float easeIn;
  public float easeOut;

  int compare(Handle other) {
    //is the other one earlier?
    if (other.time < time) return -1;
    //are they the same?
    else if (other.time == time) return 0;
    //well, then the other must be later...
    else return 1;
  }
  
}
