import SwiftUI

struct ContentView: View {
    @State private var viewModel = AppViewModel()
    @State private var input = ""
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                historySection
                Divider()
                inputBar
            }
            .navigationTitle("Calendar Assistant")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            await viewModel.requestPermissions()
        }
    }

    // MARK: - History

    private var historySection: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(viewModel.memory.turns.indices, id: \.self) { index in
                    let turn = viewModel.memory.turns[index]
                    messageBubble(role: turn.role, content: turn.content)
                }
                statusBubble
            }
            .padding()
        }
    }

    @ViewBuilder
    private var statusBubble: some View {
        switch viewModel.state {
        case .idle:
            EmptyView()
        case .processing:
            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Thinking…")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
            .padding(.top, 4)
        case .success(let message):
            Label(message, systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.subheadline)
                .padding(.top, 4)
        case .failure(let message):
            Label(message, systemImage: "exclamationmark.circle.fill")
                .foregroundStyle(.red)
                .font(.subheadline)
                .padding(.top, 4)
        }
    }

    private func messageBubble(role: String, content: String) -> some View {
        let isUser = role == "user"
        return HStack {
            if isUser { Spacer(minLength: 40) }
            Text(content)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isUser ? Color.accentColor : Color(.systemGray5))
                .foregroundStyle(isUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            if !isUser { Spacer(minLength: 40) }
        }
    }

    // MARK: - Input bar

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("e.g. Lunch with Ana tomorrow at 1pm", text: $input, axis: .vertical)
                .lineLimit(1...4)
                .focused($inputFocused)
                .submitLabel(.send)
                .onSubmit { submit() }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 20))

            Button(action: submit) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(canSubmit ? Color.accentColor : Color(.systemGray3))
            }
            .disabled(!canSubmit)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private var canSubmit: Bool {
        !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && viewModel.state != .processing
    }

    private func submit() {
        guard canSubmit else { return }
        let text = input
        input = ""
        inputFocused = false
        viewModel.reset()
        Task { await viewModel.process(input: text) }
    }
}
