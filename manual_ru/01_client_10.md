# Эволюция игрового фреймворка. Клиент 10. Менеджеры

До этого момента мы вели речь в основном о графике и добавлении к ней логики. Так мы придумали компоненты. Их особенностью является то, что на один мувиклип, нужен отдельный экземпляр компонента. Но есть вещи общие для всего приложения. Сюда относится локализация, звуки, ресурсы. Для всего этого достаточно по одному экземпляру, и они будут использоваться совместно разными компонентами. Назовем такой отдельный тип классов менеджерами (managers).

Например, чтобы показывать искать переводы разных названий или запускать звук по клику на кнопке, совсем не обязательно в каждом месте, где они используются создавать отдельно объект класса, отвечающего за запуск звуков или хранение переводов. Напротив, это может оказаться очень неудобным, так как эти объекты еще придется настраивать, загружать переводы и т.д. Еще они будут занимать в памяти больше места, в то время как вполне хватило бы одного глобального объекта на все приложение.

Когда речь заходит о глобальной переменной или функции в объектно-ориентированных языках, то на ум сразу приходят статические члены класса. Если речь идет о глобальном объекте, то возникает соблазн реализовать его статическим классом, то есть таким классом, у которого все свойства и методы являются статическими. В результате класс получается экземпляром самого себя — к его свойствам и методам можно обращаться напрямую через имя класса (```MyClass.method()```).

Но тут есть одно но. Статический метод, то это все равно, что глобальная функция. Ты можешь вызвать именно эту функцию, и никакую другую подставить на ее место невозможно. Т.е. мы лишаем себя возможности использовать виртуальные методы — наследоваться, подменять и расширять код. Вот почему статические классы используются только как хранилище констант и утилитарных функций, вроде вычисления синусов и косинусов, про которые заранее известно, что меняться они точно не будут.

Чтобы создать глобальный объект и одновременно пользоваться всеми преимуществами ООП, такими как наследование, используют паттерн одиночка, или синглтон (Singleton). Он реализуется как обычный класс, но доступ к его единственному экземпляру предоставляется через статичное свойство (или метод). Чтобы нельзя было создать второй экземпляр, в конструкторе генерируется исключение, если это свойство не равно null.

В качестве примера преобразуем уже известный нам класс Screens в синглтон. Получать ссылку на его объект через ```Screens.getInstance()``` гораздо проще, чем искать ее среди родительских (parent) компонентов.

```haxe
class Screens extends Component
{
    // State
    private static var instance:Screens;
    public static function getInstance():Screens
    {
        if (instance == null)
        {
            instance = new Screens();
        }
        return instance;
    }

    public function new()
    {
        super();
        if (instance != null)
        {
            throw new Exception("Singleton class can have only one instance!");
        }
        // Should be set only once
        instance = this;
    }
    //...
}
```

Синглтон объединяет в себе преимущества статических и нестатических классов. Как первые, он глобальный, как вторые — он позволяет наследоваться и переопределять свои методы. Для этого нужно вызвать конструктор подкласса (```new MyScreens();```) до самого первого вызова ```Screens.getInstance()```. Тогда в свойстве instance будет экземпляр MyScreens, а не Screens.

Перейдем теперь, к менеджерам.

## ResourceManager

В OpenFL механизм получения ресурсов реализован в статичном классе Assets. А это означает, что везде, где мы его используем, мы привязываемся к конкретным функциям, которые нельзя переопределить. И если нам понадобится, скажем, добавить логирование на создание новых мувиклипов, то придется искать все вызовы таких функций и добавлять код логирования возле каждого. Чтобы добавить в наши проекты больше гибкости, сделаем обертку над Assets — ResourceManager. То есть он поначалу будет только оберткой, но по мере надобности в него можно добавить и другой полезный функционал. Чего нельзя сказать про статичный Assets.

```haxe
class ResourceManager
{
    // Static
    private static var instance:ResourceManager;
    public static function getInstance():ResourceManager
    {
        if (instance == null)
        {
            instance = new ResourceManager();
        }
        return instance;
    }

    public function new()
    {
        super();
        if (instance != null)
        {
            throw new Exception("Singleton class can have only one instance!");
        }
        // Should be set only once
        instance = this;
    }
    public function createMovieClip(assetName:String, callback:(MovieClip) -> Void):Void
    {
        if (assetName == null || assetName == "")
        {
            callback(null);
            return;
        }
        if (assetName == "MovieClip" || assetName == "openfl.display.MovieClip")
        {
            callback(new MovieClip());
            return;
        }
        // Get
        var movieClip = getMovieClip(assetName);
        if (movieClip != null)
        {
            callback(movieClip);
            return;
        }
        // Load
        var libraryName = getLibraryName(assetName);
        loadLibrary(libraryName, function(libraryName:String):Void
        {
            var movieClip = Assets.getMovieClip(assetName);
            callback(movieClip);
        });
    }
	public function getMovieClip(assetName:String):MovieClip
	{
		if (assetName == null || assetName == "")
		{
			return null;
		}
		var libraryName = getLibraryName(assetName);
		if (!loadedLibraries.contains(libraryName))
		{
			// Not loaded yet
			return null;
		}
		return Assets.getMovieClip(assetName);
	}
    private function getLibraryName(assetName:String):String
    {
        return assetName.indexOf(":") != -1 ? assetName.split(":")[0] : "default";
    }
    public function getSound(assetName:String):Sound
    {
        // As sounds and music are not necessary part of game, ignore if they absent
        try
        {
            return Assets.getSound(assetName);
        }
        catch (e:Exception)
        {
            return null;
        }
    }
    public function getData(assetName:String):Dynamic
    {
        var text;
        try
        {
            text = Assets.getText(assetName);
        }
        catch (e:Exception)
        {
            Log.warn(e.message);
            return null;
        }
        var nameParts = assetName.split(".");
        var ext = nameParts.length > 1 ? nameParts[nameParts.length - 1] : "";
        try
        {
            switch (ext)
            {
                case "json":
                    return Json.parse(text);
                // Add "<haxelib name="yaml"/>" to project.xml
                case "yml" | "yaml":
                    return Yaml.parse(text, new ParserOptions().useObjects());
            }
        }
        catch (e:Exception)
        {
            Log.error(e.message);
            return null;
        }
        return text;
    }
}
```

