/// A five-minute, presenter-led story. The demos use local sample data only.
class PresentationSlide {
  const PresentationSlide(
    this.chapter,
    this.title,
    this.body,
    this.takeaway,
    this.notes,
    this.seconds,
  );

  final String chapter;
  final String title;
  final String body;
  final String takeaway;
  final String notes;
  final int seconds;
}

List<PresentationSlide> presentationSlides(String language) =>
    language == 'en' ? _english : _russian;

const _russian = [
  PresentationSlide(
    'Идея',
    'От кода\nк работающей системе',
    'Pepeunit объединяет устройства и программы: разворачивайте код, связывайте их между собой и наблюдайте результат.',
    'Открытая платформа. Один путь от Git до данных.',
    'Представьте небольшую теплицу: датчик измеряет температуру, вентилятор охлаждает воздух, а график показывает, что происходило ночью. По отдельности всё просто. Сложность начинается, когда нужно связать устройства, обновлять программы и понимать, что работает. Pepeunit собирает эти задачи в одной системе. За пять минут пройдём путь от программы в Git до управляемой сети устройств. Теплица — наш пример; тот же подход подходит для программных сервисов.',
    25,
  ),
  PresentationSlide(
    'Общий язык',
    'Устройство или сервис.\nВсё это Unit.',
    'Unit — участник системы со своей программой, настройками, входами и выходами. Он может работать на микроконтроллере или на сервере.',
    'MicroPython · ESP-IDF · Python · Go',
    'В Pepeunit устройство называется Unit. Но это не обязательно плата: Python-скрипт на сервере тоже может быть Unit. У каждого есть код, переменные окружения и схема обмена сообщениями. Выберите на слайде разные примеры. Для платформы важен общий контракт, а не корпус устройства. Библиотеки MicroPython, ESP-IDF, Python и Go помогают подключиться, отправлять состояние и принимать команды. Логику самого устройства пишет разработчик.',
    30,
  ),
  PresentationSlide(
    'Код → устройство',
    'Начните с Git.\nПродолжайте по воздуху.',
    'Добавьте Repo из GitHub или GitLab, создайте Unit и выполните первый запуск. Дальше управляйте версиями и отправляйте обновления удалённо.',
    'Код, окружение и схема связей — рядом с вашим Unit.',
    'Нажмите на три этапа слева направо. Сначала добавляем подготовленный репозиторий с программой. Затем создаём Unit, задаём окружение и запускаем его на устройстве: первоначальная установка всё ещё нужна. После подключения можно выбирать ветку и режим обновлений, отправлять новую прошивку, окружение или схему. Не нужно каждый раз идти к устройству с кабелем. Устройство должно поддерживать соответствующие команды и быть онлайн. Здесь мы показываем этот путь на демонстрационных данных.',
    40,
  ),
  PresentationSlide(
    'Взаимодействие',
    'Соедините выход\nсо входом.',
    'Связи направляют сообщения между Unit через MQTT. Подключение готовых входов и выходов настраивается в интерфейсе.',
    'Связь настраивает Pepeunit. Реакцию задаёт код Unit.',
    'Теперь дадим датчику собеседника. Нажмите «Соединить», затем поднимите температуру выше 28 градусов. Вентилятор включится: в нашем примере его программа реагирует на порог. Pepeunit связывает выход датчика со входом вентилятора и обновляет схему подписок. Саму реакцию мы предусмотрели в коде Unit; связь не придумывает её за нас. Так уже готовые компоненты можно собирать в новые системы без переписывания их соединений. Снизьте температуру и покажите обратную реакцию.',
    45,
  ),
  PresentationSlide(
    'Наблюдение',
    'Знайте, что происходит.\nДействуйте удалённо.',
    'Состояние, версия, память и логи помогают разобраться в работе Unit. Команды позволяют перезапустить его и обновить настройки.',
    'От «не работает» — к состоянию и журналу событий.',
    'Когда устройств становится больше, мало просто отправить команду. Нужно видеть, какую версию использует Unit, когда он выходил на связь и что пишет в журнал. Переключите состояние, логи и команды. Это разные стороны одного устройства: наблюдаем, выясняем причину, действуем. Можно синхронизировать логи, обновить окружение или перезапустить Unit. Доступность данных зависит от того, что присылает устройство, а доставка команды — от его подключения и поддержки нужного топика.',
    35,
  ),
  PresentationSlide(
    'Данные',
    'Сообщения становятся\nисторией и графиками.',
    'DataPipe фильтрует и преобразует значения, сохраняет их в ClickHouse. Панели Grafana показывают историю, правила создают уведомления.',
    'Последнее значение, история, агрегации и пороги.',
    'Вернёмся к температуре. Одно число отвечает на вопрос «что сейчас», а история — «что было ночью». Включите фильтр на слайде: ошибочное измерение исчезнет из примера. В настоящем DataPipe можно задать диапазон, частоту обработки, преобразование и способ хранения: последнее значение, несколько записей, временное окно или агрегации. Данные хранятся в ClickHouse, а панели строятся в Grafana. Правила уведомлений помогают заметить нужные значения. Эти возможности включаются и настраиваются на инстансе.',
    40,
  ),
  PresentationSlide(
    'Контроль',
    'Ваш инстанс.\nВаши правила доступа.',
    'Разверните Pepeunit через Docker Compose. Выбирайте видимость Unit и выдавайте доступ к приватным устройствам и их входам и выходам.',
    'Аккаунт — файл с приватным ключом вместо пароля.',
    'Pepeunit можно развернуть на своей инфраструктуре. Инстанс хранит ваши устройства и данные, а вы определяете, что открыто другим и кому разрешён доступ к приватным Unit. Переключите примеры видимости. Аккаунт использует файл с приватным ключом вместо пароля: этот файл важно сохранить. Один ключ подходит для входа на разных инстансах. Открытый исходный код позволяет изучать устройство платформы и менять её под свои задачи.',
    35,
  ),
  PresentationSlide(
    'Федерация',
    'Самостоятельные инстансы.\nОбщий каталог идей.',
    'Федерация помогает инстансам находить друг друга и обмениваться публичными Repo. В клиенте можно переключаться между инстансами.',
    'Публичные Repo распространяются. Данные пользователей остаются на инстансе.',
    'Собственный сервер не обязан быть изолированным островом. Если включена федерация и настроено доверие, инстансы узнают о соседях и получают их публичные репозитории. Выберите узел на схеме: каталог программ можно использовать на разных инстансах. При этом федерация не переносит пользовательские данные и не превращает устройства разных серверов в одну общую сеть MQTT. Это способ делиться программами, сохраняя самостоятельность инфраструктуры.',
    30,
  ),
  PresentationSlide(
    'Ваш первый Unit',
    'Возьмите идею.\nСоберите систему.',
    'Подключите репозиторий, запустите Unit, свяжите его с другими и посмотрите на данные. Начать можно с одного устройства или скрипта.',
    'Код → Unit → связи → данные.',
    'Мы прошли полный круг: программа в Git стала Unit, получила связи, управление и историю данных. Всё это можно запустить на своём инстансе и дополнить программами из общего каталога. Следующий шаг — открыть руководство и собрать первый Unit. Спросите аудиторию: какое устройство или сервис вы бы подключили первым? Здесь можно закончить рассказ и перейти к вопросам либо открыть документацию прямо из презентации.',
    20,
  ),
];

