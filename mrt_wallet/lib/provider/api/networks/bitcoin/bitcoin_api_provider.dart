import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:mrt_wallet/models/api/api_provider_tracker.dart';
import 'package:mrt_wallet/models/wallet_models/wallet_models.dart';
import 'package:mrt_wallet/provider/api/api_provider.dart';

class BitcoinApiProvider implements NetworkApiProvider<IBitcoinAddress> {
  BitcoinApiProvider({required this.provider});
  @override
  ApiProviderTracker get serviceProvider =>
      (provider.service as HttpProvider).provider;
  final ApiProvider provider;

  @override
  Future<void> updateBalance(IBitcoinAddress account) async {
    final utxos = await provider
        .getAccountUtxo(UtxoAddressDetails.watchOnly(account.networkAddress));
    final balance = utxos.sumOfUtxosValue();
    account.address.updateBalance(balance);
  }

  Future<List<UtxoWithAddress>> readUtxos(UtxoAddressDetails address) async {
    final utxos = await provider.getAccountUtxo(address);
    return utxos;
  }
}
