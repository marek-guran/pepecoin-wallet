import 'package:blockchain_utils/bip/bip/conf/bip_coins.dart';
import 'package:mrt_wallet/models/wallet_models/wallet_models.dart';

class EthereumNewAddressParam implements NewAccountParams {
  const EthereumNewAddressParam(
      {required this.coin, required this.deriveIndex});
  @override
  bool get isMultiSig => false;
  @override
  final CryptoCoins coin;

  @override
  final AddressDerivationIndex deriveIndex;
}
