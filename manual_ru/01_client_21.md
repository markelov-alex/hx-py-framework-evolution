# Эволюция игрового фреймворка. Клиент 21. Service-Transport-Parser-Protocol

Сейчас общая схема устройства типичного игрового модуля устроена так. Игра начинается с создания скрина Dresser. Это точка входа в модуль — она порождает все остальные элементы: компоненты, модели, контроллеры и так далее. То есть создали и добавили в приложение Dresser — инициировали весь модуль.

Внутри Dresser есть внутренние UI-компоненты (кнопки), которые работают с непосредственным отображением (DisplayObject) и пользовательской активностью. При нажатии пользователя на графическое изображение кнопки (openfl.display.MovieClip или openfl.display.SimpleButton) наш компонент кнопки поймает соответствующее событие и сгенерирует сигнал клика. Dresser получит этот сигнал и сделает запрос в контроллер. Контроллер обратится к модели или сервису, в зависимости от того, офлайн- или онлайн-версия у нас приложения. Получив ответ от сервера или модели контроллер (или, как раньше у нас было, сама модель) сгенерирует сигнал. Dresser слушает этот сигнал и обновляет новыми данными отображение — напрямую или через какой-то специальный UI-компонент.

Вот какая цепочка вызовов происходит при каждом клике на кнопку. И все для того, чтобы на каждом этапе можно было подменить реализацию на другую. Чтобы изменяя отображение, не нужно было дублировать логику, изменяя логику — дублировать работу с сервером и так далее. Чтобы каждый слой можно было разрабатывать и поддерживать отдельно и независимо от других слоев. А значит, и затем, чтобы разные реализации из этих слоев можно было сочетать между собой в самых разнообразных комбинациях.

Я надеюсь, что все предыдущие заметки вполне раскрыли эти идеи, и то, что вы сейчас читаете, вам вполне понятно. Если нет, то рекомендую вернуться и пройти предыдущие шаги заново. Повторение — мать учения. Тем более, обычно, когда знаешь конец книги, начало читается совершенно по-другому.

Сейчас, перед тем как мы перейдем к сокетам, рассмотрим класс сервиса: нет ли и там разных слоев, реализации которых можно было бы комбинировать между собой?

Сейчас сервис для доступа к HTTP-серверу выглядит примерно так:

```haxe
class StorageService implements IStorageService
{
    // Settings
    public var url:String;
    // State
    public var loadSignal(default, null) = new Signal<Array<Int>>();
    public var stateChangeSignal(default, null) = new Signal<Array<Int>>();
    public var itemChangeSignal(default, null) = new Signal2<Int, Int>();

    //...
	public function setState(value:Dynamic):Void
	{
		var data = Json.stringify({state: value});
        new Request().send(url, data, onSetState, "POST");
	}
	public function changeItem(index:Dynamic, value:Dynamic):Void
	{
		var data = Json.stringify({index: index, value: value});
        new Request().send(url, data, onChangeItem, "PATCH");
	}
    //...
	private function onChangeItem(response:Dynamic):Void
	{
		var data = parseResponse(response);
        if (data.success)
		{
			// Dispatch
			itemChangeSignal.dispatch(data.index, data.value);
		}
	}
}
```

Так как DresserService реализует в общем-то стандартный набор CRUD-функций (Create-Read-Update-Delete, правда, без D — Delete), которые могут быть использованы и в других приложениях, то было переименовать класс в StorageService. Также добавилось кодирование данных в JSON формат, а анонимные callback-функции были вынесены в обычные приватные методы (onSetState, onChangeItem).

В результате, код публичных методов стал более понятным. Он состоит из двух шагов: сериализация и отправка запроса. А callback состоит из противоположных двух шагов: парсинг ответа и генерирование сигнала. И если для парсинга ответа уже есть свой метод, который можно переопределить в подклассе так, чтобы изменения в парсинге не затрагивали callback, то методах для отсылки запросов все действия выполняются напрямую. Если мы захотим, например, изменить с JSON на XML, нам придется заново написать в подклассе ```new Request().send(...);```. И наоборот, если мы изменим способ отправки сообщений, мы вынуждены будем дублировать код по сериализации.

Чтобы любой шаг в алгоритме можно было изменять независимо от других шагов, весь алгоритм реализуется как шаблонный метод (Template method pattern):

