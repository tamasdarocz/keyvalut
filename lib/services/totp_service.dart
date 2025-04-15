import 'package:dart_otp/dart_otp.dart';

class TotpService {
  // Generate a TOTP code based on a secret
  String generateTotpCode(String secret) {
    final totp = TOTP(secret: secret);
    return totp.now();
  }

  // Calculate the remaining seconds until the TOTP code refreshes (30-second interval)
  int getRemainingSeconds() {
    final now = DateTime.now().toUtc();
    return 30 - (now.second % 30);
  }

  // Generate a TOTP URI for QR code (otpauth:// format)
  String generateTotpUri(String secret, String issuer, String accountName) {
    return 'otpauth://totp/$issuer:$accountName?secret=$secret&issuer=$issuer';
  }
}