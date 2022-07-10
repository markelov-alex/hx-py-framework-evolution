# Эволюция игрового фреймворка. Клиент 9. UI

Пользуясь концепцией компонентов можно превращать любую фантазию художников в функциональные графические интерфейсы. Все, что нужно сделать дизайнеру — это превращать графику в мувиклипы и давать им определенные имена. Например, если в мувиклипе есть другой мувиклип с именем "checked", то первый может работать как чекбокс: при нажатии объект "checked" будет пропадать, а при повторном — снова появляться. Это может быть галочка, кружок, рамка — что угодно. Чтобы заставить работать графику в описанном ключе, создадим компонент CheckBox:

```haxe
class CheckBox extends Button
{
    // Settings
    public var checkedPath = "checked";
    public var uncheckedPath = "unchecked";
    // State
    private var checked:DisplayObject;
    private var unchecked:DisplayObject;
    public var isChecked(default, set):Bool = false;
    public function set_isChecked(value:Bool):Bool
    {
        if (isChecked != value)
        {
            isChecked = value;

            refreshChecked();

            // Dispatch
            if (value)
            {
                checkedSignal.dispatch(this);
            }
            else
            {
                uncheckedSignal.dispatch(this);
            }
            toggleSignal.dispatch(this);
        }
        return value;
    }
    public var checkedSignal(default, null) = new Signal<CheckBox>();
    public var uncheckedSignal(default, null) = new Signal<CheckBox>();
    public var toggleSignal(default, null) = new Signal<CheckBox>();

    override private function assignSkin():Void
    {
        super.assignSkin();

        checked = resolveSkinPath(checkedPath);
        unchecked = resolveSkinPath(uncheckedPath);

        // Apply
        refreshChecked();
    }
    private function refreshChecked():Void
    {
        if (checked != null)
        {
            checked.visible = isChecked;
        }
        if (unchecked != null)
        {
            unchecked.visible = !isChecked;
        }
    }
}
```

Все, что делает данный компонент — это показывание по очереди объектов "checked" и "unchecked" в зависимости от текущего значения isChecked, которое меняется при клике по скину. Если имена мувиклипов другие, то код можно подстроить под графику в свойствах checkedPath и uncheckedPath.

Данное решение можно шаблонно применять во всех аналогичных случаях в будущем. Есть области деятельности, где шаблонность вредна и даже губительна — например, в охоте и на войне. Но в программировании — все наоборот. Мы находим хорошее решение, проверяем его на деле, и если оно показывает себя хорошо, то используем его во всех похожих ситуациях. В разработке нужно много думать и принимать множество решений, и любая возможность сократить затраты времени на размышления оставляет больше сил на решение действительно новых интересных задач. К тому же, как и в вождении машины, все действия программиста должны быть предсказуемы и понятны. А для неочевидных мест всегда должны писаться комментарии.

В приведенном выше примере шаблонным является все. Прежде всего это упорядоченное расположение свойств и методов. Сначала идут настройки (Settings), потом свойства состояния (State). Свойства от методов отделяются конструктором. Публичные члены расположены перед приватными, перегруженные перед неперегруженными. Но главное — это чтобы очередность методов, по возможности, как можно больше совпадала с логическим их порядком. Если метод a() вызывает b(), а b() — c(), то и в тексте программы они должны располагаться так же. Тогда мы сможем читать код, почти как роман.

Другим типичным решением является метод refreshChecked(). Так как визуальное состояние чекбокса (un/checked.visible) нужно устанавливать в двух местах — сразу после парсинга скина и при каждом изменении isChecked — то этот код, во избежание дублирования, выносится в отдельный метод. Помимо проблемы дублирования, мы тут еще получаем специальную функцию, которую можно переопределять всякий раз, когда нужно расширить стандартную функциональность по отображению состояния "нажатости" кнопки.

Содержимое ```refreshChecked()``` можно сократить до двух строк, если, как мы это уже делали раньше, вместо ссылок на DisplayObject использовать компоненты. Так как скрывать и показывать объекты — функция довольно распространенная, то ее можно включить в базовый класс Component:

