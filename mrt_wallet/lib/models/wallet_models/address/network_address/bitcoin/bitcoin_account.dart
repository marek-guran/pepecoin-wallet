import 'package:blockchain_utils/bip/bip/conf/bip_coins.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:mrt_wallet/app/core.dart';
import 'package:mrt_wallet/models/serializable/serializable.dart';
import 'package:bitcoin_base/bitcoin_base.dart'
    show BitcoinAddress, BitcoinAddressType;
import 'package:mrt_wallet/models/wallet_models/wallet_models.dart';
import 'package:mrt_wallet/provider/wallet/constant/constant.dart';

class IBitcoinAddress
    with Equatable
    implements Bip32AddressCore<BigInt, BigInt, BitcoinAddress> {
  factory IBitcoinAddress.newAccount(
      {required BitcoinNewAddressParams accountParams,
      required List<int> publicKey,
      required AppNetworkImpl network}) {
    final bitcoinAddress = BlockchainAddressUtils.publicKeyToBitcoinAddress(
        publicKey, accountParams.coin, accountParams.bitcoinAddressType);

    final addressDetauls = NoneDecimalNetworkAddressDetails(
        address: bitcoinAddress.toAddress(network
            .toNetwork<AppBitcoinNetwork>()
            .coinParam
            .transacationNetwork),
        balance: NoneDecimalBalance.zero(network.coinParam.decimal));

    return IBitcoinAddress._(
        coin: accountParams.coin,
        publicKey: publicKey,
        address: addressDetauls,
        keyIndex: accountParams.deriveIndex,
        networkAddress: bitcoinAddress,
        addressType: accountParams.bitcoinAddressType,
        network: network.value);
  }
  factory IBitcoinAddress.fromCbsorHex(AppNetworkImpl network, String hex) {
    return IBitcoinAddress.fromCborBytesOrObject(network,
        bytes: BytesUtils.fromHexString(hex));
  }
  factory IBitcoinAddress.fromCborBytesOrObject(AppNetworkImpl network,
      {List<int>? bytes, CborObject? obj}) {
    final toCborTag = (obj ?? CborObject.fromCbor(bytes!)) as CborTagValue;
    if (bytesEqual(
        toCborTag.tags, WalletModelCborTagsConst.bitcoinMultiSigAccount)) {
      return IBitcoinMultiSigAddress.fromCborBytesOrObject(network,
          obj: toCborTag);
    }
    final CborListValue cbor = CborSerializable.decodeCborTags(
        null, toCborTag, WalletModelCborTagsConst.bitcoinAccoint);
    final CryptoProposal proposal = CryptoProposal.fromName(cbor.getIndex(0));
    final CryptoCoins coin = CryptoCoins.getCoin(cbor.getIndex(1), proposal)!;
    final keyIndex =
        AddressDerivationIndex.fromCborBytesOrObject(obj: cbor.getCborTag(2));
    final List<int> publicKey = cbor.getIndex(3);
    final networkId = cbor.getIndex(6);
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }
    final NoneDecimalNetworkAddressDetails address =
        NoneDecimalNetworkAddressDetails.fromCborBytesOrObject(
            network.coinParam.decimal,
            obj: cbor.getCborTag(4));
    final BitcoinAddressType bitcoinAddressType =
        BitcoinAddressType.fromValue(cbor.getIndex(5));
    final bitcoinAddress = BlockchainAddressUtils.publicKeyToBitcoinAddress(
        publicKey, coin, bitcoinAddressType);
    final String? name = cbor.getIndex(7);
    return IBitcoinAddress._(
        coin: coin,
        publicKey: publicKey,
        address: address,
        keyIndex: keyIndex,
        networkAddress: bitcoinAddress,
        addressType: bitcoinAddressType,
        network: network.value,
        accountName: name);
  }
  IBitcoinAddress._(
      {required this.keyIndex,
      required this.coin,
      required List<int> publicKey,
      required this.networkAddress,
      required this.address,
      required this.addressType,
      required this.network,
      String? accountName})
      : publicKey = List.unmodifiable(publicKey),
        _accountName = accountName;

  @override
  final CryptoCoins coin;
  @override
  final List<int> publicKey;

  @override
  CborTagValue toCbor() {
    return CborTagValue(
        CborListValue.fixedLength([
          coin.proposal.specName,
          coin.coinName,
          keyIndex.toCbor(),
          publicKey,
          address.toCbor(),
          addressType.value,
          network,
          accountName ?? const CborNullValue()
        ]),
        WalletModelCborTagsConst.bitcoinAccoint);
  }

  @override
  final BitcoinAddress networkAddress;
  final BitcoinAddressType addressType;

  @override
  final NetworkAddressDetailsCore<BigInt> address;

  @override
  final AddressDerivationIndex keyIndex;
  @override
  bool get multiSigAccount => false;

  @override
  final int network;

  @override
  List get variabels => [addressType, keyIndex, network];

  @override
  List<String> get signers => [BytesUtils.toHexString(publicKey)];

  @override
  String accountToString() {
    return "${addressType.value}\n${address.toAddress}";
  }

  @override
  String get type => addressType.value;

  @override
  List<TokenCore<BigInt>> get tokens =>
      throw WalletExceptionConst.networkTokenUnsuported;

  @override
  void addToken(TokenCore<BigInt> newToken) {
    throw WalletExceptionConst.networkTokenUnsuported;
  }

  @override
  void removeToken(TokenCore<BigInt> token) {
    throw WalletExceptionConst.networkTokenUnsuported;
  }

  @override
  void addNFT(NFTCore newNft) {
    throw WalletExceptionConst.networkNFTsUnsuported;
  }

  @override
  List<NFTCore> get nfts => throw WalletExceptionConst.networkNFTsUnsuported;

  @override
  void removeNFT(NFTCore nft) {
    throw WalletExceptionConst.networkNFTsUnsuported;
  }

  String? _accountName;
  @override
  String? get accountName => _accountName;

  @override
  void setAccountName(String? name) {
    _accountName = name;
  }

  @override
  String get orginalAddress => address.toAddress;
}

