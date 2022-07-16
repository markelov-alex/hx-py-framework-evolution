# Эволюция игрового фреймворка. Клиент 11. Аудио

## AudioManager

Мы уже как-то затрагивали тему звуков. Теперь подошла очередь их реализовать в специальном менеджере:

```haxe
class AudioManager
{
    // Static
    private static var instance:AudioManager;
    public static function getInstance():AudioManager
    {
        if (instance == null)
        {
            instance = new AudioManager();
        }
        return instance;
    }
    // Settings
    public var namePrefix = "assets/audio/";
    public var nameExt = ".ogg";
    // State
    private var resourceManager = ResourceManager.getInstance();
    public var isSoundOn(default, set):Bool = true;
    public function set_isSoundOn(value:Bool):Bool
    {
        if (isSoundOn != value)
        {
            isSoundOn = value;
            refreshSoundOn();
            // Dispatch
            toggleSoundSignal.dispatch(value);
        }
        return value;
    }
    public var soundVolume(default, set):Float = 1;
    public function set_soundVolume(value:Float):Float
    {
        // For openfl (flash) -value is same as value
        value = value < 0 ? 0 : value;
        if (soundVolume != value)
        {
            var dv = value - soundVolume;
            soundVolume = value;
            Log.debug("Sound volume: " + value);
            for (sc in currentSounds)
            {
                // (Reuse existing soundTransform)
                var st = sc.soundTransform;
                st.volume += dv;
                sc.soundTransform = st;
            }
        }
        return value;
    }
    private var currentSounds:Array<SoundChannel> = [];
    public var toggleSoundSignal(default, null) = new Signal<Bool>();
    public var soundVolumeChangeSignal(default, null) = new Signal<Float>();

    public function playSound(name:String, volume:Float=1, pan:Float=0):SoundChannel
    {
        if (name == null || !isSoundOn)
        {
            return null;
        }
        // Get
        var assetName = getAssetName(name);
        var sound = resourceManager.getSound(assetName);
        if (sound == null)
        {
            return null;
        }
        pan = pan < -1 ? -1 : (pan > 1 ? 1 : pan);
        // Play
        var soundChannel = sound.play(0, 0, new SoundTransform(soundVolume * volume, pan));
        currentSounds.push(soundChannel);
        // Listeners
        soundChannel.addEventListener(Event.SOUND_COMPLETE, sound_soundCompleteHandler);
        return soundChannel;
    }
    public function stopAllSounds():Void
    {
        for (sc in currentSounds)
        {
            // Listeners
            sc.removeEventListener(Event.SOUND_COMPLETE, sound_soundCompleteHandler);
            sc.stop();
        }
        currentSounds = [];
    }
    private function refreshSoundOn():Void
    {
        if (!isSoundOn)
        {
            stopAllSounds();
        }
    }
    private function getAssetName(name:String, isMusic=false):String
    {
        // Add dir path to all (namePrefix), and file extension if absent (nameExt).
        return namePrefix + name + (name.indexOf(".") == -1 ? nameExt : "");
    }
    private function sound_soundCompleteHandler(event:Event):Void
    {
        // (Always not null)
        var soundChannel = cast(event.currentTarget, SoundChannel);
        // Listeners
        soundChannel.removeEventListener(Event.SOUND_COMPLETE, sound_soundCompleteHandler);
        currentSounds.remove(soundChannel);
    }
}
```

Вообще говоря, все аудио в играх можно разделить на две категории: звуки и музыку. Они отличаются концептуально: звуки могут накладываться друг на друга, а для музыки имеет смысл играть только один трек за раз. А значит, для них требуется и различная реализация в коде. Выше показана реализация для звуков. Аналогично, не намного сложнее сделать и проигрывание музыки. Поэтому предлагаем сделать это самостоятельно.

Музыкальные треки могут существовать как отдельные сущности, а могут и группироваться в плейлисты. Их, как и отдельные треки, можно зациклить и проигрывать бесконечно.