```haxe
class Component
{
    public var visible(default, set):Null<Bool>;
    public function set_visible(value:Null<Bool>):Null<Bool>
    {
        if (visible != value)
        {
            visible = value;

            refreshVisible();
        }
        return value;
    }
    //...
    private function assignSkin():Void
    {
        //...
        // Apply
        refreshVisible();
    }
    private function refreshVisible():Void
    {
        if (skin == null)
        {
            return;
        }
        if (visible == null)
        {
            // Set visible by skin
            visible = skin.visible;
        }
        else
        {
            // Set visible to skin
            skin.visible = visible;
        }
    }
}
class CheckBox extends Button
{
    //...
    override private function assignSkin():Void
    {
        super.assignSkin();

        checked = new Component();
        checked.skinPath = checkedPath;
        addChild(checked);
        unchecked = new Component();
        unchecked.skinPath = uncheckedPath;
        addChild(unchecked);

        // Apply
        refreshChecked();
    }
    private function refreshChecked():Void
    {
        checked.visible = isChecked;
        unchecked.visible = !isChecked;
    }
}
```

Тут мы снова использоваль refresh-метод + свойство. Начальное значение, если оно не установлено явно в коде, берется из скина.

Еще более полезное свойство, которого пока не хватает — это isEnabled. Разместив его в Component, мы сразу получаем возможность отключать любой компонент, который уже существует или которой только будет когда-либо написан:

```haxe
class Component
{
    public var isEnabled(default, set):Bool = true;
    public function set_isEnabled(value:Bool):Bool
    {
        if (isEnabled != value)
        {
            isEnabled = value;

            refreshEnabled();
        }
        return value;
    }
    //...
    private function assignSkin():Void
    {
        //...
        // Apply
        refreshEnabled();
    }
    private function refreshEnabled():Void
    {
        // Disable mouse for a skin
        if (interactiveObject != null)
        {
            interactiveObject.mouseEnabled = isEnabled;
        }
    }
}
```

Установление ```isEnabled=false``` делает объект некликабельным. Но если простой некликабельности мало, то добавляйте проверку ```if (!isEnabled) return;``` во всех методах, где ваш компонент выполняет какое-либо действие или реагирует на событие. Метод ```refreshEnabled()``` может быть использован для добавления эффекта затемнения при отключении компонента (отображение состояния disabled).

Также отключение компонента должно отключать все его дочерние элементы. Мы не можем для каждого потомка просто присваивать родительский isEnabled (```child.isEnabled = isEnabled```), т.к. это перетрет их текущее значение. Одни из них могут уже быть отключены по разным причинам, а другие — включены. Если установить родильское значение, они все станут или вчключенными или отключенными, и их предыдущее значение не восстановить.

Поэтому мы ```isEnabled``` разбиваем на два свойства: собственный ```isEnabled``` и родительский ```isParentEnabled```. Свойство ```isParentEnabled``` проходит по всем предкам вплоть до корневого, и если оно false, то и геттер isEnabled вернет false:

```haxe
class Component
{
    @:isVar public var isEnabled(get, set):Bool = true;
    public function get_isEnabled():Bool
    {
        return isEnabled && isParentEnabled;
    }
    public function set_isEnabled(value:Bool):Bool
    {
        if (isEnabled != value)
        {
            isEnabled = value;

            refreshEnabled();
        }
        return value;
    }
    /**
     * Disabling all children on isEnabled = false.
     */
    @:isVar public var isParentEnabled(default, set):Bool = true;
    public function set_isParentEnabled(value:Bool):Bool
    {
        if (isParentEnabled != value)
        {
            isParentEnabled = value;

            // Set isParentEnabled recursively
            refreshEnabled();
        }
        return value;
    }
    //...
    private function assignSkin():Void
    {
        //...
        // Apply
        refreshEnabled();
    }
    private function refreshEnabled():Void
    {
        // (Optimization to call getter only once)
        var isEnabled = this.isEnabled;
        // Disable mouse for a skin
        if (interactiveObject != null)
        {
            interactiveObject.mouseEnabled = isEnabled;
        }
        // Set isParentEnabled recursively
        if (isParentEnabled || !isEnabled)
        {
            for (child in children)
            {
                child.isParentEnabled = isEnabled;
            }
        }
    }
}
```

