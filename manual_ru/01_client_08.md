# Эволюция игрового фреймворка. Клиент 8. Сигналы

В классе Button мы использовали callback-функцию clickHandler вместо того привычных для Flash и, соответственно, OpenFL событий и диспетчеров. Мы решили отказаться от стандартных событий по нескольким причинам.

Во-первых, нам бы пришлось наследовать Component от EventDispatcher, а когда мы наследуемся от одного класса, мы уже не сможем наследоваться от какого-нибудь другого, если вдруг это понадобится. Поэтому всякое наследование сейчас ограничивает наше пространство для маневра в будущем.

Во-вторых, для наших собственных событий пришлось бы создавать отдельные классы событий, наследуемых от Event, под каждый новый набор параметров. А как известно, зачем плодить новые сущности, особенно, если их можно и не плодить.

В-третьих, при генерации события, даже если оно никем не слушается и никому не нужно, каждый раз создается новый объект event. На выделение памяти, а потом и на ее очистку сборщиком мусора, тратится время. В общем, у нас есть не одна причина, чтобы не привязываться к EventDispatcher.

Но и использование callback-функций не сильно облегчает нам жизнь, так как мы не можем добавить больше одного слушателя для события. А это уже делает решение не универсальным. Чтобы можно было одновременно вызывать несколько callback-функций, создадим специальный класс Signal:

```haxe
class Signal<T>
{
    private var listeners = new Array<(T)->Void>();
    public function add(listener:(T)->Void):Void
    {
        if (listener != null && !listeners.contains(listener))
        {
            listeners.push(listener);
        }
    }
    public function remove(listener:(T)->Void):Void
    {
        if (listener != null)
        {
            listeners.remove(listener);
        }
    }
    public function dispose():Void
    {
        listeners.resize(0);
    }
    public function dispatch(target:T):Void
    {
        // Traverse listeners' copy, because some listeners could be
        // added or removed during dispatching and the list would change
        for (listener in listeners.copy())
        {
            listener(target);
        }
    }
}
```

Если нужно передавать в слушатели 2, 3, 4 аргумента, то нам ничего не остается как создать копию класса, но с другими параметрами:

```haxe
class Signal2<T1, T2>
{
    private var listeners = new Array<(T1, T2)->Void>();
    //...
}
class Signal3<T1, T2, T3>
{
    private var listeners = new Array<(T1, T2, T3)->Void>();
    //...
}
```

Посмотрим, как будут выглядеть наши компоненты с сигналами вместо callback-функций:

```haxe
class Button extends Component
{
    public var clickSignal(default, null) = new Signal<Button>;
    //...
    private function interactiveObject_clickHandler(event:MouseEvent):Void
    {
        clickSignal.dispatch(this);
    }
}
class Dresser extends Component
{
    //...
    private var closeButton:Button;
    public function new()
    {
        super();
        closeButton = new Button();
        closeButton.skinPath = "closeButton";
        closeButton.clickSignal.add(closeButton_clickSignalHandler);
        addChild(closeButton);
    }
    //...
    private function closeButton_clickSignalHandler(target:Button):Void
    {
        //todo
    }
}
```

Тут мы среди прочего наблюдаем тот же эффект сокращения кода, что и при использовании компонентов. А именно, исчезает проверка на null (```if (clickHandler != null)```): есть слушатели или нет, мы просто вызываем метод dispatch() и все.

Также заметим, что по умолчанию в качестве аргумента слушателям передается ссылка на компонент, который инициировал событие (target). Это будет полезно, когда мы один и тот же слушатель будем использовать для нескольких компонентов одновременно, и нам нужно будет знать, откуда к нам пришел сигнал. Без этого не обойтись, например, при обработке радио-кнопок (RadioButton) или строк в List или DataGrid, где все элементы обрабатываются однообразно, а потому имеют один обработчик.

В общем, сигналы мне кажутся наиболее удобным и экономичным способом работать с событиями, в отличие от простых callback-ов и EventDispatcher. К тому же мы тут можем более лаконично API: signal.add() вместо dispatcher.addEventListener(), signal.dispatch() вместо dispatcher.dispatchEvent() и т.д.

[Исходники](https://gitlab.com/markelov-alex/hx-py-framework-evolution/-/tree/main/b_coloring/client_haxe/src/v3/)

[< Назад](01_client_07.md)  |  [Начало](00_intro_01.md)  |  [Вперед >](01_client_09.md)
