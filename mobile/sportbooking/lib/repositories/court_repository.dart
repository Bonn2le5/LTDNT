import '../models/branch_model.dart';
import '../models/court_model.dart';

abstract class CourtRepository {
  Future<List<CourtModel>> getCourts();
  CourtModel courtById(int id);
  BranchModel branchById(int id);
  BranchPresentation branchPresentation(int id);
  CourtPresentation courtPresentation(int id);
}
