# 记途开发进度

> 最后更新：2026-06-04

---

## v1.1.0 版本 — 开发完成 ✅

### 一、笔记模块

| 功能 | 状态 | 说明 |
|------|------|------|
| 富文本编辑器集成 (flutter_quill) | ✅ | 使用 `QuillEditor` + `QuillSimpleToolbar`，支持加粗/斜体/下划线/列表/对齐 |
| 图片行内嵌入 | ✅ | 点击图片按钮 → 选择相册 → 在光标位置插入 `BlockEmbed.image()`，图片保存在 `images/` 私有目录 |
| Delta JSON 持久化 | ✅ | 内容以 Delta JSON 格式存入 `content` 字段，`plainText` 提取纯文本用于搜索 |
| 旧数据兼容 | ✅ | 加载时尝试解析 Delta JSON，失败则回退为纯文本插入 |
| 空笔记退出不保存 | ✅ | 标题和内容都为空时直接返回 |
| 封面图片提取 | ✅ | 保存时自动从 Delta 提取第一张图片路径存入 `imagePaths`，笔记列表展示为封面 |
| 删除笔记清理图片 | ✅ | 删除笔记时同步删除关联的图片文件 |
| 图片选择弹窗 | ✅ | 支持从相册选择或拍照 |
| 笔记列表瀑布流 | ✅ | 两列 MasonryGridView，显示封面/标题/摘要/时间 |
| 搜索功能 | ✅ | 标题 + 正文模糊搜索 |

### 二、待办模块

| 功能 | 状态 | 说明 |
|------|------|------|
| 创建弹窗 | ✅ | 标题(必填) + 备注 + 优先级(高/中/低) + 截止日期(日期+时间选择器) + 类型下拉 + 置顶 + 连续添加 |
| 日期分组显示 | ✅ | 今天 / 明天 / 本周 / 稍后 / 已完成 分组，每组合计数 |
| 完成勾选 | ✅ | Checkbox 切换完成状态，文字变灰加删除线 |
| 左滑删除 | ✅ | Dismissible 左滑删除 |
| 星标置顶 | ✅ | 右侧星标按钮，置顶项优先显示 |
| 优先级标签 | ✅ | 颜色区分：高(红)、中(黄)、低(绿) |
| 类型筛选 | ✅ | 顶部下拉框按类型筛选 |
| 搜索 | ✅ | 搜索框实时过滤标题和备注 |
| 排序逻辑 | ✅ | SQL 排序：置顶 → 今日截止 → 截止日期 → 优先级 → 编辑时间 |
| 统计联动 | ✅ | 添加/完成/删除后自动刷新首页统计卡片 |

### 三、打卡模块

| 功能 | 状态 | 说明 |
|------|------|------|
| 创建弹窗 | ✅ | 名称 + 标签(健康/学习/习惯) + 类型(倒计时/正向计时/不计时) + 时长快捷选择 |
| 计时页 — 正向计时 | ✅ | 50ms 精度，HH:MM:SS 显示，累计时长统计 |
| 计时页 — 倒计时 | ✅ | 毫秒显示 HH:MM:SS.mm，进度条，快捷加时(+5/+10/+30分) |
| 暂停/继续/完成 | ✅ | 三种按钮状态：暂停后显示「继续」，完成后显示「已完成」 |
| 退出恢复 | ✅ | 重新进入计时页自动检测 `currentRecordId`，恢复已流逝时间 |
| CheckinRecord 记录 | ✅ | 每次打卡创建独立记录（开始→结束，含时长） |
| 今日完成状态 | ✅ | 打卡列表按钮根据 `todayCount` 显示「已完成」/「完成」/「开始」/「继续」 |
| 智能图标 | ✅ | 根据打卡名称自动匹配图标（读书/跑步/喝水/冥想等） |
| 类型标签 | ✅ | 倒计时(红)/正向计时(蓝)/不计时(绿) 颜色区分 |
| 累计时长含秒 | ✅ | 显示格式如「1小时23分45秒」|
| 计时结束提示音 | ✅ | `audioplayers` 播放通知音 |

### 四、首页

| 功能 | 状态 | 说明 |
|------|------|------|
| 待办统计卡片 | ✅ | 蓝色主题，4行统计：总条数/已完成/今日截止/未完成 |
| 打卡统计卡片 | ✅ | 绿色主题，今日已打卡/未打卡 + 4条打卡项预览 |
| 笔记预览卡片 | ✅ | 橙色主题，上次编辑时间 + 最近笔记标题 + 内容摘要 |
| 快速添加 FAB | ✅ | 底部弹窗：新建笔记/待办/打卡 |
| 统计实时刷新 | ✅ | 全局 `statsProvider`，数据变化后自动刷新 |

