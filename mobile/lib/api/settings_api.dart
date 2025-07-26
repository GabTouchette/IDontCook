import 'package:i_cant_cook/api/api_helper.dart';

class SettingsApi {
  final ApiHelper _apiHelper = ApiHelper();

  Future<bool> updatePersonalInfo(Map<String, dynamic> data) async {
    final response = await _apiHelper.patchRequest('accounts/settings/', data);
    return response != null;
  }

  Future<Map<String, dynamic>?> getPersonalInfo() async {
    final response = await _apiHelper.getRequest('accounts/settings/');
    return response;
  }
}
