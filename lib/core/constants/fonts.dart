import 'dart:io';

/// 字体注册表 — 集中管理所有可用字体
///
/// 设计说明：
/// - 每个字体条目包含跨平台可用的 Google Fonts 家族
/// - 支持平台特定覆盖（后续可按设备配置不同字体）
/// - 新增字体只需添加一项到 [fonts] 列表
/// - 字体 ID 一旦确定请勿修改（存储在 SharedPreferences 中）
///
/// 扩展方式（新增字体）：
/// ```dart
/// fonts.add(AppFont(
///   id: 'my-font',
///   name: '我的字体',
///   nameEn: 'My Font',
///   googleFontFamily: 'MyFontFamily',
///   platformOverrides: {'ios': 'PingFang SC', 'android': 'MyFont'},
/// ));
/// ```
class AppFont {
  final String id;
  final String name;
  final String nameEn;
  final String googleFontFamily;
  final Map<String, String>? platformOverrides;

  const AppFont({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.googleFontFamily,
    this.platformOverrides,
  });

  /// 获取当前平台的最佳字体名称
  String get effectiveFont {
    if (platformOverrides != null) {
      String? platformKey;
      if (Platform.isIOS) platformKey = 'ios';
      if (Platform.isAndroid) platformKey = 'android';
      if (Platform.isWindows) platformKey = 'windows';
      if (Platform.isMacOS) platformKey = 'macos';
      if (Platform.isLinux) platformKey = 'linux';
      if (platformKey != null && platformOverrides!.containsKey(platformKey)) {
        return platformOverrides![platformKey]!;
      }
    }
    return googleFontFamily;
  }
}

/// 所有可用字体列表
///
/// 首项为默认字体。
/// 新增字体时只需在此追加条目，前端自动显示。
const List<AppFont> appFonts = [
  AppFont(
    id: 'noto-sans-sc',
    name: '思源黑体',
    nameEn: 'Noto Sans SC',
    googleFontFamily: 'Noto Sans SC',
    platformOverrides: {
      'windows': 'Microsoft YaHei',
      'ios': 'PingFang SC',
    },
  ),
  AppFont(
    id: 'noto-serif-sc',
    name: '思源宋体',
    nameEn: 'Noto Serif SC',
    googleFontFamily: 'Noto Serif SC',
    platformOverrides: {
      'windows': 'SimSun',
      'ios': 'STSongti SC',
    },
  ),
  AppFont(
    id: 'lxgw-wenkai',
    name: '霞鹜文楷',
    nameEn: 'LXGW WenKai',
    googleFontFamily: 'LXGW WenKai',
  ),
  AppFont(
    id: 'zcool-kuai-le',
    name: '站酷快乐体',
    nameEn: 'ZCOOL KuaiLe',
    googleFontFamily: 'ZCOOL KuaiLe',
  ),
  AppFont(
    id: 'ma-shan-zheng',
    name: '马善政毛笔楷书',
    nameEn: 'Ma Shan Zheng',
    googleFontFamily: 'Ma Shan Zheng',
  ),
  AppFont(
    id: 'source-han-sans',
    name: '思源黑体 CN',
    nameEn: 'Source Han Sans CN',
    googleFontFamily: 'Noto Sans SC',
  ),
];

/// 字体回退栈（当所选字体缺失字符时依次尝试）
const List<String> fontFallbackStack = [
  'PingFang SC',
  'Microsoft YaHei',
  'Noto Sans SC',
  'Noto Sans',
  'sans-serif',
];

AppFont get defaultAppFont => appFonts.first;

AppFont? findAppFontById(String id) {
  try {
    return appFonts.firstWhere((f) => f.id == id);
  } catch (_) {
    return null;
  }
}