```haxe
class StorageService implements IStorageService
{
    //...
	public function setState(value:Dynamic):Void
	{
		var plainData = serializeRequest({state: value});
		send(data, onSetState, "POST");
	}
	public function changeItem(index:Dynamic, value:Dynamic):Void
	{
		var plainData = serializeRequest({index: index, value: value});
		send(data, onChangeItem, "PATCH");
	}
    private function serializeRequest(data:Dynamic):String
    {
        return Json.stringify(data);
    }
    private function send(data:Dynamic, callback:Dynamic->Void, method:String):String
    {
        return Json.stringify(data);
    }
    //...
}
```

Но это не решает более важную проблему. А именно — невозможность комбинировать протоколы разного типа между собой. То есть мы не можем отдельно подобрать сетевой протокол, а отдельно протокол приложения. Каждый класс Service заранее жестко фиксирует определенную комбинацию, и ее можно изменить только написав новую версию Service.

Чтобы решить данную проблему из Service выделим еще два новых класса: Transport — для предоставления единого интерфейса к разным транспортным протоколам, и Parser — для наших кастомных (custom) протоколов (прикладного уровня).

```haxe
class StorageService implements IStorageService
{
    private var parser:IParser;
    private var transport:ITransport;
    //...
	public function new()
	{
		var ioc = IoC.getInstance();
		parser = ioc.create(IParser);
		transport = ioc.create(ITransport);
		transport.url = url;
		// Listeners
		transport.receiveDataSignal.add(transport_receiveDataSignalHandler);
	}
    //...
	public function setState(value:Dynamic):Void
	{
		var plainData = parser.serialize({state: value, _method: "POST"});
		transport.send(plainData);
	}
	public function changeItem(index:Dynamic, value:Dynamic):Void
	{
		var plainData = parser.serialize({index: index, value: value, _method: "PATCH"});
		transport.send(plainData);
	}
    //...
    private function processData(data:Dynamic):Void
    {
		switch data._method
		{
			case "GET" | null:
				// Dispatch
				loadSignal.dispatch(data.state);
			case "POST":
				// Dispatch
				stateChangeSignal.dispatch(data.state);
			case "PATCH":
				// Dispatch
				itemChangeSignal.dispatch(data.index, data.value);
		}
    }
	private function transport_receiveDataSignalHandler(plain:Dynamic):Void
	{
		var data:Dynamic = parser.parse(plain);
		if (data != null && data.success)
		{
			processData(data);
		}
	}
}
```

В целях унификации из transport.send() был убран отдельный параметр для HTTP-метода, потому что HTTP-метод есть только в HTTP-протоколе. В сокетах, например, его нет (в чем мы убедимся позже). Теперь, чтобы различать запросы, мы используем то же значение метода, но перенесенное в объект данных. (Позже это поле превратится в имя команды.)

Так как сервер в ответе вернет поле метода неизменным (так мы сделали на нашем сервере), то мы можем также отказаться от множества callback-функций в пользу единого сигнала transport.receiveDataSignal. Слушатель transport_receiveDataSignalHandler также построен по паттерну шаблонный метод (Template method): первым шагом парсится ответ, а вторым вызывается обработчик готовых данных ```processData()```. Поэтому мы в подклассах можем как угодно переопределять ```processData()```, не боясь, что парсинг ответа не произойдет.

В итоге после того, как мы вынесли из сервиса подготовку сообщений (Parser) и их отсылку и прием (Transport), в StorageService остались только методы и сигналы, которые, собственно, и составляют весь протокол приложения: load(), setState(), changeItem(). Поэтому имеет смысл переименовать StorageService в StorageProtocol, а код общие для всех протоколов, вынести в базовый класс Protocol.

