import 'dart:async';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:mrt_wallet/models/api/api_provider_tracker.dart';
import 'package:mrt_wallet/provider/api/api_provider.dart';
import 'package:xrpl_dart/xrpl_dart.dart';

class RippleHTTPRPCService extends HttpProvider implements RpcService {
  RippleHTTPRPCService(this.url, this.provider,
      {this.defaultTimeOut = const Duration(seconds: 30)});

  @override
  final String url;

  @override
  final ApiProviderTracker provider;
  @override
  final Duration defaultTimeOut;

  /// When the request is successful, an [RPCResponse] with the request id and
  /// the data from the server will be returned. If not, an RPCError will be
  /// thrown. Other errors might be thrown if an IO-Error occurs.
  @override
  Future<Map<String, dynamic>> call(RPCRequestDetails params) async {
    final response = await providerPOST<Map<String, dynamic>>(
        url, StringUtils.fromJson(params.toJsonRpcParams()));
    return response;
  }

  @override
  Future<String> post(String url, String body,
      {Map<String, String>? header}) async {
    final response = await providerGET<String>(url);
    return response;
  }
}
