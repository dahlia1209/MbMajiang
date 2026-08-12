//
//  CanvasEditorView.swift
//  MbMajiang
//

import SwiftUI
import PencilKit

/// 「対局編集」画面から開く、背景「キャンバス」テーマの手書き編集画面。
/// ペン・色・太さ・消しゴムはPencilKit標準の`PKToolPicker`に任せる。
///
/// `PKToolPicker.shared(for:)`はiOS 14で非推奨になっており、代わりに個別の`PKToolPicker()`インスタンスを
/// 生成して自分で保持し続けることが推奨されている。以前の実装は非推奨APIに依存していたため、
/// windowやfirst responderのタイミングに左右される不安定な挙動が起きていた
struct CanvasEditorView: View {
    @Environment(\.dismiss) private var dismiss

    /// 再読込用の既存のPKDrawing（未保存なら`nil`）
    let initialDrawingData: Data?
    /// キャンバスの背景色。エディタ内で自由に変更でき、変更は即座に反映される
    @Binding var backgroundColor: Color
    /// このキャンバス枠の名前。未入力なら`defaultName`を表示する。タイトル横のペンアイコンからその場で編集できる
    @Binding var name: String
    /// 名前が未入力の場合にタイトルへ表示する既定名（例：「キャンバス1」）
    let defaultName: String
    /// 「完了」時に、再編集用データと描画結果画像（透過PNG）を渡す
    let onSave: (_ drawingData: Data, _ imageData: Data?) -> Void

    @State private var canvasView = PKCanvasView()
    /// 個別インスタンスとして生成し、破棄されないようここで保持し続ける
    @State private var toolPicker = PKToolPicker()
    /// メニュー（サイドバー）の表示・非表示。falseの間はペン選択パネルも隠す
    @State private var isMenuVisible = true
    /// 開いた時点の描画内容。閉じる時にこれと比較し、変更があれば確認を出す
    @State private var loadedDrawingData = PKDrawing().dataRepresentation()
    @State private var showDiscardConfirmation = false
    @State private var showClearConfirmation = false
    /// タイトルが名前編集モードかどうか
    @State private var isEditingName = false
    @FocusState private var nameFieldFocused: Bool

    private let gold      = Color(red: 0.82, green: 0.68, blue: 0.25)
    private let goldLight = Color(red: 0.97, green: 0.93, blue: 0.83)

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            CanvasControllerRepresentable(canvasView: canvasView, toolPicker: toolPicker, isMenuVisible: isMenuVisible)
                .ignoresSafeArea()

            if isMenuVisible {
                VStack {
                    titleRow
                        .padding(.top, 20)
                    Spacer()
                }
            }