const _english = [
  PresentationSlide(
    'The idea',
    'From code\nto a working system',
    'Pepeunit brings devices and software together: deploy code, connect components and see the results.',
    'An open platform. One path from Git to data.',
    'Imagine a small greenhouse: a sensor measures temperature, a fan cools the air, and a chart shows what happened overnight. Each part is simple. The challenge is connecting them, updating software and knowing what works. Pepeunit brings those tasks together. In five minutes we will go from a program in Git to a managed system. The greenhouse is our example; software services can use the same approach.',
    25,
  ),
  PresentationSlide(
    'A shared language',
    'A device or a service.\nBoth are Units.',
    'A Unit has its own program, configuration, inputs and outputs. It can run on a microcontroller or a server.',
    'MicroPython · ESP-IDF · Python · Go',
    'A device in Pepeunit is called a Unit, but it does not have to be a board: a Python script on a server can be a Unit too. Each has code, environment variables and a messaging schema. Select the examples on this slide. The shared contract matters more than the hardware. MicroPython, ESP-IDF, Python and Go libraries help connect, report state and receive commands. The developer writes the application logic.',
    30,
  ),
  PresentationSlide(
    'Code → device',
    'Start with Git.\nUpdate over the air.',
    'Add a Repo from GitHub or GitLab, create a Unit and set it up once. Then manage versions and send updates remotely.',
    'Code, environment and connection schema belong with your Unit.',
    'Select the three stages from left to right. First add a prepared repository. Then create a Unit, configure its environment and run it on the device: initial installation is still required. Once connected, select a branch and update policy, and send firmware, environment or schema updates. You do not need to visit it with a cable every time. The device must be online and implement the relevant commands. This slide illustrates that process with sample data.',
    40,
  ),
  PresentationSlide(
    'Connections',
    'Connect an output\nto an input.',
    'Links route messages between Units over MQTT. Connect existing inputs and outputs directly in the interface.',
    'Pepeunit configures the link. Unit code defines the reaction.',
    'Give the sensor a partner. Press Connect, then raise the temperature above 28 degrees. The fan turns on because our example program implements a threshold. Pepeunit links the sensor output to the fan input and updates the subscription schema. The reaction is application code; a link does not invent it. Ready-made components can form new systems without rewriting their connections. Lower the temperature and show the opposite reaction.',
    45,
  ),
  PresentationSlide(
    'Operations',
    'See what is happening.\nAct remotely.',
    'State, version, memory and logs help explain a Unit’s behavior. Commands let you restart it and update configuration.',
    'From “it does not work” to state and an event log.',
    'As the fleet grows, sending a command is not enough. You need to know the running version, whether the Unit is connected and what its logs say. Switch between state, logs and commands. They are three views of one device: observe, diagnose, act. Sync logs, update the environment or restart a Unit. Available state depends on what the device reports; command delivery requires connectivity and the corresponding command topic.',
    35,
  ),
  PresentationSlide(
    'Data',
    'Messages become\nhistory and charts.',
    'DataPipe filters and transforms values and stores them in ClickHouse. Grafana dashboards show history; rules create alerts.',
    'Latest values, history, aggregations and thresholds.',
    'A single temperature answers “what is happening now”; history answers “what happened overnight”. Enable the filter: an invalid sample disappears from the example. A real DataPipe can configure ranges, processing rate, transformations and storage: the latest value, a number of records, a time window or aggregations. ClickHouse stores the data and Grafana visualizes it. Alert rules draw attention to matching values. These features must be enabled and configured on the instance.',
    40,
  ),
  PresentationSlide(
    'Control',
    'Your instance.\nYour access rules.',
    'Deploy Pepeunit with Docker Compose. Choose Unit visibility and grant access to private devices, inputs and outputs.',
    'Your account uses a private key file instead of a password.',
    'Run Pepeunit on your own infrastructure. Your instance holds your devices and data, while you decide what others can see and who can access private Units. Switch between the visibility examples. An account uses a private key file instead of a password: keep that file safe. The same key can sign in on different instances. Open source lets you study the platform and adapt it to your needs.',
    35,
  ),
  PresentationSlide(
    'Federation',
    'Independent instances.\nA shared catalog of ideas.',
    'Federation helps instances discover each other and share public Repos. Switch between instances in the client.',
    'Public Repos travel. User data stays on its instance.',
    'Your server need not be an isolated island. With federation enabled and trust configured, instances discover neighbors and obtain their public repositories. Select an instance in the diagram: programs can be reused across instances. Federation does not transfer user data or turn devices on different servers into a single MQTT network. It shares programs while keeping infrastructure independent.',
    30,
  ),
  PresentationSlide(
    'Your first Unit',
    'Take an idea.\nBuild a system.',
    'Connect a repository, run a Unit, link it to others and explore the data. Start with one device or script.',
    'Code → Unit → connections → data.',
    'We have completed the loop: a program in Git became a Unit with connections, management and data history. Run it on your own instance and add programs from a shared catalog. The next step is to open the guide and create your first Unit. Ask the audience which device or service they would connect first. End the story here and take questions, or open the documentation directly from the presentation.',
    20,
  ),
];
