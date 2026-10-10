import SwiftUI
import SpriteKit

@main struct WokLabApp: App {
    var body: some Scene { WindowGroup { RootView().tint(Color(red:0.78,green:0.30,blue:0.13)).preferredColorScheme(.light) } }
}
struct RootView: View {
    @State private var catalog: Catalog?
    @State private var failure: String?
    var body: some View {
        Group {
            if let catalog {
                TabView {
                    RecipeLibrary(catalog:catalog).tabItem { Label("开火",systemImage:"flame") }
                    PantryView(catalog:catalog).tabItem { Label("食材",systemImage:"carrot") }
                    GuideView().tabItem { Label("工艺",systemImage:"book") }
                }
            } else if let failure { ContentUnavailableView("菜谱载入失败",systemImage:"exclamationmark.triangle",description:Text(failure)) }
            else { ProgressView().task { do { catalog=try Catalog.load() } catch { failure=error.localizedDescription } } }
        }
    }
}
struct FoodIcon: View {
    let id: Int
    var body: some View { Image(uiImage:IngredientArt.shared.image(id)).resizable().scaledToFit() }
}
struct RecipeLibrary: View {
    let catalog: Catalog
    @State private var search=""
    var filtered: [Recipe] { catalog.recipes.filter { search.isEmpty || $0.name.contains(search) } }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment:.leading,spacing:20) {
                    Text("一口好锅，一桌好菜。").font(.largeTitle.bold()).padding(.top)
                    Text("20 道家常菜 · 从洗切到出锅").foregroundStyle(.secondary)
                    LazyVGrid(columns:[GridItem(.adaptive(minimum:155))],spacing:14) {
                        ForEach(filtered) { recipe in
                            NavigationLink { RecipeDetail(recipe:recipe,catalog:catalog) } label: {
                                VStack(alignment:.leading,spacing:10) {
                                    ZStack {
                                        Circle().fill(Color.white).frame(height:120)
                                        HStack(spacing:-18) { ForEach(Array(recipe.ingredients.prefix(3)),id:\.self) { FoodIcon(id:$0).frame(width:62,height:78) } }
                                    }
                                    Text(recipe.name).font(.headline).foregroundStyle(.primary)
                                    Text(recipe.subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                    HStack { Text("约 \(recipe.duration/60) 分钟"); Spacer(); Image(systemName:"arrow.up.right") }.font(.caption).foregroundStyle(.secondary)
                                }.padding(14).background(Color(red:0.95,green:0.93,blue:0.88),in:RoundedRectangle(cornerRadius:23))
                            }.buttonStyle(.plain)
                        }
                    }
                }.padding(20)
            }.navigationTitle("锅气").searchable(text:$search,prompt:"想做什么菜？")
        }
    }
}
struct RecipeDetail: View {
    let recipe: Recipe
    let catalog: Catalog
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:22) {
                HStack { ForEach(Array(recipe.ingredients.prefix(4)),id:\.self) { FoodIcon(id:$0).frame(height:90) } }.frame(maxWidth:.infinity).padding().background(.thinMaterial,in:RoundedRectangle(cornerRadius:24))
                Text(recipe.subtitle).font(.title2.bold())
                Text(recipe.grams).foregroundStyle(.secondary)
                Text(recipe.ingredients.map { catalog.ingredients[$0].name }.joined(separator:" · ")).font(.subheadline)
                Label("最高评分 \(UserDefaults.standard.integer(forKey:"best_"+recipe.id))",systemImage:"star")
                ForEach(Array(recipe.steps.enumerated()),id:\.offset) { i,step in
                    VStack(alignment:.leading,spacing:7) {
                        Text("\(i+1). \(step.title)").font(.headline)
                        Text(step.instruction).foregroundStyle(.secondary)
                        Text("\(step.station) · 目标 \(Int(step.seconds)) 秒 ± \(Int(step.tolerance)) 秒").font(.caption).foregroundStyle(.orange)
                    }
                }
                Text("时间为固定分量下的模拟参考；真实烹饪还需判断厚度、温度与熟度。").font(.caption).foregroundStyle(.secondary)
                if let url=URL(string:recipe.source) { Link("查看工艺参考",destination:url).font(.caption) }
                NavigationLink { CookingView(recipe:recipe) } label: { Text("开始备菜").font(.headline).frame(maxWidth:.infinity).padding() }.buttonStyle(.borderedProminent)
            }.padding(22)
        }.navigationTitle(recipe.name).navigationBarTitleDisplayMode(.inline)
    }
}
struct CookingView: View {
    @StateObject private var engine: KitchenEngine
    @Environment(\.scenePhase) private var phase
    @Environment(\.dismiss) private var dismiss
    init(recipe: Recipe) { _engine=StateObject(wrappedValue:KitchenEngine(recipe:recipe)) }
    var body: some View {
        ScrollView {
            VStack(spacing:16) {
                if engine.done { results }
                else {
                    HStack { Text(engine.step.station).font(.title2.bold()); Spacer(); Text("\(engine.index+1) / \(engine.recipe.steps.count)").foregroundStyle(.secondary) }
                    ProgressView(value:Double(engine.index),total:Double(engine.recipe.steps.count))
                    Text(engine.step.title).font(.headline).frame(maxWidth:.infinity,alignment:.leading)
                    Text(engine.step.instruction).font(.subheadline).foregroundStyle(.secondary).frame(maxWidth:.infinity,alignment:.leading)
                    SpriteView(scene:engine.scene,isPaused:!engine.running,options:[.allowsTransparency]).frame(height:350).clipShape(RoundedRectangle(cornerRadius:30)).accessibilityLabel("烹饪操作区域，拖动手指完成当前操作")
                    HStack {
                        metric("已用时",String(format:"%.0f 秒",engine.elapsed))
                        Spacer()
                        metric("目标窗口","\(Int(engine.step.seconds-engine.step.tolerance))–\(Int(engine.step.seconds+engine.step.tolerance)) 秒")
                        Spacer()
                        metric(engine.hot ? "锅温" : "操作",engine.hot ? "\(Int(engine.temperature))°C" : "\(min(100,Int(engine.actions/6*100)))%")
                    }
                    if engine.hot {
                        HStack { Image(systemName:"flame"); Slider(value:$engine.flame,in:0...1); Text("\(Int(engine.flame*100))%").monospacedDigit() }
                        Text("建议火力 \(Int(engine.step.heat*100))% · 热量进度 \(Int(engine.exposure/max(1,engine.step.seconds)*100))%").font(.caption).foregroundStyle(.secondary)
                        HStack {
                            Button("颠锅",systemImage:"arrow.up.forward") { engine.toss() }.disabled(engine.step.station != "炒锅" || !engine.added)
                            Button("添水 50ml",systemImage:"drop") { engine.water=min(1,engine.water+0.2) }.disabled(!engine.added)
                        }.buttonStyle(.bordered)
                        Text(engine.motionStatus).font(.caption2).foregroundStyle(.secondary)
                    }
                    Picker("时间倍率",selection:$engine.speed) { Text("实时 1×").tag(1.0); Text("练习 3×").tag(3.0); Text("快进 8×").tag(8.0) }.pickerStyle(.segmented)
                    HStack {
                        if !engine.added {
                            if engine.hot { Button(engine.running ? "正在预热" : "预热锅具") { engine.running=true }.buttonStyle(.bordered).disabled(engine.running) }
                            Button(engine.hot ? "按步骤下料" : "放入食材") { engine.add() }.buttonStyle(.borderedProminent)
                        }
                        else { Button(engine.running ? "暂停" : "继续") { engine.running.toggle() }.buttonStyle(.bordered) }
                        Spacer()
                        Button(engine.index == engine.recipe.steps.count-1 ? "出锅评分" : "完成此步") { engine.finishStep() }.buttonStyle(.borderedProminent).disabled(!engine.ready)
                    }
                    if engine.burn>0.2 { Label("出现焦化，调低火力并翻动",systemImage:"exclamationmark.triangle").font(.caption).foregroundStyle(.red) }
                }
            }.padding(20)
        }.navigationTitle(engine.recipe.name).navigationBarTitleDisplayMode(.inline)
        .onAppear { engine.start() }.onDisappear { engine.stop() }
        .onChange(of:phase) { _,value in if value != .active { engine.running=false } }
    }
    func metric(_ title:String,_ value:String) -> some View { VStack(alignment:.leading,spacing:5) { Text(title).font(.caption).foregroundStyle(.secondary); Text(value).font(.subheadline.bold()).monospacedDigit() } }
    var results: some View {
        VStack(spacing:20) {
            Image(systemName:"fork.knife.circle.fill").font(.system(size:75)).foregroundStyle(.orange)
            Text("开饭了").font(.largeTitle.bold())
            Text("\(engine.score)").font(.system(size:80,weight:.light,design:.rounded))
            Text("工艺时间 45% · 火候 25% · 操作 30%").font(.caption).foregroundStyle(.secondary)
            ForEach(engine.results) { result in
                VStack(alignment:.leading,spacing:8) {
                    HStack { Text(result.title); Spacer(); Text("\(Int(result.score)) 分").bold() }
                    ProgressView(value:result.score,total:100)
                    Text(result.time<0.7 ? "时间偏离较大：参考目标窗口，结合热量进度出锅。" : result.technique<0.7 ? "操作偏少：及时翻动，让食材均匀受热。" : result.burn>0.2 ? "有焦化：降低火力或增加翻炒。" : "节奏不错，继续保持。").font(.caption).foregroundStyle(.secondary)
                }
            }
            Button("返回菜谱") { dismiss() }.buttonStyle(.borderedProminent)
        }
    }
}
struct PantryView: View {
    let catalog: Catalog
    @State private var query=""
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns:[GridItem(.adaptive(minimum:90))],spacing:16) {
                    ForEach(catalog.ingredients.filter { query.isEmpty || $0.name.contains(query) || $0.category.contains(query) }) { item in
                        VStack { FoodIcon(id:item.id).frame(height:75); Text(item.name).font(.subheadline); Text(item.category).font(.caption2).foregroundStyle(.secondary) }.padding(10).frame(maxWidth:.infinity).background(Color(.secondarySystemBackground),in:RoundedRectangle(cornerRadius:16))
                    }
                }.padding()
            }.navigationTitle("食材库 · 64").searchable(text:$query,prompt:"搜索食材或分类")
        }
    }
}
struct GuideView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("操作") {
                    Label("洗菜池：放入蔬菜，滑动搓洗",systemImage:"drop")
                    Label("砧板：滑动切配，控制操作节奏",systemImage:"rectangle.split.3x1")
                    Label("炒锅：拖动锅铲，轻抬手腕颠锅",systemImage:"flame")
                    Label("煮锅：控制火力，观察气泡与蒸汽",systemImage:"humidity")
                }
                Section("时间与真实度") {
                    Text("20 道菜设定固定分量和步骤时间窗口。热量进度会随锅温改变；快进只改变模拟速度，不改变工艺目标。")
                    Text("贴图、二维刚体碰撞、粒子烟汽和程序着色共同形成烹饪效果。当前版本是可交互模拟，尚非经实验标定的食物热传导或流体仿真。")
                    Text("真实做菜不能只凭时间或颜色判断安全。禽肉中心需达到 74°C；肉馅及蛋类菜肴需达到 71°C。请使用食品温度计。")
                    Link("FoodSafety.gov 温度参考",destination:URL(string:"https://www.foodsafety.gov/food-safety-charts/safe-minimum-internal-temperatures")!)
                }
                Section("版本") { Text("锅气 WokLab 1.0 · 离线运行 · 无账号与数据上传") }
            }.navigationTitle("烹饪工艺")
        }
    }
}
