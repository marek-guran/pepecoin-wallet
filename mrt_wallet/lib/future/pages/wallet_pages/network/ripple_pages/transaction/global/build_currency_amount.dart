import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:mrt_wallet/app/constant/network_constant/ripple_const.dart';
import 'package:mrt_wallet/app/core.dart';
import 'package:mrt_wallet/future/pages/wallet_pages/global_pages/receipt_address_view.dart';
import 'package:mrt_wallet/future/pages/wallet_pages/global_pages/select_address.dart';
import 'package:mrt_wallet/future/pages/wallet_pages/global_pages/setup_amount.dart';
import 'package:mrt_wallet/future/widgets/custom_widgets.dart';
import 'package:mrt_wallet/models/wallet_models/wallet_models.dart';
import 'package:xrp_dart/xrp_dart.dart';

class BuildRippleCurrencyAmountView extends StatefulWidget {
  const BuildRippleCurrencyAmountView({
    super.key,
    required this.account,
    required this.scrollController,
    this.acceptZero = false,
    this.supportXRP = true,
    required this.title,
  });
  final NetworkAccountCore account;
  final ScrollController scrollController;
  final bool acceptZero;
  final bool supportXRP;
  final String title;

  @override
  State<BuildRippleCurrencyAmountView> createState() =>
      _BuildRippleCurrencyAmountViewState();
}

