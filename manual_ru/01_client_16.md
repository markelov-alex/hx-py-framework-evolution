# Эволюция игрового фреймворка. Клиент 16. Модель

В [прошлый раз](01_client_15.md) мы встали перед необходимостью выделить из логики отображения логику предметной области. Так, мы сможем их, во-первых, отдельно развивать и, во-вторых, иметь возможность сочетать в любых комбинациях. Если два класса реализуют один интерфейс, то они становятся взаимозаменяемыми имплементациями данного интерфейса и могут использоваться один вместо другого (см. [полиморфизм](https://en.wikipedia.org/wiki/Polymorphism_(computer_science)), [паттерн стратегия](https://en.wikipedia.org/wiki/Strategy_pattern)).

В простейшем случае, как в нашей одевалке, вся логика состоит пока что только из состояния, то есть данных, и методов манипулирования этими данными. Вместе они моделируют реальность, а именно, процесс примерки шмоток. Отсюда и название для такого рода классов — модель (model).

Если кратко, то модель тут — это динамическая структура данных, которая содержит также логику и правила по управлению этими данными.

Создадим модель для одевалки:

```haxe
class DresserModel
{
    // State
    public var state(default, set):Array<Int> = [];
    public function set_state(value:Array<Int>):Array<Int>
    {
        if (value == null)
        {
            value = [];
        }
        if (!ArrayUtil.equal(state, value))
        {
            state = value;
            stateChangeSignal.dispatch(value);
        }
        return value;
    }
    public var stateChangeSignal(default, null) = new Signal<Array<Int>>();
    public var itemChangeSignal(default, null) = new Signal2<Int, Int>();

    public function changeItem(index:Int, value:Int):Void
    {
        if (state[index] != value)
        {
            state[index] = value;
            itemChangeSignal.dispatch(index, value);
        }
    }
}
class ArrayUtil
{
    public static function equal(arr1:Array<Dynamic>, arr2:Array<Dynamic>):Bool
    {
        if (arr1 == null || arr2 == null)
        {
            return arr1 == arr2;
        }
        if (arr1.length != arr2.length)
        {
            return false;
        }
        for (i in 0...arr1.length)
        {
            if (arr1[i] != arr2[i])
            {
                return false;
            }
        }
        return true;
    }
}
```

Вот как, соответственно, изменится Dresser:

```haxe
class Dresser extends Component
{
    // Settings
    public var itemPathPrefix = "item";
    public var prevButtonPathPrefix = "prevButton";
    public var nextButtonPathPrefix = "nextButton";
    // State
    private var screens:Screens;
    private var model:DresserModel;
    private var closeButton:Button;
    private var items:Array<MovieClip>;
    private var prevButtons:Array<Button>;
    private var nextButtons:Array<Button>;

    override private function init():Void
    {
        super.init();
        screens = ioc.getSingleton(Screens);
        model = ioc.create(DresserModel);
        model.stateChangeSignal.add(model_stateChangeSignalHandler);
        model.itemChangeSignal.add(model_itemChangeSignalHandler);
        closeButton = createComponent(Button);
        closeButton.skinPath = "closeButton";
        closeButton.clickSignal.add(closeButton_clickSignalHandler);
        addChild(closeButton);
    }
    override public function dispose():Void
    {
        super.dispose();
        if (model != null)
        {
            model.stateChangeSignal.remove(model_stateChangeSignalHandler);
            model.itemChangeSignal.remove(model_itemChangeSignalHandler);
            model = null;
        }
        screens = null;
    }
    override private function assignSkin():Void
    {
        super.assignSkin();

        var itemPaths = cast resolveSkinPathPrefix(itemPathPrefix);
        items = [for (path in itemPaths) resolveSkinPath(path)];
        var prevButtonPaths = cast resolveSkinPathPrefix(prevButtonPathPrefix);
        var nextButtonPaths = cast resolveSkinPathPrefix(nextButtonPathPrefix);
        for (item in items)
        {
            item.stop();
            // Make items draggable
            var drag = new Drag();
            drag.skin = item; // Set skin directly
            addChild(drag);
        }
        prevButtons = [];
        for (path in prevButtonPaths)
        {
            var prevButton = new Button();
            prevButton.skinPath = path;
            prevButton.clickSignal.add(prevButton_clickSignalHandler);
            addChild(prevButton); // Skin will be set here
            prevButtons.push(prevButton);
        }
        nextButtons = [];
        for (path in nextButtonPaths)
        {
            var nextButton = new Button();
            nextButton.skinPath = path;
            nextButton.clickSignal.add(nextButton_clickSignalHandler);
            addChild(nextButton); // Skin will be set here
            nextButtons.push(nextButton);
        }
        // Apply
        refreshState();
    }
    override private function unassignSkin():Void
    {
        items = null;
        prevButtons = null;
        nextButtons = null;
        super.unassignSkin();
    }
    private function switchItem(index:Int, step:Int=1):Void
    {
        var item = items[index];
        if (item != null)
        {
            var value = (item.currentFrame + step) % item.totalFrames;
            value = value < 1 ? item.totalFrames - value : value;
            model.changeItem(index, value);
        }
    }
    private function refreshState():Void
    {
         for (i => v in model.state)
         {
             var item = items[i];
             if (item != null)
             {
                 item.gotoAndStop(v);
             }
         }
    }
    private function closeButton_clickHandler(target:Button):Void
    {
        screens.open(Menu2);
    }
    private function prevButton_clickSignalHandler(target:Button):Void
    {
        var index = prevButtons.indexOf(target);
        switchItem(index, -1);
    }
    private function nextButton_clickSignalHandler(target:Button):Void
    {
        var index = nextButtons.indexOf(target);
        switchItem(index, 1);
    }
    private function model_stateChangeSignalHandler(value:Array<Int>):Void
    {
        refreshState();
    }
    private function model_itemChangeSignalHandler(index:Int, value:Int):Void
    {
        var item = items[index];
        if (item != null)
        {
            item.gotoAndStop(value);
        }
    }
}
```

До этого модель и отображение были слиты в одном отображении. Состояние (данные) помещались в мувиклипе в свойстве currentFrame, которое можно было изменить методом gotoAndStop(). А теперь и currentFrame, и gotoAndStop() остались на месте, но они больше не играют той роли. Все операции с данными происходят в модели, а мувиклип лишь отображает ее изменения. То есть мувиклипа может и не быть, а логика игры будет продолжать работать. Только вот пользователь в этом случае ничего не увидит.

Выделив модель из отображения, мы не только разделили приложение на две физически независимых части, но и получили еще пару преимуществ в нагрузку. Первое — мы теперь можем работать с данными без воздействия на отображение. Второе — мы можем одну модель применить к нескольким компонентам. Тогда, оперируя всего одной моделью, мы сможем воздействовать сразу на несколько компонентов отображения в разных частях приложения. Например, одни и те же данные о пользователе бывает нужно показывать в верхней панели состояния игры, возле аватарки на карте в лобби и в диалоге подробной информации об игроке.

Разделение логики на модель (model) и отображение (view) является первым шагом на пути к популярному паттерну MVC, разные вариации которого мы рассмотрим в следующем материале.

[Исходники](https://gitlab.com/markelov-alex/hx-py-framework-evolution/-/tree/main/f_models/client_haxe/src/)

[< Назад](01_client_15.md)  |  [Начало](00_intro_01.md)  |  [Вперед >](01_client_17.md)
