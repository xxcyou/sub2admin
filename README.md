# Sub2API 管理面板 (Flutter Android APP)

一款**现代、多主题**的 Sub2API / new-api 系 AI 网关管理员移动端 App。
通过 **管理员 API Key（`x-api-key` 请求头）** 直连你的网关 REST API，无需网页浏览器，随时随地管理。

> 演示对接：填入你自己的网关地址 + 管理员 API Key 即可使用，示例见下文「首次使用」。

---

## ✨ 功能特性

- 🔐 **管理员密钥直连**：只需站点地址 + 管理员 API Key，存在本机，安全调用
- ⚡ **专业实时看板**：**每窗口实时 TPS（Token/秒）** 大数字 + 峰值/平均/QPS + LIVE 心跳，每 20 秒自动刷新
- 📊 **KPI 大数字**：今日请求 / 今日消耗金额 / 今日 Token，含累计对比
- 📈 **吞吐图表**：Token/秒 + QPS 双系列实时走势（渐变面积图）
- 🕐 **响应延迟分布**：分桶柱状图（<100ms → 2000ms+，颜色分级）
- 🧾 **实时用量明细（全量展开）**：逐请求 **输入/输出/缓存 Token 细分 + 各自成本**、倍率、实际成本、**首 Token 延迟 TTFT**、总耗时、用户/分组/渠道账户、IP/UA、完整 Request ID、**内嵌 API Key 详情**
- 🏆 **模型排行 / 分组用量 / 用户消耗 Top**：多维度排行
- 🖥 **系统健康**：健康评分仪表盘、CPU/内存占用条、数据库/Redis 状态、协程/并发/账号切换数
- 🔄 **系统信息**：当前版本、在线检查更新并提示新版
- 👥 **用户管理（专业版）**：分页浏览 + 实时搜索 + 总数统计、**创建用户**、**用户详情页**、**编辑（禁用/启用、并发、用户名、备注）**、**删除用户**
- 🔌 **渠道管理（专业版）**：列表 + 搜索、**创建渠道**、**启用/禁用开关**、**删除渠道**
- 🔑 **密钥中心（专业版）**：全量密钥列表 + 名称搜索 + 今日/累计成本统计、**每日 Token 走势 Top**、**展开密钥详情（成本 / ID / 归属）**、**启停密钥**、**删除密钥**
- 🔑 **API Key 检索**：按名称搜索全部用户的 API Key，显示归属
- 📜 **请求日志**：按**模型筛选** + 成功/错误**分类过滤** + 分页（显示总数）
- 🎨 **多主题系统**：6 套现代主题（极光紫/深海蓝/翡翠绿/日落橙/胭脂粉/石墨灰）× 浅色/深色/跟随系统
- 💎 **Liquid Glass 流动玻璃设计**：毛玻璃卡片 / 流动渐变背景 / 悬浮玻璃底部导航 Dock / 辉光按钮
- 🔄 **下拉刷新 / 分页加载更多 / 网络错误重试 / 操作确认保护**

---

## 📦 安装

直接安装打包好的 APK：

```
Sub2API管理面板_v1.3.0专业版.apk   （约 18 MB，arm64 架构，覆盖绝大多数现代安卓手机）
```

> 如需 x86_64 / 全 ABI 版本，请在项目目录执行：
> `flutter build apk --release`（全架构）或 `--target-platform android-x64`（x86_64）

### 首次使用

1. 打开 App，进入登录页
2. **站点地址**：`https://api.example.com`（填入你自己的网关根地址，示例为占位）
3. **管理员 API Key**：填入你的 `admin-xxxxxxxx` 管理员密钥
4. 点击「连接控制台」→ 校验通过后进入主界面

密钥仅保存在手机本机（SharedPreferences），通过 `x-api-key` 请求头与网关通信。

---

## 🛠 技术栈

| 层 | 技术 |
|---|---|
| 框架 | Flutter 3.47 + Material 3 |
| 状态管理 | Provider |
| 数据请求 | http（`x-api-key` 认证） |
| 图表 | fl_chart |
| 本地存储 | SharedPreferences |
| 主题 | 自建多主题调色板系统 |

---

## 📁 项目结构

