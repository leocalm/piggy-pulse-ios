# i18n with String Catalogs Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add full i18n support to the iOS app using a `Localizable.xcstrings` String Catalog, with English as the only language, so all user-facing strings are translatable in the future.

**Architecture:** SwiftUI `Text("literal")` already uses `LocalizedStringKey` and auto-localizes once a String Catalog exists. Helper functions that accept `String` parameters and pass them to `Text(label)` use the verbatim initializer and will NOT auto-localize — those must be changed to accept `LocalizedStringKey`. Error messages stored in `String` variables and displayed via `Text(variable)` also bypass localization and must be wrapped with `String(localized:)` at the assignment site.

**Tech Stack:** Swift String Catalogs (`.xcstrings`), `LocalizedStringKey`, `String(localized:)`

---

## Task 1: Git Setup

**Files:** none

**Step 1: Pull main branch**

```bash
cd /Volumes/T7/opt/piggy-pulse/piggy-pulse-ios
git checkout main && git pull
```

**Step 2: Create feature branch**

```bash
git checkout -b feat/i18n-string-catalogs
```

---

## Task 2: Create `Localizable.xcstrings`

**Files:**
- Create: `Localizable.xcstrings` (at project root, alongside `PiggyPulse-Info.plist`)

The file must be valid JSON with `sourceLanguage: "en"`. Every user-facing static string in the app gets an entry. English translations are explicit so Xcode shows them in the catalog editor.

**Step 1: Create the file**

Create `/Volumes/T7/opt/piggy-pulse/piggy-pulse-ios/Localizable.xcstrings` with this content:

