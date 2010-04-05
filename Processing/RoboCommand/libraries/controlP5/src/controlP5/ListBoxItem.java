package controlP5;

public class ListBoxItem {
	protected String name;
	protected String text;
	protected int value;
	protected boolean isActive;
	protected CColor color;
	protected int id = -1;
	ListBoxItem(
			ListBox theListBox,
	        String theName,
	        int theValue) {
		name = theName;
		text = theName;
		value = theValue;
		color = new CColor(theListBox.color);
	}
	
	public CColor getColor() {
		return color;
	}
	
	public void setColor(CColor theColor) {
		color.set(theColor);
	}
	
	public void setId(int theId) {
		id = theId;
	}
	public int getId() {
		return id;
	}
}