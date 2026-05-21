# 记途 (noteWay)

> 一款完全离线的个人备忘录应用，支持 Android 手机和 Windows 电脑。

[![Release](https://img.shields.io/github/v/release/ok954/noteWay)](https://github.com/ok954/noteWay/releases)
[![Flutter](https://img.shields.io/badge/Flutter-3.32.1-blue.svg)](https://flutter.dev)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

---

## 简介

**记途** 是一款面向个人用户的离线备忘录应用，所有数据完全存储在本地设备，不上传云端，无需登录账号，无需服务器。

### 核心特点

- **完全离线** — 数据存本地 SQLite，零网络依赖
- **双端支持** — Android 手机 + Windows 电脑
- **无需登录** — 打开即用，没有账号体系
- **隐私安全** — 数据不离开设备，支持应用锁

---

## 功能模块

| 模块 | 功能描述 |
|------|---------|
| **笔记** | 文本笔记的增删改查，支持搜索 |
| **待办** | 待办事项管理，支持完成状态切换 |
| **打卡** | 习惯打卡，支持正向计时和计数模式 |
| **统计** | 首页展示待办、打卡、笔记的统计概览 |
| **设置** | 数据导出/导入、主题切换、清除数据 |

---

## 下载安装

### 最新版本

| 平台 | 下载 | 说明 |
|------|------|------|
| Windows | [noteWay-windows.zip](https://github.com/ok954/noteWay/releases/latest) | 解压后双击 `memo_app.exe` 运行 |
| Android | [noteWay-android.apk](https://github.com/ok954/noteWay/releases/latest) | 下载到手机安装 |

> 所有发布包均在 [Releases](https://github.com/ok954/noteWay/releases) 页面提供。

---

## 当前版本

### v1.0.0（测试版）

**发布日期：** 2026-05-21

**包含内容：**
- 基础框架搭建（Flutter + Riverpod + SQLite）
- 笔记模块：列表页 + 编辑页（增删改查、搜索）
- 待办模块：列表页 + 创建弹窗（完成勾选、删除）
- 打卡模块：列表页 + 计时页 + 创建弹窗（计数/正向计时）
- 首页统计卡片：待办、打卡、笔记概览
- 设置页：深色模式开关、数据管理入口
- 自动化打包：GitHub Actions 自动构建 Windows + Android

**已知问题：**
- 笔记暂为纯文本编辑，富文本编辑器待集成
- 待办暂不支持优先级选择和截止日期设置
- 打卡倒计时功能待完善
- 数据导出/导入功能待实现

---

## 开发环境

### 前置要求

| 工具 | 版本 | 用途 |
|------|------|------|
| Flutter SDK | >= 3.32.1 | 跨平台开发框架 |
| Dart SDK | >= 3.8.1 | 编程语言 |
| Android Studio | 最新版 | Android 模拟器 + SDK |

### 快速开始

```bash
# 1. 克隆项目
git clone git@github.com:ok954/noteWay.git
cd noteWay

# 2. 安装依赖
flutter pub get

# 3. 运行调试（选择目标平台）
flutter run -d windows      # Windows 桌面端
flutter run                 # 已连接的 Android 设备
```

### 打包发布

```bash
# Windows
flutter build windows --release

# Android APK
flutter build apk --release
```

---

## 项目结构

```
lib/
├── main.dart                    # 应用入口
├── app.dart                     # MaterialApp 配置
├── router.dart                  # 页面路由
├── core/
│   ├── constants/               # 颜色、常量
│   ├── database/                # SQLite 数据库初始化
│   └── theme/                   # 浅色/深色主题
├── models/                      # 数据模型（Note, Todo, Habit...）
├── providers/                   # Riverpod 状态管理
├── repositories/                # 数据库操作封装
└── modules/                     # 业务模块
    ├── home/                    # 首页
    ├── notes/                   # 笔记
    ├── todos/                   # 待办
    ├── habits/                  # 打卡
    ├── timer/                   # 计时
    └── settings/                # 设置
```

---

## 技术栈

- **框架：** Flutter 3.32.1
- **状态管理：** flutter_riverpod
- **本地数据库：** sqflite / sqflite_common_ffi
- **本地存储：** shared_preferences
- **UI 组件：** Material Design 3

---

## 更新日志

### v1.0.0（2026-05-21）
- 项目初始化
- 实现笔记、待办、打卡三大核心模块
- 添加首页统计和设置页
- 配置 GitHub Actions 自动打包

---

## 许可证

MIT License
