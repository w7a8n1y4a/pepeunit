import 'package:flutter_test/flutter_test.dart';
import 'package:pepeunit_client/hive/icon_scale.dart';

void main() {
  test('one file has one size, fitted to the home menu ink', () {
    expect(iconScaleOf('assets/icons/actions/back.svg'), 1);
    expect(
      iconScaleOf('assets/icons/sections/account.svg'),
      closeTo(menuInk / 0.80, 1e-9),
    );
    expect(iconScaleOf('assets/icons/sections/instances.svg'), 1);
    expect(iconScaleOf('assets/icons/objects/users.svg'), 1);
    expect(iconScaleOf('assets/icons/objects/instance.svg'), 1);

    expect(iconScaleOf('assets/icons/actions/settings.svg'), 1.6);
    expect(iconScaleOf('assets/icons/actions/power.svg'), 1.5);
    expect(iconScaleOf('assets/icons/services/telegram.svg'), 1.2);
    expect(iconScaleOf('assets/icons/status/sight.svg'), 1.2);

    expect(
      iconScaleOf('assets/icons/actions/search.svg'),
      closeTo(menuInk / 0.66, 1e-9),
    );
    expect(
      iconScaleOf('assets/icons/actions/check.svg'),
      iconScaleOf('assets/icons/actions/ban.svg'),
    );
    expect(iconScaleOf('assets/icons/missing.svg'), 1);
  });
}
