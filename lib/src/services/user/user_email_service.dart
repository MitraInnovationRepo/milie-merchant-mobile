
import 'package:http/http.dart' as http;
import 'package:milie_merchant_mobile/src/services/security/oauth2_service.dart';
import 'package:milie_merchant_mobile/src/services/service_locator.dart';
import 'package:milie_merchant_mobile/src/util/constant.dart';

class UserEmailService {
  String backendEndpoint = Constant.backendEndpoint;
  OAuth2Service _oAuth2Service = locator<OAuth2Service>();

  Future<http.Response> resendEmail() async {
    return _oAuth2Service.getClient().post(
      '$backendEndpoint/email-verification/resend',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
  }
}