Прописать плейлист в коде неудобно, т.к. этим будут в основном заниматься дизайнеры, и лучше бы, чтобы они не беспокоили программистов по пустякам. Поэтому специально для них и плейлисты и вообще все звуки будут прописываться во внешнем файле: audio.yml. Тут можно не только указать настоящее имя звукового ассета (name) и настроить параметры для каждого трека (volume, pan), но также и кое-какие глобальные параметры (isSoundOn, isMusicOn, soundVolume, etc).

```yaml
isSoundOn: false
#isMusicOn: true
soundVolume: 0.7
musicVolume: .3

sound:
  click_button:  # Default soundName in Button
  	name: click_sound  # Real audio file name in assets
    pan: -1
music:
  track1:
    # name: track1  # By default
    pan: -1
  track2:
    name: music2
    volume: .85
  music_menu:  # Playlist "music_menu" could be default musicName value in MenuScreen
    name: [track1, track2, music3]
    isLoop: true
    volume: .75
```

Плейлисты описываются так же, как и остальные треки, только в свойстве name не строка, а массив. Если громкость (volume) и баланс (pan) отличны заданы и в треке, и в плейлисте, и глобально, то они перемножаются. Так, track2 в music_menu будет играться с громкостью 0.75 * 0.85 * 0.3 = 0.19125.

На первый взгляд введение конфигурационного файла задача сложная, но на самом деле это не так. И главная причина тому — лаконичность и простота самой структуры файла. Если формат файла сложный для понимания, то и реализация его тоже будет сложной. Вот почему всегда нужно сначала хорошо разобраться в предмете, и только потом приступать к созданию формата данных и воплощению его в коде.

```haxe
class AudioManager
{
    // Settings
    public var defaultAssetName = "audio.yml";
    private var defaultConfig:Track = {
        name: null, isLoop: false, startTime: 0, volume: 1, pan: 0,
    };
    // State
    private var soundConfigByName = new Map<String, Track>();
    private var musicConfigByName = new Map<String, Track>();
    //...
    public function load(assetName:String=null):Void
    {
        if (assetName == null)
        {
            assetName = defaultAssetName;
        }
        // Get/load data
        var data = resource.getData(assetName);
        if (data == null)
        {
            return;
        }
        // Set up manager
        for (key in Reflect.fields(data))
        {
            if (Reflect.hasField(this, key))
            {
                Reflect.setProperty(this, key, Reflect.getProperty(data, key));
            }
        }
        // Update track configs
        updateConfig(soundConfigByName, data.sound);
        updateConfig(musicConfigByName, data.music);
    }
    private function updateConfig(configByName:Map<String, Track>, data:Dynamic):Void
    {
        for (name in Reflect.fields(data))
        {
            // Get current or create default
            var current:Track = configByName[name];
            if (current == null)
            {
                // (Create with default values)
                current = configByName[name] = {
                    name: name,
                    isLoop: defaultConfig.isLoop,
                    startTime: defaultConfig.startTime,
                    volume: defaultConfig.volume,
                    pan: defaultConfig.pan,
                };
            }
            // Update current track config with loaded data
            var item = Reflect.getProperty(data, name);
            for (key in Reflect.fields(defaultConfig))
            {
                if (Reflect.hasField(item, key))
                {
                    Reflect.setProperty(current, key, Reflect.getProperty(item, key));
                }
            }
        }
    }
	public function playSound(name:String, volume:Float=1, pan:Float=0):SoundChannel
	{
		var config:Track = soundConfigByName[name];
		if (config != null)
		{
			name = config.name != null ? config.name : name;
			volume = volume * config.volume;
			pan = pan + config.pan;
		}
		//...
	}
}
typedef Track = {
    var name:Dynamic;
    var isLoop:Bool;
    var startTime:Float;
    var volume:Float;
    var pan:Float;
}
```

Чтобы конфиг менеджера загрузился и распарсился, нужно в самом начале работы приложения вызвать ```AudioManager.getInstance().load();```.

