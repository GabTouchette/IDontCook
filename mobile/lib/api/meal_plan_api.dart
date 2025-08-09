import 'package:i_cant_cook/api/api_helper.dart';

class MealPlanApi {
  final ApiHelper _api = ApiHelper();

  Future<Map<String, dynamic>> generate(Map<String, dynamic> body) async {
    return await _api.postRequest('meal-plans/', body); // placeholder create
  }

  Future<List<dynamic>> list() async {
    final res = await _api.getRequest('meal-plans/');
    return res as List<dynamic>;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    return await _api.postRequest('meal-plans/', body);
  }

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> body) async {
    return await _api.putRequest('meal-plans/$id/', body);
  }

  Future<bool> delete(int id) async {
    return await _api.deleteRequest('meal-plans/$id/');
  }

  Future<Map<String, dynamic>> groceryList(int id) async {
    return await _api.getRequest('meal-plans/$id/grocery_list/');
  }

  Future<Map<String, dynamic>> purchase(int id, List<dynamic> purchased) async {
    return await _api.postRequest('meal-plans/$id/grocery-list/purchase/', {
      'purchased_items': purchased,
    });
  }
}
