
/*
From: "Visualizing Data, First 
Edition by Ben Fry. Copyright 2008 Ben Fry, 9780596514556."

In respect to 24hours of non verbal analog data

Taking the viewer through my journey.
*/

color backgroundColor  = #424242;  // dark background color
color dormantColor     = #97FFFF;  // initial color of the map
color highlightColor   = #00E5EE;  // color for selected points
color unhighlightColor = #66664C;  // color for points that are not selected
color waitingColor     = #00F5FF;  // "please type a zip code" message
color badColor         = #FFFF66;  // text color when nothing found

ColorIntegrator faders[];

// border of where the map should be drawn on screen   
float mapX1, mapY1;
float mapX2, mapY2;

// column numbers in the data file
static final int CODE = 0;
static final int X = 1;
static final int Y = 2;
static final int NAME = 3;

int totalCount;  // total number of places
Place[] places;
int placeCount;  // number of places loaded

// min/max boundary of all points
float minX, maxX;
float minY, maxY;
  
// typing and selection  
PFont font;
String typedString = "";
char typedChars[] = new char[5];
int typedCount = 2;
int typedPartials[] = new int[6];

float messageX, messageY;

int foundCount;
Place chosen;
  
// smart updates
int notUpdatedCount = 0;
  
// zoom
boolean zoomEnabled = false;
Integrator zoomDepth = new Integrator();

Integrator zoomX1;
Integrator zoomY1;
Integrator zoomX2;
Integrator zoomY2;

float targetX1[] = new float[6];
float targetY1[] = new float[6];
float targetX2[] = new float[6];
float targetY2[] = new float[6];

// boundary of currently valid points at this typedCount
float boundsX1, boundsY1;
float boundsX2, boundsY2;  

//animation variables
int beginAnim = 0;
int timeInMillis;
int delay = 600;
int pnum = 0;

public void setup() {
  size(650, 650, P3D);
    
  mapX1 = 50;
  mapX2 = width - mapX1;
  mapY1 = 50;
  mapY2 = height - mapY1;
   
  font = loadFont("ScalaSans-Regular-14.vlw");
  textFont(font);
  //textMode(SCREEN);
    
  messageX = 40;
  messageY = height - 40;

  faders = new ColorIntegrator[6];
    
  // When nothing is typed, all points are shown with a color called
  // "dormant," which is brighter than when not highlighted, but 
  // not as bright as the highlight color for a selection.
  faders[0] = new ColorIntegrator(unhighlightColor, dormantColor);
  faders[0].attraction = 0.5f;
  faders[0].target(1);

  for (int i = 1; i < 6; i++) {
    faders[i] = new ColorIntegrator(unhighlightColor, highlightColor);
    faders[i].attraction = 0.5;
    faders[i].target(1);
  }
    
  readData();
    
  zoomX1 = new Integrator(minX);
  zoomY1 = new Integrator(minY);
  zoomX2 = new Integrator(maxX);
  zoomY2 = new Integrator(maxY);
    
  targetX1[0] = minX;
  targetX2[0] = maxX;
  targetY1[0] = minY;
  targetY2[0] = maxY;
    
  rectMode(CENTER);
  ellipseMode(CENTER);
  frameRate(15);
}
    
  
  
void readData() {
  //new Slurper();
   String[] lines = loadStrings("path2.tsv");
  parseInfo(lines[0]);
  
  //for(int i=0;i<lines.length;i++)
  //  println(lines[i]);

  places = new Place[totalCount];
  for (int i = 1; i<lines.length; i++) {
    places[placeCount] = parsePlace(lines[i]);
    
    //println(places[placeCount].code);
    
    placeCount++;
  }
}
  
  
void parseInfo(String line) {
  String infoString = line.substring(2);  // remove the #
  String[] infoPieces = split(infoString, ',');
  totalCount = int(infoPieces[0]);   
  minX = float(infoPieces[1]);
  maxX = float(infoPieces[2]);
  minY = float(infoPieces[3]);
  maxY = float(infoPieces[4]);
}
  
  
Place parsePlace(String line) {
  String pieces[] = split(line,TAB);

  //for(int i=0;i<pieces.length;i++)
    //println(i + " " + pieces[i]);

  int zip = int(pieces[CODE]);
  float x = float(pieces[X]);
  float y = float(pieces[Y]);
  String name = pieces[NAME];

  return new Place(zip, name, x, y);
}
  

// change message from 'click inside the window'
public void focusGained() {
  redraw();
}

// change message to 'click inside the window'
public void focusLost() {
  redraw();
}

// this method is empty in p5
public void mouseEntered() {
  
}


