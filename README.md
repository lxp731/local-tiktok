# LeoTok
LeoTok 是一款专为 Android 设计的本地视频播放器，采用类似 TikTok 的沉浸式短视频交互体验。它旨在让用户能够像刷短视频一样，流畅地浏览和播放存储在本地设备中的视频集合。

## 🌟 核心特性

- **沉浸式交互**：完全适配 TikTok 式的垂直滑动切换手势，支持单击暂停、长按调出功能菜单。
- **极致启动速度**：
  - **秒开体验**：引入本地视频元数据持久化缓存，应用启动即进入播放状态。
  - **增量扫描**：智能对比文件修改时间，仅更新变动内容，极大地减少了磁盘 I/O。
  - **高性能索引**：采用底层 `DocumentsContract` 查询优化，扫描速度比传统 `DocumentFile` 提升 10-50 倍。
- **现代化架构**：
  - 基于 **Provider** 的响应式状态管理。
  - **双缓冲播放池**：通过预加载机制实现视频切换的无缝衔接。
  - **异步反馈系统**：原生端与 Flutter 端实时通讯，扫描进度精准到文件夹级别。
- **SAF 安全标准**：严格遵循 Android 存储访问框架（Scoped Storage），无需申请高风险的全文件读取权限，保护用户隐私。
- **全黑视觉设计**：极简深色主题，专注于内容本身。

## 🛠 技术栈

- **Frontend**: Flutter (Dart)
- **State Management**: Provider
- **Local Storage**: SharedPreferences + JSON Serialization
- **Native Integration**: Android MethodChannel + Kotlin Coroutines/Threads
- **Platform**: Android (Min API 26)

## 🚀 快速开始

### 前提条件
- Flutter SDK (Latest Stable)
- Android Studio / VS Code
- Android 设备或模拟器 (API 26+)

### 运行步骤
1. 克隆仓库:
   ```bash
   git clone https://github.com/your-repo/local-tok.git
   ```
2. 安装依赖:
   ```bash
   flutter pub get
   ```
3. 运行项目:
   ```bash
   flutter run --release
   ```

## 📂 项目结构

- `lib/providers`: 业务逻辑与状态管理。
- `lib/services`: 文件系统索引与持久化服务。
- `lib/screens`: 沉浸式播放主屏与配置中心。
- `android/app/src/main/kotlin`: 高性能 SAF 扫描逻辑实现。

---

## 📄 开源协议
[MIT License](LICENSE)
