# 锅气 WokLab

原生 iOS 烹饪模拟器首版。SwiftUI + SpriteKit + CoreMotion，iOS 17+，iPhone / iPad，离线运行。

## 已实现
- 20 道家常菜、119 个分步工艺：清洗、切配、备料、炒制、煮制、收汁、出锅。
- 64 种食材，两套 AI 生成透明图集（原料 / 切配），共 128 个图格。
- 拖动虚拟锅铲推动食材；重力方向控制锅内移动，陀螺仪/加速度融合检测颠锅；按钮提供替代操作。
- 刚体碰撞、翻面抛起动画、粒子蒸汽和焦烟、沸腾气泡、随工艺推进的食材色泽变化。
- 火力、加水、锅温、热量积分、时间窗口、1×/3×/8×倍率、暂停及离开前台自动暂停。
- 分步评分与本地最高分：工艺时间 45%、火候 25%、操作 30%，焦化扣分。

## 菜单
番茄炒蛋、酸辣土豆丝、蒜蓉西兰花、手撕包菜、清炒小白菜、韭菜炒蛋、虾仁滑蛋、青椒肉丝、洋葱炒牛肉、宫保鸡丁、麻婆豆腐、鱼香茄子、回锅肉、红烧肉、糖醋排骨、蛋炒饭、虾仁炒饭、香菇青菜、番茄蛋花汤、西葫芦炒蛋。

## 构建
在安装 Xcode 的 Mac 上安装 XcodeGen，然后：
```sh
xcodegen generate
xcodebuild -project WokLab.xcodeproj -scheme WokLab -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
```
GitHub Actions 在 main 推送后生成 `WokLab-unsigned-IPA` 工件。下载 ZIP 后解压得到 IPA。**未签名 IPA 需自行签名后才能在普通 iPhone/iPad 安装**，并非 App Store / TestFlight 安装包。

## 真实度与范围
这是可交互首版，并非经过真实灶具实验标定的专业食品仿真。64 种食材不代表覆盖市场全部食材；每道菜的时间窗口是参考菜谱后制定的模拟参数，不存在脱离火力、分量、厚度的唯一精准最佳秒数。参考与模型边界见 [工艺研究](docs/RESEARCH.md)。

切菜当前使用原料到切配贴图切换；各步骤按配方重建锅内食材，未实现自由投料、任意刀切网格、食品流体或跨步骤逐块传热。下一步应由真机测试和厨师标定来提高拟真度。

## 素材
`Resources/Ingredients.png` 与 `Resources/Prepared.png` 由 imagegen 生成，8×8 图集，按 Catalog 食材 id 从左到右、从上到下读取；实际生成图尺寸以文件为准。提示规范：俯视、透明背景、等距单元格、无文字，分别表现完整原料与切配原料。所有素材随工程打包，无远程下载依赖。

## 验证
Actions 执行真机架构编译以及 iOS Simulator 上的工艺评分、低温不熟、目录引用、步骤门禁测试。动作感应与真实手感仍需 iPhone/iPad 实机验证。
