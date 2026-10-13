import '../../core/utils/app_exception.dart';
import '../../models/branch_model.dart';
import '../../models/court_model.dart';
import '../../models/court_type_model.dart';
import '../../repositories/court_repository.dart';

class MockCourtRepository implements CourtRepository {
  const MockCourtRepository({this.delay = const Duration(milliseconds: 350)});
  final Duration delay;
  static const _branches = [
    BranchModel(
      id: 1,
      name: 'Chi nhánh Thủ Đức',
      address: '12 Đường số 7, phường Linh Trung, TP. Hồ Chí Minh',
    ),
    BranchModel(
      id: 2,
      name: 'Chi nhánh Bình Thạnh',
      address: '85 Nguyễn Gia Trí, phường Bình Thạnh, TP. Hồ Chí Minh',
    ),
    BranchModel(
      id: 3,
      name: 'Chi nhánh Tân Phú',
      address: '24 Lê Trọng Tấn, phường Tây Thạnh, TP. Hồ Chí Minh',
    ),
  ];
  static const _hours = {
    1: BranchPresentation(
      region: 'Thủ Đức',
      openMinute: 360,
      closeMinute: 1380,
    ),
    2: BranchPresentation(
      region: 'Bình Thạnh',
      openMinute: 360,
      closeMinute: 1320,
    ),
    3: BranchPresentation(
      region: 'Tân Phú',
      openMinute: 420,
      closeMinute: 1320,
    ),
  };
  static const _courts = [
    CourtModel(
      id: 1,
      branchId: 1,
      name: 'Sân bóng đá Linh Trung',
      type: CourtType.football,
      pricePerHour: 250000,
    ),
    CourtModel(
      id: 2,
      branchId: 2,
      name: 'Sân cầu lông Gia Định',
      type: CourtType.badminton,
      pricePerHour: 80000,
    ),
    CourtModel(
      id: 3,
      branchId: 1,
      name: 'Sân pickleball Bình Minh',
      type: CourtType.pickleball,
      pricePerHour: 150000,
    ),
    CourtModel(
      id: 4,
      branchId: 3,
      name: 'Sân bóng rổ Tây Thạnh',
      type: CourtType.basketball,
      pricePerHour: 120000,
    ),
    CourtModel(
      id: 5,
      branchId: 2,
      name: 'Sân bóng chuyền Thanh Đa',
      type: CourtType.volleyball,
      pricePerHour: 100000,
    ),
    CourtModel(
      id: 6,
      branchId: 3,
      name: 'Sân bóng đá Tân Phú',
      type: CourtType.football,
      pricePerHour: 220000,
    ),
    CourtModel(
      id: 7,
      branchId: 1,
      name: 'Sân cầu lông Ánh Dương',
      type: CourtType.badminton,
      pricePerHour: 70000,
    ),
    CourtModel(
      id: 8,
      branchId: 2,
      name: 'Sân pickleball Sài Gòn',
      type: CourtType.pickleball,
      pricePerHour: 180000,
    ),
    CourtModel(
      id: 9,
      branchId: 1,
      name: 'Sân bóng rổ Đại Học',
      type: CourtType.basketball,
      pricePerHour: 100000,
    ),
    CourtModel(
      id: 10,
      branchId: 3,
      name: 'Sân bóng chuyền Bình An',
      type: CourtType.volleyball,
      pricePerHour: 90000,
    ),
    CourtModel(
      id: 11,
      branchId: 2,
      name: 'Sân bóng đá Gia Định',
      type: CourtType.football,
      pricePerHour: 300000,
    ),
    CourtModel(
      id: 12,
      branchId: 3,
      name: 'Sân cầu lông Hòa Bình',
      type: CourtType.badminton,
      pricePerHour: 85000,
    ),
  ];
  static const _amenities = [
    'Bãi giữ xe',
    'Nước uống',
    'Phòng thay đồ',
    'Đèn chiếu sáng',
  ];

  @override
  Future<List<CourtModel>> getCourts() async {
    await Future<void>.delayed(delay);
    return List.unmodifiable(_courts);
  }

  @override
  CourtModel courtById(int id) => _courts.firstWhere(
    (court) => court.id == id,
    orElse: () => throw const AppException('Không tìm thấy sân.'),
  );
  @override
  BranchModel branchById(int id) => _branches.firstWhere(
    (branch) => branch.id == id,
    orElse: () => throw const AppException('Không tìm thấy chi nhánh.'),
  );
  @override
  BranchPresentation branchPresentation(int id) => _hours[id]!;
  @override
  CourtPresentation courtPresentation(int id) {
    final court = courtById(id);
    return CourtPresentation(
      isActive: id != 12,
      description:
          '${court.name} có mặt sân chất lượng, không gian thoáng và hệ thống chiếu sáng đầy đủ. Phù hợp cho buổi tập cùng bạn bè và các trận đấu giao hữu. Nhân viên tại sân luôn sẵn sàng hỗ trợ bạn.',
      amenities: _amenities,
    );
  }
}
