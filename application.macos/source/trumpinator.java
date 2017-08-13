import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import twitter4j.*; 
import java.awt.*; 
import java.util.*; 
import java.io.*; 
import java.net.*; 
import ddf.minim.*; 

import javazoom.jl.converter.*; 
import javazoom.jl.decoder.*; 
import javazoom.jl.player.*; 
import javazoom.jl.player.advanced.*; 
import ddf.minim.javasound.*; 
import ddf.minim.*; 
import ddf.minim.analysis.*; 
import ddf.minim.effects.*; 
import ddf.minim.signals.*; 
import ddf.minim.spi.*; 
import ddf.minim.ugens.*; 
import javazoom.spi.*; 
import javazoom.spi.mpeg.sampled.convert.*; 
import javazoom.spi.mpeg.sampled.file.*; 
import javazoom.spi.mpeg.sampled.file.tag.*; 
import org.tritonus.sampled.file.*; 
import org.tritonus.share.*; 
import org.tritonus.share.midi.*; 
import org.tritonus.share.sampled.*; 
import org.tritonus.share.sampled.convert.*; 
import org.tritonus.share.sampled.file.*; 
import org.tritonus.share.sampled.mixer.*; 
import twitter4j.*; 
import twitter4j.api.*; 
import twitter4j.auth.*; 
import twitter4j.conf.*; 
import twitter4j.json.*; 
import twitter4j.management.*; 
import twitter4j.util.*; 
import twitter4j.util.function.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class trumpinator extends PApplet {

/**
 * ===========
 * TRUMPINATOR
 * ===========
 * 
 * TO USE THIS PROGRAM PROPERLY, YOU NEED TO INSERT A MICROPHONE TO YOUR COMPUTER.
 * 
 * YOU CAN SIMPLY ADD YOUR OWN FONTS BY PLACING THEM INSIDE THE "data" FOLDER.
 * CUSTOM FONTS NEED TO BE .ttf OR .otf FORMATTED, OTHERWISE THE PROGRAM WON'T READ THEM.
 * FONTS WILL BE PICKED RANDOMLY WHEN DISPLAYING ANOTHER STATUS.
 * 
 * ========
 * CONTROLS
 * ========
 * 
 * Space : Show next tweet
 *   1-3 : Set audio input sensitivity (1=low, 2=medium, 3=high)
 *     M : Show menu
 *   Esc : Quit program
 */
 
 








// Software version
private final String VERSION = "1.0";

// Twitter API settings (DO NOT CHANGE UNLESS TWITTER CONNECTION IS NOT WORKING)
private final String CONSUMER_KEY = "5si5P0GEefFMLjuH0JCz3e2Wu";
private final String CONSUMER_SECRET = "Gpyn8W4aZBfEuZ9uIqvmbljZalgXLEDiXczvJabEsCWyMXEG8M";
private final String ACCESS_TOKEN = "2273657383-ZOLTTbpsTUcU01g87EBWsn04TahGPckexKXR52Z";
private final String ACCESS_SECRET = "1zxvsNQm6SBNfkSJFYyBE3qtFOmTXlUoizbhOKcLB4t7H";

// Number of latest statuses to be displayed
private final int STATUS_COUNT = 200;

// Line height of displayed text
private final float LINE_HEIGHT = 1.2f;

// Scalings for audio input (used to increase audio input spectrum data)
private final int[] AUDIO_SCALINGS = new int[] { 2000, 8000, 14000 };

// Boundaries and maximum sizes of displayable text
private float posX;
private float posY;
private float sizeX;
private float sizeY;

// Twitter data
private java.util.List<Status> timeline;
private Twitter twitter;
private Status status;

// All fonts placed in "data" folder
private ArrayList<PFont> fonts;

// Current status text from twitter
private String text;

// Current position in List "timeline"
private int pos;

// Current random background color value (0-255)
private int randomCol;

// Gets state of menu being opened or not
private boolean inMenu;

// Audio input data
private Minim minim;
private AudioInput input;
private int currentScale = 1;

public void setup()
{
  // Window settings
  

  // Set text boundaries and maximum sizes
  posX = width * .125f;
  posY = height * .125f;
  sizeX = width * .75f;
  sizeY = height * .75f;

  // Set status position (-1 means that the menu will be shown at first, so the pointer is in front of the first status)
  pos = -1;
  
  // Get audio input
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
    timeline = twitter.getUserTimeline("realDonaldTrump", new Paging(1, STATUS_COUNT));

    // Get all custom fonts from "data" folder
    getFonts();
    
    // Display user instructions
    showInstructions();
  } 
  catch (TwitterException e) {
    error("Verbindung zu Twitter fehlgeschlagen.");
  }
}

