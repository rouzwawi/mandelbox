
int lim = 10;
float[] c = new float[]{ 0.285, 0.01 };

float zoom = 2.0;
int[] window;

void setup() {
  size(1600, 1600);
  colorMode(HSB, 255);
  background(0,0,0);
  window = new int[width*height];
}

float bail = 8.0;
int keyDown = 0;

void draw() {
  background(0,0,0); // black background
  stroke(0,0,255); // white foreground
  
  if (keyDown > 0 && keyDown + 200 > millis()) {
    keyPressed();    
  }
  
  box();
}

void keyPressed() {
  keyDown = millis();
  actKey();
}

void keyReleased() {
  keyDown = -1;  
}

void actKey() {
  switch (key) {
    case 'w': lim += 1; break;
    case 's': lim -= 1; break;
      
    case 'd': bail += 0.2; break;
    case 'a': bail -= 0.2; break;
    
    case 'e': zoom += 0.1; break;
    case 'q': zoom -= 0.1; break;
  }
}

void box() {
  float[] iter = new float[2];
  float[] c = new float[2];
  float f = 1.0;
  float r = map(mouseY, 0, height, 0.01, 2.0);
  float s = map(mouseX, 0,  width, -5.0, 5.0);
//  float r =  1.0;
//  float s = -1.5;
  
  loadPixels();
  
  // only iterate one quarter of the plane
  int xh = width/2;
  int yh = height/2;
  
  for (int i = 0; i < xh*yh; i++) {
    iter[0] = iter[1] = 0;
    c[0] = map(i % xh, 0,  width, -zoom, zoom);
    c[1] = map(i / yh, 0, height, -zoom, zoom);

    for (int j = 0; j < lim; j++) {
      boxIter(iter, f, r, s, c);
      
      int cl = color( map(j, 0,lim, 0, 255), 127, 255);
      if (iter[0]*iter[0] + iter[1]*iter[1] > bail) {
        // reflect across all quadrants
        pixels[i + i/yh*yh] = cl;
        pixels[i + i/yh*yh + width - 1 - (i%xh)*2] = cl;
        pixels[width*height - 1 - i - (i/yh*yh)] = cl;
        pixels[width*height - i - i/yh*yh - width + (i%xh)*2] = cl;
        break;
      }
    }
  }
  
  updatePixels();
}

void julia() {
  float[] z = new float[2];
  float[] y = new float[2];

  c[0] = map(mouseX, 0,  width, -2.0,  2.0);
  c[1] = map(mouseY, 0, height,  2.0, -2.0);
  
  loadPixels();
  for (int j=0; j<height; j++) {
    for (int i=0; i<width; i++) {
      z[0] = map(i, 0,  width, -zoom, +zoom);
      z[1] = map(j, 0, height, +zoom, -zoom);

      for (int k=0; k<lim; k++) {
        f(z, y);
        if (escapes(y)) {
          int c = color( map(k, 0,lim, 250,0), 200, 255);
          pixels[j*width + i] = c;
          break;
        }
        cpy(y, z);
      }
    }
  }
  updatePixels();
}

void mandelTrace() {
  float[] z = new float[2];
  float[] y = new float[2];
  
  int eIter = 0;
  int white = color(0,0,255, 10);
  // buddha julia
  for (int i=0; i<200000; i++) {
    float ix = (int)(width  * random(1));
    float iy = (int)(height * random(1));
    z[0] = 0;
    z[1] = 0;
    c[0] = map(ix, 0,  width, -zoom, +zoom);
    c[1] = map(iy, 0, height, +zoom, -zoom);
    
    boolean plot = false;
    for (int k=0; k<lim; k++) {
      f(z, y);
      if (escapes(y)) {
        plot = true;
        eIter = lim;
        break;
      }
      cpy(y, z);
    }
    if (plot) {
      z[0] = 0;
      z[1] = 0;
      c[0] = map(ix, 0,  width, -zoom, +zoom);
      c[1] = map(iy, 0, height, +zoom, -zoom);
      int cx = round( map(c[0], -zoom, +zoom, 0,  width) );
      int cy = round( map(c[1], +zoom, -zoom, 0, height) );
      if (cx >= 0 && cx < width && cy >= 0 && cy < height)
        window[cy*width + cx] += eIter;
    }
  }


  int maxWindow = 0;
  for (int i=0; i<window.length; i++)
    if (window[i] > maxWindow) maxWindow = window[i];
  loadPixels();
  for (int i=0; i<window.length; i++)
    pixels[i] = color(0,0, map(window[i], 0, maxWindow, 0, 255));
  updatePixels();

  // draw the line
  stroke(0,0,170); // white foreground
  z[0] = 0;
  z[1] = 0;
  c[0] = map(mouseX, 0,  width, -zoom, +zoom);
  c[1] = map(mouseY, 0, height, +zoom, -zoom);
  
  int sz0 = 0, sz1 = 0, sy0 = 0, sy1 = 0;
  
  for (int i=0; i<lim; i++) {
    f(z, y);
    
    if ((i%2) == 0) {
      sz0 = round( map(z[0], -zoom, +zoom, 0,  width) );
      sz1 = round( map(z[1], +zoom, -zoom, 0, height) );
    } else {
      sy0 = round( map(y[0], -zoom, +zoom, 0,  width) );
      sy1 = round( map(y[1], +zoom, -zoom, 0, height) );
      line(sz0, sz1, sy0, sy1);
    }
    cpy(y, z);
  }
}


void mousePressed() {
  window = new int[width*height];
}

void boxIter(float[] v, float f, float r, float s, float[] c) {
  // f*boxFold(v)
  boxFold(v, 0);
  boxFold(v, 1);
  v[0] *= f;
  v[1] *= f;
  
  // ballfold(r, f*boxFold(v))
  ballFold(v, r);
  
  // s*ballfold(r, f*boxFold(v))
  v[0] *= s;
  v[1] *= s;
  
  // s*ballfold(r, f*boxFold(v)) + c
  v[0] += c[0];
  v[1] += c[1];
}

void boxFold(float[] v, int d) {
  if (v[d] > 1.0)
    v[d] = 2.0 - v[d];
  else if (v[d] < -1.0)
    v[d] = -2.0 - v[d];
}

void ballFold(float[] v, float r) {
  float m = magnitude(v);
  if (m < r) {
    v[0] /= r*r;
    v[1] /= r*r;
  } else if (m < 1.0) {
    v[0] /= m*m;
    v[1] /= m*m;
  }
}

float magnitude(float[] v) {
  return sqrt(v[0] * v[0] + v[1] * v[1]);
}

void cpy(float[] y, float[] z) {
  z[0] = y[0];
  z[1] = y[1];
}

void f(float[] z, float[] y) {
  float a = z[0];
  float b = z[1];
  y[0] = a*a - b*b + c[0];
  y[1] = 2*a*b     + c[1];
}

boolean escapes(float[] z) {
  return z[0]*z[0] + z[1]*z[1] > 2.0;
}
