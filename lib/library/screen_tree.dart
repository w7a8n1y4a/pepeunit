import '../locale/languages.dart';

/// What a screen is for, or `cell` for a cell that lives on a screen and has
/// no route of its own: a button, a field, a switch, a panel it opens.
enum ScreenKind { menu, search, list, form, card, pick, text, cell }

String screenKindLabel(String language, ScreenKind kind) {
  switch (kind) {
    case ScreenKind.menu:
      return phrase(language, {'ru': 'Меню', 'en': 'Menu'});
    case ScreenKind.search:
      return phrase(language, {'ru': 'Поиск', 'en': 'Search'});
    case ScreenKind.list:
      return phrase(language, {'ru': 'Список', 'en': 'List'});
    case ScreenKind.form:
      return phrase(language, {'ru': 'Форма', 'en': 'Form'});
    case ScreenKind.card:
      return phrase(language, {'ru': 'Карточка', 'en': 'Card'});
    case ScreenKind.pick:
      return phrase(language, {'ru': 'Выбор', 'en': 'Pick'});
    case ScreenKind.text:
      return phrase(language, {'ru': 'Текст', 'en': 'Text'});
    case ScreenKind.cell:
      return phrase(language, {'ru': 'Сота', 'en': 'Cell'});
  }
}

/// Who may use a screen or a cell, from the least to the most.
enum ScreenNeed { open, signedIn, creator, staff, owner }

String screenNeedLabel(String language, ScreenNeed need) {
  switch (need) {
    case ScreenNeed.open:
      return phrase(language, {'ru': 'Всем', 'en': 'Anyone'});
    case ScreenNeed.signedIn:
      return phrase(language, {
        'ru': 'Нужен вход в аккаунт',
        'en': 'A sign-in is needed',
      });
    case ScreenNeed.creator:
      return phrase(language, {
        'ru': 'Нужен вход, создателю записи',
        'en': 'A sign-in, for the creator of the record',
      });
    case ScreenNeed.staff:
      return phrase(language, {
        'ru': 'Нужна роль Admin или Owner',
        'en': 'The Admin or Owner role is needed',
      });
    case ScreenNeed.owner:
      return phrase(language, {
        'ru': 'Нужна роль Owner',
        'en': 'The Owner role is needed',
      });
  }
}

/// One screen of the client, a route pattern of `lib/main.dart`, or one cell
/// of a screen: the address of the screen, `#`, and the id of the cell.
///
/// [open] is true when the screen opens from its address alone. A screen that
/// needs a chosen record, a value from the screen before it, or that hands a
/// choice back to its opener is not. A cell is never opened: it acts.
///
/// [tone] names the color the screen or cell wears when it is not the color
/// of its section (the color of the cells of that screen in the app), and
/// [need] the least access it asks. What a row leaves empty it takes from the
/// screen above it.
class ScreenNode {
  const ScreenNode(
    this.path,
    this.kind,
    this.ru,
    this.en, {
    this.open = false,
    this.tone,
    this.need,
  });

  final String path;
  final ScreenKind kind;
  final String ru;
  final String en;
  final bool open;
  final String? tone;
  final ScreenNeed? need;

  bool get isCell => kind == ScreenKind.cell;

  String title(String language) => phrase(language, {'ru': ru, 'en': en});

  /// The address of the screen: for a cell, the one it stands on.
  String get screenPath {
    final at = path.indexOf('#');
    return at < 0 ? path : path.substring(0, at);
  }

  /// The home menu section that holds the screen. Empty for the home screen.
  String get section {
    final parts = screenPath.split('/').where((part) => part.isNotEmpty);
    return parts.isEmpty ? '' : parts.first;
  }

  /// Names of the path parameters: `uuid` and `io` for `/units/:uuid/io/:io`.
  List<String> get params => [
    for (final match in RegExp(r':(\w+)').allMatches(screenPath))
      match.group(1)!,
  ];
}

const screenRoot = '/';

