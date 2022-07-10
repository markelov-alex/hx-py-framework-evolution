# Эволюция игрового фреймворка. Клиент 2. Компоненты

Пока что [наше приложение](01_client_01.md) состоит только из одного класса Dresser (не считая чисто формального класса Main). И уже одного этого оказалось достаточно для целого игрового жанра (до какой степени все же игроки бывают неприхотливы). Однако, для приличной игры этого маловато. Как минимум нужен еще экран меню, в котором мы могли бы выбирать игру.

Допустим, у нас есть несколько скинов для одевалки, и мы хотим для всех них использовать один экземпляр класса логики Dresser. При смене мувиклипа все ссылки на старый должны удаляться, а на новый — добавляться. Для этого код парсинга графики вынесем из конструктора в сеттер:

```haxe
class Dresser
{
    //...
    public var mc(default, set):MovieClip;
    public function set_mc(value:MovieClip):MovieClip
    {
        if (mc != value)
        {
            // Unassign previous mc
            if (mc != null)
            {
                for (prevButton in prevButtons)
                {
                    prevButton.removeEventListener(MouseEvent.CLICK, prevButton_clickHandler);
                }
                for (nextButton in nextButtons)
                {
                    nextButton.removeEventListener(MouseEvent.CLICK, nextButton_clickHandler);
                }
                items = null;
                prevButtons = null;
                nextButtons = null;
             }

            mc = value;

            // Assign new mc
            if (mc != null)
            {
                items = cast resolveNamePrefix(itemNamePrefix);
                prevButtons = cast resolveNamePrefix(prevButtonNamePrefix);
                nextButtons = cast resolveNamePrefix(nextButtonNamePrefix);
                for (item in items)
                {
                    item.stop();
                }
                for (prevButton in prevButtons)
                {
                    prevButton.buttonMode = true;
                    prevButton.addEventListener(MouseEvent.CLICK, prevButton_clickHandler);
                }
                for (nextButton in nextButtons)
                {
                    nextButton.buttonMode = true;
                    nextButton.addEventListener(MouseEvent.CLICK, nextButton_clickHandler);
                }
            }
        }
        return value;
    }
    public function new(?mc:MovieClip)
    {
        super();
        this.mc = mc;
    }
    //...
}
```

Редкая игра может состоять только из одного класса. Мы же тут изобретаем общий подход для всех игр. Поэтому придумаем для примера функционал хотя бы еще на один класс. Два класса — это уже хоть какой-то материал для обобщения. Хм..., допустим, мы захотим двигать мышкой (dragging) одежду (создадим новый жанр — раздевалка). Не будем лепить новый код в классе Dresser, а сразу создадим отдельный класс Drag. Сделаем его по образцу Dresser, то есть с сеттером mc:

```haxe
class Drag
{
    private var stage:Stage;
    private var mouseDownX:Float;
    private var mouseDownY:Float;
    public var isDragging(default, null):Bool;

    public var mc(default, set):MovieClip;
    public function set_mc(value:MovieClip):MovieClip
    {
        if (mc != value)
        {
            // Unassign previous mc
            if (mc != null)
            {
                mc.removeEventListener(MouseEvent.MOUSE_DOWN, mc_mouseDownHandler);
                if (stage != null)
                {
                    stage.removeEventListener(MouseEvent.MOUSE_UP, stage_mouseUpHandler);
                    stage.removeEventListener(MouseEvent.MOUSE_MOVE, stage_mouseMoveHandler);
                }
            }

            mc = value;

            // Assign new mc
            if (mc != null)
            {
                stage = mc.stage;
                mc.addEventListener(MouseEvent.MOUSE_DOWN, skin_mouseDownHandler);
                if (stage != null)
                {
                    stage.addEventListener(MouseEvent.MOUSE_UP, stage_mouseUpHandler);
                }
            }
        }
        return value;
    }

    public function new(?mc:MovieClip)
    {
        this.mc = mc;
    }
    private function skin_mouseDownHandler(event:MouseEvent):Void
    {
        if (stage != null)
        {
            isDragging = true;
            mouseDownX = mc.parent.mouseX - mc.x;
            mouseDownY = mc.parent.mouseY - mc.y;
            stage.addEventListener(MouseEvent.MOUSE_MOVE, stage_mouseMoveHandler);
        }
    }
    private function stage_mouseUpHandler(event:MouseEvent):Void
    {
        if (stage != null)
        {
            isDragging = false;
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, stage_mouseMoveHandler);
        }
    }
    private function stage_mouseMoveHandler(event:MouseEvent):Void
    {
        mc.x = mc.parent.mouseX - mouseDownX;
        mc.y = mc.parent.mouseY - mouseDownY;
    }
}
class Dresser
{
    //...
    private var drags:Array<Drag>;

    public var mc(default, set):MovieClip;
    public function set_mc(value:MovieClip):MovieClip
    {
        if (mc != value)
        {
            // Unassign previous mc
            if (mc != null)
            {
                for (drag in drags)
                {
                    drag.mc = null;
                }
                drags = null;
                //...
            }

            mc = value;

            // Assign new mc
            if (mc != null)
            {
                //...
                drags = [for (item in items) new Drag(item)];
            }
        }
        return value;
    }
    //...
}
```

