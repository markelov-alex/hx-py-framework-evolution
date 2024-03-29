# Эволюция игрового фреймворка. Сервер 2. Приложение

Резюме:
- Standalone-приложение.
- Разделение отображения и логики.
- Выделение отдельного слоя обмена сообщениями-командами между ними.
- Вынесение логики в отдельное физическое приложение, команды превращаются в протокол обмена сообщениями.

Всякое Standalone-приложение можно условно разделить на две составляющие: на бизнес-логику и отображение. Бизнес-логика — это правила игры, или, формально говоря, состояние игры и правила его изменения, а отображение — вывод текущего состояния на экран.

Например, возьмем простейшую игру — [одевалку](01_client_01.md). Допустим, есть три мувиклипа: для шляпы, куртки и штанов. Каждый кадр в мувиклипе — это другая вариация данного типа одежды. Слева и справа от каждого мувиклипа находятся кнопки влево и вправо. Нажимаем на верхнюю кнопку вправо, и меняется шляпа на новую. Влево — возвращается старая. Проще некуда.

![Примитивный Dress-Up](02_server_02_01.png)

"И где тут бизнес-логика?" — спросите вы — "Где состояние? Одно отображение". И да и нет. Дело в том, что тут логика выражена в тех же объектах и свойствах, что и отображение. Поэтому логика еще не отделена от отображения, слита с ним в одно неразделенное целое. Состояние игры выражено текущими кадрами мувиклипов (currentFrame), а логика смены состояния производится методами gotoAndStop() того же класса. И то и другое относится к отображению, поэтому не удивительно, что логику трудно увидеть.

В таком простом приложении, как наш пример, такая слитность не имеет большого значения, но в больших приложениях она критично сказывается на производительности разработчиков, так как очень легко запутаться в переплетении того и другого. Поэтому выделим логику из отображения. Мы рассмотрели уже [ранее в подробностях](01_client_15.md), как это делается, поэтому сразу создадим отдельный класс Controller. Класс будет где-то внутри себя хранить состояние и измененять его. Также контроллер при каждом изменении состояния будет генерировать сигналы (события), которые будет слушать отображение и обновлять по ним состояние экрана.

В результате, получатся две подсистемы, два слоя — логика и ее отображение, которые относительно независимы друг от друга. Независимы в том смысле, что для одного отображения можно подставлять разные версии контроллера, которые будут реализовывать разные правила игры. И наоборот — с одним и тем же контроллером можно использовать разные версии отображения, меняя графику, эффекты и прочее для одних и тех же правил игры.

Отображение вызывает методы контроллера и слушает его сигналы, но контроллер ничего не знает об отображении. Связь однонаправленная, поэтому отображение может меняться, никак не затрагивая логику. А так как логика предоставляет обобщенный интерфейс, то и она может иметь разные реализации так, чтобы не требовалось вносить изменения в отображение. Но все же зависимость их друг от друга, хоть и слабая, но еще немного остается. Именно из-за прямого вызова методов контроллера отображением.

Сделаем эти две подсистемы совершенно независимыми друг от друга. Для этого введем третий, промежуточный слой между ними — слой сообщений, или команд. Физически он представляет собой класс с одним методом send() для отправки сообщений и одним сигналом receiveSignal для оповещения в получении.

Конечно, вызов метода класса — это тоже способ передачи сообщения. Только тут имя сообщения и его параметры жестко фиксируются в коде в сигнатурой метода. Но если мы перенесем имя и параметры сообщения в отдельный динамический объект, то сможем использовать какие угодно значения имени и параметров, без оглядки на код. Новые типы сообщений можно даже создавать на лету, без перекомпилирования кода.

![Эволюция общей схемы приложения](02_server_02_02.png)

В итоге классы контроллеров и отображения больше не завязаны друг на друга. Они зависят только от промежуточного класса, который всегда одинаковый и не меняется, и формата объектов сообщений. Фокус внимания смещается с интерфейса контроллеров на формат команд.

