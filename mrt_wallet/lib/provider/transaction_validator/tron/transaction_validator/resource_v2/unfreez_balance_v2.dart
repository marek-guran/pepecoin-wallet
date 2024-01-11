import 'package:mrt_wallet/app/core.dart';
import 'package:mrt_wallet/models/wallet_models/account/core/account.dart';
import 'package:mrt_wallet/models/wallet_models/address/address.dart';
import 'package:mrt_wallet/models/wallet_models/currency_balance/currency_balance.dart';
import 'package:mrt_wallet/models/wallet_models/network/custom/tron/tron_account_info.dart';
import 'package:mrt_wallet/provider/transaction_validator/core/validator.dart';
import 'package:mrt_wallet/provider/transaction_validator/tron/transaction_validator/core/tron_field_validator.dart';
import 'package:mrt_wallet/provider/api/networks/tron/tron_api_provider.dart';
import 'package:on_chain/on_chain.dart';

class TronUnFreezBalanceV2Validator extends TronTransactionValidator {
  TronUnFreezBalanceV2Validator({required this.accountInfo});
  @override
  BigInt get callValue => BigInt.zero;

  @override
  final BigInt tokenValue = BigInt.zero;
  final TronAccountInfo? accountInfo;

  late final ValidatorField<NoneDecimalBalance> amount = ValidatorField(
    name: "unfreeze_balance",
    subject: "trx_unstake_amount",
    optional: false,
    id: "unfreeze_balance",
    onChangeValidator: (v) {
      try {
        if (v!.isZero || v.isNegative) return null;
        return v;
      } catch (e) {
        return null;
      }
    },
  );

  late final ValidatorField<ResourceCode> resource = ValidatorField(
    name: "resource",
    subject: "trx_stake_type",
    optional: false,
    id: "resource",
    onChangeValidator: (v) {
      try {
        if (v == ResourceCode.tronPower) return null;
        return v;
      } catch (e) {
        return null;
      }
    },
  );

  @override
  OnChangeValidator? onChanged;

  @override
  List<ValidatorField> get fields => [resource, amount];

  @override
  String get fieldsName => throw UnimplementedError();

  @override
  String get helperUri => throw UnimplementedError();

  @override
  bool get isValid => validateError() == null;

  @override
  late final String name = "tron_unstack_v2";

  @override
  void removeIndex<T>(ValidatorField<List<T>> field, int index) {}

  @override
  void setListValue<T>(ValidatorField<List<T>> field, T? value) {}

  final NoneDecimalBalance stackedBalance =
      NoneDecimalBalance.zero(TronUtils.decimal);

  @override
  void setValue<T>(ValidatorField<T>? field, T? value) {
    if (field == null) return;
    if (field.setValue(value)) {
      if (field == resource) {
        if (resource.hasValue) {
          final findResource = MethodCaller.nullOnException(() => accountInfo!
              .frozenV2
              .firstWhere((element) => element.type == resource.value));
          stackedBalance.updateBalance(findResource?.amount ?? BigInt.zero);
        } else {
          stackedBalance.updateBalance(BigInt.zero);
        }
        amount.setValue(null);
      }
      onChanged?.call();
      _checkEstimate();
    }
  }

  void _checkEstimate() {
    if (isValid) {
      onStimateChanged?.call();
    }
  }

  @override
  String get subject => throw UnimplementedError();

  @override
  String? validateError({ITronAddress? account}) {
    for (final i in fields) {
      if (!i.optional && !i.hasValue) {
        return "field_is_req".tr.replaceOne(i.name.tr);
      }
    }
    return null;
  }

  @override
  late final TransactionContractType type =
      TransactionContractType.unfreezeBalanceV2Contract;

  @override
  TronAddress? get destinationAccount {
    return null;
  }

  @override
  TronBaseContract toContract({required ITronAddress owner}) {
    final validate = validateError(account: owner);
    if (validate != null) {
      throw WalletException(validate);
    }

    return UnfreezeBalanceV2Contract(
        ownerAddress: owner.networkAddress,
        unfreezeBalance: amount.value!.balance,
        resource: resource.value);
  }

  @override
  TronAddress? get smartContractAddress => null;
  @override
  Future<void> init(
      {required TVMApiProvider provider,
      required ITronAddress address,
      required NetworkAccountCore account}) async {}
}
