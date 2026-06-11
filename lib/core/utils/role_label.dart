import '../l10n/app_localizations.dart';
import '../../domain/enums.dart';

String roleLabel(AppLocalizations l10n, Role role) => switch (role) {
      Role.owner => l10n.roleOwner,
      Role.sales => l10n.roleSales,
      Role.warehouse => l10n.roleWarehouse,
      Role.customer => l10n.roleCustomer,
    };
