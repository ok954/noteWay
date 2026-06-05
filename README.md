# 记途 (noteWay)

> 一款完全离线的个人备忘录应用，支持 Android 手机和 Windows 电脑。

[![Release](https://img.shields.io/github/v/release/ok954/noteWay-private)](https://github.com/ok954/noteWay-private/releases)
[![Flutter](https://img.shields.io/badge/Flutter-3.32.1-blue.svg)](https://flutter.dev)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

**[English](README.en.md)** | **中文**

---

## 简介

**记途** 是一款面向个人用户的轻量跨平台备忘录应用，聚焦"轻量实用、隐私安全、多端协同"三大核心理念。所有数据完全存储在本地设备，无需登录即可使用全部功能。

### 核心特点

- **完全离线** — 数据存本地 SQLite，零网络依赖
- **双端支持** — Android 手机 + Windows 电脑
- **无需登录** — 打开即用，没有账号体系
- **隐私安全** — 数据不离开设备，支持应用锁
- **富文本编辑** — 支持加粗、斜体、下划线、列表、对齐、图片插入

---

## 功能模块

| 模块 | 功能描述 |
|------|---------|
| **笔记** | 富文本编辑、图片行内嵌入、瀑布流列表、关键词搜索、封面图 |
| **待办** | 优先级(高/中/低)、截止日期、类型分类、星标置顶、分组显示 |
| **打卡** | 正向计时、倒计时(含毫秒)、暂停/继续/完成、退出恢复、快捷加时 |
| **统计** | 首页三卡片概览（待办/打卡/笔记），数据实时刷新 |
| **设置** | 深色主题、数据导入/导出(JSON)、云端同步(预留)、清除数据 |

---

## 下载安装

| 平台 | 下载 | 说明 |
|------|------|------|
| Windows | [noteWay-windows.zip](https://github.com/ok954/noteWay-private/releases/latest) | 解压后双击 `memo_app.exe` 运行 |
| Android | [noteWay-android.apk](https://github.com/ok954/noteWay-private/releases/latest) | 下载到手机安装 |

> 所有发布包均在 [Releases](https://github.com/ok954/noteWay-private/releases) 页面提供。

---

## 快速开始

### 开发环境

| 工具 | 版本 | 用途 |
|------|------|------|
| Flutter SDK | >= 3.32.1 | 跨平台开发框架 |
| Dart SDK | >= 3.8.1 | 编程语言 |
| Android Studio | 最新版 | Android 模拟器 + SDK |

### 启动项目

```bash
# 1. 克隆项目
git clone git@github.com:ok954/noteWay-private.git
cd noteWay-private

# 2. 安装依赖
flutter pub get

# 3. 运行调试
flutter run -d windows      # Windows 桌面端
flutter run -d android      # Android 设备
```

### 打包发布

```bash
# Windows
flutter build windows --release

# Android APK
flutter build apk --release
```

---

## 技术栈

| 类别 | 技术选型 |
|------|---------|
| **框架** | Flutter 3.32.1 |
| **状态管理** | flutter_riverpod 3.3.1 |
| **本地数据库** | sqflite / sqflite_common_ffi |
| **富文本编辑** | flutter_quill 11.5.0 |
| **主题** | Material Design 3 + 浅色/深色双主题 |
| **字体** | Noto Sans SC (思源黑体) → 苹方 → 微软雅黑 |
| **本地存储** | shared_preferences |
| **文件选择** | file_picker |
| **图片选择** | image_picker |
| **CSV 解析** | csv |
| **图标** | Material Icons |
| **CI/CD** | GitHub Actions (自动构建 Windows + Android) |

---

## 项目结构

```
lib/
├── main.dart                          # 应用入口 + 每日重置
├── app.dart                           # MaterialApp + 自适应 + 中文化
├── router.dart                        # 路由配置
├── core/
│   ├── constants/app_colors.dart      # 颜色常量
│   ├── theme/app_theme.dart           # Light/Dark 主题
│   └── database/database_helper.dart  # SQLite 初始化
├── models/                            # 数据模型
│   ├── note.dart / todo.dart / habit.dart
│   ├── checkin_record.dart
│   ├── user.dart / cloud_backup.dart
├── providers/                         # 状态管理
│   ├── note_provider.dart / todo_provider.dart / habit_provider.dart
│   ├── settings_provider.dart / auth_provider.dart
│   ├── cloud_sync_provider.dart / stats_provider.dart
├── repositories/                      # 数据库/API 操作
│   ├── note_repository.dart / todo_repository.dart
│   ├── habit_repository.dart / cloud_repository.dart
├── modules/                           # 业务页面
│   ├── home/       # 首页
│   ├── notes/      # 笔记列表 + 富文本编辑
│   ├── todos/      # 待办列表
│   ├── habits/     # 打卡列表
│   ├── timer/      # 计时器
│   ├── login/      # 登录/注册
│   └── settings/   # 设置页 + 云端同步 + 云端数据管理
```

---

## 版本历史

### v1.1.0（2026-06-04）
- ✅ 集成 flutter_quill 富文本编辑器，支持图片行内嵌入
- ✅ 待办事项完善（优先级/截止日期/类型/星标/分组/筛选）
- ✅ 打卡计时引擎（正向计时/倒计时/暂停/退出恢复/毫秒显示）
- ✅ 计时按钮状态机（开始→暂停→继续→已完成）
- ✅ 数据导出/导入（JSON 格式，含所有数据）
- ✅ 深色模式切换（浅色/深色/跟随系统）
- ✅ 全局 Material Design 中文化
- ✅ Windows 窗口标题 + 应用图标
- ✅ Android 权限配置 + 应用图标
- ✅ 全局自适应布局（宽屏限制 720px 居中）
- ✅ 字体优化（Noto Sans SC）
- ✅ 登录/注册页面（账号密码）
- ✅ 云端同步框架（API 占位，待接入服务器）
- ✅ 每日数据重置逻辑

### v1.0.0（2026-05-21）
- 项目初始化
- 基础框架搭建（Flutter + Riverpod + SQLite）
- 笔记纯文本增删改查
- 待办基础勾选
- 打卡计数 + 正向计时
- 首页统计卡片
- GitHub Actions 自动构建

---

## 许可证

MIT License
