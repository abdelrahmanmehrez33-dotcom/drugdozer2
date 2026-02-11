import '../entities/drug.dart';

abstract class DrugRepository {
  Future<List<Drug>> getAllDrugs();
  Future<List<Drug>> searchDrugs(String query);
  Future<Drug?> getDrugById(String id);
}
