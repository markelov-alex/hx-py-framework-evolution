package v1.menu;

import v0.menu.MenuScreen as MenuScreen0;

/**
 * MenuScreen.
 * 
 */
class MenuScreen extends MenuScreen0
{
	// Settings

	// State

	// Init

	public function new()
	{
		super();

		var mainMenu:MainMenu = Std.downcast(this.mainMenu, MainMenu);
		mainMenu.screenNames = [
			"Dressing 1", "Dressing 2", "Dressing 3",
			"Coloring 1", "Coloring 2", "Coloring 3"];
		mainMenu.roomNameByItemName = [
			"Dressing 1" => "dresser1",
			"Dressing 2" => "dresser2",
			"Dressing 3" => "dresser3",
			"Coloring 1" => "coloring1",
			"Coloring 2" => "coloring2",
			"Coloring 3" => "coloring3",
		];
	}

	// Methods
	
}