Теперь, если нам понадобится добавить перетаскивание любого объекта на экране, нам достаточно будет написать всего лишь одну строку: `new Drag(some_mc);`. Вот мы уже и подошли к повторному использованию кода!

Не нужно быть гением, чтобы увидеть, что оба наших классов имеют нечто общее. У обоих есть очень похожий сеттер — mc. В разных классах они делают разное, но шаблон явно прослеживается. Также оба класса являются оберткой вокруг графического объекта. Оберткой, которая добавляет логику к графике. Причем не только добавляет (`dresser.mc = some_mc;`), но и может очищать от нее (`dresser.mc = null;`).

Если нам понадобится реализовать кнопку, чекбокс, радио-кнопку, текстовую метку, список, скроллер, да что угодно работающее с графикой — удобнее всего их будет сделать точно так же. Вообще, все приложение целиком можно собрать из таких вот объектов-компонентов. Поэтому, почему бы нам не создать для всех них один общий базовый класс. Назовем его компонент (Component — от лат. componens «составляющий», род. пад. componentis). В программировании компонентами обычно называются классы, предназначенные для повторного использования и развёртывания. Именно так мы их и намереваемся использовать. Все сходится — компоненты.

Итак, произведем Extract class refactoring:

```haxe
class Component
{
    public var mc(default, set):MovieClip;
    // No need to override. Pattern: Template Method
    public function set_mc(value:MovieClip):MovieClip
    {
        if (mc != value)
        {
            // Unassign previous mc
            if (mc != null)
            {
                unassignMC();
            }

            mc = value;

            // Assign new mc
            if (mc != null)
            {
                assignMC();
            }
        }
        return value;
    }

    public function new(?mc:MovieClip)
    {
        this.mc = mc;
    }
    // Override
    private function assignMC():Void
    {
    }
    // Override
    private function unassignMC():Void
    {
    }
}
class Dresser extends Component
{
    private var drags:Array<Drag>;
    //...
    override private function assignMC():Void
    {
        super.assignMC();

        items = cast resolveNamePrefix(itemNamePrefix);
        prevButtons = cast resolveNamePrefix(prevButtonNamePrefix);
        nextButtons = cast resolveNamePrefix(nextButtonNamePrefix);
        for (item in items)
        {
            item.stop();
        }
        for (prevButton in prevButtons)
        {
            prevButton.buttonMode = true;
            prevButton.addEventListener(MouseEvent.CLICK, prevButton_clickHandler);
        }
        for (nextButton in nextButtons)
        {
            nextButton.buttonMode = true;
            nextButton.addEventListener(MouseEvent.CLICK, nextButton_clickHandler);
        }
        drags = [for (item in items) new Drag(item)];
    }
    override private function unassignMC():Void
    {
        for (prevButton in prevButtons)
        {
            prevButton.removeEventListener(MouseEvent.CLICK, prevButton_clickHandler);
        }
        for (nextButton in nextButtons)
        {
            nextButton.removeEventListener(MouseEvent.CLICK, nextButton_clickHandler);
        }
        for (drag in drags)
        {
            drag.mc = null;
        }
        items = null;
        prevButtons = null;
        nextButtons = null;
        drags = null;

        super.unassignMC();
    }
    //...
}
```

