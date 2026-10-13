enum CourtType {
  football('Bóng đá', 'Football'),
  badminton('Cầu lông', 'Badminton'),
  volleyball('Bóng chuyền', 'Volleyball'),
  basketball('Bóng rổ', 'Basketball'),
  pickleball('Pickleball', 'Pickleball');

  const CourtType(this.label, this.apiValue);
  final String label;
  final String apiValue;
}
