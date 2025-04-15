
import 'package:get_it/get_it.dart';
import '../data/datasources/user_api_service.dart';
import '../view_model/user_view_model.dart';

final sl = GetIt.instance;

void setupLocator() {
  sl.registerLazySingleton<UserApiService>(() => UserApiService());
  sl.registerFactory(() => UserViewModel(userApiService: sl()));
}
