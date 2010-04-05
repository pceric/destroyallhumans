package controlP5;

import processing.core.PApplet;

public class TickMark implements CDrawable, ControlP5Constants {

	protected Controller _myParent;

	protected int _myLen = 4;

	protected TickMark(Controller theController) {
		_myParent = theController;
	}

	public void draw(PApplet theApplet) {
		draw(theApplet, HORIZONTAL);
	}

	public void draw(PApplet theApplet, int theDirection) {
		theApplet.pushMatrix();
		theApplet.stroke(255);
		switch (theDirection) {
			case (HORIZONTAL):
				theApplet.translate(0, 4);
				theApplet.line(0, 0, 0, _myLen);
				break;
			case (VERTICAL):
				theApplet.translate(-4, 0);
				theApplet.line(0, 0, _myLen, 0);
				break;
		}
		theApplet.popMatrix();
	}

	public void setLength(int theLength) {
		_myLen = theLength;
	}
}
