import TipKit

// MARK: - Dashboard Tip

struct DashboardTip: Tip {
    var title: Text {
        Text("tip.dashboard.title")
    }

    var message: Text? {
        Text("tip.dashboard.message")
    }

    var image: Image? {
        Image(systemName: "rectangle.on.rectangle")
    }
}

// MARK: - Transactions Tip

struct TransactionsTip: Tip {
    var title: Text {
        Text("tip.transactions.title")
    }

    var message: Text? {
        Text("tip.transactions.message")
    }

    var image: Image? {
        Image(systemName: "arrow.left.arrow.right")
    }
}

// MARK: - Accounts Tip

struct AccountsTip: Tip {
    var title: Text {
        Text("tip.accounts.title")
    }

    var message: Text? {
        Text("tip.accounts.message")
    }

    var image: Image? {
        Image(systemName: "building.columns")
    }
}

// MARK: - Categories Tip

struct CategoriesTip: Tip {
    var title: Text {
        Text("tip.categories.title")
    }

    var message: Text? {
        Text("tip.categories.message")
    }

    var image: Image? {
        Image(systemName: "tag")
    }
}

// MARK: - Periods Tip

struct PeriodsTip: Tip {
    var title: Text {
        Text("tip.periods.title")
    }

    var message: Text? {
        Text("tip.periods.message")
    }

    var image: Image? {
        Image(systemName: "calendar")
    }
}

// MARK: - Subscriptions Tip

struct SubscriptionsTip: Tip {
    var title: Text {
        Text("tip.subscriptions.title")
    }

    var message: Text? {
        Text("tip.subscriptions.message")
    }

    var image: Image? {
        Image(systemName: "repeat")
    }
}

// MARK: - Vendors Tip

struct VendorsTip: Tip {
    var title: Text {
        Text("tip.vendors.title")
    }

    var message: Text? {
        Text("tip.vendors.message")
    }

    var image: Image? {
        Image(systemName: "storefront")
    }
}