```haxe
class Protocol
{
	// Settings
	public var url = "";
	// State
	private var parser:IParser;
	private var transport:ITransport;

	public function new()
	{
		var ioc = IoC.getInstance();
		parser = ioc.create(IParser);
		transport = ioc.create(ITransport);
		transport.url = url;
		// Listeners
		transport.receiveDataSignal.add(transport_receiveDataSignalHandler);
	}
	public function send(data:Dynamic):Void
	{
		var plain:Dynamic = parser.serialize(data);
		Log.debug('<< Send: $data -> $plain');
		transport.send(plain, data);
	}
	// Override
	private function processData(data:Dynamic):Void
	{
	}
	private function transport_receiveDataSignalHandler(plain:Dynamic):Void
	{
		var data:Dynamic = parser.parse(plain);
		Log.debug(' >> Recieve: $plain -> $data');
		if (data != null && data.success)
		{
			processData(data);
		}
	}
}
class StorageProtocol extends Protocol implements IStorageService
{
	// Signals
	public var loadSignal(default, null) = new Signal<Dynamic>();
	public var stateChangeSignal(default, null) = new Signal<Dynamic>();
	public var itemChangeSignal(default, null) = new Signal2<Dynamic, Dynamic>();
    // Requests
	public function load():Void
	{
		send(null);
	}
	public function setState(value:Dynamic):Void
	{
		send({state: value, _method: Method.POST});
	}
	public function changeItem(index:Dynamic, value:Dynamic):Void
	{
		send({index: index, value: value, _method: Method.PATCH});
	}
    // Responses
	override private function processData(data:Dynamic):Void
	{
		super.processData(data);
		switch data._method
		{
			case "GET" | null:
				// Dispatch
				loadSignal.dispatch(data.state);
			case "POST":
				// Dispatch
				stateChangeSignal.dispatch(data.state);
			case "PATCH":
				// Dispatch
				itemChangeSignal.dispatch(data.index, data.value);
		}
	}
}
```

Сервис-протокол в нашем случае имеет такой же интерфейс (методы и сигналы), как и контроллер, а сам контроллер по сути не делает ничего, кроме перенаправления методов и сигналов к сервису. Это так, потому что мы тут реализуем тонкий клиент, а он предполагает вынесение всей логики на сервер. А раз логики на клиенте, а значит, и в контроллере нет, тооба класса вполне можно слить в один. То есть мы убираем контроллер, а вместо него используем протокол, переименованный в контроллер:

```haxe
class DresserController extends StorageProtocol
{
	public function new()
	{
		super();
		transport.url = "http://127.0.0.1:5000/storage/dresser";
	}
}
```

Заметим, что в Parser-е можно не только сериализовать и парсить, но еще и преобразовывать разные серверные версии протокола в одну клиентскую. Таким образом, с помощью разных версий Parser можно подключаться к самым разным версиям сервера.

Более того, можно переключаться между этими версиями автоматически с помощью специального сообщения (команды) или поля version внутри любого сообщения. Для этого создадим специальный класс парсера, который будет по полученной версии протокола подставлять нужный экземпляр парсера, куда и будут перенаправляться все сообщения для обработки. Назовем этот класс MultiParser. А выглядеть он будет примерно так:

```haxe
class MultiParser implements IParser
{
	// Settings
    public var defaultVersion = "v.1";
	public var parserByVersion:Map<String, Dynamic> = ["v1" => new JSONParser()];
	// State
    private var parser:IParser;

	public function serialize(data:Dynamic):String
	{
		if (parser == null)
        {
            parser = parserByVersion.get(defaultVersion);
        }
		var result = parser.serialize(object);
		return result;
	}
	public function parse(plainData:String):Dynamic
	{
        var version = parseVersion(plainData);
        if (parser == null || version != null)
        {
            parser = parserByVersion.get(version != null ? version : defaultVersion);
        }
        var result = parser.parse(plainData);
        return result;
    }
	private function parseVersion(plainData:String):String
	{
        return ...; // Somehow parse plainData for version
    }
}
```

MultiParser можно подставлять вместо любого другого обычного парсера — снаружи они не различимы, так как реализуют один и тот интерфейс.

Подытожим. Выделив из сервиса функциональности по форматированию (Parser) и транспортированию (Transport) данных, мы можем отдельно реализовывать поддержку любого серверного формата (Parser) и любого стандартного протокола (HTTP, TCP, UDP — Transport). Также с вынесением парсера и транспорта сервис превратился в чистый протокол. В случае тонкого клиента этот протокол одновременно является и контроллером. Поэтому для офлайн версии игры может использоваться обычный полноценный контроллер, а для толстого онлайн клиента — контроллер с протоколом, а для тонкого клиента — протокол вместо контроллера.

Если это не очень понятно, то в следующем материале (последнем для клиента) мы повторим весь ход наших рассуждений, но уже для сокетов.

[Исходники](https://gitlab.com/markelov-alex/hx-py-framework-evolution/-/tree/main/f_models/client_haxe/src/v6/)

[< Назад](01_client_20.md)  |  [Начало](00_intro_01.md)  |  [Вперед >](01_client_22.md)