### 五、设置页

| 功能 | 状态 | 说明 |
|------|------|------|
| 账户与云端分组 | ✅ | 未登录显示「登录账号」，已登录显示用户名 + 云端同步 + 云端数据管理 + 退出登录 |
| 数据管理分组 | ✅ | 导出(JSON) + 导入(JSON) + 回收站(待开发) + 清除数据 |
| 个性化分组 | ✅ | 主题(跟随系统/浅色/深色) + 字体设置(待开发) + 提醒音效(待开发) |
| 安全与隐私分组 | ✅ | 应用锁(待开发) |
| 其他分组 | ✅ | 使用帮助 + 分享应用 + 关于(含版本号) |
| 深色模式切换 | ✅ | 底部弹窗 RadioListTile 选择，`shared_preferences` 持久化 |
| 数据导出 | ✅ | JSON 格式，含 notes/todos/habits/checkin_records 所有数据 |
| 数据导入 | ✅ | JSON 解析，按 ID 去重合并 |
| 清除数据 | ✅ | 删库文件 + 清 SP + 清图片目录 + 重建数据库 |

### 六、云端同步 + 登录系统

| 功能 | 状态 | 说明 |
|------|------|------|
| 登录/注册页面 | ✅ | 账号密码 + 登录/注册切换 + 暂不登录入口 |
| 认证状态管理 | ✅ | Riverpod `AuthNotifier`，Token 本地持久化，启动自动恢复 |
| Token 持久化 | ✅ | SharedPreferences 存储 token + user json |
| 云端同步页面 | ✅ | 立即同步按钮 + 自动同步开关 + Wi-Fi同步开关 + 同步内容选择 |
| 云端数据管理页 | ✅ | 存储空间概览 + 备份列表 + 恢复版本 + 删除备份 |
| 云端 Repository | ✅ | `CloudRepository` 封装所有 API 调用 |
| API 占位变量 | ✅ | `API_BASE_URL = 'https://your-api-server.com'` |
| 数据恢复 | ✅ | 下载完整 JSON → 清空本地 → 批量插入 |

### 七、平台适配

| 功能 | 状态 | 说明 |
|------|------|------|
| Android 权限 | ✅ | POST_NOTIFICATIONS / CAMERA / READ_EXTERNAL_STORAGE / USE_EXACT_ALARM |
| Android 应用标签 | ✅ | 「记途」 |
| Android 应用图标 | ✅ | 替换为 `图标.png`，5个 mipmap 分辨率 |
| NDK 版本 | ✅ | 27.0.12077973 |
| Windows 窗口标题 | ✅ | 从 `L"memo_app"` 改为 `"记途"`（UTF-8 → WideChar 转换） |
| Windows 应用图标 | ✅ | ICO 格式替换 |
| 全局自适应 | ✅ | 宽屏(>800px) 内容限制 720px 居中；弹窗 `insetPadding` 自适应 |
| 全局中文化 | ✅ | Material 组件中文化：`flutter_localizations` + `locale: zh_CN` |
| 字体优化 | ✅ | Noto Sans SC (google_fonts) + 回退栈(苹方/微软雅黑/sans-serif) |

### 八、深色主题

| 字段 | 浅色 | 深色 |
|------|------|------|
| scaffoldBackgroundColor | #F5F7FA | #121212 |
| cardTheme | surfaceContainerLow | #1E1E1E |
| appBarTheme | cs.surface | #1E1E1E |
| inputDecoration fill | #F5F5F5 | #2A2A2A |
| dialogTheme | cs.surface | #1E1E1E |
| bottomSheetTheme | cs.surface | #1E1E1E |
| chipTheme | ✅ 新增深色适配 | 背景 #2A2A2A |
| switchTheme | ✅ 新增 | 颜色随主题变化 |
| checkboxTheme | ✅ 新增 | 选中状态用主题色 |
| segmentedButtonTheme | ✅ 新增深色适配 | 背景 #2A2A2A |
| 页面颜色动态化 | ✅ 8个页面改用 `Theme.of(context).colorScheme` |

### 九、计时器引擎（核心逻辑）

