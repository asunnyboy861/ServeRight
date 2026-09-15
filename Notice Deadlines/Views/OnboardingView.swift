import SwiftUI
import SwiftData

struct OnboardingView: View {
    @AppStorage("finished_onboarding") private var finishedOnboarding = false
    @AppStorage("onboarding_state") private var onboardingState = ""
    @AppStorage("onboarding_property_count") private var propertyCount = ""
    @AppStorage("onboarding_concern") private var concern = ""

    @State private var step = 0
    @State private var selectedState: Jurisdiction?
    @State private var showPaywall = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Capsule()
                            .fill(index <= min(step, 2) ? Color.accentColor : Color(.systemGray4))
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                TabView(selection: $step) {
                    step1.tag(0)
                    step2.tag(1)
                    step3.tag(2)
                    magicMoment.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("ServeRight")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var step1: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Where is your property?")
                .font(.largeTitle.bold())
            Text("Every state has different notice deadlines. Pick yours and we'll show the rules instantly.")
                .font(.body)
                .foregroundStyle(.secondary)
            Menu {
                ForEach(RuleStore.shared.jurisdictions) { jurisdiction in
                    Button(jurisdiction.name) {
                        selectedState = jurisdiction
                        onboardingState = jurisdiction.code
                    }
                }
            } label: {
                HStack {
                    Text(selectedState?.name ?? "Select your state")
                        .foregroundStyle(selectedState == nil ? .secondary : .primary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
            Spacer()
            Button {
                withAnimation { step = 1 }
            } label: {
                Text("Next")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(selectedState == nil)
            .accessibilityLabel("Next question")
        }
        .padding(24)
    }

    private var step2: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("How many properties?")
                .font(.largeTitle.bold())
            Text("You can track your first property completely free.")
                .font(.body)
                .foregroundStyle(.secondary)
            VStack(spacing: 12) {
                countOption("1 property")
                countOption("2–5 properties")
                countOption("6+ properties")
            }
            Spacer()
            Button {
                withAnimation { step = 2 }
            } label: {
                Text("Next")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(propertyCount.isEmpty)
            .accessibilityLabel("Next question")
        }
        .padding(24)
    }

    private var step3: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("What worries you most?")
                .font(.largeTitle.bold())
            Text("We'll put that deadline front and center on your Radar.")
                .font(.body)
                .foregroundStyle(.secondary)
            VStack(spacing: 12) {
                concernOption("Rent increase", icon: "chart.line.uptrend.xyaxis", detail: "Getting the notice period right")
                concernOption("Deposit", icon: "dollarsign.arrow.circlepath", detail: "Returning it on time, itemized")
                concernOption("Non-renewal", icon: "envelope.badge", detail: "Terminating a month-to-month lease")
            }
            Spacer()
            Button {
                withAnimation { step = 3 }
            } label: {
                Text("Show My Rules")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(concern.isEmpty)
            .accessibilityLabel("Show my rules")
        }
        .padding(24)
    }

    private func concernOption(_ label: String, icon: String, detail: String) -> some View {
        Button {
            concern = label
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .foregroundStyle(.primary)
                        .font(.headline)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if concern == label {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding()
            .background(concern == label ? Color.accentColor.opacity(0.12) : Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .accessibilityLabel(label)
    }

    private var magicMoment: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Your state rules, ready.")
                    .font(.largeTitle.bold())
                Text("No signup. No paywall. Here is what \(selectedState?.name ?? "your state") law requires.")
                    .font(.body)
                    .foregroundStyle(.secondary)

                if let jurisdiction = selectedState {
                    ForEach([RuleCategory.depositReturn, RuleCategory.rentIncrease, RuleCategory.termination]) { category in
                        if let entry = jurisdiction.primaryRule(for: category), let days = entry.days {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Image(systemName: category.icon)
                                        .foregroundStyle(Color.accentColor)
                                    Text(category.displayName)
                                        .font(.headline)
                                    Spacer()
                                    Text("\(days) days")
                                        .font(.title3.bold())
                                        .foregroundStyle(Color.accentColor)
                                }
                                Text(entry.penalty.penaltyText)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Link(entry.sourceURL, destination: URL(string: entry.sourceURL) ?? URL(string: "https://example.com")!)
                                    .font(.caption2)
                                    .lineLimit(1)
                                Text("Verified \(entry.verifiedDate) · rules v\(RuleStore.shared.version)")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(14)
                        }
                    }
                }

                Button {
                    finishedOnboarding = true
                } label: {
                    Text("Set Up My Deadlines")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityLabel("Finish onboarding and set up deadlines")
            }
            .padding(24)
        }
    }

    private func countOption(_ label: String) -> some View {
        Button {
            propertyCount = label
        } label: {
            HStack {
                Text(label)
                    .foregroundStyle(.primary)
                Spacer()
                if propertyCount == label {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding()
            .background(propertyCount == label ? Color.accentColor.opacity(0.12) : Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .accessibilityLabel(label)
    }
}
