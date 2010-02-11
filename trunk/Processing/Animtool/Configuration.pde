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

color backgroundColor = color(100);
color highlightColor = color(120, 120, 100);

color guideLineColor = color(0, 0, 20);
int numGuideLines = 5;

boolean keyFrameStroke = true;
color keyFrameStrokeColor = color(250, 200);
color keyFrameStrokeSelectColor = color(250, 200);
boolean keyFrameFill = true;
color keyFrameFillColor = color(50, 190, 0, 200);
color keyFrameFillSelectColor = color(190, 50, 0, 200);
float keyFrameDiameter = 10;
float easingHandleFillColor = color(50, 190, 0, 100);
color easingHandleFillSelectColor = color(190, 50, 0, 100);
float easingDisplayRange = 30;

color interpolationLineColor = color(220);
float interpolationLineWeight = 1;

color borderColor = color(0);
color borderStrokeColor = color(0);

color selectBoxColor = color(200, 200, 200, 50);

color timeIndicatorColor = color(255);

int servoNumUpdatesPerSecond = 100;

PFont timelineFont;
String timelineFontFilename = "AGaramondPro-Regular-18.vlw";