```json
{
  "sourceLanguage" : "en",
  "strings" : {

    "PiggyPulse" : {
      "comment" : "App name / logo label",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "PiggyPulse" } } }
    },
    "Clarity begins with structure." : {
      "comment" : "App tagline shown on login screen",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Clarity begins with structure." } } }
    },

    "Dashboard" : {
      "comment" : "Tab bar item — main dashboard screen",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Dashboard" } } }
    },
    "Transactions" : {
      "comment" : "Tab bar item — transactions list",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Transactions" } } }
    },
    "Periods" : {
      "comment" : "Tab bar item — budget periods",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Periods" } } }
    },
    "More" : {
      "comment" : "Tab bar item — more options",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "More" } } }
    },

    "STRUCTURE" : {
      "comment" : "Section header in More tab",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "STRUCTURE" } } }
    },
    "APP" : {
      "comment" : "Section header in More tab and Settings",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "APP" } } }
    },
    "Accounts" : {
      "comment" : "Navigation link and screen title",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Accounts" } } }
    },
    "Categories" : {
      "comment" : "Navigation link and screen title",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Categories" } } }
    },
    "Vendors" : {
      "comment" : "Navigation link and screen title",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Vendors" } } }
    },
    "Category Targets" : {
      "comment" : "Navigation link in More tab for budget targets",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Category Targets" } } }
    },
    "Overlays" : {
      "comment" : "Navigation link and screen title",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Overlays" } } }
    },
    "Settings" : {
      "comment" : "Navigation link and screen title",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Settings" } } }
    },
    "Log out" : {
      "comment" : "Logout button in More tab",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Log out" } } }
    },

    "CURRENT PERIOD" : {
      "comment" : "Dashboard card section header",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "CURRENT PERIOD" } } }
    },
    "SPENDING CONSISTENCY" : {
      "comment" : "Dashboard card section header",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "SPENDING CONSISTENCY" } } }
    },
    "NET POSITION" : {
      "comment" : "Dashboard card section header",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "NET POSITION" } } }
    },
    "Retry" : {
      "comment" : "Button to retry a failed network request",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Retry" } } }
    },

    "Welcome back" : {
      "comment" : "Login screen heading",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Welcome back" } } }
    },
    "Email" : {
      "comment" : "Form field label",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Email" } } }
    },
    "you@example.com" : {
      "comment" : "Email field placeholder",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "you@example.com" } } }
    },
    "Password" : {
      "comment" : "Form field label",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Password" } } }
    },
    "Your password" : {
      "comment" : "Password field placeholder on login",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Your password" } } }
    },
    "Log in" : {
      "comment" : "Login button",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Log in" } } }
    },
    "Forgot password?" : {
      "comment" : "Link to forgot password screen",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Forgot password?" } } }
    },
    "Don't have an account?" : {
      "comment" : "Prompt before Sign up link",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Don't have an account?" } } }
    },
    "Sign up" : {
      "comment" : "Link to registration screen",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Sign up" } } }
    },
    "Two-Factor Authentication" : {
      "comment" : "2FA section heading on login",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Two-Factor Authentication" } } }
    },
    "Enter the code from your authenticator app." : {
      "comment" : "2FA instruction text",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Enter the code from your authenticator app." } } }
    },
    "Code" : {
      "comment" : "2FA code field label",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Code" } } }
    },
    "123456" : {
      "comment" : "2FA code field placeholder",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "123456" } } }
    },
    "Verify" : {
      "comment" : "2FA submit button",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Verify" } } }
    },
    "Back to login" : {
      "comment" : "Button to go back to login from 2FA or forgot password",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Back to login" } } }
    },

    "Create an account" : {
      "comment" : "Registration screen heading",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Create an account" } } }
    },
    "Full Name" : {
      "comment" : "Registration form field label",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Full Name" } } }
    },
    "John Doe" : {
      "comment" : "Name field placeholder on registration",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "John Doe" } } }
    },
    "Confirm Password" : {
      "comment" : "Registration confirm password field label",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Confirm Password" } } }
    },
    "Confirm your password" : {
      "comment" : "Confirm password field placeholder",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Confirm your password" } } }
    },
    "Register" : {
      "comment" : "Registration submit button",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Register" } } }
    },
    "Already have an account?" : {
      "comment" : "Prompt before Login link on registration",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Already have an account?" } } }
    },
    "Login" : {
      "comment" : "Link back to login from registration",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Login" } } }
    },

    "Password recovery" : {
      "comment" : "Forgot password screen heading",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Password recovery" } } }
    },
    "Enter your email address. If it is registered, you will receive a reset link." : {
      "comment" : "Forgot password instruction text",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Enter your email address. If it is registered, you will receive a reset link." } } }
    },
    "name@example.com" : {
      "comment" : "Email placeholder on forgot password screen",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "name@example.com" } } }
    },
    "Send link" : {
      "comment" : "Forgot password submit button",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Send link" } } }
    },
    "Check your email" : {
      "comment" : "Forgot password success heading",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Check your email" } } }
    },
    "If an account exists for that email, we've sent a password reset link. Check your inbox and spam folder." : {
      "comment" : "Forgot password success body",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "If an account exists for that email, we've sent a password reset link. Check your inbox and spam folder." } } }
    },

    "No transactions found" : {
      "comment" : "Empty state heading on Transactions screen",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "No transactions found" } } }
    },
    "Start tracking your spending by adding your first transaction." : {
      "comment" : "Empty state body on Transactions screen",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Start tracking your spending by adding your first transaction." } } }
    },
    "Delete" : {
      "comment" : "Destructive action button / swipe action",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Delete" } } }
    },
    "Edit" : {
      "comment" : "Edit action button / swipe action",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Edit" } } }
    },
    "Cancel" : {
      "comment" : "Cancel button in dialogs",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Cancel" } } }
    },
    "Delete transaction?" : {
      "comment" : "Confirmation dialog title before deleting a transaction",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Delete transaction?" } } }
    },
    "This transaction will be permanently deleted." : {
      "comment" : "Confirmation dialog message for transaction deletion",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "This transaction will be permanently deleted." } } }
    },

    "Add Transaction" : {
      "comment" : "Sheet title for adding a new transaction",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Add Transaction" } } }
    },
    "Edit Transaction" : {
      "comment" : "Sheet title for editing an existing transaction",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Edit Transaction" } } }
    },
    "Amount" : {
      "comment" : "Section heading / field label for currency amount",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Amount" } } }
    },
    "Transfer between accounts" : {
      "comment" : "Toggle label for transfer transaction type",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Transfer between accounts" } } }
    },
    "Details" : {
      "comment" : "Section heading in transaction form",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Details" } } }
    },
    "Description" : {
      "comment" : "Form field label for transaction description",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Description" } } }
    },
    "e.g. Groceries at Albert Heijn" : {
      "comment" : "Description field placeholder in Add Transaction",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "e.g. Groceries at Albert Heijn" } } }
    },
    "e.g. Groceries" : {
      "comment" : "Description field placeholder in Edit Transaction",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "e.g. Groceries" } } }
    },
    "Date" : {
      "comment" : "Form field label for date picker",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Date" } } }
    },
    "Classification" : {
      "comment" : "Section heading in transaction form",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Classification" } } }
    },
    "Category" : {
      "comment" : "Form field label / picker label",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Category" } } }
    },
    "Select category" : {
      "comment" : "Placeholder option in category picker",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Select category" } } }
    },
    "From Account" : {
      "comment" : "Form field label / picker label for source account",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "From Account" } } }
    },
    "To Account" : {
      "comment" : "Form field label / picker label for destination account",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "To Account" } } }
    },
    "Select account" : {
      "comment" : "Placeholder option in account picker",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Select account" } } }
    },
    "Select" : {
      "comment" : "Generic placeholder option in pickers",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Select" } } }
    },
    "Vendor" : {
      "comment" : "Form field label / picker label",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Vendor" } } }
    },
    "None" : {
      "comment" : "Placeholder 'no selection' option in vendor picker",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "None" } } }
    },
    "Failed to load form options." : {
      "comment" : "Error message when transaction form options fail to load",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Failed to load form options." } } }
    },
    "Please select a category and account." : {
      "comment" : "Validation error in Add Transaction",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Please select a category and account." } } }
    },
    "Failed to create transaction." : {
      "comment" : "Error message when transaction creation fails",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Failed to create transaction." } } }
    },
    "Failed to load options." : {
      "comment" : "Error message when edit form options fail to load",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Failed to load options." } } }
    },
    "Select a category and account." : {
      "comment" : "Validation error in Edit Transaction",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Select a category and account." } } }
    },
    "Failed to update transaction." : {
      "comment" : "Error message when transaction update fails",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Failed to update transaction." } } }
    },
    "Failed to load transactions." : {
      "comment" : "Error message when transactions list fails to load",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Failed to load transactions." } } }
    },
    "Failed to load dashboard data." : {
      "comment" : "Error message when dashboard fails to load",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Failed to load dashboard data." } } }
    },

    "PROFILE" : {
      "comment" : "Settings section header",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "PROFILE" } } }
    },
    "SECURITY" : {
      "comment" : "Settings section header",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "SECURITY" } } }
    },
    "PREFERENCES" : {
      "comment" : "Settings section header",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "PREFERENCES" } } }
    },
    "Name" : {
      "comment" : "Settings row label / form field label",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Name" } } }
    },
    "Timezone" : {
      "comment" : "Settings row label",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Timezone" } } }
    },
    "Theme" : {
      "comment" : "Settings preferences row label",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Theme" } } }
    },
    "Date Format" : {
      "comment" : "Settings preferences row label",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Date Format" } } }
    },
    "Number Format" : {
      "comment" : "Settings preferences row label",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Number Format" } } }
    },
    "Compact Mode" : {
      "comment" : "Settings preferences row label",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Compact Mode" } } }
    },
    "On" : {
      "comment" : "Compact mode enabled state value",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "On" } } }
    },
    "Off" : {
      "comment" : "Compact mode disabled state value",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Off" } } }
    },
    "Version" : {
      "comment" : "App info row label in Settings",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Version" } } }
    },
    "Build" : {
      "comment" : "App info row label in Settings",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Build" } } }
    },
    "Change" : {
      "comment" : "Button label to change password in Settings",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Change" } } }
    },
    "Failed to load settings." : {
      "comment" : "Error message when settings fail to load",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Failed to load settings." } } }
    },

    "Edit Profile" : {
      "comment" : "Sheet title for editing user profile",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Edit Profile" } } }
    },
    "Your name" : {
      "comment" : "Name field placeholder in Edit Profile",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Your name" } } }
    },
    "Save" : {
      "comment" : "Save button in forms",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Save" } } }
    },
    "Failed to update profile." : {
      "comment" : "Error message when profile update fails",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Failed to update profile." } } }
    },

    "Change Password" : {
      "comment" : "Sheet title for changing password",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Change Password" } } }
    },
    "Current Password" : {
      "comment" : "Form field label in Change Password",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Current Password" } } }
    },
    "New Password" : {
      "comment" : "Form field label in Change Password",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "New Password" } } }
    },
    "Update Password" : {
      "comment" : "Submit button in Change Password sheet",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Update Password" } } }
    },
    "Failed to change password." : {
      "comment" : "Error message when password change fails",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Failed to change password." } } }
    },

    "No accounts yet" : {
      "comment" : "Empty state heading on Accounts screen",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "No accounts yet" } } }
    },
    "Archive" : {
      "comment" : "Archive action button",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Archive" } } }
    },
    "This account will be permanently deleted." : {
      "comment" : "Confirmation dialog message for account deletion",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "This account will be permanently deleted." } } }
    },
    "Failed to load accounts." : {
      "comment" : "Error message when accounts fail to load",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Failed to load accounts." } } }
    },
    "Failed to create account." : {
      "comment" : "Error message when account creation fails",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Failed to create account." } } }
    },
    "Failed to update account." : {
      "comment" : "Error message when account update fails",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Failed to update account." } } }
    },
    "Add Account" : {
      "comment" : "Sheet title for adding a new account",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Add Account" } } }
    },
    "Edit Account" : {
      "comment" : "Sheet title for editing an account",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Edit Account" } } }
    },
    "Account Details" : {
      "comment" : "Section heading in account form",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Account Details" } } }
    },
    "Type" : {
      "comment" : "Account type form field label",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Type" } } }
    },
    "Currency" : {
      "comment" : "Account currency form field label",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Currency" } } }
    },
    "Select type" : {
      "comment" : "Placeholder option in account type picker",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Select type" } } }
    },

    "No categories yet" : {
      "comment" : "Empty state heading on Categories screen",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "No categories yet" } } }
    },
    "Failed to load categories." : {
      "comment" : "Error message when categories fail to load",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Failed to load categories." } } }
    },
    "Failed to create category." : {
      "comment" : "Error message when category creation fails",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Failed to create category." } } }
    },
    "Failed to update category." : {
      "comment" : "Error message when category update fails",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Failed to update category." } } }
    },
    "Add Category" : {
      "comment" : "Sheet title for adding a new category",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Add Category" } } }
    },
    "Edit Category" : {
      "comment" : "Sheet title for editing a category",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Edit Category" } } }
    },
    "Icon" : {
      "comment" : "Category icon form field label",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Icon" } } }
    },
    "Color" : {
      "comment" : "Category color form field label",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Color" } } }
    },
    "Income category" : {
      "comment" : "Toggle label for marking a category as income",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Income category" } } }
    },
    "Budget Target" : {
      "comment" : "Section heading for budget target in category form",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Budget Target" } } }
    },

    "No vendors yet" : {
      "comment" : "Empty state heading on Vendors screen",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "No vendors yet" } } }
    },
    "Vendors are assigned when creating transactions." : {
      "comment" : "Empty state body on Vendors screen",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Vendors are assigned when creating transactions." } } }
    },
    "ALL VENDORS" : {
      "comment" : "Section header on Vendors screen",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "ALL VENDORS" } } }
    },
    "Archived" : {
      "comment" : "Badge label for archived vendors",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Archived" } } }
    },
    "This vendor will be hidden but its history will be preserved." : {
      "comment" : "Confirmation dialog message for archiving a vendor",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "This vendor will be hidden but its history will be preserved." } } }
    },
    "This vendor will be permanently deleted." : {
      "comment" : "Confirmation dialog message for deleting a vendor",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "This vendor will be permanently deleted." } } }
    },
    "Failed to load vendors." : {
      "comment" : "Error message when vendors fail to load",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Failed to load vendors." } } }
    },
    "Failed to create vendor." : {
      "comment" : "Error message when vendor creation fails",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Failed to create vendor." } } }
    },
    "Failed to update vendor." : {
      "comment" : "Error message when vendor update fails",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Failed to update vendor." } } }
    },
    "Add Vendor" : {
      "comment" : "Sheet title for adding a new vendor",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Add Vendor" } } }
    },
    "Edit Vendor" : {
      "comment" : "Sheet title for editing a vendor",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Edit Vendor" } } }
    },
    "Vendor Details" : {
      "comment" : "Section heading in vendor form",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Vendor Details" } } }
    },
    "Optional description" : {
      "comment" : "Vendor description field placeholder",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Optional description" } } }
    },
    "Vendor name" : {
      "comment" : "Vendor name field placeholder in Edit Vendor",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Vendor name" } } }
    },
    "Optional" : {
      "comment" : "Vendor description field placeholder in Edit Vendor",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Optional" } } }
    },

    "Auto-Creation" : {
      "comment" : "Navigation link and screen title for auto-creation of periods",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Auto-Creation" } } }
    },
    "Configure automatic period generation" : {
      "comment" : "Subtitle under Auto-Creation link in Periods",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Configure automatic period generation" } } }
    },
    "SCHEDULE" : {
      "comment" : "Section header in Periods screen",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "SCHEDULE" } } }
    },
    "CURRENT PERIOD" : {
      "comment" : "Section header in Periods screen showing current period",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "CURRENT PERIOD" } } }
    },
    "UPCOMING PERIODS" : {
      "comment" : "Section header in Periods screen",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "UPCOMING PERIODS" } } }
    },
    "PAST PERIODS" : {
      "comment" : "Section header in Periods screen",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "PAST PERIODS" } } }
    },
    "No current period found." : {
      "comment" : "Empty state when no current budget period exists",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "No current period found." } } }
    },
    "No upcoming periods." : {
      "comment" : "Empty state when no upcoming budget periods exist",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "No upcoming periods." } } }
    },
    "No past periods." : {
      "comment" : "Empty state when no past budget periods exist",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "No past periods." } } }
    },
    "Failed to load periods." : {
      "comment" : "Error message when periods fail to load",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Failed to load periods." } } }
    },
    "Auto-generated" : {
      "comment" : "Badge label on auto-generated periods in period detail",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Auto-generated" } } }
    },
    "DATE RANGE" : {
      "comment" : "Section header in Period Detail",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "DATE RANGE" } } }
    },
    "METRICS" : {
      "comment" : "Section header in Period Detail",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "METRICS" } } }
    },
    "Start" : {
      "comment" : "Start date column label in Period Detail",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Start" } } }
    },
    "End" : {
      "comment" : "End date column label in Period Detail",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "End" } } }
    },
    "Budget Used" : {
      "comment" : "Metric label in Period Detail",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Budget Used" } } }
    },
    "Duration" : {
      "comment" : "Metric label in Period Detail and picker label in Create Period",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Duration" } } }
    },

    "Create Budget Period" : {
      "comment" : "Sheet title for creating a new budget period",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Create Budget Period" } } }
    },
    "Period Setup" : {
      "comment" : "Section heading in Create Period and Auto-Creation",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Period Setup" } } }
    },
    "Period boundaries are structural and can reclassify transactions." : {
      "comment" : "Informational text in Create Period form",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Period boundaries are structural and can reclassify transactions." } } }
    },
    "Start Date" : {
      "comment" : "Form field label for period start date",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Start Date" } } }
    },
    "Duration Unit" : {
      "comment" : "Picker label for duration unit in Create Period",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Duration Unit" } } }
    },
    "Days" : {
      "comment" : "Duration unit option",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Days" } } }
    },
    "Weeks" : {
      "comment" : "Duration unit option",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Weeks" } } }
    },
    "Months" : {
      "comment" : "Duration unit option",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Months" } } }
    },
    "End Rule" : {
      "comment" : "Section heading in Create Period",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "End Rule" } } }
    },
    "By Duration" : {
      "comment" : "End rule picker option",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "By Duration" } } }
    },
    "Set Manually" : {
      "comment" : "End rule picker option",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Set Manually" } } }
    },
    "Calculated End Date" : {
      "comment" : "Label showing auto-computed end date in Create Period",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Calculated End Date" } } }
    },
    "Manual End Date" : {
      "comment" : "Label for manual end date picker in Create Period",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Manual End Date" } } }
    },
    "Naming" : {
      "comment" : "Section heading for period naming in Create Period and Auto-Creation",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Naming" } } }
    },
    "Period Name" : {
      "comment" : "Form field label for period name",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Period Name" } } }
    },
    "Failed to create period." : {
      "comment" : "Error message when period creation fails",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Failed to create period." } } }
    },

    "Auto-Creation is disabled" : {
      "comment" : "Heading shown when auto-creation schedule is off",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Auto-Creation is disabled" } } }
    },
    "Enable a schedule to generate future periods automatically." : {
      "comment" : "Body text when auto-creation is disabled",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Enable a schedule to generate future periods automatically." } } }
    },
    "Set up Auto-Creation" : {
      "comment" : "Button to enable auto-creation schedule",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Set up Auto-Creation" } } }
    },
    "Start Day of Month" : {
      "comment" : "Auto-Creation form field label",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Start Day of Month" } } }
    },
    "Generate Ahead" : {
      "comment" : "Auto-Creation form field label for how many periods to pre-generate",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Generate Ahead" } } }
    },
    "Weekend Adjustments" : {
      "comment" : "Section heading in Auto-Creation for weekend day adjustments",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Weekend Adjustments" } } }
    },
    "Name Pattern" : {
      "comment" : "Auto-Creation form field label for period naming pattern",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Name Pattern" } } }
    },
    "Use {month} and {year} as placeholders." : {
      "comment" : "Helper text for auto-creation name pattern field",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Use {month} and {year} as placeholders." } } }
    },
    "Saturday" : {
      "comment" : "Weekend adjustment row label",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Saturday" } } }
    },
    "Sunday" : {
      "comment" : "Weekend adjustment row label",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Sunday" } } }
    },
    "Keep" : {
      "comment" : "Weekend adjustment option — keep the day as-is",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Keep" } } }
    },
    "Move to Friday" : {
      "comment" : "Weekend adjustment option",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Move to Friday" } } }
    },
    "Move to Monday" : {
      "comment" : "Weekend adjustment option",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Move to Monday" } } }
    },
    "Enable Auto-Creation" : {
      "comment" : "Button to save and enable auto-creation schedule",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Enable Auto-Creation" } } }
    },
    "Save Changes" : {
      "comment" : "Button to save changes to auto-creation schedule",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Save Changes" } } }
    },
    "Disable Auto-Creation" : {
      "comment" : "Button to disable auto-creation schedule",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Disable Auto-Creation" } } }
    },
    "Failed to save schedule." : {
      "comment" : "Error message when saving auto-creation schedule fails",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Failed to save schedule." } } }
    },
    "Failed to disable auto-creation." : {
      "comment" : "Error message when disabling auto-creation fails",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Failed to disable auto-creation." } } }
    },

    "No overlays yet" : {
      "comment" : "Empty state heading on Overlays screen",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "No overlays yet" } } }
    },
    "Create overlays from the web app to track temporary spending goals." : {
      "comment" : "Empty state body on Overlays screen",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Create overlays from the web app to track temporary spending goals." } } }
    },
    "ACTIVE OVERLAYS" : {
      "comment" : "Section header on Overlays screen",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "ACTIVE OVERLAYS" } } }
    },
    "UPCOMING OVERLAYS" : {
      "comment" : "Section header on Overlays screen",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "UPCOMING OVERLAYS" } } }
    },
    "PAST OVERLAYS" : {
      "comment" : "Section header on Overlays screen",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "PAST OVERLAYS" } } }
    },
    "ACTIVE" : {
      "comment" : "Status badge label for active overlay",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "ACTIVE" } } }
    },
    "UPCOMING" : {
      "comment" : "Status badge label for upcoming overlay",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "UPCOMING" } } }
    },
    "ENDED" : {
      "comment" : "Status badge label for ended overlay",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "ENDED" } } }
    },
    "Failed to load overlays." : {
      "comment" : "Error message when overlays fail to load",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Failed to load overlays." } } }
    },

    "Category targets" : {
      "comment" : "Navigation title of Budget Plan / Category Targets screen",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Category targets" } } }
    },
    "Manage your spending limits." : {
      "comment" : "Navigation subtitle on Category Targets screen",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Manage your spending limits." } } }
    },
    "No budget categories yet" : {
      "comment" : "Empty state heading on Category Targets screen",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "No budget categories yet" } } }
    },
    "Assign budgets to your categories from the web app to see them here." : {
      "comment" : "Empty state body on Category Targets screen",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Assign budgets to your categories from the web app to see them here." } } }
    },
    "BUDGETED CATEGORIES" : {
      "comment" : "Section header on Category Targets screen",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "BUDGETED CATEGORIES" } } }
    },
    "BUDGET BREAKDOWN" : {
      "comment" : "Section header on Category Targets summary card",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "BUDGET BREAKDOWN" } } }
    },
    "Total Budget" : {
      "comment" : "Breakdown row label in Category Targets",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Total Budget" } } }
    },
    "Currently Spent" : {
      "comment" : "Breakdown row label in Category Targets",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Currently Spent" } } }
    },
    "Remaining Budget" : {
      "comment" : "Breakdown row label in Category Targets",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Remaining Budget" } } }
    },
    "Failed to load budget data." : {
      "comment" : "Error message when budget data fails to load",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Failed to load budget data." } } }
    },

    "No period selected" : {
      "comment" : "Shown in period selector bar when no period is active",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "No period selected" } } }
    },
    "Select Period" : {
      "comment" : "Navigation title of the period picker sheet",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Select Period" } } }
    },

    "Something went wrong. Please try again." : {
      "comment" : "Generic error message in auth flow",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Something went wrong. Please try again." } } }
    },
    "Passwords do not match." : {
      "comment" : "Validation error when passwords don't match in registration",
      "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Passwords do not match." } } }
    }

  },
  "version" : "1.0"
}
```