/// Every screen of the router and every cell on them, a parent before its
/// children. A new route in `lib/main.dart` gets its row here in the same
/// change, and a new cell gets its row under its screen: a test compares the
/// screens with the router, parents included.
const screenTree = <ScreenNode>[
  ScreenNode('/', ScreenKind.menu, 'Главная', 'Home', open: true),
  ScreenNode(
    '/background-only',
    ScreenKind.card,
    'Только фон',
    'Background only',
    open: true,
  ),
  ScreenNode('/people', ScreenKind.menu, 'Аккаунт', 'Account', open: true),
  ScreenNode(
    '/people#profile',
    ScreenKind.cell,
    'Профиль',
    'Profile',
    need: ScreenNeed.signedIn,
  ),
  ScreenNode('/people#key', ScreenKind.cell, 'Скачать ключ', 'Download key'),
  ScreenNode(
    '/people#signout',
    ScreenKind.cell,
    'Выход',
    'Sign out',
    need: ScreenNeed.signedIn,
  ),
  ScreenNode('/people/login', ScreenKind.form, 'Вход', 'Sign in', open: true),
  ScreenNode(
    '/people/login#load',
    ScreenKind.cell,
    'Загрузка ключа',
    'Load key',
  ),
  ScreenNode(
    '/people/register',
    ScreenKind.form,
    'Регистрация',
    'Registration',
    open: true,
  ),
  ScreenNode(
    '/people/register#generate',
    ScreenKind.cell,
    'Генерация ключа',
    'Generate key',
  ),
  ScreenNode(
    '/people/settings',
    ScreenKind.menu,
    'Настройки',
    'Settings',
    open: true,
  ),
  ScreenNode(
    '/people/settings#icon',
    ScreenKind.cell,
    'Загрузить аватар',
    'Upload avatar',
    need: ScreenNeed.signedIn,
  ),
  ScreenNode(
    '/people/settings#login',
    ScreenKind.cell,
    'Изменить логин',
    'Change login',
    need: ScreenNeed.signedIn,
  ),
  ScreenNode(
    '/people/settings#sync',
    ScreenKind.cell,
    'Отправить в избранный',
    'Send to favorite',
    need: ScreenNeed.signedIn,
  ),
  ScreenNode(
    '/people/settings#pull',
    ScreenKind.cell,
    'Вытянуть из избранного',
    'Pull from favorite',
    need: ScreenNeed.signedIn,
  ),
  ScreenNode(
    '/people/settings#parameters',
    ScreenKind.cell,
    'Приложение',
    'Application',
  ),
  ScreenNode(
    '/people/settings/alerts',
    ScreenKind.form,
    'Уведомления',
    'Alerts',
    open: true,
  ),
  ScreenNode(
    '/people/settings/alerts#scheduled',
    ScreenKind.cell,
    'Сводки',
    'Summaries',
  ),
  ScreenNode(
    '/people/settings/alerts#time',
    ScreenKind.cell,
    'Время UTC',
    'UTC time',
  ),
  ScreenNode(
    '/people/settings/alerts#pipe',
    ScreenKind.cell,
    'DataPipe',
    'DataPipe',
  ),
  ScreenNode(
    '/people/settings/alerts#telegram',
    ScreenKind.cell,
    'Телеграм',
    'Telegram',
  ),
  ScreenNode(
    '/units',
    ScreenKind.menu,
    'Аппараты',
    'Units',
    open: true,
    need: ScreenNeed.signedIn,
  ),
  ScreenNode(
    '/units/search',
    ScreenKind.search,
    'Поиск аппаратов',
    'Unit search',
    open: true,
  ),
  ScreenNode(
    '/units/new',
    ScreenKind.form,
    'Новый аппарат',
    'New unit',
    open: true,
  ),
  ScreenNode('/units/new#name', ScreenKind.cell, 'Имя', 'Name'),
  ScreenNode(
    '/units/new#visibility',
    ScreenKind.cell,
    'Видимость',
    'Visibility',
  ),
  ScreenNode(
    '/units/new#create',
    ScreenKind.cell,
    'Создать',
    'Create',
    tone: 'add',
  ),
  ScreenNode(
    '/units/new/repo',
    ScreenKind.pick,
    'Репозиторий',
    'Repository',
    tone: 'registry',
  ),
  ScreenNode('/units/new/branch', ScreenKind.pick, 'Ветка', 'Branch'),
  ScreenNode('/units/new/commit', ScreenKind.pick, 'Коммит', 'Commit'),
  ScreenNode('/units/new/updates', ScreenKind.form, 'Обновления', 'Updates'),
  ScreenNode(
    '/units/new/updates#compilable',
    ScreenKind.cell,
    'Компилируемые',
    'Compilable',
  ),
  ScreenNode(
    '/units/new/updates#auto',
    ScreenKind.cell,
    'Автообновление',
    'Auto update',
  ),
  ScreenNode('/units/new/updates#tags', ScreenKind.cell, 'Теги', 'Tags'),
  ScreenNode('/units/new/platform', ScreenKind.pick, 'Платформа', 'Platform'),
  ScreenNode(
    '/units/groups',
    ScreenKind.search,
    'Группы',
    'Groups',
    open: true,
    tone: 'groups',
  ),
  ScreenNode(
    '/units/groups#create',
    ScreenKind.cell,
    'Создать группу',
    'Create group',
    tone: 'add',
  ),
  ScreenNode(
    '/units/groups/new',
    ScreenKind.form,
    'Новая группа',
    'New group',
    open: true,
  ),
  ScreenNode('/units/groups/new#name', ScreenKind.cell, 'Имя', 'Name'),
  ScreenNode(
    '/units/groups/new#create',
    ScreenKind.cell,
    'Создать группу',
    'Create group',
    tone: 'add',
  ),
  ScreenNode('/units/groups/:gid', ScreenKind.menu, 'Группа', 'Group'),
  ScreenNode('/units/groups/:gid#name', ScreenKind.cell, 'Имя', 'Name'),
  ScreenNode('/units/groups/:gid#icon', ScreenKind.cell, 'Иконка', 'Icon'),
  ScreenNode(
    '/units/groups/:gid#delete',
    ScreenKind.cell,
    'Удалить',
    'Delete',
    tone: 'danger',
  ),
  ScreenNode(
    '/units/groups/:gid/members',
    ScreenKind.search,
    'Участники',
    'Members',
  ),
  ScreenNode(
    '/units/groups/:gid/members#add',
    ScreenKind.cell,
    'Добавить',
    'Add',
  ),
  ScreenNode(
    '/units/groups/:gid/unit/:uid',
    ScreenKind.menu,
    'Аппарат в группе',
    'Unit in a group',
  ),
  ScreenNode(
    '/units/groups/:gid/unit/:uid#open',
    ScreenKind.cell,
    'Открыть',
    'Open',
  ),
  ScreenNode(
    '/units/groups/:gid/unit/:uid#unlink',
    ScreenKind.cell,
    'Убрать',
    'Remove',
    tone: 'danger',
  ),
  ScreenNode('/units/:uuid', ScreenKind.menu, 'Аппарат', 'Unit'),
  ScreenNode(
    '/units/:uuid#card',
    ScreenKind.cell,
    'Карточка аппарата',
    'Unit card',
  ),
  ScreenNode(
    '/units/:uuid#env',
    ScreenKind.cell,
    'Переменные окружения',
    'Environment variables',
    need: ScreenNeed.creator,
  ),
  ScreenNode(
    '/units/:uuid/settings',
    ScreenKind.form,
    'Настройки',
    'Settings',
    need: ScreenNeed.creator,
  ),
  ScreenNode(
    '/units/:uuid/settings#avatar',
    ScreenKind.cell,
    'Загрузить аватар',
    'Upload avatar',
  ),
  ScreenNode('/units/:uuid/settings#name', ScreenKind.cell, 'Имя', 'Name'),
  ScreenNode(
    '/units/:uuid/settings#visibility',
    ScreenKind.cell,
    'Видимость',
    'Visibility',
  ),
  ScreenNode(
    '/units/:uuid/settings#save',
    ScreenKind.cell,
    'Сохранить',
    'Save',
    tone: 'add',
  ),
  ScreenNode('/units/:uuid/info', ScreenKind.card, 'Сведения', 'Info'),
  ScreenNode(
    '/units/:uuid/info#updates',
    ScreenKind.cell,
    'Обновления',
    'Updates',
  ),
  ScreenNode('/units/:uuid/info#network', ScreenKind.cell, 'Сеть', 'Network'),
  ScreenNode('/units/:uuid/info#ram', ScreenKind.cell, 'ОЗУ', 'RAM'),
  ScreenNode('/units/:uuid/info#flash', ScreenKind.cell, 'Флеш', 'Flash'),
  ScreenNode('/units/:uuid/info#time', ScreenKind.cell, 'Время', 'Time'),
  ScreenNode('/units/:uuid/info#freq', ScreenKind.cell, 'Частота', 'Frequency'),
  ScreenNode(
    '/units/:uuid/work',
    ScreenKind.menu,
    'Управление',
    'Control',
    need: ScreenNeed.creator,
  ),
  ScreenNode('/units/:uuid/work#logs', ScreenKind.cell, 'Логи', 'Logs'),
  ScreenNode('/units/:uuid/work#state', ScreenKind.cell, 'Состояние', 'State'),
  ScreenNode(
    '/units/:uuid/work/commands',
    ScreenKind.menu,
    'Команды',
    'Commands',
  ),
  ScreenNode(
    '/units/:uuid/work/commands#update',
    ScreenKind.cell,
    'Обновить прошивку',
    'Update firmware',
  ),
  ScreenNode(
    '/units/:uuid/work/commands#envupdate',
    ScreenKind.cell,
    'Обновить окружение',
    'Update environment',
  ),
  ScreenNode(
    '/units/:uuid/work/commands#schemaupdate',
    ScreenKind.cell,
    'Обновить схему',
    'Update schema',
  ),
  ScreenNode(
    '/units/:uuid/work/commands#logsync',
    ScreenKind.cell,
    'Синхронизировать логи',
    'Sync logs',
  ),
  ScreenNode(
    '/units/:uuid/work/commands#reset',
    ScreenKind.cell,
    'Перезапустить аппарат',
    'Restart unit',
  ),
  ScreenNode(
    '/units/:uuid/work/archives',
    ScreenKind.menu,
    'Архивы',
    'Archives',
  ),
  ScreenNode('/units/:uuid/work/archives#zip', ScreenKind.cell, 'ZIP', 'ZIP'),
  ScreenNode('/units/:uuid/work/archives#tar', ScreenKind.cell, 'TAR', 'TAR'),
  ScreenNode('/units/:uuid/work/archives#tgz', ScreenKind.cell, 'TGZ', 'TGZ'),
  ScreenNode(
    '/units/:uuid/work/platforms',
    ScreenKind.list,
    'Платформы',
    'Platforms',
  ),
  ScreenNode('/units/:uuid/work/delete', ScreenKind.form, 'Удаление', 'Delete'),
  ScreenNode(
    '/units/:uuid/work/delete#confirm',
    ScreenKind.cell,
    'Удалить аппарат',
    'Delete unit',
    tone: 'danger',
  ),
  ScreenNode(
    '/units/:uuid/access',
    ScreenKind.list,
    'Доступ',
    'Access',
    tone: 'access',
    need: ScreenNeed.creator,
  ),
  ScreenNode('/units/:uuid/access#add', ScreenKind.cell, 'Добавить', 'Add'),
  ScreenNode(
    '/units/:uuid/io',
    ScreenKind.list,
    'Входы и выходы',
    'Inputs and outputs',
    tone: 'io',
  ),
  ScreenNode(
    '/units/:uuid/io/:io',
    ScreenKind.menu,
    'Вход или выход',
    'Input or output',
  ),
  ScreenNode('/units/:uuid/io/:io#card', ScreenKind.cell, 'Топик', 'Topic'),
  ScreenNode('/units/:uuid/io/:io#value', ScreenKind.cell, 'Значение', 'Value'),
  ScreenNode(
    '/units/:uuid/io/:io/settings',
    ScreenKind.form,
    'Настройки',
    'Settings',
    need: ScreenNeed.creator,
  ),
  ScreenNode(
    '/units/:uuid/io/:io/settings#max',
    ScreenKind.cell,
    'Максимум связей',
    'Max links',
  ),
  ScreenNode(
    '/units/:uuid/io/:io/settings#visibility',
    ScreenKind.cell,
    'Видимость',
    'Visibility',
  ),
  ScreenNode(
    '/units/:uuid/io/:io/settings#rewrite',
    ScreenKind.cell,
    'Перезаписываемый',
    'Rewritable',
  ),
  ScreenNode(
    '/units/:uuid/io/:io/settings#save',
    ScreenKind.cell,
    'Сохранить',
    'Save',
    tone: 'add',
  ),
  ScreenNode(
    '/units/:uuid/io/:io/links',
    ScreenKind.list,
    'Связи',
    'Links',
    tone: 'link',
  ),
  ScreenNode(
    '/units/:uuid/io/:io/links#add',
    ScreenKind.cell,
    'Добавить',
    'Add',
  ),
  ScreenNode(
    '/units/:uuid/io/:io/pipe',
    ScreenKind.form,
    'Пайп',
    'Pipe',
    tone: 'pipe',
    need: ScreenNeed.creator,
  ),
  ScreenNode(
    '/units/:uuid/io/:io/pipe#flag',
    ScreenKind.cell,
    'DataPipe',
    'DataPipe',
  ),
  ScreenNode(
    '/units/:uuid/io/:io/pipe#editor',
    ScreenKind.cell,
    'Редактор',
    'Editor',
  ),
  ScreenNode(
    '/units/:uuid/io/:io/pipe#import',
    ScreenKind.cell,
    'Импорт',
    'Import',
  ),
  ScreenNode(
    '/units/:uuid/io/:io/pipe#export',
    ScreenKind.cell,
    'Экспорт',
    'Export',
  ),
  ScreenNode(
    '/units/:uuid/io/:io/pipe#clear',
    ScreenKind.cell,
    'Удалить все данные',
    'Delete all data',
    tone: 'danger',
  ),
  ScreenNode(
    '/units/:uuid/io/:io/access',
    ScreenKind.list,
    'Доступ',
    'Access',
    tone: 'access',
    need: ScreenNeed.creator,
  ),
  ScreenNode(
    '/units/:uuid/io/:io/access#add',
    ScreenKind.cell,
    'Добавить',
    'Add',
  ),
  ScreenNode('/units/pick', ScreenKind.pick, 'Выбор аппарата', 'Pick a unit'),
  ScreenNode(
    '/units/pick-user',
    ScreenKind.pick,
    'Выбор пользователя',
    'Pick a user',
    tone: 'people',
  ),
  ScreenNode(
    '/units/outputs',
    ScreenKind.pick,
    'Выбор выхода',
    'Pick an output',
    tone: 'io',
  ),
  ScreenNode(
    '/units/access/kind',
    ScreenKind.pick,
    'Вид доступа',
    'Access kind',
    tone: 'access',
  ),
  ScreenNode(
    '/units/access/kind#user',
    ScreenKind.cell,
    'Пользователь',
    'User',
    tone: 'people',
  ),
  ScreenNode(
    '/units/access/kind#unit',
    ScreenKind.cell,
    'Аппарат',
    'Unit',
    tone: 'units',
  ),
  ScreenNode(
    '/units/pipe/:uuid/data',
    ScreenKind.list,
    'Данные пайпа',
    'Pipe data',
    tone: 'pipe',
  ),
  ScreenNode('/peers', ScreenKind.menu, 'Сеть', 'Network', open: true),
  ScreenNode(
    '/peers/search',
    ScreenKind.search,
    'Поиск узлов',
    'Peer search',
    open: true,
  ),
  ScreenNode(
    '/peers/search/settings',
    ScreenKind.form,
    'Настройки поиска',
    'Search settings',
    open: true,
  ),
  ScreenNode(
    '/peers/search/settings#add',
    ScreenKind.cell,
    'Добавить локально',
    'Add locally',
    tone: 'add',
  ),
  ScreenNode(
    '/peers/allow',
    ScreenKind.list,
    'Разрешённые',
    'Allowed',
    open: true,
  ),
  ScreenNode(
    '/peers/deny',
    ScreenKind.list,
    'Запрещённые',
    'Denied',
    open: true,
  ),
  ScreenNode(
    '/peers/add',
    ScreenKind.form,
    'Добавить узел',
    'Add a peer',
    open: true,
  ),
  ScreenNode('/peers/add#url', ScreenKind.cell, 'Ссылка', 'Link'),
  ScreenNode(
    '/peers/track',
    ScreenKind.form,
    'Отслеживать',
    'Track',
    open: true,
    need: ScreenNeed.owner,
  ),
  ScreenNode('/peers/track#url', ScreenKind.cell, 'Ссылка', 'Link'),
  ScreenNode('/peers/instance', ScreenKind.card, 'Экземпляр', 'Instance'),
  ScreenNode(
    '/peers/instance#identity',
    ScreenKind.cell,
    'Инстанс',
    'Instance',
  ),
  ScreenNode('/peers/instance#metrics', ScreenKind.cell, 'Сводка', 'Summary'),
  ScreenNode(
    '/peers/instance#target',
    ScreenKind.cell,
    'Сделать избранным',
    'Make favorite',
  ),
  ScreenNode(
    '/peers/instance#clear',
    ScreenKind.cell,
    'Снять избранный',
    'Clear favorite',
  ),
  ScreenNode(
    '/peers/instance#telegram',
    ScreenKind.cell,
    'Телеграм',
    'Telegram',
  ),
  ScreenNode(
    '/peers/instance#peer',
    ScreenKind.cell,
    'Модерация',
    'Moderation',
    need: ScreenNeed.staff,
  ),
  ScreenNode(
    '/peers/instance#trust',
    ScreenKind.cell,
    'Доверять',
    'Trust',
    need: ScreenNeed.staff,
  ),
  ScreenNode(
    '/peers/instance#block',
    ScreenKind.cell,
    'Блокировать',
    'Block',
    need: ScreenNeed.staff,
  ),
  ScreenNode(
    '/peers/instance#scan',
    ScreenKind.cell,
    'Опросить',
    'Scan',
    need: ScreenNeed.staff,
  ),
  ScreenNode(
    '/peers/instance#delete',
    ScreenKind.cell,
    'Удалить',
    'Delete',
    tone: 'danger',
    need: ScreenNeed.staff,
  ),
  ScreenNode(
    '/peers/users',
    ScreenKind.search,
    'Пользователи',
    'Users',
    open: true,
    need: ScreenNeed.signedIn,
  ),
  ScreenNode('/peers/users/member', ScreenKind.card, 'Пользователь', 'User'),
  ScreenNode('/peers/users/member#card', ScreenKind.cell, 'Карточка', 'Card'),
  ScreenNode(
    '/peers/users/member#grant',
    ScreenKind.cell,
    'Сделать админом',
    'Grant admin',
    need: ScreenNeed.owner,
  ),
  ScreenNode(
    '/peers/users/member#revoke',
    ScreenKind.cell,
    'Снять админа',
    'Revoke admin',
    need: ScreenNeed.owner,
  ),
  ScreenNode(
    '/peers/users/member#block',
    ScreenKind.cell,
    'Заблокировать',
    'Block',
    tone: 'danger',
    need: ScreenNeed.staff,
  ),
  ScreenNode(
    '/peers/users/member#unblock',
    ScreenKind.cell,
    'Разблокировать',
    'Unblock',
    need: ScreenNeed.staff,
  ),
  ScreenNode(
    '/peers/tune',
    ScreenKind.menu,
    'Управление',
    'Management',
    open: true,
    need: ScreenNeed.owner,
  ),
  ScreenNode(
    '/peers/tune/:category',
    ScreenKind.menu,
    'Настройки и команды',
    'Settings and commands',
  ),
  ScreenNode(
    '/peers/tune/:category#instance',
    ScreenKind.cell,
    'Инстанс',
    'Instance',
  ),
  ScreenNode('/peers/tune/:category#mqtt', ScreenKind.cell, 'MQTT', 'MQTT'),
  ScreenNode(
    '/peers/tune/:category#datapipe',
    ScreenKind.cell,
    'DataPipe',
    'DataPipe',
  ),
  ScreenNode(
    '/peers/tune/:category#notifications',
    ScreenKind.cell,
    'Уведомления',
    'Notifications',
  ),
  ScreenNode(
    '/peers/tune/:category#telegram',
    ScreenKind.cell,
    'Телеграм бот',
    'Telegram Bot',
  ),
  ScreenNode(
    '/peers/tune/:category#icon',
    ScreenKind.cell,
    'Загрузить аватар',
    'Upload avatar',
  ),
  ScreenNode('/peers/tune/:category#tests', ScreenKind.cell, 'Тесты', 'Tests'),
  ScreenNode(
    '/peers/tune/:category#scan-all',
    ScreenKind.cell,
    'Опросить соседей',
    'Poll neighbors',
  ),
  ScreenNode(
    '/peers/tune/:category#update-repos',
    ScreenKind.cell,
    'Обновить репозитории',
    'Update repositories',
  ),
  ScreenNode(
    '/peers/tune/:category#update-units',
    ScreenKind.cell,
    'Обновить все',
    'Update all',
  ),
  ScreenNode(
    '/peers/tune/:category#reboot',
    ScreenKind.cell,
    'Перезапуск',
    'Reboot',
    tone: 'danger',
  ),
  ScreenNode(
    '/registry',
    ScreenKind.menu,
    'Репозитории',
    'Repositories',
    open: true,
    need: ScreenNeed.signedIn,
  ),
  ScreenNode(
    '/registry/search',
    ScreenKind.search,
    'Поиск репозиториев',
    'Repository search',
    open: true,
  ),
  ScreenNode(
    '/registry/new',
    ScreenKind.form,
    'Новый репозиторий',
    'New repository',
    open: true,
  ),
  ScreenNode('/registry/new#url', ScreenKind.cell, 'Ссылка', 'Link'),
  ScreenNode(
    '/registry/new#platform',
    ScreenKind.cell,
    'Платформа',
    'Platform',
  ),
  ScreenNode('/registry/new#access', ScreenKind.cell, 'Доступ', 'Access'),
  ScreenNode(
    '/registry/new#create',
    ScreenKind.cell,
    'Добавить',
    'Add',
    tone: 'add',
  ),
  ScreenNode(
    '/registry/new/credentials',
    ScreenKind.form,
    'Доступ',
    'Credentials',
  ),
  ScreenNode('/registry/new/credentials#name', ScreenKind.cell, 'Имя', 'Name'),
  ScreenNode(
    '/registry/new/credentials#token',
    ScreenKind.cell,
    'Токен',
    'Token',
  ),
  ScreenNode(
    '/registry/repo/:uuid',
    ScreenKind.card,
    'Репозиторий',
    'Repository',
  ),
  ScreenNode('/registry/repo/:uuid#card', ScreenKind.cell, 'Карточка', 'Card'),
  ScreenNode(
    '/registry/repo/:uuid#summary',
    ScreenKind.cell,
    'Сводка',
    'Summary',
  ),
  ScreenNode(
    '/registry/repo/:uuid#unit',
    ScreenKind.cell,
    'Создать аппарат',
    'Create unit',
    tone: 'add',
  ),
  ScreenNode(
    '/registry/repo/:uuid#sync',
    ScreenKind.cell,
    'Синхронизировать',
    'Synchronize',
    need: ScreenNeed.creator,
  ),
  ScreenNode(
    '/registry/repo/:uuid#delete',
    ScreenKind.cell,
    'Удалить',
    'Delete',
    tone: 'danger',
    need: ScreenNeed.creator,
  ),
  ScreenNode(
    '/registry/repo/:uuid/credentials',
    ScreenKind.form,
    'Доступ',
    'Credentials',
    need: ScreenNeed.creator,
  ),
  ScreenNode(
    '/registry/repo/:uuid/credentials#name',
    ScreenKind.cell,
    'Имя',
    'Name',
  ),
  ScreenNode(
    '/registry/repo/:uuid/credentials#token',
    ScreenKind.cell,
    'Токен',
    'Token',
  ),
  ScreenNode(
    '/registry/repo/:uuid/branches',
    ScreenKind.list,
    'Ветки',
    'Branches',
  ),
  ScreenNode(
    '/dashboards',
    ScreenKind.menu,
    'Панели',
    'Dashboards',
    open: true,
    need: ScreenNeed.signedIn,
  ),
  ScreenNode(
    '/dashboards/search',
    ScreenKind.search,
    'Поиск панелей',
    'Dashboard search',
    open: true,
  ),
  ScreenNode(
    '/dashboards/new',
    ScreenKind.form,
    'Новая панель',
    'New dashboard',
    open: true,
  ),
  ScreenNode('/dashboards/new#name', ScreenKind.cell, 'Имя', 'Name'),
  ScreenNode(
    '/dashboards/new#create',
    ScreenKind.cell,
    'Создать панель',
    'Create dashboard',
    tone: 'add',
  ),
  ScreenNode(
    '/dashboards/type',
    ScreenKind.pick,
    'Тип визуализации',
    'Panel type',
  ),
  ScreenNode('/dashboards/:uuid', ScreenKind.menu, 'Панель', 'Dashboard'),
  ScreenNode(
    '/dashboards/:uuid#card',
    ScreenKind.cell,
    'Карточка панели',
    'Dashboard card',
  ),
  ScreenNode(
    '/dashboards/:uuid#info',
    ScreenKind.cell,
    'Информация',
    'Information',
  ),
  ScreenNode(
    '/dashboards/:uuid#sync',
    ScreenKind.cell,
    'Отправить в Grafana',
    'Send to Grafana',
  ),
  ScreenNode(
    '/dashboards/:uuid#open',
    ScreenKind.cell,
    'Открыть в Grafana',
    'Open in Grafana',
  ),
  ScreenNode('/dashboards/:uuid/delete', ScreenKind.form, 'Удаление', 'Delete'),
  ScreenNode(
    '/dashboards/:uuid/delete#confirm',
    ScreenKind.cell,
    'Удалить панель',
    'Delete dashboard',
    tone: 'danger',
  ),
  ScreenNode(
    '/dashboards/:uuid/panels',
    ScreenKind.list,
    'Визуализации',
    'Panels',
  ),
  ScreenNode(
    '/dashboards/:uuid/panels#add',
    ScreenKind.cell,
    'Добавить',
    'Add',
    tone: 'add',
  ),
  ScreenNode(
    '/dashboards/:uuid/panels/new',
    ScreenKind.form,
    'Новая визуализация',
    'New panel',
  ),
  ScreenNode(
    '/dashboards/:uuid/panels/new#name',
    ScreenKind.cell,
    'Название',
    'Title',
  ),
  ScreenNode(
    '/dashboards/:uuid/panels/new#create',
    ScreenKind.cell,
    'Создать',
    'Create',
    tone: 'add',
  ),
  ScreenNode(
    '/dashboards/:uuid/panels/:pid',
    ScreenKind.menu,
    'Визуализация',
    'Panel',
  ),
  ScreenNode(
    '/dashboards/:uuid/panels/:pid#card',
    ScreenKind.cell,
    'Карточка',
    'Card',
  ),
  ScreenNode(
    '/dashboards/:uuid/panels/:pid#delete',
    ScreenKind.cell,
    'Удалить',
    'Delete',
    tone: 'danger',
  ),
  ScreenNode(
    '/dashboards/:uuid/panels/:pid/nodes',
    ScreenKind.list,
    'Узлы',
    'Nodes',
    tone: 'io',
  ),
  ScreenNode(
    '/dashboards/:uuid/panels/:pid/nodes#add',
    ScreenKind.cell,
    'Добавить',
    'Add',
    tone: 'add',
  ),
  ScreenNode(
    '/dashboards/:uuid/panels/:pid/nodes/new',
    ScreenKind.form,
    'Новый узел',
    'New node',
  ),
  ScreenNode(
    '/dashboards/:uuid/panels/:pid/nodes/new#node',
    ScreenKind.cell,
    'Узел',
    'Node',
  ),
  ScreenNode(
    '/dashboards/:uuid/panels/:pid/nodes/new#last',
    ScreenKind.cell,
    'Только последнее',
    'Only last value',
  ),
  ScreenNode(
    '/dashboards/:uuid/panels/:pid/nodes/new#json',
    ScreenKind.cell,
    'Значение как JSON',
    'Value as JSON',
  ),
  ScreenNode(
    '/dashboards/:uuid/panels/:pid/nodes/new#create',
    ScreenKind.cell,
    'Связать',
    'Link',
    tone: 'add',
  ),
  ScreenNode(
    '/alerts',
    ScreenKind.search,
    'Уведомления',
    'Alerts',
    open: true,
    need: ScreenNeed.signedIn,
  ),
  ScreenNode('/alerts/types', ScreenKind.list, 'Типы', 'Types', open: true),
  ScreenNode('/library', ScreenKind.menu, 'Библиотека', 'Library', open: true),
  ScreenNode(
    '/library/presentation',
    ScreenKind.text,
    'Презентация',
    'Presentation',
    open: true,
  ),
  ScreenNode(
    '/library/about',
    ScreenKind.menu,
    'О приложении',
    'About',
    open: true,
  ),
  ScreenNode(
    '/library/about#version',
    ScreenKind.cell,
    'Версия клиента',
    'Client version',
  ),
  ScreenNode(
    '/library/about#updates',
    ScreenKind.cell,
    'Проверить обновления',
    'Check updates',
  ),
  ScreenNode(
    '/library/about/apps',
    ScreenKind.list,
    'Приложения',
    'Native apps',
    open: true,
  ),
  ScreenNode(
    '/library/about/apps#android',
    ScreenKind.cell,
    'Android',
    'Android',
  ),
  ScreenNode('/library/about/apps#ios', ScreenKind.cell, 'iOS', 'iOS'),
  ScreenNode('/library/about/apps#linux', ScreenKind.cell, 'Linux', 'Linux'),
  ScreenNode('/library/about/apps#macos', ScreenKind.cell, 'macOS', 'macOS'),
  ScreenNode(
    '/library/about/apps#windows',
    ScreenKind.cell,
    'Windows',
    'Windows',
  ),
  ScreenNode(
    '/library/about/social',
    ScreenKind.list,
    'Соцсети',
    'Social',
    open: true,
  ),
  ScreenNode(
    '/library/about/social#discord',
    ScreenKind.cell,
    'Discord',
    'Discord',
  ),
  ScreenNode(
    '/library/about/social#github',
    ScreenKind.cell,
    'GitHub',
    'GitHub',
  ),
  ScreenNode(
    '/library/about/social#gitlab',
    ScreenKind.cell,
    'GitLab',
    'GitLab',
  ),
  ScreenNode(
    '/library/about/social#telegram',
    ScreenKind.cell,
    'Telegram',
    'Telegram',
  ),
  ScreenNode(
    '/library/about/social#youtube',
    ScreenKind.cell,
    'YouTube',
    'YouTube',
  ),
  ScreenNode(
    '/library/about/support',
    ScreenKind.menu,
    'Поддержка',
    'Support',
    open: true,
  ),
  ScreenNode(
    '/library/about/support#bitcoin',
    ScreenKind.cell,
    'Bitcoin',
    'Bitcoin',
  ),
  ScreenNode(
    '/library/about/support#ethereum',
    ScreenKind.cell,
    'Ethereum',
    'Ethereum',
  ),
  ScreenNode(
    '/library/about/support#rules',
    ScreenKind.cell,
    'Правила расходов',
    'Spending rules',
  ),
  ScreenNode(
    '/library/about/support#report',
    ScreenKind.cell,
    'Скачать отчётность',
    'Download report',
  ),
  ScreenNode(
    '/library/tools',
    ScreenKind.menu,
    'Инструменты',
    'Tools',
    open: true,
  ),
  ScreenNode(
    '/library/tools#readme',
    ScreenKind.cell,
    'Генератор README',
    'README generator',
    need: ScreenNeed.signedIn,
  ),
  ScreenNode(
    '/library/docs',
    ScreenKind.text,
    'Документация',
    'Documentation',
    open: true,
  ),
  ScreenNode(
    '/library/tree',
    ScreenKind.list,
    'Дерево 6 путей',
    'Tree of 6 paths',
    open: true,
  ),
];