Теперь, чтобы, скажем, добавить в кнопку звук на клик, в класс Button добавляется в буквальном смысле всего 2 строки:

```haxe
class Button extends Component
{
    public var soundClick = "click_button";
    //...
    private function skin_clickHandler(event:MouseEvent):Void
    {
        if (!isEnabled)
        {
            return;
        }
        AudioManager.getInstance().playSound(soundClick);
        //...
    }
}
```

Если в директории со звуками есть файл "click_button.ogg", то он будет проигрываться при каждом нажатии на любую кнопку, даже если он не упоминается в config.yml. Если имя файла другое (например, "click_sound"), то его можно привязать к "click_button" в config.yml (см. выше), чтобы не настраивать все компоненты Button на новое имя.

Для управления аудио системой пользователем можно создать специальные компоненты: SoundToggleButton, MusicToggleButton, SoundVolumeSlider, MusicVolumeSlider, так как все эти UI-элементы присутствуют практически в каждой игре. Например, вот чекбокс, который будет включать и выключать звуковые эффекты в приложении:

```haxe
class SoundToggleButton extends CheckBox
{
    // State
    private var audio = AudioManager.getInstance();
    public function new()
    {
        super();
        skinPath = "soundToggleButton";
    }
    override private function assignSkin():Void
    {
        super.assignSkin();
        isChecked = audio.isSoundOn;
        audio.toggleSoundSignal.add(audio_toggleSoundSignalHandler);
    }
    override private function unassignSkin():Void
    {
        audio.toggleSoundSignal.remove(audio_toggleSoundSignalHandler);
        super.unassignSkin();
    }
    override private function refreshChecked():Void
    {
        super.refreshChecked();
        audio.isSoundOn = isChecked;
    }
    private function audio_toggleSoundSignalHandler(value:Bool):Void
    {
        isChecked = value;
    }
}
```

На случай, если мы хотим сохранять настройки пользователя между сессиями, можно воспользоваться стандартным классом SharedObject:

```haxe
class AudioManager
{
    // State
    private var shared:SharedObject = SharedObject.getLocal("managers");
    //...
    public function loadPrevious():Void
    {
        //shared.clear();
        if (shared.data.isMusicOn != null)
        {
            isSoundOn = shared.data.isSoundOn;
            isMusicOn = shared.data.isMusicOn;
            soundVolume = shared.data.soundVolume;
            musicVolume = shared.data.musicVolume;
        }
        else
        {
            shared.data.isSoundOn = isSoundOn;
            shared.data.isMusicOn = isMusicOn;
            shared.data.soundVolume = soundVolume;
            shared.data.musicVolume = musicVolume;
            //shared.flush();
        }
    }
    public function set_soundVolume(value:Float):Float
    {
        //...
        shared.data.soundVolume = value;
        //shared.flush();
        return value;
    }
    private function refreshSoundOn():Void
    {
        //...
        shared.data.isSoundOn = isSoundOn;
        //shared.flush();
    }
    //... and so on
}
```

Все изменения свойств isSoundOn, soundVolume и т.д. будут сохраняться в локальном хранилище пользователя автоматически. Чтобы предыдущие настройки загрузить, после ```AudioManager.getInstance().load();``` нужно вызвать ```AudioManager.getInstance().loadPrevious();```.

```haxe
class Main extends Sprite
{
    public function new()
    {
        super();
        AudioManager.getInstance().load();
        AudioManager.getInstance().loadPrevious();
        var screens = new Screens();
        screens.skin = this;
        screens.open(Menu);
    }
}
```

Со звуками теперь все понятно. Остался еще мендежер для переводов и локализации.

[Исходники](https://gitlab.com/markelov-alex/hx-py-framework-evolution/-/tree/main/d_managers/client_haxe/src/)

[< Назад](01_client_10.md)  |  [Начало](00_intro_01.md)  |  [Вперед >](01_client_12.md)
