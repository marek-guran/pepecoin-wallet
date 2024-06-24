import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_coins.dart';
import 'package:flutter/material.dart';
import 'package:mrt_wallet/app/core.dart';
import 'package:mrt_wallet/future/pages/start_page/home.dart';
import 'package:mrt_wallet/future/pages/wallet_pages/global_pages/address_derivation/setup_address_derivation_mode.dart';
import 'package:mrt_wallet/future/pages/wallet_pages/global_pages/wallet_global_pages.dart';
import 'package:mrt_wallet/future/widgets/custom_widgets.dart';
import 'package:mrt_wallet/main.dart';
import 'package:mrt_wallet/models/wallet_models/wallet_models.dart';
import 'package:mrt_wallet/types/typedef.dart';

class SetupBitcoinAddressView extends StatefulWidget {
  const SetupBitcoinAddressView({super.key});

  @override
  State<SetupBitcoinAddressView> createState() =>
      _SetupBitcoinAddressViewState();
}

class _SetupBitcoinAddressViewState extends State<SetupBitcoinAddressView>
    with SafeState {
  final GlobalKey<PageProgressState> pageProgressKey =
      GlobalKey<PageProgressState>(debugLabel: "SetupBitcoinAddressView");
  late final AppChain chainAccount;
  final GlobalKey visibleGenerateAddress =
      GlobalKey(debugLabel: "_SetupBitcoinAddressViewState_visibleContinue");

  AppBitcoinNetwork get network => chainAccount.network as AppBitcoinNetwork;
  List<CryptoCoins> get coins => network.coins;
  bool inited = false;
  late final List<P2shAddressType> p2shTypes;
  late final List<P2pkhAddressType> p2pkhTypes;
  late final List<BitcoinAddressType> supportAddressTypes;
  late final Map<BitcoinAddressType, String> typesToSelect = {
    P2pkhAddressType.p2pkh: P2pkhAddressType.p2pkh.value,
    if (supportAddressTypes.contains(P2shAddressType.p2pkhInP2sh))
      _defaultP2sh(): "P2SH",
    if (supportAddressTypes.contains(SegwitAddresType.p2wpkh))
      SegwitAddresType.p2wpkh: SegwitAddresType.p2wpkh.value,
    if (supportAddressTypes.contains(SegwitAddresType.p2wsh))
      SegwitAddresType.p2wsh: SegwitAddresType.p2wsh.value,
    if (supportAddressTypes.contains(SegwitAddresType.p2tr))
      SegwitAddresType.p2tr: SegwitAddresType.p2tr.value,
  };

  late final bool isSupportSegwit;
  late final bool isSupportP2tr;

  CryptoCoins findCoin() {
    return network.findCOinFromBitcoinAddressType(selected.first);
  }

  void _setupIAccount() {
    if (inited) return;
    inited = true;
    final model = context.watch<WalletProvider>(StateIdsConst.main);
    chainAccount = model.chain;
    supportAddressTypes =
        network.coinParam.transacationNetwork.supportedAddress;
    p2shTypes = supportAddressTypes.whereType<P2shAddressType>().toList();
    p2pkhTypes = supportAddressTypes.whereType<P2pkhAddressType>().toList();
    p2shType = _defaultP2sh();
    isSupportP2tr = supportAddressTypes.contains(SegwitAddresType.p2tr);
    isSupportSegwit = supportAddressTypes.contains(SegwitAddresType.p2wpkh);
    if (isSupportP2tr) {
      selected = {SegwitAddresType.p2tr};
    } else if (isSupportSegwit) {
      selected = {SegwitAddresType.p2wpkh};
    } else {
      selected = {P2pkhAddressType.p2pkh};
    }
  }

  late Set<BitcoinAddressType> selected;

  P2shAddressType _defaultP2sh() {
    if (p2shTypes.contains(P2shAddressType.p2wpkhInP2sh)) {
      return P2shAddressType.p2wpkhInP2sh;
    }
    return P2shAddressType.p2pkInP2sh;
  }

  void onChangeSelected(Set<BitcoinAddressType> value) {
    selected = value;
    p2shType = _defaultP2sh();
    p2pkhType = P2pkhAddressType.p2pkh;
    setState(() {});
  }

  late P2shAddressType p2shType;
  P2pkhAddressType p2pkhType = P2pkhAddressType.p2pkh;

  void onChageSegwit(P2shAddressType? val) {
    if (!p2shTypes.contains(val)) return;
    p2shType = val ?? p2shType;
    setState(() {});
  }

  void onChangeP2pkh(P2pkhAddressType? val) {
    if (!p2pkhTypes.contains(val)) return;
    p2pkhType = val ?? p2pkhType;
    setState(() {});
  }

  void generateAddress() async {
    final wallet = context.watch<WalletProvider>(StateIdsConst.main);
    final coin = findCoin();
    BitcoinAddressType selectedType;
    if (selected.first == _defaultP2sh()) {
      selectedType = p2shType;
    } else if (selected.first == P2pkhAddressType.p2pkh) {
      selectedType = p2pkhType;
    } else {
      selectedType = selected.first;
    }
    final customKeys = wallet.getCustomKeysForCoin([coin]);

    Bip32AddressIndex? keyIndex = await context
        .openSliverBottomSheet<Bip32AddressIndex>("setup_derivation".tr,
            child: SetupDerivationModeView(
                coin: coin, chainAccout: chainAccount, customKeys: customKeys));

    if (keyIndex == null) return;

    pageProgressKey.progressText("generating_new_addr".tr);
    NewAccountParams newAccount;
    if (network is AppBitcoinCashNetwork) {
      newAccount = BitcoinCashNewAddressParams(
          deriveIndex: keyIndex, bitcoinAddressType: selectedType, coin: coin);
    } else {
      newAccount = BitcoinNewAddressParams(
          deriveIndex: keyIndex, bitcoinAddressType: selectedType, coin: coin);
    }

    final result = await wallet.deriveNewAccount(newAccount);
    if (result.hasError) {
      pageProgressKey.errorText(result.error!.tr);
    } else {
      pageProgressKey.success(
          backToIdle: false,
          progressWidget: SuccessWithButtomView(
            buttomText: "generate_new_address".tr,
            buttomWidget: ContainerWithBorder(
                margin: WidgetConstant.paddingVertical8,
                child: AddressDetailsView(address: result.result)),
            onPressed: () {
              if (mounted) {
                pageProgressKey.backToIdle();
              }
            },
            text: "address_added_success".tr,
          ));
    }
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    _setupIAccount();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("setup_address".tr),
      ),
      body: PageProgress(
        key: pageProgressKey,
        backToIdle: AppGlobalConst.oneSecoundDuration,
        initialStatus: PageProgressStatus.idle,
        child: () => UnfocusableChild(
          child: Center(
            child: CustomScrollView(
              shrinkWrap: true,
              slivers: [
                SliverToBoxAdapter(
                    child: ConstraintsBoxView(
                  padding: WidgetConstant.paddingHorizontal20,
                  child: Column(
                    key: const ValueKey<bool>(true),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PageTitleSubtitle(
                          title: "setup_network_address"
                              .tr
                              .replaceOne(network.coinParam.token.name),
                          body: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("disable_standard_derivation".tr),
                              WidgetConstant.height8,
                              Text("setup_address_derivation_keys_desc".tr),
                              WidgetConstant.height8,
                              Text("please_following_steps_to_generate_address"
                                  .tr),
                            ],
                          )),
                      _DriveFromHdWallet(
                        onVisibleGenerateAddress: visibleGenerateAddress,
                        typesToSelect: typesToSelect,
                        generateAddress: generateAddress,
                        p2shTypes: p2shTypes,
                        p2pkhTypes: p2pkhTypes,
                        onChageSegwit: onChageSegwit,
                        onChangeSelected: onChangeSelected,
                        selected: selected,
                        selectedP2shType: p2shType,
                        onChangeP2pkh: onChangeP2pkh,
                        selectedP2pkhType: p2pkhType,
                      ),
                    ],
                  ),
                ))
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DriveFromHdWallet extends StatelessWidget {
  const _DriveFromHdWallet(
      {required this.selected,
      required this.generateAddress,
      required this.p2shTypes,
      required this.onChageSegwit,
      required this.onChangeSelected,
      required this.selectedP2shType,
      required this.onVisibleGenerateAddress,
      required this.typesToSelect,
      required this.p2pkhTypes,
      required this.onChangeP2pkh,
      required this.selectedP2pkhType});

  final Set<BitcoinAddressType> selected;
  final _OnChangeP2shType onChageSegwit;
  final DynamicVoid generateAddress;
  final VoidSetT<BitcoinAddressType> onChangeSelected;
  final List<P2shAddressType> p2shTypes;
  final List<P2pkhAddressType> p2pkhTypes;
  final P2shAddressType selectedP2shType;
  final P2pkhAddressType selectedP2pkhType;
  final _OnChangeP2pkhTypes onChangeP2pkh;
  final GlobalKey onVisibleGenerateAddress;
  final Map<BitcoinAddressType, String> typesToSelect;

  static String? recomendedTypeDescription(
      Map<BitcoinAddressType, String> typesToSelect) {
    return typesToSelect[SegwitAddresType.p2tr] ??
        typesToSelect[SegwitAddresType.p2wpkh] ??
        typesToSelect[P2shAddressType.p2wpkhInP2sh] ??
        typesToSelect[P2shAddressType.p2pkInP2sh];
  }

  @override
  Widget build(BuildContext context) {
    final String? recomendedDesc = recomendedTypeDescription(typesToSelect);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("choose_bitcoin_address_type".tr,
            style: context.textTheme.titleMedium),
        if (recomendedDesc != null)
          Text("bitcoin_type_recomended".tr.replaceOne(recomendedDesc)),
        WidgetConstant.height8,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppSegmentedButton<BitcoinAddressType>(
                items: typesToSelect,
                onChangeSelected: onChangeSelected,
                selected: selected),
          ],
        ),
        WidgetConstant.height20,
        _AddressTypeOPtion(
          select: selected.first,
          p2shTypes: p2shTypes,
          selectedP2shType: selectedP2shType,
          onChangeP2shSegwit: onChageSegwit,
          p2pkhTypes: p2pkhTypes,
          onChangeP2pkhAddress: onChangeP2pkh,
          selectP2pkhType: selectedP2pkhType,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FixedElevatedButton(
              padding: WidgetConstant.paddingVertical20,
              onPressed: generateAddress,
              key: onVisibleGenerateAddress,
              child: Text("setup_derivation".tr),
            ),
          ],
        )
      ],
    );
  }
}

