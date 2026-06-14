import 'package:flutter/material.dart';

/// Stable keys for integration / e2e widget finders.
abstract final class IntegrationKeys {
  static const dashboardAddProduct = Key('dashboard_add_product');
  static const dashboardNewBill = Key('dashboard_new_bill');
  static const billFormCancel = Key('bill_form_cancel');
  static const billFormSaveDraft = Key('bill_form_save_draft');
  static const billFormAddProduct = Key('bill_form_add_product');
  static const sidebarCreateBill = Key('sidebar_create_bill');

  static Key sidebarNav(String path) =>
      Key('nav${path.replaceAll('/', '_')}');
}