**Step 2: Verify the file is valid JSON**

```bash
python3 -m json.tool /Volumes/T7/opt/piggy-pulse/piggy-pulse-ios/Localizable.xcstrings > /dev/null && echo "Valid JSON"
```

Expected: `Valid JSON`

---

## Task 3: Register `Localizable.xcstrings` in the Xcode project file

**Files:**
- Modify: `PiggyPulse.xcodeproj/project.pbxproj`

The `.pbxproj` needs three additions: a `PBXFileReference` entry, a `PBXBuildFile` entry, and an addition to the `PBXResourcesBuildPhase`. We also add the file reference to the root `PBXGroup`.

Use these stable UUIDs (they just need to be unique 24-char hex within the file):
- File reference: `02AAAAAA2F5B6D5900E96DF7`
- Build file: `02BBBBBB2F5B6D5900E96DF7`

**Step 1: Add `PBXBuildFile` entry**

In `project.pbxproj`, find the `/* Begin PBXBuildFile section */` block. Add inside it (before the `/* End PBXBuildFile section */` line):

```
		02BBBBBB2F5B6D5900E96DF7 /* Localizable.xcstrings in Resources */ = {isa = PBXBuildFile; fileRef = 02AAAAAA2F5B6D5900E96DF7 /* Localizable.xcstrings */; };
```