```
lib/
├── main.dart                 # 入口，主题/会话装配
├── theme/
│   ├── app_theme.dart        # 6 套现代主题 + Material3 全局样式
│   └── liquid.dart           # Liquid Glass 设计系统（流动渐变 / 毛玻璃卡片 / 玻璃导航）
├── models/
│   └── models.dart           # 数据模型（总览/用户/渠道/日志/排行/密钥）
├── services/
│   ├── api_client.dart       # REST 客户端（x-api-key 认证、异常处理）
│   ├── app_state.dart        # 全局状态（会话/主题/亮度）
│   └── repository.dart       # 数据仓库（聚合各接口）
├── screens/
│   ├── login_screen.dart     # 登录
│   ├── home_shell.dart       # 底部导航壳（玻璃 Dock）
│   ├── dashboard_screen.dart # 总览 + 图表 + 排行
│   ├── key_screen.dart       # 密钥中心（全量密钥 + 成本 + 走势 + 启停/删除）
│   ├── users_screen.dart     # 用户
│   ├── user_detail_screen.dart # 用户详情
│   ├── channels_screen.dart  # 渠道
│   ├── models_screen.dart    # 模型 + 请求日志
│   ├── usage_screen.dart     # 实时用量明细
│   ├── system_screen.dart    # 系统健康 / 信息 / 更新
│   └── settings_screen.dart  # 主题切换 / 明暗 / 退出
└── widgets/
    ├── widgets.dart          # 复用组件（渐变卡片/图块/状态徽章等）
    └── dialogs.dart          # 通用对话框
```

---

## 🔗 API 对接说明

所有请求调用 `<站点地址>/api/v1/admin/*`，请求头携带：

```
x-api-key: <你的管理员 api key>
```

响应为标准信封格式：`{ "code": 0, "message": "success", "data": {...} }`

本 App 对接的端点：

| 功能 | 端点 |
|---|---|
| 总览快照 | `GET /dashboard/snapshot-v2` |
| 趋势 | `GET /dashboard/trend` |
| 模型排行 | `GET /dashboard/models` |
| 分组用量 | `GET /dashboard/groups` |
| 用户消耗排行 | `GET /dashboard/users-ranking` |
| 系统健康 | `GET /ops/dashboard/overview` |
| 用户列表 | `GET /users?page=&page_size=` |
| 用户详情 | `GET /users/{id}` |
| 编辑用户 | `PUT /users/{id}` |
| 创建用户 | `POST /users` |
| 删除用户 | `DELETE /users/{id}` |
| 渠道列表 | `GET /channels?page=&page_size=` |
| 渠道开关 | `PUT /channels/{id}` |
| 创建渠道 | `POST /channels` |
| 删除渠道 | `DELETE /channels/{id}` |
| 请求日志(可筛选) | `GET /ops/requests?page=&model=&api_key_id=` |
| API Key 检索 | `GET /usage/search-api-keys?keyword=` |
| 密钥用量统计 | `POST /dashboard/api-keys-usage` |
| 密钥用量走势 | `GET /dashboard/api-keys-trend` |
| 用户密钥列表 | `GET /users/{id}/api-keys` |
| 密钥启停 | `PUT /api-keys/{id}` |
| 删除密钥 | `DELETE /api-keys/{id}` |
| 系统版本 | `GET /system/version` |
| 更新检查 | `GET /system/check-updates` |

---

## 🔧 本地开发

```bash
# 安装依赖
flutter pub get

# 运行（需连接设备/模拟器）
flutter run

# 分析
flutter analyze

# 测试
flutter test

# 打 APK
flutter build apk --release
```

---

## ⚠️ 安全提示

- 管理员密钥拥有**完全控制权**，请勿分发或截图给他人
- 密钥仅在**本机**存储；如需更高的密钥安全，可进一步接入 `flutter_secure_storage`
- 发布正式版前，建议替换 `android/app/build.gradle.kts` 中的 release 签名（当前使用 debug 签名）

---

## 📌 Roadmap（可扩展）

- [x] 密钥（Token）管理 / 密钥中心
- [ ] 编辑渠道 / 渠道状态切换
- [ ] 系统健康度 / 实时 QPS 大屏
- [ ] 多网关多账号切换
- [ ] 生物识别解锁 + 安全存储
