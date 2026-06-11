import '../l10n/app_localizations.dart';
import '../../domain/enums.dart';

String paymentMethodLabel(AppLocalizations l10n, PaymentMethod method) {
  return switch (method) {
    PaymentMethod.cash => l10n.paymentMethodCash,
    PaymentMethod.cheque => l10n.paymentMethodCheque,
    PaymentMethod.wallet => l10n.paymentMethodWallet,
    PaymentMethod.bank => l10n.paymentMethodBank,
  };
}
