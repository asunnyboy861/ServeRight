import SwiftUI
import SwiftData

struct RulesView: View {
    @AppStorage("onboarding_state") private var preferredState = ""
    @State private var selectedCode: String = ""
    @State private var selectedCategory: RuleCategory = .depositReturn

    private var selectedJurisdiction: Jurisdiction? {
        RuleStore.shared.jurisdiction(for: selectedCode)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("State", selection: $selectedCode) {
                    ForEach(RuleStore.shared.jurisdictions) { jurisdiction in
                        Text("\(jurisdiction.name)").tag(jurisdiction.code)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal)

                Picker("Category", selection: $selectedCategory) {
                    ForEach(RuleCategory.allCases) { category in
                        Text(category.displayName).tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 8)

                ScrollView {
                    VStack(spacing: 12) {
                        if let jurisdiction = selectedJurisdiction {
                            ForEach(jurisdiction.rules(for: selectedCategory)) { entry in
                                RuleCard(stateName: jurisdiction.name, category: selectedCategory, entry: entry)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("50-State Rules")
            .onAppear {
                if selectedCode.isEmpty {
                    selectedCode = RuleStore.shared.jurisdiction(for: preferredState)?.code ?? "CA"
                }
            }
        }
    }
}

struct RuleCard: View {
    let stateName: String
    let category: RuleCategory
    let entry: RuleEntry
    @State private var showOverride = false
    @State private var overrideDays: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundStyle(Color.accentColor)
                Text(stateName)
                    .font(.headline)
                Spacer()
                if let days = displayDays {
                    Text("\(days) days")
                        .font(.title3.bold().monospacedDigit())
                        .foregroundStyle(Color.accentColor)
                } else if let cap = entry.capMonths {
                    Text(cap == 0 ? "No cap" : "\(formatCap(cap)) months")
                        .font(.title3.bold())
                        .foregroundStyle(Color.accentColor)
                }
            }
            Text(entry.trigger.replacingOccurrences(of: "_", with: " ").capitalized)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(entry.penalty.penaltyText)
                .font(.callout)
            if let note = entry.note {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let overrideDays {
                Label("Override active: \(overrideDays) days (user-defined, not state default)", systemImage: "pencil.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            Divider()
            HStack {
                Link("Statute", destination: URL(string: entry.sourceURL) ?? URL(string: "https://example.com")!)
                    .font(.caption)
                Spacer()
                Text("Verified \(entry.verifiedDate) · v\(RuleStore.shared.version)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Button("Override (city rules may be stricter)") {
                showOverride = true
            }
            .font(.caption)
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
        .sheet(isPresented: $showOverride) {
            RuleOverrideSheet(entry: entry, savedDays: $overrideDays)
        }
        .onAppear {
            overrideDays = UserDefaults.standard.object(forKey: "override_\(entry.id)") as? Int
        }
    }

    private var displayDays: Int? {
        overrideDays ?? entry.days
    }

    private func formatCap(_ months: Double) -> String {
        months == months.rounded() ? "\(Int(months))" : "\(months)"
    }
}

struct RuleOverrideSheet: View {
    @Environment(\.dismiss) private var dismiss
    let entry: RuleEntry
    @Binding var savedDays: Int?
    @State private var daysText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("If your city ordinance is stricter than state law, enter the custom notice period here. Overrides are always labeled as user-defined.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Custom days (e.g. 45)", text: $daysText)
                        .keyboardType(.numberPad)
                } footer: {
                    Text("Source: user-defined, not state default. The state rule remains visible for reference.")
                }
            }
            .navigationTitle("Override Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let days = Int(daysText), days > 0 {
                            UserDefaults.standard.set(days, forKey: "override_\(entry.id)")
                            savedDays = days
                        }
                        dismiss()
                    }
                    .disabled(Int(daysText) == nil)
                }
            }
            .onAppear {
                if let existing = UserDefaults.standard.object(forKey: "override_\(entry.id)") as? Int {
                    daysText = "\(existing)"
                }
            }
        }
    }
}