**Step 2: Add `PBXFileReference` entry**

In `project.pbxproj`, find the `/* Begin PBXFileReference section */` block. Add inside it (before the `/* End PBXFileReference section */` line):

```
		02AAAAAA2F5B6D5900E96DF7 /* Localizable.xcstrings */ = {isa = PBXFileReference; lastKnownFileType = text.json.xcstrings; path = Localizable.xcstrings; sourceTree = "<group>"; };
```

**Step 3: Add the file reference to the root PBXGroup**

The root group `0208539E2F5898F7004E2FD4` lists the top-level children. Find this block:

```
		0208539E2F5898F7004E2FD4 = {
			isa = PBXGroup;
			children = (
				02F038C62F598D2B008DD1E7 /* Features */,
				02F038BE2F58E9D3008DD1E7 /* PiggyPulse-Info.plist */,
				02F038BC2F58E87A008DD1E7 /* Assets.xcassets */,
```

Add the xcstrings reference to children:

```
		0208539E2F5898F7004E2FD4 = {
			isa = PBXGroup;
			children = (
				02F038C62F598D2B008DD1E7 /* Features */,
				02AAAAAA2F5B6D5900E96DF7 /* Localizable.xcstrings */,
				02F038BE2F58E9D3008DD1E7 /* PiggyPulse-Info.plist */,
				02F038BC2F58E87A008DD1E7 /* Assets.xcassets */,
```

