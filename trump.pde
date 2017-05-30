import twitter4j.*;
import java.awt.*;
import java.util.*;
import java.io.*;
import java.net.*;
import ddf.minim.*;

private final String CONSUMER_KEY = "5si5P0GEefFMLjuH0JCz3e2Wu";
private final String CONSUMER_SECRET = "Gpyn8W4aZBfEuZ9uIqvmbljZalgXLEDiXczvJabEsCWyMXEG8M";
private final String ACCESS_TOKEN = "2273657383-RGW1GvXHedkK6cRzpg424t3K6wK8n1hfy8HB8A7";
private final String ACCESS_SECRET = "admz1Hhusclk1zeW6hpW76oAMvyowlgIlaHcpGco62Pfl";

private final int STATUS_COUNT = 200;
private final float LINE_HEIGHT = 1.2;
private final int AUDIO_SCALE = 100000;

private float posX;
private float posY;
private float sizeX;

private java.util.List<Status> timeline;
private Twitter twitter;
private Status status;

private java.util.List<PFont> fonts;

private ArrayList<String> lines;
private int textSize;
private String text;
public String word;
private int pos;
private int randomCol;

private Minim minim;
private AudioInput input;

bouncyWord bAd = new bouncyWord(word, width/4);

void setup()
{
  // Window settings
  size(1080, 720);
  background(255);

  // Set status position
  pos = 0;

  // Set sizes
  posX = width * .125;
  posY = height * .125;
  sizeX = width * .75;

  // Text settings
  textAlign(LEFT, TOP);

  // Audio settings
  minim = new Minim(this);
  input = minim.getLineIn(Minim.STEREO, 512);

  // Twitter configuration
  ConfigurationBuilder cb = new ConfigurationBuilder();
  cb.setOAuthConsumerKey(CONSUMER_KEY);
  cb.setOAuthConsumerSecret(CONSUMER_SECRET);
  cb.setOAuthAccessToken(ACCESS_TOKEN);
  cb.setOAuthAccessTokenSecret(ACCESS_SECRET);

  // Connect to Twitter
  twitter = new TwitterFactory(cb.build()).getInstance();

  try {

    // Get statuses
    // Query query = new Query("#trump");
    // QueryResult res = twitter.search(query);
    // hashtags = res.getTweets();
    timeline = twitter.getUserTimeline("realDonaldTrump", new Paging(1, STATUS_COUNT));

    // Get fonts
    getFonts();

    // Display statuses
    setNextStatus();
  } 
  catch (TwitterException e) {
    println("Connection to Twitter failed.");
  }
}

void draw()
{
  if (timeline != null)
  {
    // Reset position
    if (pos >= timeline.size()) {
      pos = 0;
    }

    //backgroundCol();
    //displayStatuses();
    //explode();
    //changePixels();
    //bAd.draw();
  }
}

void keyTyped()
{
  if (key == ' ') {
    setNextStatus();
    searchAd();
    // if
    // bAd.theWord = (" ");
  }
}

void changePixels()
{
  // Get input audio volume
  float volume = getAudioVolume();

  // Set move borders
  int pixelCenter = pixelWidth * (pixelHeight / 2) - (pixelWidth / 2);
  int topBorder = (pixelHeight / 2) - (pixelHeight / 4);
  int bottomBorder = (pixelHeight / 2) + (pixelHeight / 4);
  int leftBorder = (pixelWidth / 2) - (pixelWidth / 6);
  int rightBorder = (pixelWidth / 2) + (pixelWidth / 6);

  loadPixels ();

  // Move pixels
  for (int i=topBorder; i < bottomBorder; i++)
  {
    for(int n = (i * pixelWidth + leftBorder); n < (i * pixelWidth + rightBorder); n++)
    {
      println(n);
      if (n - (i * pixelWidth + leftBorder) == 200) break;
    }
  }

  /*int pixelTemp = pixels[pixelCenter];
   pixels[pixelCenter] = pixels[pixelCenter - (int) volume];
   pixels[pixelCenter - (int) volume] = pixelTemp;*/

  updatePixels();
}

void getFonts()
{
  // Initialize fonts list
  fonts = new ArrayList<PFont>();

  // Get contents
  File data = new File(dataPath(""));
  String[] files = data.list();

  // Set fonts
  for (String file : files)
  {
    // Get extension
    String ext = file.substring(file.lastIndexOf('.') + 1).toLowerCase();

    // Add font
    if (ext.equals("ttf") || ext.equals("otf")) {
      fonts.add(createFont(file, 14, true));
    }
  }
}

void setNextStatus()
{
  if (timeline != null)
  {
    // Get status
    status = (Status) timeline.get(pos++);

    // Get text
    text = status.getText();

    // Convert line breaks to whitespaces
    text = text.replaceAll("\n", " ");

    // Remove URLs
    for (URLEntity url : status.getURLEntities()) {
      text = text.replace(url.getURL(), "");
    }
    for (MediaEntity media : status.getMediaEntities()) {
      text = text.replace(media.getURL(), "");
    }

    // Set font
    PFont font;
    if (fonts != null && fonts.size() > 0) {
      int index = (int) random(fonts.size());
      font = fonts.get(index);
    } else {
      font = createFont("Arial", 14, true);
    }
    textFont(font);

    // Set text size
    textSize = 120 - text.length() / 2;
    textSize(textSize);

    // Get text lines
    lines = new ArrayList<String> ();
    int enterPos = 0;
    for (int i=0; i < text.length(); i++)
    {
      String s = "";
      for (int n=enterPos; n < i; n++)
      {
        if (n == enterPos && text.charAt(n) == ' ') {
          n++;
        } else {
          s += text.charAt(n);
        }
      }

      if (textWidth(s) > sizeX) {
        lines.add(s.substring(0, s.length()-1));
        enterPos = --i;
      } else if (i == text.length()-1) {
        lines.add(s.substring(0, s.length()));
      }
    }

    // Get random value for color
    randomCol = (int) random(255);

    // Search for adjectives
    searchAd();
  }

  backgroundCol();
  displayStatuses();
  changePixels();
}