class _BuildRippleCurrencyAmountViewState
    extends State<BuildRippleCurrencyAmountView>
    with SingleTickerProviderStateMixin, SafeState {
  late final TabController controller = TabController(length: 2, vsync: this);
  void _listener() {
    _isReady();
  }

  @override
  void initState() {
    super.initState();
    controller.addListener(_listener);
    if (!widget.supportXRP) {
      controller.animateTo(1);
    }
    _isReady();
  }

  @override
  void dispose() {
    controller.removeListener(_listener);
    controller.dispose();
    super.dispose();
  }

  ReceiptAddress? issuer;
  DecimalBalance? value;
  String? currency;
  bool isReady = false;

  void onSelectIssuer(ReceiptAddress? issue) {
    issuer = issue;
    _isReady();
  }

  void setCurrency(String? newCurrency) {
    currency = newCurrency;
    value = null;
    _isReady();
  }

  void setupIssueAmount(BigRational? amount) {
    value = amount == null ? null : DecimalBalance.fromRational(amount);
    _isReady();
  }

  late final NoneDecimalBalance xrpAmount =
      NoneDecimalBalance.zero(widget.account.network.coinParam.decimal);
  void setupXrpAmount(BigInt? amount) {
    xrpAmount.updateBalance(amount ?? BigInt.zero);
    _isReady();
  }

  void _isReady() {
    if (controller.index == 0) {
      if (widget.acceptZero) {
        isReady = !xrpAmount.isNegative;
      } else {
        isReady = (!xrpAmount.isZero && !xrpAmount.isNegative);
      }
    } else {
      bool currencyFiled = currency != null &&
          issuer != null &&
          value != null &&
          !value!.isNegative;
      if (widget.acceptZero) {
        isReady = currencyFiled;
      } else {
        isReady = currencyFiled && (!value!.isZero);
      }
    }
    setState(() {});
  }

  void onSetup() {
    _isReady();
    if (!isReady) return;
    if (controller.index == 0) {
      context.pop(XRPCurrencyAmount(
          amount: CurrencyAmount.xrp(xrpAmount.balance),
          price: xrpAmount,
          token: widget.account.network.coinParam.token));
    } else {
      context.pop(XRPCurrencyAmount(
          amount: CurrencyAmount.issue(IssuedCurrencyAmount(
              value: value!.balance.toDecimal(),
              currency: currency!,
              issuer: issuer!.view)),
          price: value!,
          token: Token(name: currency!, symbol: currency!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: ReadOnlyTabbar(
          isEnabled: widget.supportXRP,
          child: TabBar(controller: controller, tabs: [
            Tab(text: "xrp_amount".tr),
            Tab(text: "token_amount".tr),
          ]),
        ),
      ),
      body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [],
          body: TabBarView(
              physics:
                  widget.supportXRP ? null : WidgetConstant.noScrollPhysics,
              controller: controller,
              children: [
                Padding(
                  padding: WidgetConstant.padding20,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("currency".tr,
                            style: context.textTheme.titleMedium),
                        WidgetConstant.height8,
                        ContainerWithBorder(
                          onRemove: () {},
                          onRemoveIcon: WidgetConstant.sizedBox,
                          child: const Text("XRP"),
                        ),
                        WidgetConstant.height20,
                        Text("trust_set_value".tr,
                            style: context.textTheme.titleMedium),
                        Text("token_value".tr),
                        WidgetConstant.height8,
                        ContainerWithBorder(
                            validate: widget.acceptZero
                                ? !xrpAmount.isNegative
                                : !xrpAmount.isNegative && !xrpAmount.isZero,
                            onRemoveIcon: value != null
                                ? const Icon(Icons.edit)
                                : const Icon(Icons.add),
                            onRemove: () {
                              context
                                  .openSliverBottomSheet<BigInt>(
                                    "xrp_amount".tr,
                                    child: SetupNetworkAmount(
                                      min: BigInt.zero,
                                      network: widget.account.network,
                                      subtitle: const SizedBox(),
                                    ),
                                  )
                                  .then(setupXrpAmount);
                            },
                            child: CoinPriceView(
                              balance: xrpAmount,
                              token: widget.account.network.coinParam.token,
                              style: context.textTheme.titleLarge,
                            )),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FixedElevatedButton(
                              padding: WidgetConstant.paddingVertical20,
                              onPressed: isReady ? onSetup : null,
                              child: Text("setup_currency_amount".tr),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: WidgetConstant.padding20,
                  child: SingleChildScrollView(
                    controller: widget.scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PageTitleSubtitle(
                            title: "token_amount".tr,
                            body: Text("token_amount_desc".tr)),
                        ReceiptAddressView(
                          address: issuer,
                          title: "issuer",
                          subtitle: "token_issuer".tr,
                          onTap: () {
                            context
                                .openSliverBottomSheet<ReceiptAddress>(
                                    "token_amount".tr,
                                    maxExtend: 0.8,
                                    minExtent: 0.7,
                                    initialExtend: 0.7,
                                    child: SelectNetworkAddressView(
                                      account: widget.account,
                                      subtitle: PageTitleSubtitle(
                                          title: "issuer".tr,
                                          body: Text("token_issuer".tr)),
                                    ))
                                .then(onSelectIssuer);
                          },
                        ),
                        WidgetConstant.height20,
                        Text("currency".tr,
                            style: context.textTheme.titleMedium),
                        Text("token_currency".tr),
                        WidgetConstant.height8,
                        ContainerWithBorder(
                          onRemove: () {
                            context
                                .openSliverBottomSheet<String>(
                                  "token_amount".tr,
                                  child: StringWriterView(
                                    defaultValue: currency,
                                    regExp: RippleConst.currencyCodeRegex,
                                    title: PageTitleSubtitle(
                                        title: "currency".tr,
                                        body: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text("token_currency".tr),
                                          ],
                                        )),
                                    buttomText: "setup_input".tr,
                                    label: "currency".tr,
                                  ),
                                )
                                .then(setCurrency);
                          },
                          onRemoveIcon: currency != null
                              ? const Icon(Icons.edit)
                              : const Icon(Icons.add),
                          validate: currency != null,
                          child:
                              Text(currency ?? "tap_to_enter_currency_code".tr),
                        ),
                        WidgetConstant.height20,
                        Text("trust_set_value".tr,
                            style: context.textTheme.titleMedium),
                        Text("token_value".tr),
                        WidgetConstant.height8,
                        ContainerWithBorder(
                            validate: value != null,
                            onRemoveIcon: value != null
                                ? const Icon(Icons.edit)
                                : const Icon(Icons.add),
                            onRemove: () {
                              if (currency == null) {
                                context
                                    .showAlert("plese_enter_currency_first".tr);
                              } else {
                                context
                                    .openSliverBottomSheet<BigRational>(
                                      "token_amount".tr,
                                      child: SetupDecimalTokenAmountView(
                                        token: Token(
                                            name: currency!, symbol: currency!),
                                        subtitle: const SizedBox(),
                                      ),
                                    )
                                    .then(setupIssueAmount);
                              }
                            },
                            child: value == null
                                ? Text("tap_to_input_value".tr)
                                : CoinPriceView(
                                    balance: value,
                                    token: Token(
                                        name: currency ?? "",
                                        symbol: currency ?? ""),
                                    style: context.textTheme.titleLarge,
                                  )),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FixedElevatedButton(
                              padding: WidgetConstant.paddingVertical20,
                              onPressed: isReady ? onSetup : null,
                              child: Text("setup_currency_amount".tr),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                )
              ])),
    );
  }
}

class ReadOnlyTabbar extends StatelessWidget implements PreferredSizeWidget {
  const ReadOnlyTabbar({required this.child, required this.isEnabled, Key? key})
      : super(key: key);
  final bool isEnabled;
  final PreferredSizeWidget child;
  @override
  Size get preferredSize => child.preferredSize;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !isEnabled,
      child: child,
    );
  }
}