            // 左上：閉じる（キャンセル系）。常時表示
            VStack {
                HStack {
                    Button(action: { requestClose() }) {
                        Text("×")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                Spacer()
            }
            .padding(20)

            // 右上：完了（確定系）。閉じるとは反対側に置き誤操作を防ぐ
            VStack {
                HStack {
                    Spacer()
                    iconButton(icon: "checkmark", isPrimary: true) {
                        let drawingData = canvasView.drawing.dataRepresentation()
                        let scale = canvasView.window?.windowScene?.screen.scale ?? 2
                        let imageData = canvasView.drawing.bounds.isEmpty
                            ? nil
                            : canvasView.drawing.image(from: canvasView.bounds, scale: scale).pngData()
                        onSave(drawingData, imageData)
                        dismiss()
                    }
                }
                Spacer()
            }
            .padding(20)

            // 左側：開閉できるツール列（元に戻す・先に進む）
            HStack {
                toolMenu
                Spacer()
            }

            if isMenuVisible {
                // 左下：クリア。頻繁に使う元に戻す・先に進むから離し、誤タップを防ぐ
                VStack {
                    Spacer()
                    HStack {
                        iconButton(icon: "trash") { requestClear() }
                        Spacer()
                    }
                }
                .padding(20)

                // 右下：背景色（キャンバスの設定）。完了とは別の意味の操作なので離す
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ColorPicker("", selection: $backgroundColor, supportsOpacity: false)
                            .labelsHidden()
                            .frame(width: 40, height: 40)
                    }
                }
                .padding(20)
            }
        }
        .onAppear {
            if let data = initialDrawingData, let drawing = try? PKDrawing(data: data) {
                canvasView.drawing = drawing
            }
            loadedDrawingData = canvasView.drawing.dataRepresentation()
        }
        .confirmationDialog("変更を破棄しますか？", isPresented: $showDiscardConfirmation, titleVisibility: .visible) {
            Button("破棄して閉じる", role: .destructive) { dismiss() }
            Button("キャンセル", role: .cancel) {}
        }
        .confirmationDialog("キャンバスをすべて消去しますか？", isPresented: $showClearConfirmation, titleVisibility: .visible) {
            Button("消去する", role: .destructive) { canvasView.drawing = PKDrawing() }
            Button("キャンセル", role: .cancel) {}
        }
    }

    /// タイトル表示。通常時は名前＋リネームアイコン、編集中は名前を直接入力できる
    private var titleRow: some View {
        HStack(spacing: 8) {
            if isEditingName {
                TextField(defaultName, text: $name)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(goldLight)
                    .multilineTextAlignment(.center)
                    .frame(width: 180)
                    .focused($nameFieldFocused)
                    .onSubmit { isEditingName = false }
                titleIconButton(icon: "checkmark") { isEditingName = false }
            } else {
                Text(name.isEmpty ? defaultName : name)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(goldLight)
                    .shadow(color: .black.opacity(0.9), radius: 2)
                titleIconButton(icon: "pencil") {
                    isEditingName = true
                    nameFieldFocused = true
                }
            }
        }
    }

    /// タイトル横に置く小さめのアイコンボタン（リネーム操作用）
    private func titleIconButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(gold)
                .frame(width: 26, height: 26)
                .background(Color.black.opacity(0.4))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    /// 描画内容が開いた時点から変わっていれば確認してから閉じる
    private func requestClose() {
        if canvasView.drawing.dataRepresentation() == loadedDrawingData {
            dismiss()
        } else {
            showDiscardConfirmation = true
        }
    }

    /// 消去する内容がある場合のみ確認する
    private func requestClear() {
        if canvasView.drawing.strokes.isEmpty {
            canvasView.drawing = PKDrawing()
        } else {
            showClearConfirmation = true
        }
    }

    private var toolMenu: some View {
        VStack(spacing: 10) {
            if isMenuVisible {
                iconButton(icon: "chevron.left") {
                    withAnimation(.easeInOut(duration: 0.2)) { isMenuVisible.toggle() }
                }

                HStack(spacing: 10) {
                    iconButton(icon: "arrow.uturn.backward") { canvasView.undoManager?.undo() }
                    iconButton(icon: "arrow.uturn.forward") { canvasView.undoManager?.redo() }
                }
            } else {
                iconButton(icon: "chevron.right") {
                    withAnimation(.easeInOut(duration: 0.2)) { isMenuVisible.toggle() }
                }
            }
        }
        .padding(.top, 70)
        .padding(.leading, 20)
    }

    private func iconButton(icon: String, isPrimary: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(isPrimary ? Color.black : goldLight)
                .frame(width: 44, height: 44)
                .background(isPrimary ? goldLight : Color.black.opacity(0.4))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

/// PKCanvasView＋標準ツールピッカーをSwiftUIから使うためのラッパー
private struct CanvasControllerRepresentable: UIViewControllerRepresentable {
    let canvasView: PKCanvasView
    let toolPicker: PKToolPicker
    let isMenuVisible: Bool

    func makeUIViewController(context: Context) -> CanvasHostingController {
        let controller = CanvasHostingController()
        controller.canvasView = canvasView
        controller.toolPicker = toolPicker
        return controller
    }

    func updateUIViewController(_ uiViewController: CanvasHostingController, context: Context) {
        // 状態更新のたびに再度示すことで、初回表示時のタイミング問題を吸収する。
        // メニューが非表示のときはペン選択パネルも一緒に隠す
        toolPicker.setVisible(isMenuVisible, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        if isMenuVisible {
            canvasView.becomeFirstResponder()
        }
    }
}

private final class CanvasHostingController: UIViewController {
    var canvasView: PKCanvasView!
    var toolPicker: PKToolPicker!

    override func viewDidLoad() {
        super.viewDidLoad()
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.frame = view.bounds
        canvasView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(canvasView)

        toolPicker.addObserver(canvasView)
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        canvasView.becomeFirstResponder()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        canvasView.becomeFirstResponder()
    }
}

#Preview(traits: .landscapeLeft) {
    CanvasEditorView(initialDrawingData: nil, backgroundColor: .constant(.white),
                      name: .constant(""), defaultName: "キャンバス1") { _, _ in }
}
