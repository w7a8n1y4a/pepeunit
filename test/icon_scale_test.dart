import 'package:flutter_test/flutter_test.dart';
import 'package:pepeunit_client/hive/icon_scale.dart';

void main() {
  test('one file has one size, fitted to the home menu ink', () {
    expect(iconScaleOf('assets/icons/back.svg'), 1);
    expect(iconScaleOf('assets/icons/account.svg'), 1);
    expect(iconScaleOf('assets/icons/instances.svg'), 1);
    expect(iconScaleOf('assets/icons/users.svg'), 1);
    expect(iconScaleOf('assets/icons/instance.svg'), 1);

    expect(iconScaleOf('assets/icons/settings.svg'), 1.6);
    expect(iconScaleOf('assets/icons/power.svg'), 1.5);
    expect(iconScaleOf('assets/icons/telegram.svg'), 1.2);
    expect(iconScaleOf('assets/icons/sight.svg'), 1.2);

    expect(
      iconScaleOf('assets/icons/search.svg'),
      closeTo(menuInk / 0.66, 1e-9),
    );
    expect(
      iconScaleOf('assets/icons/check.svg'),
      iconScaleOf('assets/icons/ban.svg'),
    );
    expect(iconScaleOf('assets/icons/missing.svg'), 1);
  });
}
