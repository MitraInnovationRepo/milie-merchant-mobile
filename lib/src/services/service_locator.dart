import 'package:get_it/get_it.dart';
import 'package:milie_merchant_mobile/src/screens/product/product_type_catalog.dart';
import 'package:milie_merchant_mobile/src/screens/shop/shop_service.dart';
import 'package:milie_merchant_mobile/src/services/analytics/analytics_service.dart';
import 'package:milie_merchant_mobile/src/services/order/order_service.dart';
import 'package:milie_merchant_mobile/src/services/product/product_service.dart';
import 'package:milie_merchant_mobile/src/services/product/product_type_service.dart';
import 'package:milie_merchant_mobile/src/services/user/otp_service.dart';
import 'package:milie_merchant_mobile/src/services/user/user_email_service.dart';
import 'package:milie_merchant_mobile/src/services/user/user_service.dart';
import 'package:milie_merchant_mobile/src/services/util/app_service.dart';

import 'security/oauth2_keycloak_service.dart';
import 'security/oauth2_service.dart';

GetIt locator = GetIt.instance;

setupServiceLocator() {
  locator.registerLazySingleton<OAuth2Service>(() => OAuth2KeycloakService());
  locator.registerLazySingleton<UserService>(() => UserService());
  locator.registerLazySingleton<AppService>(() => AppService());
  locator.registerLazySingleton<OTPService>(() => OTPService());
  locator.registerLazySingleton<UserEmailService>(() => UserEmailService());
  locator.registerLazySingleton<ProductTypeService>(() => ProductTypeService());
  locator.registerLazySingleton<ProductService>(() => ProductService());
  locator.registerLazySingleton<ShopService>(() => ShopService());
  locator.registerLazySingleton<OrderService>(() => OrderService());
  locator.registerLazySingleton<AnalyticsService>(() => AnalyticsService());
}
