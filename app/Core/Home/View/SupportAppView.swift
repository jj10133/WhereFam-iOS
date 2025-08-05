import SwiftUI
import RevenueCat

struct SupportAppView: View {
    
    // Define Tip enum for representing different tip levels
    enum Tip: String, CaseIterable {
        case small, medium, large, huge
        
        var id: String { rawValue }
        
        init(productId: String) {
            // Extract the tip type from the product ID (split by ".")
            self = .init(rawValue: String(productId))!
        }
        
        var productId: String {
            "com.wherefam.tipjar.\(rawValue)"
        }
        
        var title: String {
            switch self {
            case .small: return "Small Tip"
            case .medium: return "Medium Tip"
            case .large: return "Large Tip"
            case .huge: return "Huge Tip"
            }
        }
        
        var subtitle: String {
            switch self {
            case .small: return "Thank you for the coffee!"
            case .medium: return "Much appreciated!"
            case .large: return "You're a star!"
            case .huge: return "Seriously, thank you! Who are you??"
            }
        }
    }
    
    // State variables
    @State private var loadingProducts: Bool = false
    @State private var products: [StoreProduct] = []
    @State private var isProcessingPurchase: Bool = false
    @State private var purchaseSuccessDisplayed: Bool = false
    @State private var purchaseErrorDisplayed: Bool = false
    @State private var customerInfo: CustomerInfo?
    
    var body: some View {
        NavigationStack {
            Form {
                aboutSection
                subscriptionSection
                tipsSection
                restorePurchase
            }
            .navigationTitle("Support App")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadingProducts = true
                fetchStoreProducts()
                refreshUserInfo()
            }
            .alert("Success", isPresented: $purchaseSuccessDisplayed) {
                Button("OK") { purchaseSuccessDisplayed = false }
            } message: {
                Text("Your purchase was successful. Thank you!")
            }
            .alert("Error", isPresented: $purchaseErrorDisplayed) {
                Button("OK") { purchaseErrorDisplayed = false }
            } message: {
                Text("There was an error processing your purchase. Please try again.")
            }
        }
    }
    
    // About section with a description of the app and a call to action
    private var aboutSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("Hi there! My name is Nish and I love FOSS. WhereFam is one of my projects that I'm really proud of. Since everything is P2P, your data stays on your device. If you're enjoying WhereFam, consider tossing a little tip to support the app and its ongoing maintenance. 🚀")
                    .font(.body)
                    .padding(.bottom, 10)
            }
        }
    }
    
    // Dynamic tips section that displays available products
    private var tipsSection: some View {
        Section(header: Text("Support with a Tip")) {
            if loadingProducts {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center) // Ensures full width for centering
            } else {
                ForEach(products, id: \.productIdentifier) { product in
                    let tip = Tip(productId: product.productIdentifier)
                    HStack {
                        VStack(alignment: .leading) {
                            Text(tip.title)
                                .font(.headline)
                            Text(tip.subtitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        makePurchaseButton(product: product)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }
    
    // Section to restore previous purchases
    private var restorePurchase: some View {
        Section {
            HStack {
                Spacer()
                Button("Restore Purchases") {
                    restoreUserPurchases()
                }
                .buttonStyle(.bordered)
                Spacer()
            }
        } footer: {
            Text("If you've previously made a purchase and it's not showing up, tap to restore it.")
        }
        .listRowBackground(Color.clear)
    }
    
    private var subscriptionSection: some View {
        Section {
            if loadingProducts {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if let subscription = products.first(where: { $0.productIdentifier == "com.yourcompany.wherefam.subscription" }) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Subscription Plan")
                            .font(.headline)
                    }
                    Spacer()
                    
                    // Check if the user is subscribed
                    if let customerInfo = customerInfo,
                       customerInfo.entitlements["Tip"]?.isActive == true {
                        Text("You're subscribed!")
                            .font(.body)
                            .foregroundColor(.green)
                    } else {
                        makePurchaseButton(product: subscription)
                    }
                }
                .padding(.vertical, 8)
            }
        } footer: {
            if customerInfo?.entitlements.active.isEmpty == true {
                Text("Your subscription will auto-renew on a monthly basis. You can manage your subscription in the App Store settings.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 5)
            }
        }
    }

    
    // Fetch the list of products from RevenueCat
    private func fetchStoreProducts() {
        Purchases.shared.getProducts(Tip.allCases.map(\.productId)) { products in
            self.products = products.sorted(by: { $0.price < $1.price })
            withAnimation {
                loadingProducts = false
            }
        }
    }
    
    // Fetch and update the user's information
    private func refreshUserInfo() {
        Purchases.shared.getCustomerInfo { info, _ in
            customerInfo = info
        }
    }
    
    // Handle the purchase of a product
    private func purchase(product: StoreProduct) async {
        guard !isProcessingPurchase else { return }
        
        isProcessingPurchase = true
        do {
            let result = try await Purchases.shared.purchase(product: product)
            if !result.userCancelled {
                purchaseSuccessDisplayed = true
            }
        } catch {
            purchaseErrorDisplayed = true
        }
        isProcessingPurchase = false
    }
    
    // Function to handle restoring purchases
    private func restoreUserPurchases() {
        Purchases.shared.restorePurchases { info, _ in
            customerInfo = info
        }
    }
    
    // Button to initiate the purchase of a product
    private func makePurchaseButton(product: StoreProduct) -> some View {
        Button {
            Task {
                await purchase(product: product)
                refreshUserInfo()
            }
        } label: {
            if isProcessingPurchase {
                ProgressView()
            } else {
                Text(product.localizedPriceString)
            }
        }
        .buttonStyle(.bordered)
    }
}

#Preview {
    SupportAppView()
}
