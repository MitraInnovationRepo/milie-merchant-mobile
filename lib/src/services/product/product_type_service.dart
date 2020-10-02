import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:milie_merchant_mobile/src/data/model/product_type.dart';
import 'package:milie_merchant_mobile/src/services/security/oauth2_service.dart';
import 'package:milie_merchant_mobile/src/services/service_locator.dart';
import 'package:milie_merchant_mobile/src/util/constant.dart';

class ProductTypeService {
  OAuth2Service _oAuth2Service = locator<OAuth2Service>();
  String backendEndpoint = Constant.backendEndpoint;

  Future<List<ProductType>> findAllShopProducts() async {
    final http.Response response  = await _oAuth2Service.getClient().get('$backendEndpoint/product-type/mine', headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    });
    List<ProductType> list = [];
    if (response.statusCode == 200) {
      var data = json.decode(utf8.decode(response.bodyBytes));
      var rest = data as List;
      list = rest.map<ProductType>((json) => ProductType.fromJson(json)).toList();
    }
    return list;
  }
}