void displayStatuses()
{
  if (timeline != null)
  {
    // Write text
    for (int i=0; i < lines.size(); i++) {
      fill(0);
      text(lines.get(i), posX, posY + (LINE_HEIGHT * i * textSize));
    }
  }
}

void backgroundCol()
{
  // Set calendar time
  Calendar cal = Calendar.getInstance();
  cal.setTime(status.getCreatedAt());

  // Get day and hour of status
  int hour = cal.get(Calendar.HOUR);

  // Set colors
  int red = 0, blue = 0, green = 0;

  if (hour <= 6) {
    red = 255;
    blue = randomCol;
    green = 0;
  } else if (hour <= 12) {
    red = 0;
    blue = 255;
    green = randomCol;
  } else if (hour <= 18) {
    red = 0;
    blue = randomCol;
    green = 255;
  } else if (hour <= 24) {
    red = randomCol;
    blue = 0;
    green = 255;
  }

  // Set background
  background(red, blue, green);
}

float getAudioVolume()
{
  float sum = 0;
  for (int i=0; i < input.bufferSize(); i++) sum += input.mix.get(i);

  float average = (sum * AUDIO_SCALE) / input.bufferSize();
  if (average < 0) average *= -1;
  if ((int) average == 0) average++;

  return average;
}



private boolean flotus;
private float wr, hr;

//search for adjectives
void searchAd() {
  String[] list = split(text, ' ');
  ArrayList<String> words = new ArrayList<String>(Arrays.asList(list));
  String adList[] = loadStrings("ad_list.txt");
  //ArrayList<String> ads = new ArrayList<String>(Arrays.asList(adList));
  HashSet<String> adjectives = new HashSet<String>();

  for (String bw : adList) adjectives.add(bw);

  for (String word : words) {

    if (adjectives.contains(word)) {
      println("I've got it! - " + word);
      flotus = true;
      wr = random(width);
      hr = random(height);
      bAd = new bouncyWord(word, width/4);
      adFound();
      break;
    } else {
      bAd = new bouncyWord("", 0);
    }
  }
}

//expolsion if adjective was found
ArrayList plist = new ArrayList();
int MAX = 50;

class Particle {
  float r = 2;
  PVector pos, speed, grav; 
  ArrayList tail;
  float splash = 5;
  int margin = 2;
  int taillength = 25;

  Particle(float tempx, float tempy) {
    float startx = tempx + random(-splash, splash);
    float starty = tempy + random(-splash, splash);
    startx = constrain(startx, 0, width);
    starty = constrain(starty, 0, height);
    float xspeed = random(-3, 3);
    float yspeed = random(-3, 3);

    pos = new PVector(startx, starty);
    speed = new PVector(xspeed, yspeed);
    grav = new PVector(0, 0.02);

    tail = new ArrayList();
  }

  void run() {
    pos.add(speed);

    tail.add(new PVector(pos.x, pos.y, 0));
    if (tail.size() > taillength) {
      tail.remove(0);
    }

    float damping = random(-0.5, -0.6);
    if (pos.x > width - margin || pos.x < margin) {
      speed.x *= damping;
    }
    if (pos.y > height -margin) {
      speed.y *= damping;
    }
  }

  void gravity() {
    speed.add(grav);
  }

  void update() {
    for (int i = 0; i < tail.size(); i++) {
      PVector tempv = (PVector)tail.get(i);
      noStroke();
      fill(6*i + 50);
      ellipse(tempv.x, tempv.y, r, r);
    }
  }
}

void explode() {
  if (flotus /*&& test == true*/) {
    for (int i = 0; i < plist.size(); i++) {
      Particle p = (Particle) plist.get(i); 
      //makes p a particle equivalent to ith particle in ArrayList
      p.run();
      p.update();
      p.gravity();
    }
  }
}

void adFound() {
  // test = true;
  for (int i = 0; i < MAX; i ++) {
    plist.add(new Particle(wr, hr)); // fill ArrayList with particles

    if (plist.size() > 5*MAX) {
      plist.remove(0);
    }
  }
}

public String getWord()
{
  return word;
}

class bouncyWord {
  String theWord; 
  float px, py, vx, vy;
  bouncyWord(String word, float ipx) {
    theWord = word;
    px=ipx;
    vx=0;
    py=height/2;
    vy=random(2, 7);
  }
  void draw() {
    px+=vx;
    py+=vy;
    if (py<0) {
      py=0;
      vy=-vy;
    }
    if (py>height) {
      py=height;
      vy=-vy;
    }
    text(theWord, px, py);
  }
}