**Step 4: Add the build file to `PBXResourcesBuildPhase`**

Find:

```
		020853A52F5898F7004E2FD4 /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				027B34B12F5B6D5900E96DF6 /* LaunchScreen.storyboard in Resources */,
```

Add the xcstrings build file:

```
		020853A52F5898F7004E2FD4 /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				02BBBBBB2F5B6D5900E96DF7 /* Localizable.xcstrings in Resources */,
				027B34B12F5B6D5900E96DF6 /* LaunchScreen.storyboard in Resources */,
```

**Step 5: Commit**

```bash
cd /Volumes/T7/opt/piggy-pulse/piggy-pulse-ios
git add Localizable.xcstrings PiggyPulse.xcodeproj/project.pbxproj
git commit -m "feat(i18n): add Localizable.xcstrings String Catalog with all English strings"
```

---

## Task 4: Fix helper functions — change `String` params to `LocalizedStringKey`

**Background:** SwiftUI's `Text(someStringVar)` uses the verbatim initializer (no localization). By changing helper function parameters from `String` to `LocalizedStringKey`, string literals at the call sites (e.g., `settingsRow("Name", ...)`) will automatically use the `LocalizedStringKey` initializer and look up the catalog.

**Files:**
- Modify: `Features/Settings/Views/SettingsView.swift`
- Modify: `App/Features/Navigation/MainTabView.swift`
- Modify: `Features/Periods/Views/PeriodDetailView.swift`
- Modify: `Features/Overlays/Views/OverlaysView.swift`
- Modify: `Features/Budget/Views/BudgetPlanView.swift`

