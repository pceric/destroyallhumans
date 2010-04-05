package controlP5;

import processing.core.PFont;

/**
 * ControlFont is a container for a PFont that
 * can be used for customizing the font of a label.
 * Fonts other than the pixel fonts provided by
 * ControlP5 can for now only be used for TextLabels
 * and Controller Labels. Textarea and Textfield are
 * not supported.
 * 
 * @author andreas
 * 
 */
public class ControlFont {

	protected int fontSize;

	protected PFont font;

	protected boolean isControlFont;

	protected boolean isSmooth;

	// textorize, a Ruby-based font rasterizer command line utility for Mac OS X
	// http://textorize.org/

	/**
	 * create a controlFont and pass a reference to
	 * a PFont. fontsize needs to be defined as second parameter.
	 * 
	 * @param theFont
	 * @param theFontSize
	 */
	public ControlFont(PFont theFont, int theFontSize) {
		font = theFont;
		fontSize = theFontSize;
		isControlFont = true;
	}
	
	public ControlFont(PFont theFont) {
		font = theFont;
		fontSize = font.getFont().getSize();
		isControlFont = true;
	}

	protected boolean isActive() {
		return isControlFont;
	}

	protected boolean setActive(boolean theFlag) {
		isControlFont = theFlag;
		return isControlFont;
	}

	/**
	 * @deprecated
	 * @param theFlag
	 */
	public void setSmooth(boolean theFlag) {
		System.out
		  .println("deprecated: ControlFont.setSmooth(). PFont.smooth not supported with processing 1.1+ anymore. Set the smooth flag in the constructor when creating a PFont.");
	}

	/**
	 * @deprecated
	 * @return
	 */
	public boolean isSmooth() {
		System.out
		  .println("deprecated: ControlFont.isSmooth(). PFont.smooth not supported with processing 1.1+ anymore. Set the smooth flag in the constructor when creating a PFont.");
		return true;
	}

	public PFont getPFont() {
		return font;
	}

	public int size() {
		return fontSize;
	}

	public void setSize(int theSize) {
		fontSize = theSize;
	}

}
