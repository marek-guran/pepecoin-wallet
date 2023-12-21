import 'package:mrt_wallet/models/wallet_models/network/custom/ripple/account_object_signer_list.dart';
import 'package:xrp_dart/xrp_dart.dart';

class XRPRPCSignerAccountObject
    extends XRPLedgerRequest<XRPAccountObjectEntry?> {
  XRPRPCSignerAccountObject({
    required this.account,
    XRPLLedgerIndex? ledgerIndex = XRPLLedgerIndex.validated,
  });
  @override
  String get method => XRPRequestMethod.accountObjects;

  final String account;
  final AccountObjectType type = AccountObjectType.signerList;

  @override
  Map<String, dynamic> toJson() {
    return {
      "account": account,
      "type": type.value,
    };
  }

  @override
  XRPAccountObjectEntry? onResonse(Map<String, dynamic> result) {
    final accountObjects = List.from(result["account_objects"] ?? []);
    if (accountObjects.isEmpty) return null;
    return XRPAccountObjectEntry.fromJson(accountObjects.first);
  }
}
