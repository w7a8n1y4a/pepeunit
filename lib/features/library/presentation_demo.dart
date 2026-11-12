import 'package:flutter/material.dart';

import '../../hive/bevel.dart';
import '../../hive/hex_scene.dart';
import '../../locale/languages.dart';
import '../../navigation/sections.dart';
import 'presentation_controls.dart';

/// Local examples drawn by the same hex renderer as the application screens.
class PresentationDemo extends StatefulWidget {
  const PresentationDemo({
    required this.slide,
    required this.language,
    required this.onDocs,
    required this.onHome,
    super.key,
  });

  final int slide;
  final String language;
  final VoidCallback onDocs;
  final VoidCallback onHome;

  @override
  State<PresentationDemo> createState() => _PresentationDemoState();
}

class _PresentationDemoState extends State<PresentationDemo> {
  final _temperatureFocus = FocusNode();
  int _selected = 0;
  bool _connected = false;
  bool _filtered = false;
  double _temperature = 24;

  Color get color => presentationColor(widget.slide);
  String t(String ru, String en) => localized(widget.language, ru, en);

  @override
  void dispose() {
    _temperatureFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ..._content(),
      if (widget.slide > 0 && widget.slide < 8) ...[
        const SizedBox(height: 12),
        _caption(
          t(
            'Интерактивный пример · демонстрационные данные',
            'Interactive example · sample data',
          ),
          size: 14,
        ),
      ],
    ],
  );

  List<Widget> _content() {
    switch (widget.slide) {
      case 0:
        return [
          _scene(
            [
              HexSlot(
                id: 'pepeunit',
                title: 'Pepeunit',
                color: color,
                q: 0,
                r: 0,
                center: 'Pepeunit',
                centerScale: 2.2,
                footer: 'Open source',
                tappable: false,
              ),
              for (final section in menuSections.where((s) => s.id != 'people'))
                HexSlot(
                  id: section.id,
                  title: section.title(widget.language),
                  color: section.color,
                  q: section.q,
                  r: section.r,
                  icon: section.icon,
                  tappable: false,
                ),
            ],
            ratio: 1.15,
            links: [for (var i = 1; i < 7; i++) (0, i)],
          ),
          _caption(
            t(
              'Repo → Unit → Связи → Данные',
              'Repo → Unit → Connections → Data',
            ),
          ),
        ];
      case 1:
        final names = [
          t('Датчик', 'Sensor'),
          t('Вентилятор', 'Fan'),
          t('Сервис', 'Service'),
        ];
        final details = [
          t(
            'ESP32 / MicroPython\nВыход: температура → 24 °C',
            'ESP32 / MicroPython\nOutput: temperature → 24 °C',
          ),
          t(
            'ESP32 / ESP-IDF\nВход: температура → управление мотором',
            'ESP32 / ESP-IDF\nInput: temperature → motor control',
          ),
          t(
            'Сервер / Python или Go\nВход: данные → обработка → выход: результат',
            'Server / Python or Go\nInput: data → processing → output: result',
          ),
        ];
        return [
          _choices(names, [
            'sections/micro',
            'actions/power',
            'objects/terminal',
          ]),
          _details([
            _headline('Unit / ${names[_selected]}'),
            _caption(details[_selected]),
          ]),
        ];
      case 2:
        final titles = [
          t('Программа в Git', 'A program in Git'),
          t('Первый запуск', 'First launch'),
          t('Удалённое обновление', 'Remote update'),
        ];
        final details = [
          'GitHub / GitLab\ncode + env + schema',
          t(
            'Выберите версию, задайте окружение\nи запустите программу на устройстве.',
            'Choose a version, configure the environment\nand run the program on the device.',
          ),
          t(
            'Коммит a1b2 → c3d4\nНовая версия доставлена онлайн-устройству.',
            'Commit a1b2 → c3d4\nNew version delivered to the online device.',
          ),
        ];
        return [
          _choices(
            ['1. Repo', '2. Unit', '3. OTA'],
            ['sections/git', 'sections/micro', 'actions/updates'],
            connect: true,
          ),
          _details([
            _headline(titles[_selected]),
            _caption(details[_selected]),
          ]),
        ];
      case 3:
        final running = _connected && _temperature > 28;
        return [
          _scene(
            [
              _slot(
                'sensor',
                t('Датчик', 'Sensor'),
                'sections/micro',
                0,
                footer: '${_temperature.round()} °C',
              ),
              _slot(
                'link',
                _connected
                    ? t('Разъединить', 'Disconnect')
                    : t('Соединить', 'Connect'),
                'objects/links',
                1,
                active: true,
                tone: _connected ? addColor : hexMuted,
                tappable: true,
              ),
              _slot(
                'fan',
                t('Вентилятор', 'Fan'),
                'actions/power',
                2,
                footer: running ? 'ON' : 'OFF',
                tone: running ? addColor : color,
              ),
            ],
            links: _connected ? [(0, 1), (1, 2)] : [],
            onTap: (id) {
              if (id == 'link') setState(() => _connected = !_connected);
            },
          ),
          _details([
            Semantics(
              liveRegion: true,
              child: _headline(
                !_connected
                    ? t('Нет связи', 'Not connected')
                    : running
                    ? t('Вентилятор включён', 'Fan is on')
                    : t('Вентилятор выключен', 'Fan is off'),
              ),
            ),
            _headline('${_temperature.round()} °C', tone: color),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: color,
                inactiveTrackColor: hexMuted.withValues(alpha: .35),
                thumbColor: Colors.white,
                overlayColor: color.withValues(alpha: .12),
                trackHeight: 2,
                thumbShape: const _HexThumb(),
              ),
              child: Slider(
                focusNode: _temperatureFocus,
                value: _temperature,
                min: 18,
                max: 36,
                divisions: 18,
                semanticFormatterCallback: (v) => '${v.round()} °C',
                onChanged: (value) => setState(() => _temperature = value),
              ),
            ),
            _caption(
              t(
                'Температура · порог в коде Unit: > 28 °C',
                'Temperature · threshold in Unit code: > 28 °C',
              ),
            ),
          ]),
        ];
      case 4:
        return [
          _choices(
            [
              t('Состояние', 'State'),
              t('Логи', 'Logs'),
              t('Команды', 'Commands'),
            ],
            ['status/info', 'objects/file', 'objects/terminal'],
          ),
          _details([
            _headline('greenhouse / sensor-01'),
            if (_selected == 0) ...[
              _metric('MQTT', 'ONLINE'),
              _metric(t('Версия', 'Version'), 'c3d4'),
              _metric(t('Свободная память', 'Free memory'), '128 KB'),
            ] else if (_selected == 1) ...[
              _metric('12:00:01', 'INFO · MQTT connected'),
              _metric('12:00:02', 'INFO · schema updated'),
              _metric('12:00:05', 'INFO · temperature: 24'),
            ] else ...[
              _metric('01', t('Обновить прошивку', 'Update firmware')),
              _metric('02', t('Обновить окружение', 'Update environment')),
              _metric('03', t('Перезапустить аппарат', 'Restart Unit')),
            ],
          ]),
        ];
      case 5:
        const samples = [22, 24, 23, 99, 26, 25, 24];
        return [
          _scene(
            [
              _slot('pipe', 'DataPipe', 'objects/pipe', 0),
              _slot('storage', 'ClickHouse', 'objects/archive', 1),
              _slot('grafana', 'Grafana', 'services/grafana', 2),
            ],
            links: [(0, 1), (1, 2)],
          ),
          _details([
            _headline(t('Температура / °C', 'Temperature / °C')),
            SizedBox(
              height: 128 + MediaQuery.textScalerOf(context).scale(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final value in samples)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _filtered && value == 99 ? '—' : '$value',
                                style: const TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            AnimatedContainer(
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 240),
                              height: _filtered && value == 99
                                  ? 2
                                  : value.toDouble(),
                              color: value == 99 ? errorColor : color,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _caption(t('Фильтр: от 0 до 50 °C', 'Filter: 0 to 50 °C')),
            Center(
              child: PresentationWord(
                label: _filtered
                    ? t('Выключить фильтр', 'Disable filter')
                    : t('Включить фильтр', 'Enable filter'),
                color: _filtered ? color : Colors.white,
                selected: _filtered,
                onTap: () => setState(() => _filtered = !_filtered),
              ),
            ),
            _caption(
              _filtered
                  ? t(
                      '99 °C отфильтровано. Осталось 6 измерений.',
                      '99 °C filtered out. 6 samples remain.',
                    )
                  : t(
                      '7 измерений, одно выходит за диапазон.',
                      '7 samples, one outside the range.',
                    ),
            ),
          ]),
        ];
      case 6:
        return [
          _choices(
            [
              t('Публичный Unit', 'Public Unit'),
              t('Приватный Unit', 'Private Unit'),
            ],
            ['status/sight', 'objects/key'],
          ),
          _details([
            _headline(t('Ваш сервер Pepeunit', 'Your Pepeunit server')),
            _caption(
              _selected == 0
                  ? t(
                      'Unit виден всем.\nУправляет им создатель.',
                      'Everyone can see the Unit.\nIts creator manages it.',
                    )
                  : t(
                      'Unit виден создателю\nи тем, кому выдан доступ.',
                      'The creator and agents\nwith access can see the Unit.',
                    ),
            ),
          ]),
        ];
      case 7:
        final names = [
          t('Дом', 'Home'),
          t('Мастерская', 'Workshop'),
          t('Лаборатория', 'Lab'),
        ];
        return [
          _choices(names, [
            'objects/instance',
            'objects/instance',
            'objects/instance',
          ], connect: true),
          _details([
            _headline(t('Инстанс: ', 'Instance: ') + names[_selected]),
            _metric(
              t('Публичные Repo', 'Public Repos'),
              'sensor / fan / logger',
            ),
            _metric(
              t('Данные Unit', 'Unit data'),
              t('На этом инстансе', 'On this instance'),
            ),
            _caption(
              t(
                'Обмен Repo при включённой федерации и доверии',
                'Repo sharing requires enabled federation and trust',
              ),
            ),
          ]),
        ];
      default:
        return [
          _headline(t('Что подключите вы?', 'What will you connect?')),
          _scene(
            [
              _slot(
                'home',
                t('В главное меню', 'Go to main menu'),
                'actions/back',
                0,
                tappable: true,
              ),
              _slot(
                'docs',
                t('Создать первый Unit', 'Create your first Unit'),
                'sections/library',
                1,
                tappable: true,
              ),
            ],
            ratio: 1.8,
            onTap: (id) => id == 'home' ? widget.onHome() : widget.onDocs(),
          ),
        ];
    }
  }

  HexSlot _slot(
    String id,
    String title,
    String icon,
    int index, {
    bool active = true,
    bool tappable = false,
    Color? tone,
    String? footer,
  }) => HexSlot(
    id: id,
    title: title,
    icon: 'assets/icons/$icon.svg',
    color: tone ?? (active ? color : hexMuted),
    q: index == 1 ? 1 : 0,
    r: index == 2 ? 1 : 0,
    footer: footer,
    tappable: tappable,
  );

  Widget _choices(
    List<String> labels,
    List<String> icons, {
    bool connect = false,
  }) => _scene(
    [
      for (var i = 0; i < labels.length; i++)
        _slot(
          '$i',
          labels[i],
          icons[i],
          i,
          active: _selected == i,
          tappable: true,
        ),
    ],
    ratio: labels.length == 2 ? 1.8 : 1.65,
    links: connect ? [(0, 1), (1, 2)] : [],
    onTap: (id) => setState(() => _selected = int.parse(id)),
  );

  Widget _scene(
    List<HexSlot> slots, {
    double ratio = 1.65,
    List<(int, int)> links = const [],
    ValueChanged<String>? onTap,
  }) => LayoutBuilder(
    builder: (context, bounds) {
      // Leave room for the example controls below the cells on a projector.
      final maxHeight = widget.slide == 0
          ? 640.0
          : (MediaQuery.sizeOf(context).height * .34).clamp(180.0, 360.0);
      return SizedBox(
        height: (bounds.maxWidth / ratio).clamp(0.0, maxHeight),
        child: Stack(
          children: [
            if (links.isNotEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _Connections(slots, links, color),
                  ),
                ),
              ),
            HexScene(slots: slots, onTap: onTap ?? (_) {}),
          ],
        ),
      );
    },
  );

  Widget _details(List<Widget> children) => BevelFrame(
    color: color.withValues(alpha: .65),
    radius: 14,
    width: 1.2,
    child: PresentationSurface(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    ),
  );

  Widget _headline(String text, {Color tone = Colors.white}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'OpenGost Type B',
        fontSize: 26,
        height: 1.15,
        color: tone,
      ),
    ),
  );

  Widget _caption(String text, {double size = 18}) => Text(
    text,
    textAlign: TextAlign.center,
    style: TextStyle(
      fontFamily: 'OpenGost Type B',
      fontSize: size,
      height: 1.35,
      color: hexMuted,
    ),
  );

  Widget _metric(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 16,
      runSpacing: 6,
      children: [
        Text(label, style: const TextStyle(fontSize: 17, color: hexMuted)),
        Text(value, style: TextStyle(fontSize: 17, color: color)),
      ],
    ),
  );
}