В ResourceManager мы прежде всего сделаем единый стандартный метод для создания графических объектов. Так как помимо мувиклипов нам ничего не понадобится, то называться метод будет createMovieClip().

Ресурсы могут требовать загрузки (preload=false в project.xml), а могут загружены заранее при старте приложения (preload=true). Во последнем случае результат вернется немедленно, а в первом, нужно передавать callback-функцию, которыя будет вызвана, после загрузки. Чтобы абстрагироваться от этого различия, мы сделали только одну реализацию — через callback. Делаем для всех одинаково.

Для загрузки библиотеки ресурсов нужно выделить из assetName ее название (например, "dresser" из assetName="dresser:AssetDresserScreen"). Так, выделение отдельного класса для менеджеров ресурсов оправдывает себя уже на этапе создания единообразного API для разных типов библиотек.

Далее, в методе ```getSound()``` мы изменили реакцию на отсутствие звуков. Вместо того, чтобы генерировать исключение в случае отсутствие ассета, возвращается просто null. Таким образом, мы можем в базовом компоненте для всех кнопок Button задать звук при клике по умолчанию (например, "button_click"). Если его нет в ассетах, то ничего не происходит, а если мы добавим звуковой файл с таким же именем, то у нас автоматически для всех кнопок появится озвучка.

Такой подход, когда мы просто игнорируем, чего нет, позволяет нам по мере необходимости насыщать приложение разными ресурсами без всяких изменений в коде. Звуки, музыка, графика — все будет подхватываться системой автоматически. Надо добавить в игру звук для кнопки — просто добавляем файл с именем "button_click". Надо нарисовать отдельное состояние для чекбокса — рисуем внутри него два мувиклипа с именами "checked" и "unchecked", и сложная, казалось бы, кнопка готова.

Еще один метод ```getData()``` расширяет стандартный ```Asset.getText()``` тем, что для JSON и YAML файлов возвращает уже готовый распарсенный объект, а не строку, которую только еще предстоит распарсить. Очень скоро нам этот метод пригодится для загрузки конфигов.

## Log

Без внимания остался только новый класс Log. Для начала это — простая обертка над функцией для стандартного вывода — ```trace()```. Ее назначение — разделять все логи по уровню важности и позволять отключать самые малозначащие из них. Также тут автоматически добавляется префиксы вроде "WARNING!", "ERROR!!", чтобы было легче ориентироваться в тексте логов.

```haxe
class Log
{
    // Settings
    public static var isDebug = true;
    public static var isInfo = true;
    // Methods
    public static function debug(message:Dynamic, ?posInfo:PosInfos):Void
    {
        if (isDebug)
        {
            Log.trace("debug: " + message, posInfo);
        }
    }
    public static function info(message:Dynamic, ?posInfo:PosInfos):Void
    {
        if (isInfo)
        {
            Log.trace(message, posInfo);
        }
    }
    public static function warn(message:Dynamic, ?posInfo:PosInfos):Void
    {
        Log.trace("WARNING! " + message, posInfo);
    }
    public static function error(message:Dynamic, ?posInfo:PosInfos):Void
    {
        Log.trace("ERROR!! " + message, posInfo);
    }
    public static function fatal(message:Dynamic, ?posInfo:PosInfos):Void
    {
        Log.trace("FATAL!!! " + message, posInfo);
    }
    private static dynamic function trace(v:Dynamic, infos:PosInfos):Void {
        #if (fdb || native_trace)
        var str = haxe.Log.formatOutput(v, infos);
        untyped __global__["trace"](str);
        #else
        flash.Boot.__trace(v, infos);
        #end
    }
}
```

Но главное — это не то, что методы класса Log делают, а то, что приложение повсюду использует эти методы. Где нужно фиксировать важные события, мы вызываем Log.info(), где появляются ошибки — Log.error() или Log.fatal(). Со временем мы можем сделать форматирование логов, добавление к ним времени (timestamp), сохранение их в файл или отправку на сервер. Для всего этого понадобится лишь подредактировать всего один класс — Log. Пока что мы будем просто постепенно вводить логирование в наше приложение, и ничего, что это всего лишь обертка над trace().

Так как класс служебный, то вполне достаточно сделать его просто статическим. Возиться с синглтонами или созданием отдельного экземпляра логгера для каждого его использования (например, так: ```Log.getLogger(this).info("text");``` или ```private var logger = Log.getLogger(AudioManager); /*...*/ logger.info("text");```), особого смысла не имеет.

[Исходники](https://gitlab.com/markelov-alex/hx-py-framework-evolution/-/tree/main/d_managers/client_haxe/src/)

[< Назад](01_client_09.md)  |  [Начало](00_intro_01.md)  |  [Вперед >](01_client_11.md)