Сами сообщения представляют собой обычные JSON-объекты, со стандартными фиксированными полями, вроде code, from, to, target, value. Именно это в совокупности о составляет формат сообщения. Чтобы не создавать особый протокол для каждого типа игры, нужно для полей подобрать достаточно общие и абстрактные названия. Тогда формат сообщений будет всегда одинаковым и неизменным — фиксированным, а наши подсистемы по-настоящему независимы.

Отделив контроллеры от отображения посредством системы сообщений (команд), у нас появляется возможность запускать эти подсистемы на разных машинах. Ведь мы больше не привязаны к вызовам методов, а объекты можно всегда сериализовать и передавать по сети. Контроллер, реализующий логику игры, получает команды от промежуточного слоя передачи сообщений и ему все равно откуда они там появляются: от локального ли отображения или от удаленного, с этой машины или с другой. То же самое, когда контроллер передает сообщения: он адресует их определенному игроку, а прослойка уже сама решает передать ее локальному отображению или по сетевому соединению на другой компьютер.

![Отделение сервера от клиента. Listen server](02_server_02_03.png)

Так мы пришли к реализации концепции Server + Clients. А точнее Listen Server, который еще может совмещать в одной программе и функции клиента, и функции сервера. Аналогично, можно продолжить мысль и вообще вынести логику игры в отдельное приложение. Ведь контроллеры и отображения настолько отдельны и независимы друг от друга, что они могут находится не только в разных приложениях, но могут быть даже написаны на разных языках программирования. Поэтому если в отдельной программе будет только логика, без отображения, то получим Dedicated Server. А отображение без логики, соответственно, будет клиентом.

![Отделение сервера от клиента. Dedicated server](02_server_02_04.png)

Все типы серверов и клиентов используют один и тот же формат сообщений. Если нам удастся придумать такой формат, который был бы одинаковым для всех типов и жанров игр, тогда мы можем разрабатывать разные части игры совершенно отдельно и независимо от прочих частей. Например, мы можем продумать универсальный набор команд для карточных игр, где будут только самые общие операции вроде: переместить карту (между колодой, отбоем и игроками), перевернуть ее (открыть или закрыть), выделить или отменить выделение с карты и т.д. Далее, создаем подсистему отображения, которая исполняет эти команды и показывает соответствующие изменения на экране. Самое замечательное в ней то, что она теперь будет работать для всех карточных игр, которые мы уже написали, или которые нам только предстоит написать. Мы получили универсальный карточный клиент, и все благодаря выбранной нами обобщенной системы команд.

Теперь осталось подставить нужную графику и реализовать правила той или иной карточной игры в контроллере, который должен просто генерировать нужные команды в нужное время. Все команды стандартные и одинаковы для всех разновидностей карточных игр. Да по большому счету, и всех игр вообще, т.к. любые игровые понятия можно свести к самым абстрактным: добавить, удалить, переместить, выделить и т.д.

Формат сообщений, названия команд и набор их параметров составляют вместе протокол обмена сообщениями. Протокол — это то общее связующее звено, что объединяет логику и отображение, сервер и клиенты. Может существовать множество реализаций сервера, но пока они используют один протокол, это никак не влияет на клиенты, и наоборот. Вот почему важно придумать как можно более абстрактную систему команд. Тогда все игры будут иметь привычный набор команд, хоть они и будут реализованы для каждой отдельной игры по-разному. Серверы и клиенты можно разрабатывать отдельно, независимыми командами, и при этом изменения в одном не будут требовать изменений в другом.

Для выработки такого протокола потребуется систематизация и анализ всех существующих игровых жанров, а это тема уже [следующего цикла](03_game_01.md). Пока что мы переходим непосредственно к реализации игрового сервера на Python и эволюции его до фреймворка, на котором можно будет построить любую игру и любой протокол.

[Исходники](https://gitlab.com/markelov-alex/hx-py-framework-evolution/-/tree/main/f_models/)

[< Назад](02_server_01.md)  |  [Начало](00_intro_01.md)  |  [Вперед >](02_server_03.md)
