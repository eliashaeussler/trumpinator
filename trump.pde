import twitter4j.*;
import java.awt.*;
import java.util.*;
import java.io.*;
import java.net.*;
import ddf.minim.*;

private final String VERSION = "1.0";

private final String CONSUMER_KEY = "5si5P0GEefFMLjuH0JCz3e2Wu";
private final String CONSUMER_SECRET = "Gpyn8W4aZBfEuZ9uIqvmbljZalgXLEDiXczvJabEsCWyMXEG8M";
private final String ACCESS_TOKEN = "2273657383-ZOLTTbpsTUcU01g87EBWsn04TahGPckexKXR52Z";
private final String ACCESS_SECRET = "1zxvsNQm6SBNfkSJFYyBE3qtFOmTXlUoizbhOKcLB4t7H";

private final int STATUS_COUNT = 200;
private final float LINE_HEIGHT = 1.2;
private final int[] AUDIO_SCALINGS = new int[] { 2000, 8000, 14000 };

private float posX;
private float posY;
private float sizeX;
private float sizeY;

private java.util.List<Status> timeline;
private Twitter twitter;
private Status status;

private ArrayList<PFont> fonts;
private int textSize;
private String text;
public String word;
private int pos;
private int randomCol;
private boolean inMenu;

private Minim minim;
private AudioInput input;
private int currentScale = 1;

void setup()
{
  // Window settings
  fullScreen();

  // Set sizes
  posX = width * .125;
  posY = height * .125;
  sizeX = width * .75;
  sizeY = height * .75;

  // Set status position
  pos = -1;
  
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
    
    // Display user instructions
    showInstructions();
  } 
  catch (TwitterException e) {
    println("Connection to Twitter failed.");
  }
}

void showInstructions()
{
  inMenu = true;
  
  // Text settings
  PFont font = getFont("Obelix");
  textFont(font);
  textAlign(CENTER, TOP);
  fill(255);
  background(0);
  
  // Set text
  String headline = "Trumpinator";
  String description = "Hey, kennen Sie Donald Trump?\nSind Sie genau so fasziniert von ihm wie wir?\n" +
                       "Dann ran an's Mikrofon! Schreien Sie sich die Seele aus dem Leib!\n" +
                       "Zerstören Sie die total idiotischen Tweets von diesem Verrückten!\nHave fun ;)";
  String[][] keys = new String[][] {
    new String[] {"Space", "Nächster Tweet"},
    new String[] {"1-3", "Empfindlichkeit des Mikrofons ändern"},
    new String[] {"M", "Zurück zum Menü"},
    new String[] {"Esc", "Beenden"}
  };
  
  // Set shortcuts
  String shortcuts = "";
  for (String[] shortcut : keys) {
    shortcuts += "\n" + shortcut[0] + ": " + shortcut[1];
  }
  
  // Show headline
  textSize(50);
  text(headline, width/2, posY);
  
  // Show version
  textSize(14);
  text(VERSION, width/2, posY + 100);
  
  // Show description and shortcuts
  font = getFont("Sketchit");
  textFont(font);
  textSize(25);
  text(description + "\n\n" + shortcuts, posX, posY + 170, sizeX, sizeY);
}

void draw()
{
  if (!inMenu && timeline != null)
  {
    // Reset position
    if (pos >= timeline.size()-1) {
      pos = -1;
    }
    
    // Change pixels on mic input
    changePixels();
  }
}

void keyTyped()
{
  switch (key)
  {
    // Show next status
    case ' ':
      inMenu = false;
      setNextStatus();
      break;
    
    // Set audio scale
    case '1':
    case '2':
    case '3':
      currentScale = int(key+"")-1;
      break;
    
    case 'm':
      showInstructions();
      break;
    
    case ESC:
      exit();
  }
}

void changePixels()
{
  // Get input audio volume
  float volume = getAudioVolume();

  // Define pixel shift
  int pixelCenter = int(posY) * pixelWidth + pixelWidth / 2;
  int pixelShift = volume > sizeX / 2 ? int(sizeX / 2) : int(volume);
  
  // Set pixels to be moved
  loadPixels ();
  
  for (int y = 0; y <= int(sizeY); y++)
  {
    // Get center of current line
    int currentCenter = pixelCenter + y * pixelWidth;

    // Move pixels
    for (int i=currentCenter - pixelShift; i <= currentCenter; i++) {
      arrayCopy(pixels, i, pixels, i - 1, 1);
    }
    for (int i=currentCenter + pixelShift; i > currentCenter; i--) {
      arrayCopy(pixels, i, pixels, i + 1, 1);
    }
  }

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

PFont getFont(String fontName)
{
  if (fonts != null) {
    for (PFont font : fonts) {
      if (font.getName().toLowerCase().indexOf(fontName.toLowerCase()) == 0) {
        return font;
      }
    }
  }
  
  return createFont("Arial", 14, true);
}

void setNextStatus()
{
  if (timeline != null)
  {
    // Get status
    status = (Status) timeline.get(++pos);

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
    textAlign(LEFT, TOP);

    // Set text size
    textSize = 120 - text.length() / 2;
    textSize(textSize);
    textLeading(textSize * LINE_HEIGHT);

    // Get random value for color
    randomCol = (int) random(255);
  }

  backgroundCol();
  displayStatuses();
}

void displayStatuses()
{
  if (timeline != null) {
    fill(0);
    text(text, posX, posY, sizeX, height);
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

  float average = (sum * AUDIO_SCALINGS[currentScale]) / input.bufferSize();
  if (average < 0) average *= -1;
  if ((int) average == 0) average++;

  return average;
}






/*
* THESE METHODS AREN'T USED CURRENTLY!
*
* Methods for an explosion if an adjctive was found.
* Searching for adjectives. Comparing the words from the current tweet with an 
* selfmade list full of adjectives. If one is found a new ArrayList with particles 
* will be created. The explosion will be located radnom on the frame.
*/



private boolean explo;
private float wr, hr;

/*
* Search for adjectives in the tweet
*/
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
      explo = true;
      wr = random(width);
      hr = random(height);
      adFound();
    }
  }
}

/*
* new class for new generated particles for the explosion
*/
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

/*
* method for the expolison
*/
void explode() {
  if (explo) {
    for (int i = 0; i < plist.size(); i++) {
      Particle p = (Particle) plist.get(i); 
      //makes p a particle equivalent to ith particle in ArrayList
      p.run();
      p.update();
      p.gravity();
    }
  }
}

/*
* method for a new ArrayList with particles if adjective was found
*/
void adFound() {
  for (int i = 0; i < MAX; i ++) {
    plist.add(new Particle(wr, hr)); // fill ArrayList with particles

    if (plist.size() > 5*MAX) {
      plist.remove(0);
    }
  }
}