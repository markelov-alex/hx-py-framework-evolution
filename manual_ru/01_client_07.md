# Эволюция игрового фреймворка. Клиент 7. Диалоги

Аналогично скринам можно реализовать и диалоги. Диалоги отличаются от скринов только тем, что за раз можно показывать только один скрин, а диалогов — сколько угодно. Поэтому для них нужно создать отдельный метод — ```openDialog()```. Диалоги бывают двух типов: глобальные и локальные. Первые добавляются в компонент Screens, вторые — в текущий скрин. Вместе со скрином они и уничтожатся, а глобальные так и будут висеть, пока их не закроешь вручную. Еще, чтобы новый скрин не перекрывал глобальные диалоги, сразу после создания его скин перемещается в самый низ списка отображения (display list). Вот, собственно, и вся система диалогов — достаточно всего одного метода:

```haxe
class Screens extends Component
{
    // State
    private var currentScreen:Component;

    public function open(screenClass:Class<Dynamic>):Void
    {
        // Dispose current
        if (currentScreen != null)
        {
            currentScreen.dispose();
        }
        // Create new
        currentScreen = Type.createInstance(screenClass, []);
        addChild(currentScreen); // Skin will be created here
        // Move under all global dialogs
        // (temporary solution: only if skin is already loaded and created instantly)
        if (currentScreen.skin != null && currentScreen.skin.parent != null)
        {
            currentScreen.skin.parent.addChildAt(currentScreen.skin, 0);
        }
    }
	// Any component with assetName set can be opened as a dialog
	public function openDialog(dialogClass:Class<Dynamic>, isLocal=true):Component
	{
		var target:Component = Type.createInstance(dialogClass, []);
        var container = isLocal ? currentScreen : this;
        if (container != null)
        {
            container.addChild(target); // Skin will be created here
        }
		return dialog;
	}
    //...
}
```

В качестве диалога сгодится любой компонент с заданным ```assetName```. Но так как большинство диалогов обычно имеет кнопку закрытия, может быть модальными и масштабируемыми, то, чтобы не дублировать один и тот же код в разных классах, полезно вынести все подобные стандартные функции в отдельный базовый класс Dialog. Система диалогов может существовать и без него, но с ним удобнее.

```haxe
class Dialog extends Component
{
	// Settings
	public var closeButtonPath:String = "closeButton";
	public var modalPath:String = "modal";
	public var isCloseOnClickOutside:Bool = false;
	public var isModal(default, set):Bool = true;
	public function set_isModal(value:Bool):Bool
	{
		if (isModal != value)
		{
			isModal = value;
            refreshModal();
		}
		return value;
	}
	// State
	private var closeButton:Button;
	private var resizer:StageResizer;
	private var modal:DisplayObject;
	// Signals
	public var closeSignal(default, null) = new Signal<Dialog>();

	public function new()
	{
		super();
		closeButton = new Button();
		closeButton.skinPath = closeButtonPath;
		closeButton.clickHandler = closeButton_clickHandler;
		addChild(closeButton);
		resizer = new StageResizer();
		addChild(resizer);
	}
	override public function dispose():Void
	{
		super.dispose();
		closeSignal.dispose();
	}
	override private function assignSkin():Void
	{
		super.assignSkin();
		modal = resolveSkinPath(modalPath);
		if (modal != null)
		{
			modal.addEventListener(MouseEvent.CLICK, modal_clickHandler);
		    refreshModal();
		}
	}
	override private function unassignSkin():Void
	{
		if (modal != null)
		{
			modal.removeEventListener(MouseEvent.CLICK, modal_clickHandler);
		    modal = null;
		}
		super.unassignSkin();
	}
	public function close():Void
	{
		closeSignal.dispatch(this);
		dispose();
	}
	private function refreshModal():Void
	{
		if (modal != null)
		{
            modal.visible = isModal;
		}
	}
	private function closeButton_clickHandler(target:Button):Void
	{
		close();
	}
	private function modal_clickHandler(event:MouseEvent):Void
	{
		if (isCloseOnClickOutside)
		{
			close();
		}
	}
}
```

Класс Dialog — пример того, как несколько простых классов могут вместе составлять сложную функциональность и тем самым образовывать новую сущность. Сложное — это всего лишь сложенное из простых.

[Исходники](https://gitlab.com/markelov-alex/hx-py-framework-evolution/-/tree/main/e_dialogs/client_haxe/src/)

[< Назад](01_client_06.md)  |  [Начало](00_intro_01.md)  |  [Вперед >](01_client_08.md)