**Step 1: `SettingsView` — `settingsRow`**

Change the function signature from:
```swift
private func settingsRow(_ label: String, value: String) -> some View {
```
To:
```swift
private func settingsRow(_ label: LocalizedStringKey, value: String) -> some View {
```

No call-site changes needed — all call sites pass string literals.

**Step 2: `MainTabView` — `moreLink`**

Change the function signature from:
```swift
private func moreLink<Destination: View>(
    _ title: String,
    icon: String,
```
To:
```swift
private func moreLink<Destination: View>(
    _ title: LocalizedStringKey,
    icon: String,
```

Inside the function body, the `Label(title, systemImage: icon)` call already works with `LocalizedStringKey`.

**Step 3: `PeriodDetailView` — `dateColumn` and `metricItem`**

Change:
```swift
private func dateColumn(_ label: String, date: String) -> some View {
```
To:
```swift
private func dateColumn(_ label: LocalizedStringKey, date: String) -> some View {
```

Change:
```swift
private func metricItem(value: String, label: String) -> some View {
```
To:
```swift
private func metricItem(value: String, label: LocalizedStringKey) -> some View {
```

**Step 4: `OverlaysView` — `overlaySection`**

Change:
```swift
private func overlaySection(_ title: String, items: [OverlayItem], badge: Bool) -> some View {
```
To:
```swift
private func overlaySection(_ title: LocalizedStringKey, items: [OverlayItem], badge: Bool) -> some View {
```

