import '../locale/languages.dart';
import '../units/unit.dart';

/// Panel types the backend accepts, in the order Grafana lists them.
/// The value is what `POST /grafana/create_dashboard_panel` takes.
const panelTypes = <({String value, String label})>[
  (value: 'timeseries', label: 'Time series'),
  (value: 'barchart', label: 'Bar chart'),
  (value: 'stat', label: 'Stat'),
  (value: 'gauge', label: 'Gauge'),
  (value: 'bargauge', label: 'Bar gauge'),
  (value: 'table', label: 'Table'),
  (value: 'piechart', label: 'Pie chart'),
  (value: 'state-timeline', label: 'State timeline'),
  (value: 'heatmap', label: 'Heatmap'),
  (value: 'status-history', label: 'Status history'),
  (value: 'histogram', label: 'Histogram'),
  (value: 'text', label: 'Text'),
  (value: 'alertlist', label: 'Alert list'),
  (value: 'dashlist', label: 'Dashboard list'),
  (value: 'news', label: 'News'),
  (value: 'annolist', label: 'Annotations list'),
  (value: 'candlestick', label: 'Candlestick'),
  (value: 'canvas', label: 'Canvas'),
  (value: 'flamegraph', label: 'Flame graph'),
  (value: 'geomap', label: 'Geomap'),
  (value: 'logs', label: 'Logs'),
  (value: 'marcusolsson-hourly-heatmap-panel', label: 'Hourly heatmap'),
  (value: 'nodeGraph', label: 'Node graph'),
  (value: 'traces', label: 'Traces'),
  (value: 'trend', label: 'Trend'),
  (value: 'xychart', label: 'XY chart'),
];

/// Grafana's own name of a panel type. Unknown values stay as the backend sent.
String panelTypeLabel(String type) {
  for (final item in panelTypes) {
    if (item.value == type) return item.label;
  }
  return type;
}

/// `Success`, `Processing` and `Error` are what `sync_status` carries. A
/// dashboard that was never sent has none.
String dashboardStatusLabel(String language, String? status) {
  switch (status) {
    case 'Success':
      return phrase(language, {'ru': 'Отправлена', 'en': 'Synced'});
    case 'Processing':
      return phrase(language, {'ru': 'Отправляется', 'en': 'Syncing'});
    case 'Error':
      return phrase(language, {'ru': 'Ошибка', 'en': 'Error'});
    default:
      return phrase(language, {'ru': 'Черновик', 'en': 'Draft'});
  }
}

/// One dashboard of `GET /grafana/get_dashboards`.
class Dashboard {
  const Dashboard({
    required this.uuid,
    required this.name,
    required this.created,
    required this.creatorUuid,
    this.url,
    this.version,
    this.syncStatus,
    this.syncError,
    this.syncAt,
  });

  final String uuid;
  final String name;
  final String created;
  final String creatorUuid;

  /// Path on the instance that Grafana gave back at the last sync.
  final String? url;
  final int? version;
  final String? syncStatus;
  final String? syncError;
  final String? syncAt;

  bool get opens => url != null && url!.isNotEmpty;

  factory Dashboard.fromJson(Map<String, Object?> json) {
    final version = json['inc_last_version'];
    return Dashboard(
      uuid: json['uuid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      created: json['create_datetime'] as String? ?? '',
      creatorUuid: json['creator_uuid'] as String? ?? '',
      url: _text(json['dashboard_url']),
      version: version is num ? version.round() : null,
      syncStatus: _text(json['sync_status']),
      syncError: _text(json['sync_error']),
      syncAt: _text(json['sync_last_datetime']),
    );
  }
}

/// A node on a panel, with the two flags chosen when it was linked.
class PanelLink {
  const PanelLink({
    required this.io,
    required this.name,
    required this.lastOnly,
    required this.asJson,
  });

  final UnitIo io;

  /// `unit@topic`, as the backend names the series.
  final String name;
  final bool lastOnly;
  final bool asJson;

  factory PanelLink.fromJson(Map<String, Object?> json) {
    final io = json['unit_io'];
    return PanelLink(
      io: UnitIo.fromJson(
        io is Map ? io.cast<String, Object?>() : const <String, Object?>{},
      ),
      name: json['unit_with_unit_io_name'] as String? ?? '',
      lastOnly: json['is_last_data'] == true,
      asJson: json['is_forced_to_json'] == true,
    );
  }
}

class DashboardPanel {
  const DashboardPanel({
    required this.uuid,
    required this.type,
    required this.title,
    required this.created,
    required this.dashboardUuid,
    this.links = const [],
  });

  final String uuid;
  final String type;
  final String title;
  final String created;
  final String dashboardUuid;
  final List<PanelLink> links;

  int get inputs => links.where((link) => link.io.input).length;
  int get outputs => links.length - inputs;

  factory DashboardPanel.fromJson(Map<String, Object?> json) {
    return DashboardPanel(
      uuid: json['uuid'] as String? ?? '',
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      created: json['create_datetime'] as String? ?? '',
      dashboardUuid: json['dashboard_uuid'] as String? ?? '',
      links: [
        for (final item
            in json['unit_ios_for_panel'] as List<Object?>? ?? const [])
          if (item is Map) PanelLink.fromJson(item.cast<String, Object?>()),
      ],
    );
  }
}

/// Where the dashboard opens in Grafana. The backend keeps the path Grafana
/// returned, which already carries the `/grafana` sub path. [orgId] picks the
/// user's own organization.
Uri dashboardLink(String origin, String url, {String? orgId}) {
  final base = url.startsWith('http')
      ? Uri.parse(url)
      : Uri.parse(origin.replaceAll(RegExp(r'/+$'), '') + _rooted(url));
  if (orgId == null || orgId.isEmpty) return base;
  return base.replace(
    queryParameters: {...base.queryParameters, 'orgId': orgId},
  );
}

String _rooted(String path) => path.startsWith('/') ? path : '/$path';

String? _text(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return value;
}
