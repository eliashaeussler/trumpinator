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
private final int AUDIO_SCALE = 50000;

private float posX;
private float posY;
private float sizeX;
private float sizeY;

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

void setup()
{
  // Window settings
  size(1440, 900);
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
    
    // Change pixels on mic input
    changePixels();
  }
}

void keyTyped()
{
  if (key == ' ') {
    setNextStatus();
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
  }

  backgroundCol();
  displayStatuses();
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
    
    // Set y size
    sizeY = (lines.size()+1) * textSize;
    if (sizeY + posY > pixelHeight) {
      sizeY = pixelHeight - posY;
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