Inside this function, make sure `title` is used as `Text(title)` (already `LocalizedStringKey`).

Also change `statusText` — it returns a `String` used inside `Text(statusText(status))`. Change it to return `LocalizedStringKey`:
```swift
private func statusText(_ status: OverlayStatus) -> LocalizedStringKey {
    switch status {
    case .active: return "ACTIVE"
    case .upcoming: return "UPCOMING"
    case .ended: return "ENDED"
    }
}
```

**Step 5: `BudgetPlanView` — `breakdownRow`**

Change:
```swift
private func breakdownRow(_ label: String, value: Int64, color: Color) -> some View {
```
To:
```swift
private func breakdownRow(_ label: LocalizedStringKey, value: Int64, color: Color) -> some View {
```

**Step 6: Commit**

```bash
cd /Volumes/T7/opt/piggy-pulse/piggy-pulse-ios
git add \
  Features/Settings/Views/SettingsView.swift \
  App/Features/Navigation/MainTabView.swift \
  Features/Periods/Views/PeriodDetailView.swift \
  Features/Overlays/Views/OverlaysView.swift \
  Features/Budget/Views/BudgetPlanView.swift
git commit -m "feat(i18n): change helper function String params to LocalizedStringKey"
```

---

## Task 5: Wrap error message string literals with `String(localized:)`

**Background:** Error messages are stored in `@State var errorMessage: String?` (or `@Published var errorMessage: String?`). When displayed via `Text(errorMessage)`, Swift uses the verbatim `String` overload — the catalog is never consulted. Wrapping the assignment in `String(localized:)` ensures the translated string is stored at assignment time.

