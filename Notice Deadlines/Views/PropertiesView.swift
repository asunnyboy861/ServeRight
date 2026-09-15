import SwiftUI
import SwiftData

struct PropertiesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var properties: [Property]
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var showAddProperty = false
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    if properties.isEmpty {
                        EmptyPropertiesCard {
                            showAddProperty = true
                        }
                    } else {
                        ForEach(properties) { property in
                            PropertyCard(property: property)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Properties")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if !purchaseManager.isPro && properties.count >= FreeLimits.maxFreeProperties {
                            showPaywall = true
                        } else {
                            showAddProperty = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityLabel("Add property")
                }
            }
            .sheet(isPresented: $showAddProperty) {
                PropertyEditorView()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }
}

struct EmptyPropertiesCard: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "house")
                .font(.system(size: 44))
                .foregroundStyle(Color.accentColor)
            Text("Add your first property")
                .font(.title3.bold())
            Text("Enter the state and lease details. ServeRight computes every statutory deadline automatically.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Add Property", action: onAdd)
                .buttonStyle(.borderedProminent)
        }
        .padding(28)
        .frame(maxWidth: 720)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(20)
    }
}

struct PropertyCard: View {
    @Environment(\.modelContext) private var modelContext
    let property: Property
    @State private var showEditor = false
    @State private var showDeleteConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(property.nickname)
                        .font(.headline)
                    Text(property.street)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(property.stateCode)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.12))
                    .foregroundStyle(Color.accentColor)
                    .cornerRadius(8)
            }
            ForEach(property.leaseList) { lease in
                LeaseRow(lease: lease)
            }
            HStack {
                Button {
                    showEditor = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                Spacer()
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("Delete", systemImage: "trash")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .confirmationDialog("Delete this property and all its leases?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete Property", role: .destructive) {
                modelContext.delete(property)
            }
        }
        .sheet(isPresented: $showEditor) {
            PropertyEditorView(property: property)
        }
    }
}

struct LeaseRow: View {
    let lease: Lease

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(lease.tenantName)
                    .font(.subheadline.weight(.medium))
                Text(leaseSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(lease.monthlyRent, format: .currency(code: "USD"))
                .font(.subheadline.monospacedDigit())
        }
        .padding(10)
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(10)
    }

    private var leaseSummary: String {
        let end = lease.endDate?.formatted(date: .abbreviated, time: .omitted) ?? "month-to-month"
        return "Lease \(lease.startDate.formatted(date: .abbreviated, time: .omitted)) – \(end)"
    }
}

