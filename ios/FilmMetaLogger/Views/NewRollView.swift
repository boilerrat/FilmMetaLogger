import SwiftUI

struct NewRollView: View {
    @EnvironmentObject private var rollStore: RollStore
    @Environment(\.dismiss) private var dismiss

    @State private var filmStock = ""
    @State private var isoText = "400"
    @State private var camera = ""
    @State private var lens = ""
    @State private var notes = ""

    private var isoValue: Int? {
        Int(isoText.trimmingCharacters(in: .whitespaces))
    }

    private var canSave: Bool {
        !filmStock.trimmingCharacters(in: .whitespaces).isEmpty &&
            isoValue != nil &&
            !camera.trimmingCharacters(in: .whitespaces).isEmpty &&
            !lens.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Roll Details") {
                    TextField("Film stock", text: $filmStock)
                    TextField("ISO", text: $isoText)
                        .keyboardType(.numberPad)
                    TextField("Camera", text: $camera)
                    TextField("Lens", text: $lens)
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle("New Roll")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRoll()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private func saveRoll() {
        guard let iso = isoValue else { return }
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        rollStore.createRoll(
            filmStock: filmStock.trimmingCharacters(in: .whitespacesAndNewlines),
            iso: iso,
            camera: camera.trimmingCharacters(in: .whitespacesAndNewlines),
            lens: lens.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes
        )
        dismiss()
    }
}
