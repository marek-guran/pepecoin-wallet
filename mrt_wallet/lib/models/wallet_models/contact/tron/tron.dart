import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:mrt_wallet/app/core.dart';
import 'package:mrt_wallet/models/serializable/serializable.dart';
import 'package:mrt_wallet/models/wallet_models/contact/contract_core.dart';
import 'package:mrt_wallet/provider/wallet/constant/constant.dart';
import 'package:on_chain/on_chain.dart';

class TronContact with Equatable implements ContactCore<TronAddress> {
  TronContact._(
      {required this.addressObject, required this.created, required this.name});
  factory TronContact.newContact(
      {required TronAddress address, required String name}) {
    return TronContact._(
        addressObject: address, created: DateTime.now(), name: name);
  }
  factory TronContact.fromCborBytesOrObject(
      {List<int>? bytes, CborObject? obj}) {
    try {
      final CborListValue cbor = CborSerializable.decodeCborTags(
          bytes, obj, WalletModelCborTagsConst.tronContact);
      final String address = cbor.getIndex(0);
      final DateTime created = cbor.getIndex(1);
      final String name = cbor.getIndex(2);
      final TronAddress ethAddress = TronAddress(address);

      return TronContact._(
          addressObject: ethAddress, created: created, name: name);
    } catch (e) {
      throw WalletExceptionConst.invalidContactDetails;
    }
  }

  @override
  final TronAddress addressObject;
  @override
  String get address => addressObject.toAddress();
  @override
  final DateTime created;
  @override
  final String name;

  @override
  CborTagValue toCbor() {
    return CborTagValue(
        CborListValue.fixedLength([address, CborEpochIntValue(created), name]),
        WalletModelCborTagsConst.tronContact);
  }

  @override
  List get variabels => [address, name];

  @override
  final String? type = null;
}