/**
 * Show menu which contains welcome screen and user instructions.
 */
public void showInstructions()
{
  inMenu = true;
  
  // Text settings
  PFont font = getFont("Obelix");
  textFont(font);
  textAlign(CENTER, TOP);
  fill(255);
  background(0);
  
  // Set texts
  String headline = "Trumpinator";
  String description = "Hey, kennen Sie Donald Trump?\nSind Sie genau so fasziniert von ihm wie wir?\n" +
                       "Dann ran an's Mikrofon! Schreien Sie sich die Seele aus dem Leib!\n" +
                       "Zerst\u00f6ren Sie die total idiotischen Tweets von diesem Verr\u00fcckten!\nHave fun ;)";
  String[][] keys = new String[][] {
    new String[] {"Space", "N\u00e4chster Tweet"},
    new String[] {"1-3", "Empfindlichkeit des Mikrofons \u00e4ndern"},
    new String[] {"M", "Zur\u00fcck zum Men\u00fc"},
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

/**
 * On each frame reset position if last status has been reached and change pixels on audio input.
 */
public void draw()
{
  if (!inMenu && timeline != null)
  {
    // Reset pointer
    if (pos >= timeline.size()-1) {
      pos = -1;
    }
    
    // Change pixels on mic input
    changePixels();
  }
}

/**
 * Do operation when user has typed any key.
 */
public void keyTyped()
{
  if (timeline != null)
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
        currentScale = PApplet.parseInt(key+"")-1;
        break;
      
      // Show menu
      case 'm':
        showInstructions();
        break;
      
      // Quit program
      case ESC:
        exit();
    }
  }
  else
  {
    // Show error message if connection to twitter is not established
    error("Verbindung zu Twitter fehlgeschlagen.");
  }
}

/**
 * Move pixels on audio input to destroy displayed status text.
 */
public void changePixels()
{
  // Get input audio volume
  float volume = getAudioVolume();

  // Define pixel shift
  int pixelCenter = PApplet.parseInt(posY) * pixelWidth + pixelWidth / 2;
  int pixelShift = volume > sizeX / 2 ? PApplet.parseInt(sizeX / 2) : PApplet.parseInt(volume);
  
  // Get pixels to be moved
  loadPixels();
  
  // Move each pixel
  for (int y=0; y <= PApplet.parseInt(sizeY); y++)
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

  // Set updated pixels
  updatePixels();
}

/**
 * Load all fonts into "fonts" list which are placed inside the "data" folder.
 */
public void getFonts()
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

/**
 * Get custom font from "data" folder set by "fontName".
 */
public PFont getFont(String fontName)
{
  // Try to get font
  if (fonts != null) {
    for (PFont font : fonts) {
      if (font.getName().toLowerCase().indexOf(fontName.toLowerCase()) == 0) {
        return font;
      }
    }
  }
  
  // If font was not founded, return default font (Arial)
  return createFont("Arial", 14, true);
}

/**
 * Move pointer to next status and set interface output.
 * This gets the text of the next status in the "status" list. After that, some interface modifications
 * such as removing line breaks and urls and setting font, text and background color will be processed.
 * In the end, the new text is going to be displayed in the interface.
 */
