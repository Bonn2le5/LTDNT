/// Maps to Venue (Venues) in the checked-in backend.
class BranchModel {
  const BranchModel({
    required this.id,
    required this.name,
    required this.address,
  });
  final int id;
  final String name;
  final String address;
}

/// Mock opening hours and region do not extend the backend database schema.
class BranchPresentation {
  const BranchPresentation({
    required this.region,
    required this.openMinute,
    required this.closeMinute,
  });
  final String region;
  final int openMinute;
  final int closeMinute;
}