**Files to modify** (every file with `errorMessage = "..."` string literal assignments):

- `Features/Auth/ViewModels/AuthViewModel.swift`
- `Features/Dashboard/ViewModels/DashboardViewModel.swift`
- `Features/Transactions/ViewModels/TransactionsViewModel.swift`
- `Features/Budget/ViewModels/BudgetViewModel.swift`
- `Features/Periods/ViewModels/PeriodsViewModel.swift`
- `Features/Transactions/Views/AddTransactionSheet.swift`
- `Features/Transactions/Views/EditTransactionSheet.swift`
- `Features/Accounts/Views/AccountsView.swift`
- `Features/Accounts/Views/AddAccountSheet.swift`
- `Features/Accounts/Views/EditAccountSheet.swift`
- `Features/Categories/Views/CategoriesView.swift`
- `Features/Categories/Views/AddCategorySheet.swift`
- `Features/Categories/Views/EditCategorySheet.swift`
- `Features/Vendors/Views/VendorsView.swift`
- `Features/Vendors/Views/AddVendorSheet.swift`
- `Features/Vendors/Views/EditVendorSheet.swift`
- `Features/Settings/Views/SettingsView.swift`
- `Features/Settings/Views/EditProfileSheet.swift`
- `Features/Settings/Views/ChangePasswordSheet.swift`
- `Features/Overlays/Views/OverlaysView.swift`
- `Features/Periods/Views/CreatePeriodSheet.swift`
- `Features/Periods/Views/AutoCreationView.swift`

**Step 1: Apply the pattern**

For every line matching `errorMessage = "some literal string"`, change it to:
```swift
errorMessage = String(localized: "some literal string")
```

Example — `AuthViewModel.swift`:
```swift
// Before:
errorMessage = "Something went wrong. Please try again."
// After:
errorMessage = String(localized: "Something went wrong. Please try again.")
```

Do NOT wrap `errorMessage = nil` or `errorMessage = error.errorDescription` (those are not string literals).

**Step 2: Commit**

```bash
cd /Volumes/T7/opt/piggy-pulse/piggy-pulse-ios
git add \
  Features/Auth/ViewModels/AuthViewModel.swift \
  Features/Dashboard/ViewModels/DashboardViewModel.swift \
  Features/Transactions/ViewModels/TransactionsViewModel.swift \
  Features/Budget/ViewModels/BudgetViewModel.swift \
  Features/Periods/ViewModels/PeriodsViewModel.swift \
  Features/Transactions/Views/AddTransactionSheet.swift \
  Features/Transactions/Views/EditTransactionSheet.swift \
  Features/Accounts/Views/AccountsView.swift \
  Features/Accounts/Views/AddAccountSheet.swift \
  Features/Accounts/Views/EditAccountSheet.swift \
  Features/Categories/Views/CategoriesView.swift \
  Features/Categories/Views/AddCategorySheet.swift \
  Features/Categories/Views/EditCategorySheet.swift \
  Features/Vendors/Views/VendorsView.swift \
  Features/Vendors/Views/AddVendorSheet.swift \
  Features/Vendors/Views/EditVendorSheet.swift \
  Features/Settings/Views/SettingsView.swift \
  Features/Settings/Views/EditProfileSheet.swift \
  Features/Settings/Views/ChangePasswordSheet.swift \
  Features/Overlays/Views/OverlaysView.swift \
  Features/Periods/Views/CreatePeriodSheet.swift \
  Features/Periods/Views/AutoCreationView.swift
git commit -m "feat(i18n): wrap error message string literals with String(localized:)"
```

---

## Task 6: Open PR

**Step 1: Push the branch**

```bash
cd /Volumes/T7/opt/piggy-pulse/piggy-pulse-ios
git push -u origin feat/i18n-string-catalogs
```

**Step 2: Open a draft PR**

```bash
gh pr create \
  --title "feat(i18n): add String Catalog localization support (English)" \
  --body "$(cat <<'EOF'
## Summary

- Adds `Localizable.xcstrings` String Catalog with all user-facing English strings (~100 entries with translator comments)
- Registers the catalog in `project.pbxproj` so Xcode includes it as a resource
- Changes helper function parameters from `String` to `LocalizedStringKey` so SwiftUI resolves them through the catalog
- Wraps `errorMessage = "..."` assignments with `String(localized:)` so stored error strings are localized at assignment time

SwiftUI `Text("literal")` and `.navigationTitle("literal")` are already `LocalizedStringKey` and localize automatically — no changes needed for those.

## Test plan

- [ ] Build succeeds with no warnings about missing strings
- [ ] Open Xcode → `Localizable.xcstrings` appears in the project navigator under the project root
- [ ] All screens display correct English text
- [ ] Adding a new language in Xcode Project settings shows all ~100 strings ready for translation

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)" \
  --draft
```