typedef _OnChangeP2shType = void Function(P2shAddressType?);
typedef _OnChangeP2pkhTypes = void Function(P2pkhAddressType?);

class _AddressTypeOPtion extends StatelessWidget {
  const _AddressTypeOPtion(
      {required this.select,
      required this.p2pkhTypes,
      required this.selectedP2shType,
      required this.onChangeP2shSegwit,
      required this.p2shTypes,
      required this.onChangeP2pkhAddress,
      required this.selectP2pkhType});
  final List<P2shAddressType> p2shTypes;
  final List<P2pkhAddressType> p2pkhTypes;
  final BitcoinAddressType select;
  final P2shAddressType selectedP2shType;
  final P2pkhAddressType selectP2pkhType;
  final _OnChangeP2shType onChangeP2shSegwit;
  final _OnChangeP2pkhTypes onChangeP2pkhAddress;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppGlobalConst.animationDuraion,
      child: Column(
        key: ValueKey<BitcoinAddressType>(select),
        children: [
          if (select.isP2sh)
            Column(
              children: [
                ...List.generate(p2shTypes.length, (index) {
                  return AppRadioListTile(
                      title: Text(p2shTypes[index].value),
                      value: p2shTypes[index],
                      groupValue: selectedP2shType,
                      subtitle: Text(
                          BitcoinUtils.getAddressDetails(p2shTypes[index])),
                      onChanged: onChangeP2shSegwit);
                })
              ],
            ),
          if (select == P2pkhAddressType.p2pkh) ...[
            ...List.generate(
                p2pkhTypes.length,
                (index) => AppRadioListTile<P2pkhAddressType>(
                    title: Text(p2pkhTypes[index].value),
                    value: p2pkhTypes[index],
                    groupValue: selectP2pkhType,
                    subtitle:
                        Text(BitcoinUtils.getAddressDetails(p2pkhTypes[index])),
                    onChanged: onChangeP2pkhAddress))
          ],
          if (select == SegwitAddresType.p2wsh)
            Text(
              "p2wsh_one_of_one_desc".tr,
              textAlign: TextAlign.center,
            )
        ],
      ),
    );
  }
}
