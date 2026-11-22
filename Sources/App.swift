import SwiftUI
import AppKit
import ApplicationServices
import UniformTypeIdentifiers

@main
struct GroupManagerApp: App {
    @StateObject private var model = GroupModel()
    var body: some Scene {
        WindowGroup("微信群聊管理器") {
            ContentView().environmentObject(model).frame(minWidth: 850, minHeight: 580)
        }
    }
}

struct GroupRecord: Identifiable {
    let id = UUID()
    var name: String
    var source: String = "手动录入"
    var status: String = "待核验"
    var selected = false
    var isProtected = false
}

@MainActor
final class GroupModel: ObservableObject {
    @Published var groups: [GroupRecord] = []
    @Published var visibleCandidates: [String] = []
    @Published var message = "开发验证版：不会执行真实退群。"
    @Published var mode = 0
    @Published var inputName = ""
    @Published var permission = false

    func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: kCFBooleanTrue!] as CFDictionary
        permission = AXIsProcessTrustedWithOptions(options)
        message = permission ? "已取得辅助功能授权" : "请在系统设置中授权辅助功能"
    }

    func inspectWeChat() {
        guard AXIsProcessTrusted() else { requestPermission(); return }
        guard let app = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == "com.tencent.xinWeChat" ||
            $0.localizedName == "微信" || $0.localizedName == "WeChat"
        }) else { message = "未找到运行中的微信"; return }
        let root = AXUIElementCreateApplication(app.processIdentifier)
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(root, kAXWindowsAttribute as CFString, &value) == .success,
              let windows = value as? [AXUIElement] else {
            message = "微信窗口辅助功能不可访问"; return
        }
        message = "只读检测：发现 \(windows.count) 个微信窗口。尚未实现全量群聊或共同群发现。"
    }

    func scanVisibleSearchResults() {
        guard AXIsProcessTrusted() else { requestPermission(); return }
        guard let app = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == "com.tencent.xinWeChat" ||
            $0.localizedName == "微信" || $0.localizedName == "WeChat"
        }) else { message = "未找到运行中的微信"; return }
        let root = AXUIElementCreateApplication(app.processIdentifier)
        var windowsValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(root, kAXWindowsAttribute as CFString, &windowsValue) == .success,
              let windows = windowsValue as? [AXUIElement] else {
            message = "无法读取微信窗口"; return
        }
        var labels = Set<String>()
        var visited = 0
        func walk(_ element: AXUIElement, _ depth: Int) {
            guard depth < 14, visited < 12000 else { return }
            visited += 1
            for key in [kAXTitleAttribute, kAXValueAttribute, kAXDescriptionAttribute] {
                var value: CFTypeRef?
                if AXUIElementCopyAttributeValue(element, key as CFString, &value) == .success,
                   let text = value as? String {
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty && trimmed.count < 160 { labels.insert(trimmed) }
                }
            }
            var childrenValue: CFTypeRef?
            if AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenValue) == .success,
               let children = childrenValue as? [AXUIElement] {
                for child in children { walk(child, depth + 1) }
            }
        }
        for window in windows { walk(window, 0) }
        visibleCandidates = labels.sorted()
        message = "只读检查完成：访问了 \(visited) 个元素，发现 \(visibleCandidates.count) 条不同文本。尚未验证哪些是群聊，不会自动加入群聊清单。"
    }

    func addManual() {
        let name = inputName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        groups.append(GroupRecord(name: name))
        inputName = ""
    }

    func preview() {
        let count = groups.filter { $0.selected && !$0.isProtected && $0.status == "已核验" }.count
        message = "预览：\(count) 条候选记录。手动标记不代表身份验证；实际退出功能未启用。"
    }

    func exportCSV() {
        let header = "群名称,来源,核验状态,保护,已选\n"
        let rows = groups.map { group in
            [group.name, group.source, group.status, group.isProtected ? "是" : "否",
             group.selected ? "是" : "否"].map {
                "\"" + $0.replacingOccurrences(of: "\"", with: "\"\"") + "\""
            }.joined(separator: ",")
        }.joined(separator: "\n")
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "群聊清单.csv"
        panel.allowedContentTypes = [.commaSeparatedText]
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try ("\u{FEFF}" + header + rows).write(to: url, atomically: true, encoding: .utf8)
                message = "CSV 导出成功"
            } catch { message = "导出失败：\(error.localizedDescription)" }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var model: GroupModel
    @State private var search = ""
    @State private var acknowledged = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("微信群聊管理器").font(.title2.bold())
                Spacer()
                Text("V1.4 · 开发验证版").foregroundStyle(.secondary)
            }
            Picker("模式", selection: $model.mode) {
                Text("全部群聊").tag(0)
                Text("好友共同群").tag(1)
            }.pickerStyle(.segmented)
            if model.mode == 1 {
                Text("好友共同群识别尚未实现：本页面不会推断或自动选择共同群。")
                    .foregroundStyle(.orange)
            }
            HStack {
                Button("申请辅助功能权限") { model.requestPermission() }
                Button("只读检查微信窗口") { model.inspectWeChat() }
                Button("读取可见候选文本") { model.scanVisibleSearchResults() }
                Spacer()
                Button("导出 CSV") { model.exportCSV() }
            }
            HStack {
                TextField("手动输入待核验群名称", text: $model.inputName)
                Button("添加记录") { model.addManual() }
            }
            if !model.visibleCandidates.isEmpty {
                DisclosureGroup("微信窗口候选文本（\(model.visibleCandidates.count) 条，未经群聊识别）") {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 5) {
                            ForEach(model.visibleCandidates, id: \.self) { candidate in
                                Text(candidate).font(.caption).textSelection(.enabled)
                            }
                        }
                    }.frame(maxHeight: 160)
                }
            }
            TextField("搜索已记录群聊", text: $search)
            Text("记录 \(model.groups.count) 条 · 手动核验不代表微信身份验证")
                .foregroundStyle(.secondary)
            List {
                ForEach($model.groups) { $group in
                    if search.isEmpty || group.name.localizedCaseInsensitiveContains(search) {
                        HStack {
                            Toggle("", isOn: $group.selected).labelsHidden()
                                .disabled(group.isProtected || group.status != "已核验")
                            VStack(alignment: .leading) {
                                Text(group.name)
                                Text(group.source).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Picker("状态", selection: $group.status) {
                                Text("待核验").tag("待核验")
                                Text("已核验").tag("已核验")
                            }.frame(width: 120)
                            Toggle("保护", isOn: $group.isProtected).toggleStyle(.checkbox)
                        }
                    }
                }
            }
            Text("警告：本版本只提供界面、只读窗口检测和清单管理，不具备真实退群能力。")
                .font(.callout).foregroundStyle(.orange)
            Toggle("我理解退出群聊可能无法自行恢复", isOn: $acknowledged)
            HStack {
                Button("预览候选清单") { model.preview() }.disabled(!acknowledged)
                Spacer()
                Text("实际退群：未启用").foregroundStyle(.secondary)
            }
            Text(model.message).textSelection(.enabled)
        }.padding(20)
    }
}
