import 'dart:typed_data';

/// A single app currently locked until [lockedUntil].
class AppLock {
  const AppLock({
    required this.packageName,
    required this.appName,
    this.iconBytes,
    required this.lockedUntil,
    required this.lockedAt,
    this.usedMinutes = 0,
  });

  final String packageName;
  final String appName;
  final Uint8List? iconBytes;
  final DateTime lockedUntil;
  final DateTime lockedAt;

  /// Minutes this app was used today before it was locked.
  final double usedMinutes;

  bool get isExpired => lockRemaining.isNegative;

  Duration get lockRemaining => lockedUntil.difference(DateTime.now());

  AppLock copyWith({
    Uint8List? Function()? iconBytes,
    double? usedMinutes,
  }) {
    return AppLock(
      packageName: packageName,
      appName: appName,
      iconBytes: iconBytes != null ? iconBytes() : this.iconBytes,
      lockedUntil: lockedUntil,
      lockedAt: lockedAt,
      usedMinutes: usedMinutes ?? this.usedMinutes,
    );
  }

  /// Maps to the JSON blob persisted by [LockService].
  Map<String, dynamic> toJson() => {
        'name': appName,
        'until': lockedUntil.millisecondsSinceEpoch,
        'at': lockedAt.millisecondsSinceEpoch,
        'usedMinutes': usedMinutes,
      };

  static AppLock fromJson(
    String packageName,
    Map<String, dynamic> json,
  ) {
    return AppLock(
      packageName: packageName,
      appName: json['name'] as String? ?? packageName,
      lockedUntil:
          DateTime.fromMillisecondsSinceEpoch(json['until'] as int),
      lockedAt:
          DateTime.fromMillisecondsSinceEpoch((json['at'] as int?) ??
              (json['until'] as int)),
      usedMinutes: (json['usedMinutes'] as num?)?.toDouble() ?? 0,
    );
  }
}