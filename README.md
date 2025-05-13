KeyVault
KeyVault is a secure Flutter app for managing passwords, credit cards, and rich-text notes. Built with robust security features, it offers biometric authentication, TOTP code generation, encrypted SQLite storage, and a customizable app lock. The intuitive UI supports QR code scanning, rich-text editing, and encrypted backups, making KeyVault a powerful tool for safeguarding sensitive data.
Features

App Lock: Secure the app with a PIN, password, or biometrics, with configurable timeout options.
TOTP Authentication: Scan QR codes to generate time-based one-time passwords (TOTP) with a 30-second refresh cycle.
Password Management: Store login credentials with TOTP secrets, billing details, linked credit cards, and website URLs.
Credit Card Storage: Save card details, including billing addresses and card types, with copy-to-clipboard functionality.
Rich-Text Notes: Create and edit formatted notes using flutter_quill with customizable fonts and colors.
Data Import/Export: Export data to encrypted JSON or import backups using AES-CBC and Argon2id encryption.
Recovery Key: Reset master credentials using an encrypted .keyfile for secure recovery.
Theme Support: Choose from 10 themes, including Solarized Light and Night Owl.
Password Generation: Generate strong passwords with customizable character types and lengths.
Security: Uses flutter_secure_storage, cryptography, and argon2 for secure data handling.

Getting Started
Prerequisites

Flutter SDK (3.0.0+)
Dart SDK
Android Studio or VS Code
Device/emulator with biometric support (optional)

Installation

Clone the repository:git clone https://github.com/tamasdarocz/keyvalut.git
cd keyvalut


Install dependencies:flutter pub get


Run the app:flutter run



Usage

Setup Database: Create a new database with a PIN or password and save the recovery key.
Login: Authenticate using a PIN, password, or biometrics via login_screen.dart.
Manage Credentials: Add or edit login credentials with TOTP secrets, billing details, and linked credit cards using create_logins_form.dart.
Add Credit Cards: Input card details, such as card number, expiry date, CVV, and billing address in card_input_form.dart.
Edit Notes: Create rich-text notes with formatting options using flutter_quill in note_edit_page.dart.
TOTP Codes: Scan QR codes to add TOTP secrets (qr_scanner_screen.dart) and view live codes with a progress indicator (totp_widget.dart).
Import/Export: Export encrypted backups or import JSON files via settings_menu.dart.
Settings: Customize themes, lock settings, or manage databases in settings_menu.dart.
Recovery: Reset credentials using a .keyfile with recovery_key_dialog.dart or reset_credential_dialog.dart.

Project Structure
lib/
├
── data/
│   ├── database_model.dart      # Data models (Logins, CreditCard, Note)
│   ├── database_provider.dart   # State management with Provider
│   ├── database_helper.dart     # SQLite database operations
├── services/
│   ├── auth_service.dart        # Authentication (PIN, password, biometrics)
│   ├── export_services.dart     # Encrypted JSON export
│   ├── import_service.dart      # JSON import
│   ├── lock_service.dart        # App locking logic
│   ├── password_generator.dart  # Password generation
│   ├── password_strength.dart   # Password strength assessment
│   ├── qr_scanner.dart          # QR scanning (possibly deprecated)
│   ├── totp_generator.dart      # TOTP code generation
│   ├── url_service.dart         # URL launching
│   ├── utils.dart               # Utilities (toast, error handling)
├── theme/
│   ├── theme_provider.dart      # Theme management
│   ├── themes.dart              # Theme definitions
├── views/
│   ├── Dialogs/
│   │   ├── recovery_key_dialog.dart      # Recovery key management
│   │   ├── delete_confirmation_dialog.dart  # Database deletion
│   │   ├── rename_database_dialog.dart   # Database renaming
│   │   ├── reset_credential_dialog.dart   # Credential reset
│   ├── Tabs/
│   │   ├── archived_logins_screen.dart    # Archived items
│   │   ├── card_input_form.dart           # Credit card input form
│   │   ├── change_login_screen.dart       # Change master credential
│   │   ├── create_logins_form.dart        # Login credentials form
│   │   ├── deleted_credentials_screen.dart  # Deleted items
│   │   ├── homepage.dart                  # Main app interface
│   │   ├── login_screen.dart              # Database selection and login
│   │   ├── logins_widget_tab.dart         # Logins display tab
│   │   ├── note_edit_page.dart            # Note editing with Quill
│   │   ├── notes_page.dart                # Notes list
│   │   ├── note_view_page.dart            # Note read-only view
│   │   ├── payments_tab.dart              # Credit cards tab
│   │   ├── qr_scanner_screen.dart         # QR code scanning
│   │   ├── setup_login_screen.dart        # New database setup
│   │   ├── settings_menu.dart             # Settings UI
│   ├── Widgets/
│   │   ├── date_picker.dart               # Date picker input
│   │   ├── horizontal_quill_toolbar.dart  # Quill font toolbar
│   │   ├── totp_widget.dart               # TOTP code display
│   │   ├── vertical_quill_toolbar.dart    # Quill color toolbar
│   ├── textforms/
│   │   ├── billing_address_input_form.dart  # Billing address input
│   │   ├── email_input_field.dart           # Email input
│   │   ├── notification_dropdown.dart       # Billing notification dropdown
│   │   ├── period_dropdown.dart             # Billing period dropdown
│   │   ├── phone_number_input_field.dart    # Phone number input
│   │   ├── password_text_field.dart         # Password input with generator
│   │   ├── title_input_field.dart           # Title input
│   │   ├── totp_secret_input_field.dart     # TOTP secret input
│   │   ├── username_input_field.dart        # Username input
│   │   ├── website_input_field.dart         # Website input
├── main.dart                           # App entry point

Dependencies
KeyVault relies on the following packages (see pubspec.yaml for details):

sqflite: SQLite database storage
local_auth: Biometric authentication
permission_handler: Camera access for QR scanning
provider: State management
flutter_secure_storage: Secure key storage
mobile_scanner: QR code scanning
flutter_quill: Rich-text note editing
cryptography & argon2: Encryption and hashing
share_plus & file_saver: File sharing and saving
flutter_slidable & flutter_swipe_action_cell: Swipeable list actions
intl: Date formatting
fluttertoast: Toast notifications
pin_code_fields: PIN input fields

Notes

The totp_widget.dart file handles TOTP code display. Ensure it’s referenced correctly in logins_widget_tab.dart after removing totp_display.dart.
The email_input_field.dart, username_input_field.dart, and title_input_field.dart lack programmatic validation despite being marked as required; consider adding validators for production.
The assets: section in pubspec.yaml is empty; add assets (e.g., images, fonts) if used.
Ensure camera permissions are configured in AndroidManifest.xml (<uses-permission android:name="android.permission.CAMERA"/>) and Info.plist (NSCameraUsageDescription) for permission_handler and mobile_scanner.

Contact
Open an issue on GitHub for support or feedback.