public void setNextStatus()
{
  if (timeline != null)
  {
    // Get status
    status = (Status) timeline.get(++pos);

    // Get status text
    text = status.getText();

    // Convert line breaks to whitespaces
    text = text.replaceAll("\n", " ");

    // Remove URLs
    for (URLEntity url : status.getURLEntities()) text = text.replace(url.getURL(), "");
    for (MediaEntity media : status.getMediaEntities()) text = text.replace(media.getURL(), "");

    // Set font (tries to get any random custom font, otherwise the default font (Arial) is being used)
    PFont font;
    if (fonts != null && fonts.size() > 0) {
      int index = (int) random(fonts.size());
      font = fonts.get(index);
    } else {
      font = createFont("Arial", 14, true);
    }
    
    // Apply font and set text align
    textFont(font);
    textAlign(LEFT, TOP);

    // Set text size
    int textSize = 120 - text.length() / 2;
    textSize(textSize);
    textLeading(textSize * LINE_HEIGHT);

    // Get random value for color
    randomCol = (int) random(255);
  }

  // Set background color of current status
  backgroundCol();
  
  // Display current status
  displayStatus();
}

/**
 * Display current status.
 */
public void displayStatus()
{
  if (timeline != null) {
    fill(0);
    text(text, posX, posY, sizeX, height);
  }
}

/**
 * Set background color for current status.
 */
public void backgroundCol()
{
  if (status != null)
  {
    // Get time instance and set time to creation time of current status
    Calendar cal = Calendar.getInstance();
    cal.setTime(status.getCreatedAt());
  
    // Get hour of current status
    int hour = cal.get(Calendar.HOUR);
  
    // Reset rgb colors
    int red = 0,
        blue = 0,
        green = 0;
  
    // Set colors depending on the creation time of the current status
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
  
    // Apply color to background
    background(red, blue, green);
  }
}

/**
 * Read volume of audio input (this is normally the user mic).
 */
public float getAudioVolume()
{
  // Add multiple spectrum data
  float sum = 0;
  for (int i=0; i < input.bufferSize(); i++) sum += input.mix.get(i);

  // Set used audio volume depending on the selected audio scaling
  float average = (sum * AUDIO_SCALINGS[currentScale]) / input.bufferSize();
  if (average < 0) average *= -1;
  if ((int) average == 0) average++;

  return average;
}

/**
 * Show error message on screen.
 */
public void error(String text)
{
  if (text.trim().length() > 0)
  {
    // Prevent program to recognize mic input
    inMenu = true;
    
    // Load fonts
    getFonts();
    
    // Set background
    background(0);
    
    // Set text
    fill(255);
    textAlign(CENTER, CENTER);
    textFont(getFont("Sketchit"));
    textSize(25);
    text(text.trim(), width/2, height/2);
  }
}











/*
* THE ABOVE METHODS AREN'T USED CURRENTLY!
*
* Methods for an explosion if an adjctive was found.
* Searching for adjectives. Comparing the words from the current tweet with an 
* selfmade list full of adjectives. If one is found a new ArrayList with particles 
* will be created. The explosion will be located random on the frame.
*/

private boolean explo;
private float wr, hr;

/*
* Search for adjectives in the tweet
*/
public void searchAd() {
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
    grav = new PVector(0, 0.02f);

    tail = new ArrayList();
  }

  public void run() {
    pos.add(speed);

    tail.add(new PVector(pos.x, pos.y, 0));
    if (tail.size() > taillength) {
      tail.remove(0);
    }

    float damping = random(-0.5f, -0.6f);
    if (pos.x > width - margin || pos.x < margin) {
      speed.x *= damping;
    }
    if (pos.y > height -margin) {
      speed.y *= damping;
    }
  }

  public void gravity() {
    speed.add(grav);
  }

  public void update() {
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
public void explode() {
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
public void adFound() {
  for (int i = 0; i < MAX; i ++) {
    plist.add(new Particle(wr, hr)); // fill ArrayList with particles

    if (plist.size() > 5*MAX) {
      plist.remove(0);
    }
  }
}
  public void settings() {  fullScreen(); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "trumpinator" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
