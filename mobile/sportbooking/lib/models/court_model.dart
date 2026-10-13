import 'court_type_model.dart';

/// branchId maps to Court.VenueId; type maps to Court.SportType.
class CourtModel {
  const CourtModel({
    required this.id,
    required this.branchId,
    required this.name,
    required this.type,
    required this.pricePerHour,
  });
  final int id;
  final int branchId;
  final String name;
  final CourtType type;

  /// Integer VND; future API decimal conversion belongs in a DTO adapter.
  final int pricePerHour;
}

class CourtPresentation {
  const CourtPresentation({
    required this.description,
    required this.amenities,
    this.isActive = true,
  });
  final String description;
  final List<String> amenities;
  final bool isActive;
}
