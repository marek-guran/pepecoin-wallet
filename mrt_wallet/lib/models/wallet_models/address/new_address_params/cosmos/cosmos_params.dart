import 'package:blockchain_utils/bip/bip/conf/bip_coins.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cosmos_sdk/cosmos_sdk.dart';
import 'package:mrt_wallet/models/wallet_models/address/core/bip/bip32_address_core.dart';
import 'package:mrt_wallet/models/wallet_models/address/core/derivation/address_derivation.dart';
import 'package:mrt_wallet/models/wallet_models/address/network_address/cosmos/cosmos.dart';
import 'package:mrt_wallet/models/wallet_models/address/new_address_params/new_address_params.dart';
import 'package:mrt_wallet/models/wallet_models/network/core/network.dart';

class CosmosNewAddressParams
    implements NewAccountParams<CosmosNewAddressParams> {
  @override
  bool get isMultiSig => false;
  @override
  final CryptoCoins coin;

  @override
  final AddressDerivationIndex deriveIndex;

  const CosmosNewAddressParams({
    required this.deriveIndex,
    required this.coin,
  });

  CosmosBaseAddress toAddress(
      {required List<int> publicKey, required String hrp}) {
    if (deriveIndex.currencyCoin.conf.type == EllipticCurveTypes.nist256p1) {
      return CosmosBaseAddress.fromBytes(
          CosmosAddrUtils.secp256r1PubKeyToAddress(publicKey),
          hrp: hrp);
    }
    return CosmosBaseAddress.fromBytes(
        CosmosAddrUtils.secp256k1PubKeyToAddress(publicKey),
        hrp: hrp);
  }

  @override
  Bip32AddressCore toAccount(AppNetworkImpl network, List<int> publicKey) {
    return ICosmosAddress.newAccount(
        accountParams: this,
        publicKey: publicKey,
        network: network as APPCosmosNetwork);
  }
}