| 特性 | 实现 |
|------|------|
| 精度 | 50ms 刷新 |
| 倒计时格式 | HH:MM:SS.mm |
| 正向计时格式 | HH:MM:SS |
| 状态恢复 | 根据 `startTime` + `currentRecordId` 计算已流逝时间 |
| 按钮状态机 | 无记录→[开始] → 创建记录→[暂停] → 退出→[继续] → 结束→[已完成] |
| 暂停不丢失 | `isTiming=false` 但 `currentRecordId` 保留 |
| 结束打卡 | 主动结束按钮，累加 `totalDuration` |
| 倒计时结束 | 自动触发完成回调 |

### 十、数据模型

| 模型 | 字段 | 说明 |
|------|------|------|
| `Note` | id/title/content/plainText/imagePaths/createdAt/updatedAt | content 存 Delta JSON |
| `Todo` | id/title/content/type/dueDate/priority/isCompleted/isPinned/createdAt/updatedAt | 支持截止日期和优先级 |
| `Habit` | id/name/tag/habitType/planDuration/totalDuration/todayDuration/checkinCount/todayCount/isPinned/isTiming/currentRecordId/lastCheckinAt/createdAt/updatedAt | 含计时状态 |
| `CheckinRecord` | id/habitId/recordType/startTime/endTime/duration/isCompleted/createdAt | 每次打卡一条记录 |
| `User` | id/username/nickname/avatar/createdAt | 账号模型 |
| `CloudBackup` | id/userId/backupJson/noteCount/todoCount/habitCount/deviceInfo/createdAt | 云端备份记录 |

### 十一、文件清单

```
lib/
├── main.dart                         # 入口 + 每日重置检查
├── app.dart                          # MaterialApp + 全局自适应 + 中文化
├── router.dart                       # 路由配置（含cloud_sync/cloud_data）
│
├── core/
│   ├── constants/app_colors.dart     # 主题色常量
│   ├── theme/app_theme.dart          # Light/Dark 主题定义
│   └── database/database_helper.dart # SQLite 初始化 + 默认数据
│
├── models/
│   ├── note.dart                     # 笔记模型
│   ├── todo.dart                     # 待办模型
│   ├── habit.dart                    # 打卡模型
│   ├── checkin_record.dart           # 打卡记录模型
│   ├── user.dart                     # 用户模型
│   └── cloud_backup.dart             # 云端备份模型
│
├── providers/
│   ├── note_provider.dart            # 笔记状态管理
│   ├── todo_provider.dart            # 待办状态管理
│   ├── habit_provider.dart           # 打卡状态管理
│   ├── settings_provider.dart        # 主题设置状态
│   ├── auth_provider.dart            # 认证状态管理
│   ├── cloud_sync_provider.dart      # 云端同步状态
│   └── stats_provider.dart           # 首页统计
│
├── repositories/
│   ├── note_repository.dart          # 笔记数据库操作
│   ├── todo_repository.dart          # 待办数据库操作（含排序）
│   ├── habit_repository.dart         # 打卡数据库操作
│   └── cloud_repository.dart         # 云端 API 封装
│
├── modules/
│   ├── home/home_page.dart           # 首页三卡片 + 快速添加
│   ├── notes/
│   │   ├── note_list_page.dart       # 笔记列表（瀑布流）
│   │   └── note_edit_page.dart       # 富文本编辑器
│   ├── todos/todo_list_page.dart     # 待办分组列表 + 创建弹窗
│   ├── habits/habit_list_page.dart   # 打卡列表 + 创建弹窗
│   ├── timer/timer_page.dart         # 计时器（正计时/倒计时）
│   ├── login/login_page.dart         # 登录/注册
│   └── settings/
│       ├── settings_page.dart        # 设置页
│       ├── cloud_sync_page.dart      # 云端同步详情
│       └── cloud_data_page.dart      # 云端数据管理
```

---

## v1.2.0 规划（待开发）

| 功能 | 优先级 | 说明 |
|------|--------|------|
| 回收站 | P1 | 删除后 7 天内可恢复 |
| 排序筛选功能 | P1 | 笔记/待办的自定义排序和筛选 |
| 字体设置 | P2 | 字体大小和样式调整 |
| 提醒音效 | P2 | 待办提醒 + 打卡倒计时音效设置 |
| 应用锁 | P2 | 数字密码/图案密码 |
| 云端自建服务器 | P1 | Node.js/NestJS + PostgreSQL + Redis |
| 富文本完善 | P2 | 代码块、引用、链接支持 |
