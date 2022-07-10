# Эволюция игрового фреймворка. Клиент 3. Скин

В [прошлый раз](01_client_03.md) мы ввели концепцию компонентов как удобный способ добавлять логику к графике. В базовом классе Component есть свойство `skin`, в сеттере которого парсится новая графика при установке значения и удаляются все ссылки на нее — при удалении. Благодаря этому свойству в приложении можно менять графику GUI на лету, без перезагрузки, как в каком-нибудь Winamp'е.

Сама графика должна каким-то образом создаваться снаружи компонента, и сам компонент на это никак не влияет. Но так как мы твердо решили сделать всю логику приложения через компоненты, то и создание скинов должно осуществляться в тех же классах. Этим мы в данной статье и займемся.

## Новое свойство assetName

Если компонент сейчас станет создавать для себя мувиклип с графикой, то пользователь его не увидит, потому что его нужно сначала добавить на сцену. Чтобы было куда добавлять станем передавать в корневой компонент ссылку на Main (`this`), а там уже компоненты сами разберутся:

```haxe
class Main extends Sprite
{
    public function new()
    {
        super();
        new Dresser(this);
    }
}
class Dresser extends Component
{
    public function new(?skin:DisplayObject, ?assetName:String)
    {
        // Default
        assetName = assetName != null ? assetName : "dresser:AssetDresserScreen";
        // If assetName defined, then current given skin would be temporary for this component
        super(skin, assetName);
    }
    //...
}
class Component
{
    private var assetName:String;
    //...
    public function new(?skin:DisplayObject, ?assetName:String)
    {
        this.skin = skin;
        if (assetName != null) // To do not overwrite default value with null
        {
            this.assetName = assetName;
        }
        createSkin();
    }
    private function createSkin():Void
    {
        if (assetName == null)
        {
            return;
        }
        var mc = Assets.getMovieClip(assetName);
        if (mc != null && container != null)
        {
            // Add to current temporary skin
            container.addChild(mc);
            // Set real component's skin
            skin = mc;
        }
    }
    //...
}
```

В конструкторе Component мы получаем скин по умолчанию и имя для создания нового скина. Если это имя определено, то скин по умолчанию используется как контейнер для нового скина.

Так компонент становится полностью самодостаточным. Теперь он полностью определяется самим собой, а не снаружи. Если мы захотим создать `Dresser` с другой графикой, мы можем передать ему в конструктор нужный `assetName` или создать подкласс с другим `assetName` по умолчанию:

```haxe
class MyDresser extends Dresser
{
    public function new(?skin:DisplayObject, ?assetName:String)
    {
        assetName = assetName != null ? assetName : "dresser:AssetDresserScreen2";
        super(skin, assetName);
    }
    //...
}
```

## Компонент для кнопки

Не все скины попадают в компоненты прямо из ассетов. Большинство компонентов получает скины после парсинга одного из корневых мувиклипов. Создадим для примера один из таких компонентов. Для этого добавим в `AssetDresserScreen` и класс `Dresser` кнопку-крестик в углу экрана с именем closeButton, чтобы по нажатии на нее можно было выйти из игры в меню:

```haxe
class Dresser extends Component
{
    //...
    private var closeButton:InteractiveObject;
    override private function assignSkin():Void
    {
        super.assignSkin();
        //...
        closeButton = container.getChildByName("closeButton");
        if (closeButton != null)
        {
            closeButton.addEventListener(MouseEvent.CLICK, closeButton_clickHandler);
        }
    }
    override private function unassignSkin():Void
    {
        if (closeButton != null)
        {
            closeButton.addEventListener(MouseEvent.CLICK, closeButton_clickHandler);
            closeButton = null;
        }
        //...
        super.unassignSkin();
    }
    private function closeButton_clickHandler(event:MouseEvent):Void
    {
        //todo
    }
}
```

Так как мы пишем обобщенный код, то он должен работать без ошибок во всех ситуациях. Например, `closeButton` может быть, а может и не быть — в обоих случаях игра **не должна ломаться**. Поэтому мы должны всегда добавлять проверку на то, что полученный объект не `null`. В результате код в `assignSkin()` занимает не 2 строки, а 5. А когда таких объектов много, это *выглядит еще хуже*.

Поэтому почему бы нам не создать специальный компонент для кнопки, к которому мы могли бы подписываться всегда — вне зависимости от того, есть для него скин или нет.

```haxe
class Button extends Component
{
    public var clickHandler:(event:MouseEvent)->Void;
    override private function assignSkin():Void
    {
        super.assignSkin();
        if (sprite != null)
        {
            // Make hand cursor on mouse over
            sprite.buttonMode = true;
        }
        if (interactiveObject != null)
        {
            interactiveObject.addEventListener(MouseEvent.CLICK, interactiveObject_clickHandler);
        }
    }
    override private function unassignSkin():Void
    {
        if (interactiveObject != null)
        {
            interactiveObject.addEventListener(MouseEvent.CLICK, interactiveObject_clickHandler);
        }
        super.unassignSkin();
    }
    private function interactiveObject_clickHandler(event:MouseEvent):Void
    {
        if (clickHandler != null)
        {
            clickHandler(event);
        }
    }
}
class Dresser extends Component
{
    //...
    private var closeButton:Button;
    public function new(?skin:DisplayObject, ?assetName:String)
    {
        closeButton = new Button();
        closeButton.clickHandler = closeButton_clickHandler;
        super(skin, assetName);
    }
    override private function assignSkin():Void
    {
        super.assignSkin();
        //...
        closeButton.skin = container.getChildByName("closeButton");
    }
    override private function unassignSkin():Void
    {
        closeButton.skin = null;
        //...
        super.unassignSkin();
    }
    private function closeButton_clickHandler(event:MouseEvent):Void
    {
        //todo
    }
}
```