/// The tree over [screenTree]: who is above a row, who is below it.
///
/// The parent of a screen is the longest shorter address that is a screen
/// too, and the home screen above the sections. This is how the router nests
/// its routes, and a test checks that it stays so. The parent of a cell is the
/// screen it stands on.
class ScreenMap {
  ScreenMap(this.nodes) {
    for (final node in nodes) {
      _byPath[node.path] = node;
    }
    for (final node in nodes) {
      final parent = parentPath(node.path);
      if (parent == null) continue;
      (_children[parent] ??= []).add(node);
    }
  }

  final List<ScreenNode> nodes;
  final _byPath = <String, ScreenNode>{};
  final _children = <String, List<ScreenNode>>{};

  ScreenNode get root => _byPath[screenRoot]!;

  ScreenNode? node(String path) => _byPath[path];

  /// Address of the row above [path], or null for the home screen.
  String? parentPath(String path) {
    if (path == screenRoot) return null;
    final at = path.indexOf('#');
    if (at >= 0) return path.substring(0, at);
    final parts = path.split('/').where((part) => part.isNotEmpty).toList();
    while (parts.length > 1) {
      parts.removeLast();
      final upper = '/${parts.join('/')}';
      if (_byPath.containsKey(upper)) return upper;
    }
    return screenRoot;
  }

  ScreenNode? parentOf(String path) {
    final upper = parentPath(path);
    return upper == null ? null : _byPath[upper];
  }

  List<ScreenNode> childrenOf(String path) => _children[path] ?? const [];

  /// From the home screen down to [path], both ends included.
  List<ScreenNode> trail(String path) {
    final found = <ScreenNode>[];
    String? at = _byPath.containsKey(path) ? path : null;
    while (at != null) {
      found.add(_byPath[at]!);
      at = parentPath(at);
    }
    return found.reversed.toList();
  }

  /// The tone of [path]: its own, or the nearest one above it. Null is the
  /// color of the section.
  String? toneOf(String path) {
    String? at = path;
    while (at != null) {
      final tone = _byPath[at]?.tone;
      if (tone != null) return tone;
      at = parentPath(at);
    }
    return null;
  }

  /// What [path] asks: its own, or the nearest one above it.
  ScreenNeed needOf(String path) {
    String? at = path;
    while (at != null) {
      final need = _byPath[at]?.need;
      if (need != null) return need;
      at = parentPath(at);
    }
    return ScreenNeed.open;
  }
}

final screenMap = ScreenMap(screenTree);
