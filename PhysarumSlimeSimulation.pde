/*
Simulation based on Physarum slime, only simulate with square dimensions
 
 @author Anuj Panta
 */



/*
2d array to keep track of residue and residue decay
 */
float[][] residue;
float residueDecay = 0.006;

/*
keeps track of agents in array and assigns total agent number
 */
Agent[] agents;
int totalAgents;

/*
uses a set ratio inorder to determine the amount of agents needed
 based on the width of the screen
 */
float sizeToAgentRatio= 3 / 100;

/*
setting up canvas, agents, and residue
 */
void setup() {
  size(500, 500);
  totalAgents = round(width * 35);
  agents = new Agent[totalAgents];
  for (int i = 0; i < agents.length; i++) {
    agents[i] = new Agent();
  }

  residue = new float[height][width];
}

/*
running draw loop taking care of agents and the residue process
 */
void draw() {
  for (Agent a : agents) {
    a.move();
    a.depositResidue();
  }
  residueProcess();
}

/*
performs diffusing and decay on residue, then displays
 */
void residueProcess() {
  displayResidue();
  diffuseResidue();
  decayResidue();
}

/*
goes through residue and diffuses based on neighbors, then
 replaces residue with diffused residue 2d array
 */
void diffuseResidue() {
  float[][] newResidue = new float[height][width];
  int border = Agent.border;
  for (int row = border; row < height - border; row++) {
    for (int col = border; col < width - border; col++) {
      float total = 0;
      for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
          total += residue[row + i][col + j];
        }
      }
      total = total / 9;
      newResidue[row][col] = total;
    }
  }
  residue = newResidue;
}

/*
resude all residue values by residue decay
 */
void decayResidue() {
  for (int row = 0; row < height; row++) {
    for (int col = 0; col < width; col++) {
      residue[row][col] -= residueDecay;
    }
  }
}

/*
uses residue values to assign pixels to rgb colors
 */
void displayResidue() {
  loadPixels();
  for (int row = 0; row < height; row++) {
    for (int col = 0; col < width; col++) {
      int index = (row + col * width);
      pixels[index] = color(residue[row][col]*255);
    }
  }
  updatePixels();
}

/*
checks if given row and col are within residue bounds
 */
public boolean withinResidueBounds(int row, int col) {
  if (row <= 0 || row >= width || col <= 0 || col >= height) {
    return false;
  }
  return true;
}

class Agent {

  /*
  creates position, velocity, and heading that lets Agent move
   */
  private PVector pos;
  private PVector vel;
  private float heading;
  private float velMag;

  /*
  border varialbe decreases side of where Agent can move
   inorder to allow for residue array to work without accounting
   for edge cases
   */
  static final int border = 2;

  /*
  creates needed variables for Agent sensing ability
   */
  private int sensorWidth;
  private float sensorAngle;
  private int sensorOffSet;

  /*
  initalizes positon, velocity, and sensor variables
   */

  public Agent() {
    //pos = new PVector(random(width), random(height));
    pos = new PVector(width/2, height/2);
    heading = random(TWO_PI);
    velMag = 3;
    vel = formVector(heading, velMag);

    sensorWidth = 5;
    sensorAngle = radians(9);
    sensorOffSet = 6;
  }

  /*
  returns a new velocity given a angle and magnitude
   */
  private PVector formVector(float angle, float magnitude) {
    PVector result = PVector.fromAngle(angle);
    result.setMag(magnitude);
    return result;
  }

  /*
  returns a new velocity given a angle, magnitude, and PVector as reference
   */
  private PVector formVector(float angle, int magnitude, PVector reference) {
    PVector result = formVector(angle, magnitude);
    result.add(reference);
    return result;
  }

  /*
  helper funciton to see where the Agent is at
   */
  public void show() {
    stroke(255, 0, 0);
    strokeWeight(3);
    point(pos.x, pos.y);
  }

  /*
  check's if the agent can deposit then moves and deposits if able to
   */
  public void move() {
    sense();
    boolean canDepositResidue = canDeposit();
    pos.add(vel);

    if (canDepositResidue) {
      depositResidue();
    }
  }


  /*
  decides if agent can deposit based on if
   it's within bounds, if not it fixes the bounds as well
   */
  private boolean canDeposit() {
    boolean result = true;
    if (pos.x - border <= 0 || pos.x + border >= width) {
      vel.x *= -1;
      heading = vel.heading();
      result = false;
    }

    if (pos.y - border <= 0 || pos.y + border >= height) {
      vel.y *= -1;
      heading = vel.heading();
      result = false;
    }

    return result;
  }

  /*
  makes residue value at postion 1
   */
  public void depositResidue() {
    int row = int(pos.y);
    int col = int(pos.x);
    if (withinResidueBounds(row, col)) {
      residue[row][col] = 1;
    }
  }

  /*
  senses based on location and decides which way to rotate
   */
  private void sense() {
    float[] sectorValues = getSectorValues();

    if (sectorValues[1] > sectorValues[0] && sectorValues[1] > sectorValues[2]) {
      return;
    } else if (sectorValues[1] < sectorValues[0] && sectorValues[1] < sectorValues[2]) {
      if (random(1) > 0.5) {
        rotateAgent(sensorAngle);
      } else {
        rotateAgent(-sensorAngle);
      }
    } else if (sectorValues[0] < sectorValues[2]) {
      rotateAgent(+sensorAngle);
    } else if (sectorValues[2] < sectorValues[0]) {
      rotateAgent(-sensorAngle);
    }
  }

  /*
  rotates heading by angle, and sets velocity to needed configuration
   */
  private void rotateAgent(float alpha) {
    heading += alpha + rAngle();
    vel = formVector(heading, velMag);
  }


  /*
    looks at three sensors and get's the average values within a array of floats
   */
  private float[] getSectorValues() {

    float[] sectorValues = new float[3];

    float currHeading = heading;
    PVector currPos = pos.copy();

    for (int i=-1; i <= 1; i++) {
      float beta = currHeading + (sensorAngle * (i));
      PVector sectorVector = formVector(beta, sensorOffSet, currPos);
      if (withinBounds(sectorVector)) {
        sectorValues[i+1] = getAverageSectorValue(sectorVector);
      }
    }

    return sectorValues;
  }

  /*
  given a vector it gets the average residue value around that area
   */
  private float getAverageSectorValue(PVector sectorVector) {

    float average = 0;
    int totalCounted = 0;

    int row = round(sectorVector.y);
    int col = round(sectorVector.x);

    for (int i=-sensorWidth; i < sensorWidth; i++) {
      for (int j =-sensorWidth; j < sensorWidth; j++) {
        if (withinResidueBounds(row+j, col+i)) {
          average += residue[row+j][col+i];
          totalCounted += 1;
        }
      }
    }

    average = average - residue[row][col];
    totalCounted = totalCounted - 1;
    average = average/totalCounted;
    return average;
  }


  /*
  checks if given vector is within bounds
   */
  private boolean withinBounds(PVector v) {
    if (v.x - border < 0 || v.x + border > width || v.y - border < 0 || v.y + border > height) {
      return false;
    }
    return true;
  }

  /*
  random angle that sways for intersting effects
   */
  private float rAngle() {
    return random(TWO_PI)* 0.015;
  }
}
