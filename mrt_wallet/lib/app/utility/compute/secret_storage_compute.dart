import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:mrt_wallet/app/utility/compute/compute.dart';

abstract class SecretStorageCompute {
  static Future<String> encrypt(String credentials, String password,
      {int scryptN = 8192,
      int p = 1,
      SecretWalletEncoding encoding = SecretWalletEncoding.cbor}) {
    String encrypt(SecretWalletEncoding enc) {
      final secureStorage =
          SecretWallet.encode(StringUtils.toBytes(credentials), password);
      return secureStorage.encrypt(encoding: enc);
    }

    return AppCompute.compute(encrypt, encoding);
  }

  static Future<List<int>> decrypt(String backup, String password,
      {int scryptN = 8192,
      int p = 1,
      SecretWalletEncoding encoding = SecretWalletEncoding.cbor}) {
    List<int> encrypt(SecretWalletEncoding enc) {
      final secureStorage =
          SecretWallet.decode(backup, password, encoding: enc);
      return secureStorage.data;
    }

    return AppCompute.compute(encrypt, encoding);
  }
}
