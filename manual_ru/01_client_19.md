# Эволюция игрового фреймворка. Клиент 19. Сервис

В [текущей версии](01_client_18.md) модели бизнес-логика тесно переплетена с запросами на сервер. Повсюду создаются экземпляры Request, вызывается метод send() и обрабатываются ответы от сервера (parseResponse()). В результате получается то же самое, что у нас было с отображением до отделения от него модели. Только там перемешивалось отображение с логикой, а тут логика с обменом сообщениями с сервером.

Получается, что как тогда мы не могли заменить логику, чтобы не заменить визуальную часть приложения, так и тут мы не можем заменить, скажем протокол, чтобы не зацепить логику. В новую версию DresserModel придется переносить немало из старой версии, а мы помним, что дублирование кода — один из основных смертных грехов программиста, за которые ему придется расплачиваться еще в этой жизни.

В общем, существует явная необходимость выделить особый класс (Extract class refactoring), который делает непосредственные запросы на сервер, а модели предоставляет понятный интерфейс в виде методов и их параметров. Если абстрагироваться от реализации сервера и рассматривать его просто как удаленную служебную программу, то и класс, который представляет эту службу можно также назвать службой, или сервисом (Service) (см. [Service-oriented architecture](https://en.wikipedia.org/wiki/Service-oriented_architecture)).

Задача сервиса абстрагировать логику от того, как и куда будут совершаться запросы. Например, можно подставить такую реализацию, которая вообще не будет обращаться на сервер, а будет просто брать данные из локального файла. Модели нет дела до того, откуда она получает данные. Она просто вызывает определенный метод и получает определенные данные.

Данные ожидаются в виде объекта в привычном для модели формате. Поэтому можно также сделать реализацию сервиса, которая будет преобразовывать формат данных из серверного в клиентский, если они отличаются. Так, благодаря классу Service код клиента становится независимым от изменений в сервеном API.

```haxe
class DresserModel
{
    // State
    private var service:DresserService;
    private var _state:Array<Int> = [];
    @:isVar
    public var state(get, set):Array<Int>;
    public function get_state():Array<Int>
    {
        return _state;
    }
    public function set_state(value:Array<Int>):Array<Int>
    {
        if (value == null)
        {
            value = [];
        }
        if (!ArrayUtil.equal(_state, value))
        {
            service.setState(value);
        }
        return value;
    }
    public var stateChangeSignal(default, null) = new Signal<Array<Int>>();
    public var itemChangeSignal(default, null) = new Signal2<Int, Int>();

    public function new()
    {
        service = new DresserService();
        service.loadSignal.add(service_loadSignalHandler);
        service.stateChangeSignal.add(service_stateChangeSignalHandler);
        service.itemChangeSignal.add(service_itemChangeSignalHandler);
    }
    public function load():Void
    {
        service.load();
    }
    public function changeItem(index:Int, value:Int):Void
    {
        if (state[index] != value)
        {
            service.changeItem(index, value);
        }
    }
    private function service_loadSignalHandler(value:Dynamic):Void
    {
        _state = cast value;
        stateChangeSignal.dispatch(value);
    }
    private function service_stateChangeSignalHandler(value:Array<Int>):Void
    {
        _state = cast value;
        stateChangeSignal.dispatch(value);
    }
    private function service_itemChangeSignalHandler(index:Int, value:Int):Void
    {
        state[index] = value;
        itemChangeSignal.dispatch(index, value);
    }
}
class DresserService
{
    // Settings
    public var url = "http://127.0.0.1:5000/storage/dresser";
    // State
    public var loadSignal(default, null) = new Signal<Array<Int>>();
    public var stateChangeSignal(default, null) = new Signal<Array<Int>>();
    public var itemChangeSignal(default, null) = new Signal2<Int, Int>();

    public function load():Void
    {
        new Request().send(url, null, function (response:Dynamic):Void {
            var data = parseResponse(response);
            if (data.success)
            {
                loadSignal.dispatch(data);
            }
        });
    }
    public function setState(value:Array<Int>):Array<Int>
    {
        new Request().send(url, value, function (response:Dynamic):Void {
            var data = parseResponse(response);
            if (data.success)
            {
                stateChangeSignal.dispatch(data);
            }
        }, URLRequestMethod.POST);
    }
    public function changeItem(index:Int, value:Int):Void
    {
        if (state[index] != value)
        {
            new Request().send(url, {index: index, value: value}, function (response:Dynamic):Void {
                var data = parseResponse(response);
                if (data.success)
                {
                    itemChangeSignal.dispatch(index, value);
                }
            }, "PATCH");
        }
    }
    private function parseResponse(response:Dynamic):Dynamic
    {
        Log.debug('Load data: ${response} from url: $url');
        try
        {
            var data:Dynamic = Json.parse(response);
            Log.debug(' Loaded state data: ${data} from url: $url');
            return data;
        }
        catch (e:Exception)
        {
            Log.error('Parsing error: $e');
        }
        return null;
    }
}
```

Теперь можно использовать один и то же сервис с разными моделями, и одну и ту же модель с разными реализациями сервиса. Так, один и тот же сервер может быть нужен в разных моделях, и эти модели не должны знать друг о друге. С другой стороны, удаленный сервер может работать на разных транспортных (TCP или UDP) и прикладных протоколах. Но модель всего этого не должна знать и не знает — она получает данные от сервиса всегда в одном и том же формате.

Таким образом, в лице сервисов мы произвели отделение данных от их источника и способа получения. В следующем материале нам предстоит отделить логику обработки данных от бизнес-логики, или правил работы приложения. Другими словами, мы из модели, наконец, выделим контроллер.

[Исходники](https://gitlab.com/markelov-alex/hx-py-framework-evolution/-/tree/main/f_models/client_haxe/src/v4/)

[< Назад](01_client_18.md)  |  [Начало](00_intro_01.md)  |  [Вперед >](01_client_20.md)
