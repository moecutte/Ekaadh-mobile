import 'package:flutter/widgets.dart';
import 'package:ekaadh_mobile/core/locale_service.dart';

class LocaleScope extends InheritedNotifier<LocaleService> {
  const LocaleScope({
    super.key,
    required LocaleService service,
    required super.child,
  }) : super(notifier: service);

  static LocaleService of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LocaleScope>();
    assert(scope != null, 'LocaleScope not found in widget tree');
    return scope!.notifier!;
  }

  static LocaleService? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LocaleScope>()?.notifier;
  }
}