class IBitcoinMultiSigAddress extends IBitcoinAddress
    implements MultiSigCryptoAccountAddress {
  factory IBitcoinMultiSigAddress.newAccount({
    required BitcoinMultiSignatureAddress multiSignatureAddress,
    required AppBitcoinNetwork network,
    required CryptoCoins coin,
    required BitcoinAddressType bitcoinAddressType,
  }) {
    try {
      final toBitcoinAddress = multiSignatureAddress.fromType(
          network: network.coinParam.transacationNetwork,
          addressType: bitcoinAddressType);
      final addressDetauls = NoneDecimalNetworkAddressDetails(
          address:
              toBitcoinAddress.toAddress(network.coinParam.transacationNetwork),
          balance: NoneDecimalBalance.zero(network.coinParam.decimal));

      return IBitcoinMultiSigAddress._(
          coin: coin,
          address: addressDetauls,
          multiSignatureAddress: multiSignatureAddress,
          bitcoinAddress: toBitcoinAddress,
          addressType: bitcoinAddressType,
          network: network.value,
          keyIndex: const MultiSigAddressIndex());
    } catch (e) {
      throw WalletExceptionConst.invalidAccountDetails;
    }
  }
  factory IBitcoinMultiSigAddress.fromCborHex(
      AppNetworkImpl network, String hex) {
    return IBitcoinMultiSigAddress.fromCborBytesOrObject(network,
        bytes: BytesUtils.fromHexString(hex));
  }
  factory IBitcoinMultiSigAddress.fromCborBytesOrObject(AppNetworkImpl network,
      {List<int>? bytes, CborObject? obj}) {
    final CborListValue cbor = CborSerializable.decodeCborTags(
        bytes, obj, WalletModelCborTagsConst.bitcoinMultiSigAccount);
    final CryptoProposal proposal = CryptoProposal.fromName(cbor.getIndex(0));
    final CryptoCoins coin = CryptoCoins.getCoin(cbor.getIndex(1), proposal)!;
    final BitcoinMultiSignatureAddress multiSignatureAddress =
        BitcoinMultiSignatureAddress.fromCborBytesOrObject(
            obj: cbor.getCborTag(2));
    final int networkId = cbor.getIndex(5);
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }
    final NoneDecimalNetworkAddressDetails address =
        NoneDecimalNetworkAddressDetails.fromCborBytesOrObject(
            network.coinParam.decimal,
            obj: cbor.getCborTag(3));
    final BitcoinAddressType bitcoinAddressType =
        BitcoinAddressType.fromValue(cbor.getIndex(4));
    final keyIndex =
        AddressDerivationIndex.fromCborBytesOrObject(obj: cbor.getCborTag(6));
    final String? name = cbor.getIndex(7);

    return IBitcoinMultiSigAddress._(
        coin: coin,
        address: address,
        bitcoinAddress: multiSignatureAddress.fromType(
            network: network
                .toNetwork<AppBitcoinNetwork>()
                .coinParam
                .transacationNetwork,
            addressType: bitcoinAddressType),
        addressType: bitcoinAddressType,
        multiSignatureAddress: multiSignatureAddress,
        network: network.value,
        keyIndex: keyIndex,
        accountName: name);
  }
  IBitcoinMultiSigAddress._(
      {required CryptoCoins coin,
      required BitcoinAddress bitcoinAddress,
      required NetworkAddressDetailsCore<BigInt> address,
      required BitcoinAddressType addressType,
      required this.multiSignatureAddress,
      required super.network,
      required super.keyIndex,
      String? accountName})
      : super._(
            coin: coin,
            publicKey: const [],
            networkAddress: bitcoinAddress,
            address: address,
            addressType: addressType,
            accountName: accountName);

  @override
  List<int> get publicKey => throw UnimplementedError();

  final BitcoinMultiSignatureAddress multiSignatureAddress;

  @override
  CborTagValue toCbor() {
    return CborTagValue(
        CborListValue.fixedLength([
          coin.proposal.specName,
          coin.coinName,
          multiSignatureAddress.toCbor(),
          address.toCbor(),
          addressType.value,
          network,
          keyIndex.toCbor(),
          accountName ?? const CborNullValue()
        ]),
        WalletModelCborTagsConst.bitcoinMultiSigAccount);
  }

  @override
  bool get multiSigAccount => true;
  @override
  List get variabels => [
        addressType,
        keyIndex,
        network,
        multiSignatureAddress.multiSigScript.toHex()
      ];

  @override
  List<String> get signers =>
      multiSignatureAddress.signers.map((e) => e.publicKey).toList();

  @override
  List<(String, AddressDerivationIndex)> get keyDetails =>
      multiSignatureAddress.signers
          .map((e) => (e.publicKey, e.keyIndex))
          .toList();
}
