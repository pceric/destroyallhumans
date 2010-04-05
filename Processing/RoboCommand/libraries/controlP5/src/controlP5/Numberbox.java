package controlP5;

import processing.core.PApplet;

/**
 * press the mouse inside a numberbox and move up and down to
 * change the values of a numberbox.
 * 
 * by default you increase and decrease numbers by dragging the mouse up and
 * down. use setDirection(Controller.HORIZONTAL) to change the mouse control to
 * left and right.
 * Why do I get -1000000 as initial value when creating a numberbox
 * without a default value?
 * the value of a numberbox defaults back to its minValue, which is
 * -1000000. either use a default value or link a variable to the
 * numberbox - this is done by giving a float or int variable the
 * same name as the numberbox.
 * 
 * Use setMultiplier(float) to change the sensitivity of values
 * increasing/decreasing, by default the multiplier is 1.
 * 
 * 
 * @example ControlP5numberbox
 * @nosuperclasses Controller
 * @related Controller
 */
public class Numberbox extends Controller {

	protected int cnt;

	protected boolean isActive;

	public static int LEFT = 0;

	public static int UP = 1;

	public static int RIGHT = 2;

	public static int DOWN = 3;

	protected int _myNumberCount = VERTICAL;

	protected float _myMultiplier = 1;

	protected static int autoWidth = 100;

	protected static int autoHeight = 15;

	protected CVector3f autoSpacing = new CVector3f(10, 20, 0);

	/**
	 * 
	 * 
	 */

	/**
	 * 
	 * 
	 * @invisible
	 * @param theControlP5
	 *        ControlP5
	 * @param theParent
	 *        Tab
	 * @param theName
	 *        String
	 * @param theDefaultValue
	 *        float
	 * @param theX
	 *        int
	 * @param theY
	 *        int
	 * @param theWidth
	 *        int
	 * @param theHeight
	 *        int
	 */
	public Numberbox(
	  ControlP5 theControlP5,
	  Tab theParent,
	  String theName,
	  float theDefaultValue,
	  int theX,
	  int theY,
	  int theWidth,
	  int theHeight) {
		super(theControlP5, theParent, theName, theX, theY, theWidth, theHeight);
		_myValue = theDefaultValue;
		_myValueLabel = new Label("" + _myValue, theWidth, 12, color.colorValue);
		_myMin = -1000000;
		_myMax = 1000000;
	}

	/**
	 * @see ControllerInterfalce.updateInternalEvents
	 * @invisible
	 */
	public void updateInternalEvents(PApplet theApplet) {
		if (isActive) {
			if (!ControlP5.keyHandler.isAltDown) {
				if (_myNumberCount == VERTICAL) {
					setValue(_myValue + (_myControlWindow.mouseY - _myControlWindow.pmouseY) * _myMultiplier);
				} else {
					setValue(_myValue + (_myControlWindow.mouseX - _myControlWindow.pmouseX) * _myMultiplier);
				}
			}
		}
	}

	/**
	 * @invisible
	 * @param theApplet
	 *        PApplet
	 */
	public void draw(PApplet theApplet) {
		theApplet.pushMatrix();
		theApplet.translate(position().x(), position().y());
		theApplet.stroke(color.colorForeground);
		theApplet.fill(color.colorBackground);
		theApplet.rect(0, 0, width, height);
		theApplet.noStroke();
		_myCaptionLabel.draw(theApplet, 4, height + 4);
		_myValueLabel.draw(theApplet, 4, 4);
		theApplet.popMatrix();
	}

	/**
	 * @invisible
	 */
	public void mousePressed() {
		isActive = true;
	}

	/**
	 * @invisible
	 */
	public void mouseReleased() {
		isActive = false;
	}

	public void mouseReleasedOutside() {
		mouseReleased();
	}

	public void setMultiplier(float theMultiplier) {
		_myMultiplier = theMultiplier;
	}

	public float multiplier() {
		return _myMultiplier;
	}

	/**
	 * set the value of the numberbox.
	 * 
	 * @param theValue
	 *        float
	 */
	public void setValue(float theValue) {
		_myValue = theValue;
		_myValue = Math.max(_myMin, Math.min(_myMax, _myValue));
		broadcast(FLOAT);
		_myValueLabel.set(adjustValue(_myValue));
	}

	/**
	 * set the direction for changing the numberbox value when dragging the mouse.
	 * by default this is up/down (VERTICAL), use
	 * setDirection(Controller.HORIZONTAL) to change to
	 * left/right or back with setDirection(Controller.VERTICAL).
	 * 
	 * @param theValue
	 */
	public void setDirection(int theValue) {
		if (theValue == HORIZONTAL || theValue == VERTICAL) {
			_myNumberCount = theValue;
		} else {
			_myNumberCount = VERTICAL;
		}
	}

	public void update() {
		setValue(_myValue);
	}

	public Controller linebreak() {
		controlP5.linebreak(this, true, autoWidth, autoHeight, autoSpacing);
		return this;
	}

	/**
	 * @invisible
	 * @param theElement
	 *        ControlP5XMLElement
	 */
	public void addToXMLElement(ControlP5XMLElement theElement) {
		theElement.setAttribute("type", "numberbox");
	}

}
