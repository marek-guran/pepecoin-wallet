import 'package:cosmos_sdk/cosmos_sdk.dart';
import 'package:flutter/material.dart';
import 'package:mrt_wallet/app/core.dart';
import 'package:mrt_wallet/app/utility/blockchin_utils/cosmos/cosmos.dart';
import 'package:mrt_wallet/future/widgets/progress_bar/progress.dart';
import 'package:mrt_wallet/models/wallet_models/currency_balance/currency_balance.dart';
import 'transaction.dart';

enum CosmosFeeTypes {
  basic("basic"),
  manually("manually");

  final String val;
  const CosmosFeeTypes(this.val);
  bool get isManually => this == CosmosFeeTypes.manually;
}

mixin CosmosTransactionFeeImpl on CosmosTransactiomImpl {
  late final NoneDecimalBalance _feeAmount =
      NoneDecimalBalance.zero(network.coinParam.decimal);
  late final NoneDecimalBalance _networkFeeRate =
      NoneDecimalBalance.zero(network.coinParam.decimal);

  CosmosFeeTypes _feeType = CosmosFeeTypes.basic;
  CosmosFeeTypes get feeType => _feeType;
  Fee? _fee;
  @override
  Fee? get fee => _fee;
  bool get hasFee => _fee != null;
  NoneDecimalBalance get feeAmount => _feeAmount;

  final GlobalKey<StreamWidgetState> feeProgressKey =
      GlobalKey<StreamWidgetState>(debugLabel: "CosmosTransactionFeeImpl");

  String? _feeError;
  String? get feeError => _feeError;

  final Cancelable _cancelable = Cancelable();

  Future<Fee> _simulateTr() async {
    final messages = validator.validator.messages(address.networkAddress);

    final txbody = TXBody(messages: messages, memo: memo);
    final authInfo = AuthInfo(
        signerInfos: [
          address.signerInfo.copyWith(sequence: ownerAccount.sequence)
        ],
        fee: CosmosUtils.simulateFee(
          denom: network.coinParam.mainCoin.denom,
        ));
    final tx = Tx(
        body: txbody,
        authInfo: authInfo,
        signatures: [List<int>.filled(64, 0)]);
    final simulate = await apiProvider.simulateTransaction(tx.toBuffer());
    if (isThorChain) {
      final BigInt fixedFee =
          BigInt.from(thorNodeNetworkConstants.nativeTransactionFee);
      return CosmosUtils.simulateFee(
          denom: network.coinParam.mainCoin.denom,
          gasLimit: simulate.gasInfo.gasUsed,
          amount: messages.isEmpty
              ? fixedFee
              : BigInt.from(messages.length) * fixedFee);
    }
    return CosmosUtils.calculateFee(
        gasUsed: simulate.gasInfo.gasUsed.toInt(),
        denom: network.coinParam.mainCoin.denom);
  }

  Future<void> simulateTr() async {
    _feeError = null;
    _cancelable.cancel();
    feeProgressKey.process();
    try {
      final result = await MethodCaller.call(() async {
        return await _simulateTr();
      }, cancelable: _cancelable);
      if (result.hasError) {
        if (result.isCancel) return;
        _feeError = result.error;
        notify();
        return;
      }
      _fee = result.result;
      _networkFeeRate.updateBalance(_fee!.amount.first.amount);
      if (_feeType.isManually) return;

      _feeAmount.updateBalance(_fee!.amount.first.amount);
      onCalculateAmount();
    } finally {
      feeProgressKey.idle();
    }
  }

  void setupFee(BigInt? val) {
    if (isThorChain) return;
    if (val == null) {
      if (_feeType.isManually) {
        _feeType = CosmosFeeTypes.basic;
        _feeAmount.updateBalance(_networkFeeRate.balance);
      }
    } else {
      if (val.isNegative) return;
      _feeAmount.updateBalance(val);
      _fee = _fee?.copyWith(amount: [
            Coin(amount: val, denom: network.coinParam.mainCoin.denom)
          ]) ??
          CosmosUtils.simulateFee(
              amount: val, denom: network.coinParam.mainCoin.denom);
      _feeType = CosmosFeeTypes.manually;
    }
    onCalculateAmount();
  }
}