public void draw() {
  background(backgroundColor);
  
  updateAnimation();

  for (int i = 0; i < placeCount; i++) {
    places[i].draw();
  }


  if(beginAnim==0)
  {
  fill(waitingColor);
  textAlign(LEFT);
  String message = "Click to Begin";
  text(message, messageX, messageY);
  }
  
  if (typedCount == 0) {
    
    // if all places are loaded
    //println(placeCount + " " + totalCount);
    /*
    if (placeCount == totalCount) {
      if (focused) {
	message = "type the digits of a zip code";
      } else {
	message = "click the map image to begin";
      }
    }
    */
  } else {
    if (foundCount > 0) {
      if (!zoomEnabled && (typedCount == 4)) {
	// re-draw the chosen ones, because they're often occluded
	// by the non-selected points
	for (int i = 0; i < placeCount; i++) {
	  if (places[i].matchDepth == typedCount) {
	    places[i].draw();
	  }
	}
      }

      if (chosen != null) {
	chosen.drawChosen();
      }
        
      fill(highlightColor);
      textAlign(LEFT);
      text(typedString, messageX, messageY);
        
    } else {
      fill(badColor);
      text(typedString, messageX, messageY);
    }
  }

  /*
  // draw "zoom" text toggle
  textAlign(RIGHT);
  fill(zoomEnabled ? highlightColor : unhighlightColor);
  text("zoom", width - 40, height - 40);
  textAlign(LEFT);
  */
  
  
  //Move through points
  if(pnum==85)
    beginAnim = 0;
  
  if(beginAnim == 1)
  {
    updateTyped(pnum+"");
    if(millis() - timeInMillis >= delay)
    {
      pnum++;
      timeInMillis += delay;
    }
  }
}
  
  
void updateAnimation() {
  boolean updated = false;
    
  for (int i = 0; i < 6; i++) {
    updated |= faders[i].update();
  }
    
  if (foundCount > 0) {
    zoomDepth.target(typedCount);
  } else {
    zoomDepth.target(typedCount-1);
  }
  updated |= zoomDepth.update();

  updated |= zoomX1.update();
  updated |= zoomY1.update();
  updated |= zoomX2.update();
  updated |= zoomY2.update();

  // if the data is loaded, can optionally call noLoop() to save cpu
  if (placeCount == totalCount) {  // if fully loaded
    if (!updated) {
      notUpdatedCount++;
      // after 20 frames of no updates, shut off the loop
      if (notUpdatedCount > 20) {
	noLoop();
	notUpdatedCount = 0;
      }
    } else {
      notUpdatedCount = 0;
    }
  }
}

  
float TX(float x) {
  if (zoomEnabled) {
    return map(x, zoomX1.value, zoomX2.value, mapX1, mapX2);

  } else {
    return map(x, minX, maxX, mapX1, mapX2);
  }
}


float TY(float y) {
  if (zoomEnabled) {
    return map(y, zoomY1.value, zoomY2.value, mapY2, mapY1);

  } else {
    return map(y, minY, maxY, mapY2, mapY1);
  }
}


void mousePressed() {
  /*
  if ((mouseX > width-100) && (mouseY > height - 50)) {
    zoomEnabled = !zoomEnabled;
    redraw();
  }
  */
  
  if((mouseX < 100) && (mouseY > height - 50))
  {
    beginAnim = 1;
    timeInMillis = millis();
    redraw();
  }
}

/*
void keyPressed() {
  if ((key == BACKSPACE) || (key == DELETE)) {
    if (typedCount > 0) {
      typedCount--;
    }
    updateTyped();

  } else if ((key >= '0') && (key <= '9')) {
    if (typedCount != 2) {  // only 5 digits
      if (foundCount > 0) {  // don't allow to keep typing bad
	typedChars[typedCount++] = key;
      }
    }
  }
  updateTyped();
}
*/


void updateTyped(String temp) {
  //typedString = new String(typedChars, 0, typedCount);
  typedString = temp;

  // Un-highlight areas already typed past
  for (int i = 0; i < typedCount; i++) faders[i].target(0);
  // Highlight potential dots not yet selected by keys
  for (int i = typedCount; i < 3; i++) faders[i].target(1);

  typedPartials[typedCount] = int(typedString);
  for (int j = typedCount-1; j > 0; --j) {
    typedPartials[j] = typedPartials[j + 1] / 10;
  }

  foundCount = 0;
  chosen = null;
    
  boundsX1 = maxX;
  boundsY1 = maxY;
  boundsX2 = minX;
  boundsY2 = minY;

  for (int i = 0; i < placeCount; i++) {
    // update boundaries of selection
    // and identify whether a particular place is chosen
    places[i].check();
  }
  calcZoom();

  loop(); // re-enable updates
}

  
void calcZoom() {
  if (foundCount != 0) {
    // given a set of min/max coords, expand in one direction so that the 
    // selected area includes the range with the proper aspect ratio

    float spanX = (boundsX2 - boundsX1);
    float spanY = (boundsY2 - boundsY1);
      
    float midX = (boundsX1 + boundsX2) / 2;
    float midY = (boundsY1 + boundsY2) / 2;
      
    if ((spanX != 0) && (spanY != 0)) {
      float screenAspect = width / float(height);
      float spanAspect = spanX / spanY;
        
      if (spanAspect > screenAspect) {
	spanY = (spanX / width) * height;  // wide
          
      } else {
	spanX = (spanY / height) * width;  // tall          
      }
    } else {  // if span is zero
      // use the span from one level previous
      spanX = targetX2[typedCount-1] - targetX1[typedCount-1];
      spanY = targetY2[typedCount-1] - targetY1[typedCount-1];
    }
    targetX1[typedCount] = midX - spanX/2;
    targetX2[typedCount] = midX + spanX/2;
    targetY1[typedCount] = midY - spanY/2;
    targetY2[typedCount] = midY + spanY/2;

  } else if (typedCount != 0) {
    // nothing found at this level, so set the zoom identical to the previous
    targetX1[typedCount] = targetX1[typedCount-1];
    targetY1[typedCount] = targetY1[typedCount-1];
    targetX2[typedCount] = targetX2[typedCount-1];
    targetY2[typedCount] = targetY2[typedCount-1];
  }

  zoomX1.target(targetX1[typedCount]);
  zoomY1.target(targetY1[typedCount]);
  zoomX2.target(targetX2[typedCount]);
  zoomY2.target(targetY2[typedCount]);

  if (!zoomEnabled) {
    zoomX1.set(zoomX1.target);
    zoomY1.set(zoomY1.target);
    zoomX2.set(zoomX2.target);
    zoomY2.set(zoomY2.target);
  }
}