Сеттер мы сделали по паттерну **шаблонный метод** (Template method). Тогда нам не нужно при переопределении `set_mc()` делать каждый раз проверки `if (mc != null)`. Во-первых, это скучная рутина — печатать одно и то же. Во-вторых, об этом нужно помнить. А идеальный метод не должен заставлять нас что-либо помнить, когда мы его переопределяем. Мы всегда должны в подклассе иметь возможность писать что-угодно, в том числе и — ничего. Всё, о чем не надо забывать, обязательно однажды будет забыто. Именно поэтому и были добавлены методы `assignMC()` и `unassignMC()`. Теперь переопределяться должны они, а не `set_mc()`.

Однако, тут обнаруживается один недостаток. Не все графические объекты на экране могут быть мувиклипами (MovieClip). Бывают еще SimpleButton и Shape. MovieClip и SimpleButton имеют общим родительским классом InteractiveObject, а с Shape — аж только DisplayObject (поэтому Shape и не воспринимает события мышки). Значит, чтобы сделать класс Component по-настоящему универсальным, будем использовать в качестве базового класса для графики не MovieClip, а DisplayObject, а само свойство mc переименуем в более абстрактный skin:

```haxe
class Component
{
    public var skin(default, set):DisplayObject;
    // No need to override. Pattern: Template Method
    public function set_skin(value:DisplayObject):DisplayObject
    {
        if (skin == value)
        {
            return value;
        }
        // Unassign previous skin
        if (skin != null)
        {
            unassignSkin();
        }

        skin = value;
        interactiveObject = Std.downcast(value, InteractiveObject);
        simpleButton = Std.downcast(value, SimpleButton);
        container = Std.downcast(value, DisplayObjectContainer);
        sprite = Std.downcast(value, Sprite);
        mc = Std.downcast(value, MovieClip);

        // Assign new skin
        if (skin != null)
        {
            assignSkin();
        }
        return value;
    }
    public var interactiveObject(default, null):InteractiveObject;
    public var simpleButton(default, null):SimpleButton;
    public var container(default, null):DisplayObjectContainer;
    public var sprite(default, null):Sprite;
    public var mc(default, null):MovieClip;

    public function new(?skin:MovieClip)
    {
        this.skin = skin;
    }
    // Override
    private function assignSkin():Void
    {
    }
    // Override
    private function unassignSkin():Void
    {
    }
}
```

Чтобы не заниматься дополнительным приведением типов, если нам вдруг понадобятся свойства мувиклипа или кнопки, мы сделали все возможные приведения типов заранее и сохранили ссылки на них в свойствах: interactiveObject, simpleButton, container, sprite, mc.

Вот мы и получили компонент в самом чистом виде — как простая обертка для графики. Позже мы добавим сюда еще кое-какие свойства и методы, но это будет только расширение и углубление его основной задачи — быть оберткой. (Можно, конечно, обойтись и без них, но с ними удобнее.) Сущность класса выражена полностью.

Концепция компонентов позволяют нам писать любую логику отображения: от простых UI-элементов до сложных панелей, состоящих из других компонентов. Так, можно, как из кубиков, собрать что-угодно вплоть до целого приложения. Со временем у нас накопятся целые библиотеки компонентов, так что мы сможем собирать новые игры из готовых частей, не создавая ни одного нового класса. Представьте себе приложение состоящее из одного Main-класса, конфигурационного JSON- или YAML-файла и ассетов... Но об этом пока еще рано говорить.

[Исходники](https://gitlab.com/markelov-alex/hx-py-framework-evolution/-/tree/main/b_coloring/client_haxe/src/v2/)

[< Назад](01_client_01.md)  |  [Начало](00_intro_01.md)  |  [Вперед >](01_client_03.md)
