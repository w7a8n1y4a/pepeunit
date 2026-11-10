import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../hex_page.dart';
import '../network/line_cell.dart';
import 'library_menu_page.dart';
import 'library_modal.dart';

const _bitcoinAddress = 'bc1q537kletr80tg9s3cc47920cd5qcef0dwly08qr';
const _ethereumAddress = '0xF7BF1e2C10c562679A88DB8DC73b67cc8469Ca19';
const _reportUrl = 'https://minio.pepemoss.com/public-data/csv/detail.csv';

const _spendingRules = '''
:::info
Монеты будут расходоваться на улучшение проекта:
1. Привлечение профильных разработчиков для повышения качества кодовой базы или разработку новых фич
2. Оплату дополнительной инфраструктуры, если такая потребуется
3. Оплату работы дополнительных специалистов в смежных областях: аналитиков, юридических консультантов, видео-монтажёров и др.
4. Закупку IoT компонентов для тестирования библиотек и/или компонентов Pepeunit. Закупленные элементы не будут перепроданы без решения сообщества, но могут быть переданы разработчикам Pepeunit для тестов.

В случае расходования значительных средств будет объявлено голосование в https://t.me/pepeunit, по результатам которого средства будут направлены на наиболее привлекательный для сообщества вариант.

В голосовании всегда будет вариант "Никакой из предложенных", чтобы у сообщества была возможность отменить голосование и предложить другие варианты
:::
''';

const _spendingRulesEn = '''
:::info
The coins will be spent on improving the project:
1. Hiring specialist developers to raise the quality of the code base or to build new features
2. Paying for additional infrastructure, if it is needed
3. Paying for additional specialists in related fields: analysts, legal advisers, video editors and others
4. Buying IoT components to test the libraries and/or components of Pepeunit. The purchased items will not be resold without a decision of the community, but may be handed to Pepeunit developers for tests.

If a significant amount is spent, a vote will be announced in https://t.me/pepeunit, and the funds will go to the option the community finds most appealing.

The vote will always include the option "None of the above", so the community can cancel the vote and propose other options
:::
''';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  var _rulesOpen = false;
  var _downloading = false;
  String? _failure;
  var _failureOpen = false;

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final board = cardBoard(const [
      'bitcoin',
      'ethereum',
      'rules',
      'report',
    ], wide: wide);
    final slots = [
      for (final slot in board)
        switch (slot.id) {
          'back' => backSlot(
            title: libText(language, 'Назад', 'Back'),
            q: slot.q,
            r: slot.r,
          ),
          'bitcoin' => _wallet(
            slot,
            title: 'Bitcoin',
            address: _bitcoinAddress,
            language: language,
          ),
          'ethereum' => _wallet(
            slot,
            title: 'Ethereum',
            address: _ethereumAddress,
            language: language,
          ),
          'rules' => HexSlot(
            id: 'rules',
            title: libText(language, 'Правила расходов', 'Spending rules'),
            color: libraryColor,
            q: slot.q,
            r: slot.r,
            icon: 'assets/icons/objects/file.svg',
            center: '.csv',
          ),
          _ => HexSlot(
            id: 'report',
            title: libText(language, 'Скачать Отчётность', 'Download report'),
            color: libraryColor,
            q: slot.q,
            r: slot.r,
            icon: 'assets/icons/actions/download.svg',
            busy: _downloading,
          ),
        },
    ];
    appendError(
      slots,
      message: _failure,
      open: _failureOpen,
      language: language,
      text: libErrorText,
      wide: wide,
    );
    final scene = HexPage(slots: slots, onTap: (id) => _tap(id, language));
    if (!_rulesOpen) return scene;
    return Stack(
      children: [
        scene,
        Material(
          type: MaterialType.transparency,
          child: LibraryModal(
            title: libText(language, 'Правила расходов', 'Spending rules'),
            color: libraryColor,
            source: language == 'en' ? _spendingRulesEn : _spendingRules,
            onClose: () => setState(() => _rulesOpen = false),
          ),
        ),
      ],
    );
  }

  HexSlot _wallet(
    BoardSlot slot, {
    required String title,
    required String address,
    required String language,
  }) {
    return HexSlot(
      id: slot.id,
      title: title,
      color: libraryColor,
      q: slot.q,
      r: slot.r,
      tappable: false,
      body: MetricsCell(
        lines: [address],
        copyText: address,
        copyLabel: libText(language, 'Скопировать', 'Copy'),
      ),
    );
  }

  Future<void> _tap(String id, String language) async {
    switch (id) {
      case 'back':
        popOrHome(context);
      case 'rules':
        setState(() => _rulesOpen = true);
      case 'report':
        await _download(language);
      case 'error':
        setState(() => _failureOpen = true);
    }
  }

  Future<void> _download(String language) async {
    if (_downloading) return;
    final model = AppScope.of(context);
    setState(() {
      _downloading = true;
      _failure = null;
      _failureOpen = false;
    });
    String? failure;
    try {
      final bytes = await model.downloadFile(Uri.parse(_reportUrl));
      if (!mounted) return;
      await model.saveBytes('detail.csv', bytes);
    } catch (_) {
      failure = libErrorText(
        language,
        'Не удалось скачать отчётность',
        'The report could not be downloaded',
      );
    }
    if (!mounted) return;
    setState(() {
      _downloading = false;
      _failure = failure;
    });
  }
}
