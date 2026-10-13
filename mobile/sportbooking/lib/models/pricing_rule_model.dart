import 'court_type_model.dart';

class PricingRuleModel {
  const PricingRuleModel({
    required this.id,
    required this.startMinute,
    required this.endMinute,
    required this.surchargePercent,
    this.type,
    this.weekendOnly = false,
  });
  final int id;
  final int startMinute;
  final int endMinute;
  final int surchargePercent;
  final CourtType? type;
  final bool weekendOnly;
}
