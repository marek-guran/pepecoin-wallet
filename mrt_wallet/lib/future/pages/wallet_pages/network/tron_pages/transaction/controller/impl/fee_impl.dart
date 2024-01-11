import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:mrt_wallet/app/core.dart';
import 'package:mrt_wallet/future/pages/wallet_pages/network/tron_pages/transaction/controller/impl/transaction.dart';
import 'package:mrt_wallet/models/wallet_models/wallet_models.dart';
import 'package:on_chain/on_chain.dart';

typedef OnTronFeeLimit = Future<BigInt?> Function();
mixin TronTransactionFeeIMpl on TronTransactionImpl {
  TronFee? _consumedFee;
  @override
  TronFee? get consumedFee => _consumedFee;
  NoneDecimalBalance? _customFeeLimit;
  NoneDecimalBalance? get feeLimit => _consumedFee?.feeLimit;
  NoneDecimalBalance? get totalBurn => _consumedFee?.totalBurn;
  // ignore: unused_field
  String? _feeCalculationError;

  String? get feeCalculationError => _feeCalculationError;
  void setCustomFeeLimit(OnTronFeeLimit onTronFeeLimit) async {
    final feeLimit = await onTronFeeLimit();
    if (feeLimit != null) {
      _customFeeLimit = NoneDecimalBalance(feeLimit, network.coinParam.decimal);
      _consumedFee =
          _consumedFee!.setCustomFeeLimit(customFeeLimit: _customFeeLimit);
      calculateFee();
    }
    onFeeChanged();
  }

  TransactionRaw _buildFeeTr(int? permissiondID) {
    final contract = field.toContract(owner: owner);
    final transactionContract = TransactionContract(
        type: contract.contractType,
        permissionId: permissiondID,
        parameter: Any(typeUrl: contract.typeURL, value: contract));
    final BigInt epochNow = BigInt.from(DateTime.now().millisecondsSinceEpoch);
    return TransactionRaw(
        refBlockBytes: List<int>.filled(2, 0),
        refBlockHash: List<int>.filled(8, 0),
        expiration: epochNow,
        contract: [transactionContract],
        feeLimit: field.type == TransactionContractType.triggerSmartContract
            ? (_consumedFee?.feeLimit.balance ?? TronUtils.maxTronFeeLimit)
            : null,
        data: StringUtils.tryToBytes(memo),
        timestamp: epochNow);
  }

  void onFeeChanged();

  final Map<String, TronAccountInfo?> _trackActivatedDestionation = {};

  Future<TronFee> _calcuateFee() async {
    int signer = 1;
    int energy = 0;
    int? permissionId;
    bool isNewAccount = false;
    final dstAccount = field.destinationAccount;
    if (dstAccount != null) {
      if (!_trackActivatedDestionation.containsKey(dstAccount.toAddress())) {
        _trackActivatedDestionation[dstAccount.toAddress()] =
            await apiProvider.getAccount(dstAccount);
      }
      isNewAccount =
          _trackActivatedDestionation[dstAccount.toAddress()] == null;
    }
    if (address.multiSigAccount) {
      final multiSigAccount = address as ITronMultisigAddress;
      permissionId = multiSigAccount.multiSignatureAccount.permissionID;
      signer = multiSigAccount.signers.length;
    }
    final smartContractAddr = field.smartContractAddress;
    final raw = _buildFeeTr(permissionId);
    if (smartContractAddr != null) {
      final contract =
          raw.contract.first.parameter.value as TriggerSmartContract;
      energy = await apiProvider.estimateContractEnergy(
          account: address,
          contractAddress: smartContractAddr,
          data: BytesUtils.toHexString(contract.data!));
    }
    final fee = TronFee.calculate(
        raw: raw,
        chainParameters: tronChainParameters,
        resource: owner.accountResource!,
        hasMemo: memo != null,
        signature: signer,
        consumedEnergy: energy,
        isNewAccount: isNewAccount);

    return fee;
  }

  final Canclable _feeCanclable = Canclable();
  bool _loadingFee = false;
  bool get loadingFee => _loadingFee;

  Future<void> calculateFee() async {
    _feeCanclable.cancel();
    _consumedFee = null;
    _loadingFee = true;
    _feeCalculationError = null;
    onFeeChanged();
    final result = await MethodCaller.call(() async {
      final fee = await _calcuateFee();
      return fee;
    }, canclable: _feeCanclable);
    if (!result.hasError) {
      _consumedFee = result.result;
      _consumedFee =
          _consumedFee?.setCustomFeeLimit(customFeeLimit: _customFeeLimit);
    }
    if (!result.isCancel) {
      _loadingFee = false;
      if (result.hasError) {
        _feeCalculationError = result.error;
      }
    }
    onFeeChanged();
  }
}