class _Connections extends CustomPainter {
  const _Connections(this.slots, this.links, this.color);
  final List<HexSlot> slots;
  final List<(int, int)> links;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cells = HexLayout.fit(slots, size).placed;
    final paint = Paint()
      ..color = color.withValues(alpha: .65)
      ..strokeWidth = 1.5;
    for (final (from, to) in links) {
      final a = cells[from];
      final b = cells[to];
      final delta = b.center - a.center;
      final direction = delta / delta.distance;
      final start = a.center + direction * (a.radius + 3);
      final end = b.center - direction * (b.radius + 3);
      canvas.drawLine(start, end, paint);
      final middle = (start + end) / 2;
      final normal = Offset(-direction.dy, direction.dx);
      canvas.drawPath(
        Path()
          ..moveTo(middle.dx + direction.dx * 4, middle.dy + direction.dy * 4)
          ..lineTo(
            middle.dx - direction.dx * 3 + normal.dx * 3,
            middle.dy - direction.dy * 3 + normal.dy * 3,
          )
          ..lineTo(
            middle.dx - direction.dx * 3 - normal.dx * 3,
            middle.dy - direction.dy * 3 - normal.dy * 3,
          )
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_Connections oldDelegate) =>
      slots != oldDelegate.slots ||
      links != oldDelegate.links ||
      color != oldDelegate.color;
}

class _HexThumb extends SliderComponentShape {
  const _HexThumb();
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(20, 20);
  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final path = pointyHex(center, 9);
    context.canvas.drawPath(path, Paint()..color = hexFill);
    context.canvas.drawPath(
      path,
      Paint()
        ..color = sliderTheme.thumbColor ?? Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}
