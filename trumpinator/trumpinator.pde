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
 
 

import twitter4j.*;
import java.awt.*;
import java.util.*;
import java.io.*;
import java.net.*;
import ddf.minim.*;

// Software version
private final String VERSION = "2.0.0";

// Twitter API settings
private Map<String, String> API_CREDENTIALS = new HashMap<String, String>();

// Number of latest statuses to be displayed
private final int STATUS_COUNT = 200;

// Line height of displayed text
private final float LINE_HEIGHT = 1.2;

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

void setup()
{
  // Window settings
  fullScreen();

  // Set text boundaries and maximum sizes
  posX = width * .125;
  posY = height * .125;
  sizeX = width * .75;
  sizeY = height * .75;

  // Set status position (-1 means that the menu will be shown at first, so the pointer is in front of the first status)
  pos = -1;
  
  // Get audio input
  minim = new Minim(this);
  input = minim.getLineIn(Minim.STEREO, 512);

  try {
    // Get Twitter credentials
    getApiCredentials();
    
    // Set Twitter configuration
    ConfigurationBuilder cb = new ConfigurationBuilder();
    cb.setOAuthConsumerKey(API_CREDENTIALS.get("consumerKey"));
    cb.setOAuthConsumerSecret(API_CREDENTIALS.get("consumerSecret"));
    cb.setOAuthAccessToken(API_CREDENTIALS.get("accessToken"));
    cb.setOAuthAccessTokenSecret(API_CREDENTIALS.get("accessSecret"));
  
    // Connect to Twitter
    twitter = new TwitterFactory(cb.build()).getInstance();
    
    // Get statuses
    timeline = twitter.getUserTimeline("realDonaldTrump", new Paging(1, STATUS_COUNT));

    // Get all custom fonts from "data" folder
    getFonts();
    
    // Display user instructions
    showInstructions();
    
  } catch (Exception e) {
    error("Connection to Twitter failed." + "\n" + "Please make sure to provide valid API keys.");
    print("Error during connection with Twitter:" + "\n\n" + e.getMessage());
  }
}

/**
 * Show menu which contains welcome screen and user instructions.
 */
void showInstructions()
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
  String description = "Hey, you know Donald Trump?" + "\n" +
                       "You like his fascinating tweets he's producing day by day? Don't you?" + "\n" +
                       "Then turn on your microphone and scream the f*ck out of you!" + "\n" +
                       "Destroy these stupid tweets from this crazy man which are filled with lots of crappy stuff!";
  String[][] keys = new String[][] {
    new String[] {"Space", "Next Tweet"},
    new String[] {"1-3", "Set audio input sensitivity"},
    new String[] {"M", "Back to menu"},
    new String[] {"Esc", "Quit"}
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
void draw()
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
void keyTyped()
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
        currentScale = int(key+"")-1;
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
    error("Connection to Twitter failed." + "\n" + "Please make sure to provide valid API keys.");
  }
}

/**
 * Move pixels on audio input to destroy displayed status text.
 */
void changePixels()
{
  // Get input audio volume
  float volume = getAudioVolume();

  // Define pixel shift
  int pixelCenter = int(posY) * pixelWidth + pixelWidth / 2;
  int pixelShift = volume > sizeX / 2 ? int(sizeX / 2) : int(volume);
  
  // Get pixels to be moved
  loadPixels();
  
  // Move each pixel
  for (int y=0; y <= int(sizeY); y++)
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

/**
 * Get custom font from "data" folder set by "fontName".
 */
PFont getFont(String fontName)
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
void setNextStatus()
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
void displayStatus()
{
  if (timeline != null) {
    fill(0);
    text(text, posX, posY, sizeX, height);
  }
}

/**
 * Set background color for current status.
 */
void backgroundCol()
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
float getAudioVolume()
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
 * Get Twitter API credentials and save them to global API_CREDENTIALS map.
 */
void getApiCredentials() throws Exception
{
  // Read credentials
  String[] credentials = loadStrings("../credentials");
  
  if (credentials.length == 0) {
    throw new Exception("Please provide a valid credentials file inside the project directory. Use credentials.sample as template and fill in your API keys.");
  }
  
  for (String current : credentials)
  {
    // Save credentials to API_CREDENTIALS map
    String[] contents = current.split(":");
    if (contents.length == 2)
    {
      String key = contents[0].trim();
      String value = contents[1].trim();
      API_CREDENTIALS.put(key, value);
    }
    else
    {
      throw new Exception("Please provide valid Twitter credentials in the credentials file inside the project directory.");
    }
  }
}

/**
 * Show error message on screen.
 */
void error(String text)
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
