# 工艺研究与参数边界

查阅日期：2026-10-10。首版按 1–2 人份、薄切与家用炒锅设计。以下时间是**游戏参数**，不是实测认证的唯一最佳时间；容差与火力均为工程设定。每道菜的烹饪流程参考下列来源，做了简化或改编。洗菜/切配时长仅为操作练习。

| 菜品 | 热加工目标合计 | 流程参考 |
|---|---:|---|
| 番茄炒蛋 | 4.0 分钟 | [参考](https://thewoksoflife.com/stir-fried-tomato-and-egg/) |
| 酸辣土豆丝 | 3.3 分钟 | [参考](https://thewoksoflife.com/sichuan-stir-fried-potatoes/) |
| 蒜蓉西兰花 | 2.8 分钟 | [参考](https://thewoksoflife.com/garlicky-broccoli/) |
| 手撕包菜 | 3.3 分钟 | [参考](https://thewoksoflife.com/chinese-cabbage-stir-fry/) |
| 清炒小白菜 | 2.2 分钟 | [参考](https://thewoksoflife.com/stir-fried-bok-choy-recipe/) |
| 韭菜炒蛋 | 2.0 分钟 | [参考](https://thewoksoflife.com/chinese-chives-eggs/) |
| 虾仁滑蛋 | 3.5 分钟 | [参考](https://thewoksoflife.com/shrimp-and-eggs/) |
| 青椒肉丝 | 4.2 分钟 | [参考](https://thewoksoflife.com/shredded-pork-stir-fry/) |
| 洋葱炒牛肉 | 4.8 分钟 | [参考](https://thewoksoflife.com/beef-onion-stir-fry/) |
| 宫保鸡丁 | 6.2 分钟 | [参考](https://thewoksoflife.com/kung-pao-chicken/) |
| 麻婆豆腐 | 10.2 分钟 | [参考](https://thewoksoflife.com/ma-po-tofu-real-deal/) |
| 鱼香茄子 | 10.5 分钟 | [参考](https://thewoksoflife.com/fish-fragrant-eggplant-yuxiang-qiezi/) |
| 回锅肉 | 30.8 分钟 | [参考](https://thewoksoflife.com/twice-cooked-pork/) |
| 红烧肉 | 71.5 分钟 | [参考](https://thewoksoflife.com/shanghai-style-braised-pork-belly/) |
| 糖醋排骨 | 52.0 分钟 | [参考](https://thewoksoflife.com/shanghai-sweet-sour-ribs/) |
| 蛋炒饭 | 5.0 分钟 | [参考](https://thewoksoflife.com/egg-fried-rice/) |
| 虾仁炒饭 | 8.0 分钟 | [参考](https://thewoksoflife.com/shrimp-fried-rice/) |
| 香菇青菜 | 5.0 分钟 | [参考](https://chinasichuanfood.com/bok-choy-and-mushroom/) |
| 番茄蛋花汤 | 8.8 分钟 | [参考](https://thewoksoflife.com/tomato-egg-drop-soup/) |
| 西葫芦炒蛋 | 4.2 分钟 | [参考](https://thewoksoflife.com/zucchini-stir-fry-chicken/) |

## 证据与改编
番茄炒蛋：原食谱番茄炒约 1 分钟，合炒后加盖约 1–2 分钟。宫保鸡丁：原食谱分开煎鸡肉、低火煸香，回锅炒约 1 分钟、挂汁约 1 分钟、最后加熟花生。土豆丝：薄切并清洗淀粉是脆口的关键，不能把厚片沿用细丝时间。红烧类采用长时间微沸而非快炒窗口。
青椒肉丝参考肉丝上浆与分次炒制工艺，西葫芦炒蛋参考西葫芦快炒方法并改用鸡蛋；两者不宣称原食谱完全一致。各容差、目标火力和部分时长尚待真实厨师/灶具对照标定。

## 模拟模型
使用一阶锅温响应、随温度积分的等效热加工时间、蒸发量和翻动不足焦化模型。不是 CFD、传热有限元或真实微生物杀灭模型。几何、碰撞与颠锅为二维刚体加伪高度动画。切配为交互式贴图状态切换，不是任意网格切割。

## 食品安全参考
[FoodSafety.gov](https://www.foodsafety.gov/food-safety-charts/safe-minimum-internal-temperatures)：禽肉 74°C，肉馅及蛋类菜肴 71°C，剩食再加热 74°C。模拟锅温不是食物中心温度，不能据此判定现实食物安全。
