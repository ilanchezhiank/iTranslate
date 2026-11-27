//
//  TranslateView.swift
//  iTranslate
//
//  Created by Ilanchezhian Kuppusamy on 05/10/26.
//

import SwiftUI
import Translation

struct TranslateView: View {
    @Environment(HistoryViewModel.self) private var history
    @State private var viewModel: TranslateViewModel?

    var body: some View {
        NavigationStack {
            if let viewModel {
                content(viewModel)
            } else {
                ProgressView().task {
                    // Inject the history store into the view model once the environment is available.
                    viewModel = TranslateViewModel(onComplete: {
                        history.add($0)
                    })
                }
            }
        }
    }

    @ViewBuilder
    private func content(_ vm: TranslateViewModel) -> some View {
        @Bindable var vm = vm
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                languagePicker(vm: vm)
                inputCard(vm: vm)
                translateButton(vm: vm)
                resultSection(vm: vm)
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Translate")
        .task { await vm.loadLanguages() }
        .translationTask(vm.configuration) { session in
            await vm.runTranslation(with: session)
        }
    }

    // MARK: Subviews

    private func inputCard(vm: TranslateViewModel) -> some View {
        @Bindable var vm = vm
        return VStack(alignment: .leading, spacing: 8) {
            Text("English").font(.caption).foregroundStyle(.secondary)
            ZStack(alignment: .topLeading) {
                TextEditor(text: $vm.inputText)
                    .frame(minHeight: 140)
                    .scrollContentBackground(.hidden)
                if vm.inputText.isEmpty {
                    Text("Type or tap the mic and speak…")
                        .foregroundStyle(.tertiary)
                        .padding(.top, 8).padding(.leading, 5)
                        .allowsHitTesting(false)
                }
            }
            HStack {
                Spacer()
                Button {
                    vm.toggleRecording()
                } label: {
                    Image(
                        systemName: vm.isRecording
                            ? "stop.circle.fill" : "mic.circle.fill"
                    )
                    .font(.system(size: 36))
                    .symbolEffect(.pulse, isActive: vm.isRecording)
                    .foregroundStyle(vm.isRecording ? .red : .accentColor)
                }
                .accessibilityLabel(
                    vm.isRecording ? "Stop dictation" : "Start dictation"
                )
            }
        }
        .padding()
        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 16))
    }

    private func translateButton(vm: TranslateViewModel) -> some View {
        Button {
            vm.translateTapped()
        } label: {
            HStack {
                if vm.isBusy { ProgressView().tint(.white) }
                Text(buttonTitle(vm.phase)).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(!vm.canTranslate)
    }

    private func buttonTitle(_ phase: TranslateViewModel.Phase) -> String {
        switch phase {
        case .translating: "Translating…"
        case .validating: "Validating with AI…"
        default: "Translate"
        }
    }

    private func languagePicker(vm: TranslateViewModel) -> some View {
        HStack {
            Text("Translate to").foregroundStyle(.secondary)
            Spacer()
            Picker(
                "Target language",
                selection: Binding(
                    get: { vm.targetLanguage },
                    set: { vm.select($0) }
                )
            ) {
                ForEach(vm.availableLanguages) { Text($0.name).tag($0) }
            }
            .pickerStyle(.menu)
            .disabled(vm.isBusy)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func resultSection(vm: TranslateViewModel) -> some View {
        switch vm.phase {
        case .done(let record): ResultCard(record: record)
        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red).font(.callout)
        default: EmptyView()
        }
    }
}

struct ResultCard: View {
    let record: TranslationRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            //            Text("Spanish").font(.caption).foregroundStyle(.secondary)
            Text(record.targetLanguageName).font(.caption2).foregroundStyle(
                .tertiary
            )
            Text(record.translated).font(.title3).textSelection(.enabled)

            Divider()

            if let v = record.validation {
                HStack {
                    Label(
                        v.isAccurate ? "Looks accurate" : "Needs review",
                        systemImage: v.isAccurate
                            ? "checkmark.seal.fill"
                            : "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(v.isAccurate ? .green : .orange)
                    .font(.headline)
                    Spacer()
                    Text("\(v.score)/10").font(.headline.monospacedDigit())
                }
                Text(v.feedback).font(.callout).foregroundStyle(.secondary)
                if !v.suggestedCorrection.isEmpty {
                    Text("Suggestion: \(v.suggestedCorrection)").font(.callout)
                }
            } else {
                Label(
                    "AI validation unavailable on this device",
                    systemImage: "sparkles"
                )
                .font(.callout).foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 16))
    }
}