Еще всеобщностью класса Component при работе с графикой можно воспользоваться для округления координат. Дробные свойства x и y могут включать сглаживание (smoothing) и объект будет выглядеть немного размытым (blurred). Сделав это в коде, мы снимаем с дизайнеров обязанность следить, чтобы координаты всех объекты в исходниках (.fla) не имели дробных частей.

```haxe
class Component
{
    public var isFixBlurring = true;
    //...
    private function assignSkin():Void
    {
        //...
        if (isFixBlurring)
        {
            skin.x = Math.round(skin.x);
            skin.y = Math.round(skin.y);
        }
    }
}
```

Говоря о практических примерах компонентов, невозможно обойти стороной такой UI-элемент как RadioButton. Радиобаттон — это такая разновидность чекбокс, которая зависит от состояния других чекбоксов в группе. Поэтому логично наследовать его от уже готового CheckBox.

```haxe
class RadioButton extends CheckBox
{
    // State
    private var isClicking = false;

    override public function set_isChecked(value:Bool):Bool
    {
        if (isClicking && isChecked && !value)
        {
            // Can not uncheck by clicking
            return isChecked;
        }
        if (value && isChecked != value && parent != null)
        {
            // Uncheck other radio buttons in the group
            for (child in parent.children)
            {
                var radioButton = Std.downcast(child, RadioButton);
                if (radioButton != null && radioButton != this)
                {
                    radioButton.isChecked = false;
                }
            }
        }
        return super.set_isChecked(value);
    }
    override private function skin_clickHandler(event:MouseEvent):Void
    {
        isClicking = true;
        super.skin_clickHandler(event);
        isClicking = false;
    }
}
```

В качестве группы используется просто ближайший родительский компонент (parent). То есть все радиокнопки, созданные в одном компоненте, уже априори сгруппированы между собой. А если их нужно разбить еще на несколько групп, то можно просто использовать обычный Component: ```radioGroup = new Component(); radioGroup.addChild(radioButton1);```.

Ну и, конечно, как обойтись без текстовых меток:

```haxe
class Label extends Component
{
    // State
    private var textField:TextField;
    public var text(default, set):String;
    public function set_text(value:String):String
    {
        if (text != value)
        {
            text = value;
            refreshText();
        }
        return value;
    }

    override private function assignSkin():Void
    {
        super.assignSkin();
        // Parse
        textField = Std.downcast(skin, TextField);
        if (textField != null)
        {
            textField.type = TextFieldType.DYNAMIC;
            textField.mouseEnabled = false;
            initialTextColor = textField.textColor;
        }
        // Apply
        refreshText();
    }
    override private function unassignSkin():Void
    {
        textField = null;
        super.unassignSkin();
    }
    private function refreshText():Void
    {
        if (textField != null)
        {
            textField.text = new UTF8String(actualText);
        }
    }
}
```

В таком состоянии использование компонента может быть удобно, только если нам влом добавлять всякий раз проверку ```if (textField != null)```, когда мы обращаемся к свойствам textField (потому что ничего другого класс пока не делает). Для примера, добавим метку в уже имеющийся у нас компонент кнопки:

```haxe
class Button extends Component
{
    // Settings
    public var captionLabelPath = "captionLabel";
    // State
    private var captionLabel:Label;
    @:isVar public var caption(get, set):String;
    public function get_caption():String
    {
        return captionLabel.text;
    }
    public function set_caption(value:String):String
    {
        return captionLabel.text = value;
    }
    //...
    public function new()
    {
        super();
        captionLabel = new Label();
        captionLabel.skinPath = captionLabelPath;
        addChild(captionLabel);
    }
    //...
}
```