struct PropertyEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    var property: Property?

    @State private var nickname = ""
    @State private var street = ""
    @State private var stateCode = "TX"
    @State private var tenantName = ""
    @State private var monthlyRent = ""
    @State private var depositAmount = ""
    @State private var startDate = Date.now
    @State private var hasEndDate = false
    @State private var endDate = Date.now.addingTimeInterval(365 * 86400)
    @State private var tenancyYears = ""
    @State private var hasIncrease = false
    @State private var increasePercent = ""
    @State private var increaseEffectiveDate = Date.now.addingTimeInterval(90 * 86400)
    @State private var hasKeysReturned = false
    @State private var keysReturnedOn = Date.now
    @State private var hasForwarding = false
    @State private var forwardingReceivedOn = Date.now
    @State private var deductionsClaimed = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Property") {
                    TextField("Nickname (e.g. Oak Street Duplex)", text: $nickname)
                    TextField("Street address", text: $street)
                    Picker("State", selection: $stateCode) {
                        ForEach(RuleStore.shared.jurisdictions) { jurisdiction in
                            Text(jurisdiction.name).tag(jurisdiction.code)
                        }
                    }
                }
                Section("Lease") {
                    TextField("Tenant name", text: $tenantName)
                    TextField("Monthly rent (USD)", text: $monthlyRent)
                        .keyboardType(.decimalPad)
                    TextField("Deposit amount (USD)", text: $depositAmount)
                        .keyboardType(.decimalPad)
                    DatePicker("Lease start", selection: $startDate, displayedComponents: .date)
                    Toggle("Fixed end date", isOn: $hasEndDate)
                    if hasEndDate {
                        DatePicker("Lease end", selection: $endDate, displayedComponents: .date)
                    }
                    TextField("Tenancy years (for CA/NY/DC tiers)", text: $tenancyYears)
                        .keyboardType(.decimalPad)
                }
                Section("Rent Increase Intent") {
                    Toggle("Planning a rent increase", isOn: $hasIncrease)
                    if hasIncrease {
                        TextField("Increase percent (e.g. 5)", text: $increasePercent)
                            .keyboardType(.decimalPad)
                        DatePicker("Effective date", selection: $increaseEffectiveDate, displayedComponents: .date)
                    }
                }
                Section("Move-Out Events") {
                    Toggle("Keys returned", isOn: $hasKeysReturned)
                    if hasKeysReturned {
                        DatePicker("Keys returned on", selection: $keysReturnedOn, displayedComponents: .date)
                    }
                    Toggle("Forwarding address received", isOn: $hasForwarding)
                    if hasForwarding {
                        DatePicker("Received on", selection: $forwardingReceivedOn, displayedComponents: .date)
                    }
                    Toggle("Deductions will be claimed", isOn: $deductionsClaimed)
                }
            }
            .navigationTitle(property == nil ? "New Property" : "Edit Property")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
            .onAppear(perform: load)
        }
    }

    private var isValid: Bool {
        !nickname.isEmpty && !street.isEmpty && !tenantName.isEmpty &&
        Double(monthlyRent) != nil && Double(depositAmount) != nil
    }

    private func load() {
        guard let property else { return }
        nickname = property.nickname
        street = property.street
        stateCode = property.stateCode
        guard let lease = property.leaseList.first else { return }
        tenantName = lease.tenantName
        monthlyRent = "\(lease.monthlyRent)"
        depositAmount = "\(lease.depositAmount)"
        startDate = lease.startDate
        if let end = lease.endDate {
            hasEndDate = true
            endDate = end
        }
        tenancyYears = "\(lease.tenancyYears)"
        if let percent = lease.increasePercent {
            hasIncrease = true
            increasePercent = "\(percent)"
            increaseEffectiveDate = lease.increaseEffectiveDate ?? .now
        }
        if let keys = lease.keysReturnedOn {
            hasKeysReturned = true
            keysReturnedOn = keys
        }
        if let forwarding = lease.forwardingAddressReceivedOn {
            hasForwarding = true
            forwardingReceivedOn = forwarding
        }
        deductionsClaimed = lease.deductionsClaimed
    }

    private func save() {
        let target: Property
        if let property {
            target = property
        } else {
            target = Property(nickname: nickname, street: street, stateCode: stateCode)
            modelContext.insert(target)
        }
        target.nickname = nickname
        target.street = street
        target.stateCode = stateCode

        let lease = target.leaseList.first ?? {
            let newLease = Lease(tenantName: tenantName, monthlyRent: 0, depositAmount: 0, startDate: startDate)
            newLease.property = target
            modelContext.insert(newLease)
            return newLease
        }()
        lease.tenantName = tenantName
        lease.monthlyRent = Double(monthlyRent) ?? 0
        lease.depositAmount = Double(depositAmount) ?? 0
        lease.startDate = startDate.startOfDay
        lease.endDate = hasEndDate ? endDate.startOfDay : nil
        lease.tenancyYears = Double(tenancyYears) ?? 0
        lease.increasePercent = hasIncrease ? (Double(increasePercent) ?? 0) : nil
        lease.increaseEffectiveDate = hasIncrease ? increaseEffectiveDate.startOfDay : nil
        lease.keysReturnedOn = hasKeysReturned ? keysReturnedOn.startOfDay : nil
        lease.forwardingAddressReceivedOn = hasForwarding ? forwardingReceivedOn.startOfDay : nil
        lease.deductionsClaimed = deductionsClaimed

        RuleEngine.rebuildDeadlines(for: lease, property: target, context: modelContext)
        NotificationScheduler.rescheduleAll(deadlines: currentDeadlines())
        dismiss()
    }

    private func currentDeadlines() -> [DeadlineInstance] {
        let descriptor = FetchDescriptor<DeadlineInstance>()
        return (try? modelContext.fetch(descriptor)) ?? []
    }
}
