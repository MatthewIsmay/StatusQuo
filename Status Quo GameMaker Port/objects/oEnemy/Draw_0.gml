if (inDarkness())
{
	draw_set_color(LIGHT_COLOR);
}
else
{
	draw_set_color(DARK_COLOR);	
}
draw_rectangle((x-4), (y+4), (x+4), (y-4), false);
draw_set_color(c_white);