Но существует и более весомая причина создавать такие чисто символические компоненты. Это возможность в любой момент добавить в него функциональность, так что она мгновенно распространится повсюду, где этот класс используется. Более того, новую фичу (feature) можно отладить на одном проекте, и только потом внедрять на других, которые используют эту же библиотеку. Другими словами, можно создать каркас из пустых компонентов для всего приложения, а потом постепенно наполнять его функционалом.

В дальнейшем, когда проект будет готов, компоненты будут продолжать насыщаться функциями из других проектов. Так что использование их становится удобным способом обмена лучшими практиками между разными командами. Это экономит кучу времени на разработке вещей, которые были уже разработаны другими. Многие менеджеры мечтают о синергии (в действительности, о ней не мечтают только те, кто уже отчаялся ее добиться), но не многие подозревают, что для этого нужно не так уж много: общая библиотека, простая концепция компонентов и дисциплина программистов в соблюдении принятых заранее конвенций по написанию кода.

Ну это мы что-то отвлеклись. Вернемся к нашей текстовой метке. Добавим в нее для примера пару полезных функций: автоматический перевод в верхний/нижний регистр и цвет текста. Т.к. заданное значение text отличается от отображаемого, которое генерируется автоматически, для получения последнего добавим геттер ```actualText```:

```haxe
class Label extends Component
{
    // State
    private var textField:TextField;
    public var text(default, set):String;
    public function set_text(value:String):String
    {
        if (text != value)
        {
            text = value;
            refreshText();
        }
        return value;
    }
    public var actualText(default, null):String;
    public var isUpperCase(default, set):Bool = false;
    public function set_isUpperCase(value:Bool):Bool
    {
        if (isUpperCase != value)
        {
            isUpperCase = value;
            refreshText();
        }
        return value;
    }
    public var isLowerCase(default, set):Bool = false;
    public function set_isLowerCase(value:Bool):Bool
    {
        if (isLowerCase != value)
        {
            isLowerCase = value;
            refreshText();
        }
        return value;
    }
    private var initialTextColor:Int = -1;
    @:isVar public var textColor(default, set):Null<Int> = null;
    public function set_textColor(value:Null<Int>):Null<Int>
    {
        if (textColor != value)
        {
            textColor = value;
            refreshColor();
        }
        return textColor;
    }

    override private function assignSkin():Void
    {
        super.assignSkin();
        // Parse
        textField = Std.downcast(skin, TextField);
        if (textField != null)
        {
            textField.type = TextFieldType.DYNAMIC;
            textField.mouseEnabled = false;
            initialTextColor = textField.textColor;
        }
        // Apply
        refreshText();
        refreshColor();
    }
    override private function unassignSkin():Void
    {
        textField = null;
        super.unassignSkin();
    }
    private function refreshText():Void
    {
        actualText = lang.get(text);
        if (isUpperCase)
        {
            actualText = actualText.toUpperCase();
        }
        else if (isLowerCase)
        {
            actualText = actualText.toLowerCase();
        }

        if (textField != null && actualText != null)
        {
            textField.text = new UTF8String(actualText);
        }
    }
    private function refreshColor():Void
    {
        if (textField != null)
        {
            textField.textColor = if (textColor != null && textColor >= 0)
                textColor else initialTextColor;
        }
    }
}
```

Так, а что если добавить в ```Label``` локализацию. Допустим, мы все текстовые метки в приложении обернули в компонент ```Label```, тогда у нас сразу появится автоматическая локализация во всей игре. Точно так же можно добавить звук клика для всех кнопок в проекте, изменив один класс ```Button```. Видите? Это то, о чем я говорил. Мы "вливаем" функционал в один класс, а он (функционал) распространяется по всем проектам, которые это класс используют.

Что касается локализации и звуков, то тут мы уже плавно переходим к менеджерам. А это уже немного другая история...

[Исходники](https://gitlab.com/markelov-alex/hx-py-framework-evolution/-/tree/main/b_coloring/client_haxe/src/v3/)

[< Назад](01_client_80.md)  |  [Начало](00_intro_01.md)  |  [Вперед >](01_client_10.md)