Конечно, одной проверки на `null` еще недостаточно, чтобы создавать для этого отдельный класс, но даже тут мы в очередной раз убеждаемся в небесполезности концепции компонентов. Даже если компонент не совершает практически никаких действий, использование его все равно делает код более лаконичным и красивым. Ниже, когда мы внесем еще кое-какие улучшения, эта мысль станет еще более очевидной.

## Свойство skinName

Теперь можно процесс установки скинов для вложенных компонентов автоматизировать. Для этого добавим свойство `skinName`, чтобы родительский компонент знал, какой скин его дочерним элементам нужен. Строки `closeButton.skin = container.getChildByName("closeButton");` и `closeButton.skin = null;`, соответственно, убираются:

```haxe
class Dresser extends Component
{
    //...
    private var closeButton:Button;
    public function new(?skin:DisplayObject, ?assetName:String)
    {
        closeButton = new Button();
        closeButton.skinName = "closeButton";
        closeButton.clickHandler = closeButton_clickHandler;
        children.push(closeButton); // See below
        super(skin, assetName);
    }
    private function closeButton_clickHandler(event:MouseEvent):Void
    {
        //todo
    }
}
class Component
{
    private var skinName:String = "";
    private var children:Array<Component> = [];
    //...
    private function assignSkin():Void
    {
        // Set skin for children using skinName
        for (child in children.copy())
        {
            child.skin = container.getChildByName(child.skinName);
        }
    }
    private function unassignSkin():Void
    {
        // Clear all children components
        for (child in children.copy())
        {
            child.skin = null;
        }
    }
}
```

Уже неплохо. Но сделаем еще пару улучшений.

Во-первых, структура графики, которую нам предоставляет художник, не обязательно будет совпадать со структурой нашего кода. Например, `skinName` для кнопки может быть и "closeButton", и "mainPanel.closeButton", и "mc.mainPanel.closeButton" и так далее. Вложенность мувиклипов друг в друга может понадобится, скажем, для того, чтобы наложить эффект на объект или сгруппировать его с другим мувиклипами. Тогда нам придется вызывать `getChildByName()` больше одного раза, причем количество вызовов может варьироваться для разных версий графики. Т.е. это уже не `skinName`, а skinNamePath, или проще — `skinPath`. Чтобы получать скин по произвольному skinPath создадим специальный метод `resolveSkinPath()`, который будем использовать вместо `getChildByName()`.

Во-вторых, никто не мешает нам создавать мувиклипы по assetName и во вложенных компонентах. Объединить оба решения можно примерно так: если задан `assetName`, то создавать новый мувиклип, если нет — взять скин по пути `skinPath`:

```haxe
class Component
{
    private var skinPath:String = "";
    //...
    private function assignSkin():Void
    {
        // Set skin for children using skinPath or assetName
        for (child in children.copy())
        {
            if (child.assetName != null)
            {
                var mc = Assets.getMovieClip(child.assetName);
                container.addChild(mc);
                child.skin = mc;
            }
            else
            {
                child.skin = resolveSkinPath(child.skinPath);
            }
        }
    }
    //...
    private function resolveSkinPath(path:String, source=null):DisplayObject
    {
        if (path == null)
        {
            return null;
        }
        if (source == null)
        {
            source = container;
        }
        if (source == null || path == "")
        {
            return source;
        }
        var result:DisplayObject = null;
        var pathParts:Array<String> = path.split(".");
        var count = pathParts.length;
        for (i in 0...count)
        {
            if (source == null)
            {
                return null;
            }
            var name = pathParts[i];
            result = if (name == "parent") source.parent else source.getChildByName(name);
            if (result == null)
            {
                return null;
            }
            if (i < count - 1)
            {
                source = Std.downcast(result, DisplayObjectContainer);
            }
        }
        return result;
    }
}
```

Часть кода из `assignSkin()` уже существует в `createSkin()`. Неплохо было бы их объединить в одной функции, которая бы отвечала в целом за создание скина в компоненте. Но для этого, как мы убедимся ниже, нужна ссылка на родителя (свойство `parent`) и более сложная система вложенности компонентов. Созданием этой системы мы и займемся в [следующий раз](01_client_04.md).

[Исходники](https://gitlab.com/markelov-alex/hx-py-framework-evolution/-/tree/main/c_screens/client_haxe/src/v3)

[< Назад](01_client_02.md)  |  [Начало](00_intro_01.md)  |  [Вперед >](01_client_04.md)
