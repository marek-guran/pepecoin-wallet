import 'package:mrt_wallet/models/app/app_image.dart';
import 'package:mrt_wallet/models/serializable/serializable.dart';
import 'package:mrt_wallet/models/wallet_models/network/network_models.dart';
import 'package:mrt_wallet/provider/api/api_provider.dart';

abstract class NetworkCoinParams with CborSerializable {
  abstract final int decimal;
  abstract final String? transactionExplorer;
  abstract final String? addressExplorer;
  abstract final AppImage? logo;
  abstract final Token token;
  abstract final List<ApiProviderService> providers;
  abstract final bool mainnet;
  String? getAccountExplorer(String address);
  String? getTransactionExplorer(String txId);
}
