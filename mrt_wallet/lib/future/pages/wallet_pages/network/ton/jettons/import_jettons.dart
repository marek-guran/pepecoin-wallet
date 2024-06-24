import 'package:flutter/material.dart';
import 'package:mrt_wallet/app/core.dart';
import 'package:mrt_wallet/future/pages/start_page/home.dart';
import 'package:mrt_wallet/future/pages/wallet_pages/account_pages/account_controller.dart';
import 'package:mrt_wallet/future/widgets/custom_widgets.dart';
import 'package:mrt_wallet/models/wallet_models/address/address.dart';
import 'package:mrt_wallet/models/wallet_models/network/network_models.dart';
import 'package:mrt_wallet/models/wallet_models/token/networks/networks.dart';
import 'package:mrt_wallet/provider/api/api_provider.dart';
import 'package:ton_dart/ton_dart.dart';

class TonImportJettonsView extends StatelessWidget {
  const TonImportJettonsView({super.key});

  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<APPTonNetwork, ITonAddress>(
      title: "import_jettons".tr,
      childBulder: (wallet, account, address, network, onAccountChanged) {
        return _TonImportJettonsView(
          apiProvider: account.provider()!,
          account: address,
          wallet: wallet,
          network: network,
        );
      },
    );
  }
}

class _TonImportJettonsView extends StatefulWidget {
  const _TonImportJettonsView(
      {required this.apiProvider,
      required this.account,
      required this.wallet,
      required this.network});
  final TonApiProvider apiProvider;
  final ITonAddress account;
  final WalletProvider wallet;
  final APPTonNetwork network;
  @override
  State<_TonImportJettonsView> createState() => __TonImportJettonsViewState();
}

class __TonImportJettonsViewState extends State<_TonImportJettonsView>
    with SafeState {
  List<TonJettonToken> get accountTokens => widget.account.tokens.cast();
  final List<TonAccountJettonResponse> tokens = [];

  final GlobalKey<PageProgressState> progressKey =
      GlobalKey<PageProgressState>(debugLabel: "_TonImportJettonsView");

  void fetchTokens() async {
    if (progressKey.isSuccess || progressKey.inProgress) return;
    final result = await MethodCaller.call(() async {
      final jettons = await widget.apiProvider
          .getAccountJettons(widget.account.networkAddress);
      return jettons;
    });
    if (result.hasError) {
      progressKey.errorText(result.error!, backToIdle: false);
    } else {
      for (final i in result.result) {
        final existToken = MethodCaller.nullOnException(() => accountTokens
            .firstWhere((element) => element.minterAddress == i.tokenAddress));
        if (existToken != null) {
          tokens.add(i.copyWith(jettonToken: existToken));
          continue;
        }
        tokens.add(i);
      }
      if (tokens.isNotEmpty) {
        progressKey.success();
      } else {
        progressKey.success(
            backToIdle: false,
            progressWidget: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                WidgetConstant.checkCircleLarge,
                WidgetConstant.height8,
                Text("unable_to_locate_token".tr),
              ],
            ));
      }
    }
  }

  final Set<TonAddress> progress = {};
  Future<void> getContent(TonAccountJettonResponse jetton) async {
    if (progress.contains(jetton.tokenAddress) ||
        (jetton.jettonToken?.verified ?? false)) {
      return;
    }
    progress.add(jetton.tokenAddress);
    final tokenInfo = await MethodCaller.call(() async {
      return await widget.apiProvider.getJettonInfo(jetton);
    });
    final index = tokens.indexOf(jetton);
    if (index < 0) return;
    if (tokenInfo.hasError) {
      tokens[index] = jetton.copyWith(
          jettonToken: TonJettonToken.create(
              balance: jetton.balance,
              token: Token(
                  name: jetton.tokenAddress.toFriendlyAddress(),
                  symbol: jetton.tokenAddress.toFriendlyAddress(),
                  decimal: 0),
              minterAddress: jetton.tokenAddress,
              walletAddress: jetton.jettonWalletAddress,
              verified: false));
    } else {
      tokens[index] = jetton.copyWith(jettonToken: tokenInfo.result);
    }
    setState(() {});
  }

  void retryJettonContent(TonAccountJettonResponse jetton) {
    progress.remove(jetton.tokenAddress);
    final index = tokens.indexOf(jetton);
    if (index < 0) return;
    tokens[index] = TonAccountJettonResponse(
        tokenAddress: jetton.tokenAddress,
        balance: jetton.balance,
        owner: jetton.owner,
        jettonWalletAddress: jetton.jettonWalletAddress);
    getContent(jetton);
    setState(() {});
  }

  Future<void> add(TonJettonToken token) async {
    final result = await widget.wallet.addNewToken(token, widget.account);
    if (result.hasError) throw result.error!;
    return result.result;
  }

  Future<void> removeToken(TonJettonToken token) async {
    final result = await widget.wallet.removeToken(token, widget.account);
    if (result.hasError) throw result.error!;
    return result.result;
  }

  Future<void> onTap(TonJettonToken token, bool exist) async {
    try {
      if (exist) {
        await removeToken(token);
      } else {
        await add(token);
      }
    } finally {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchTokens();
  }

  @override
  Widget build(BuildContext context) {
    return PageProgress(
      key: progressKey,
      initialStatus: PageProgressStatus.progress,
      backToIdle: AppGlobalConst.oneSecoundDuration,
      initialWidget:
          ProgressWithTextView(text: "fetching_account_token_please_wait".tr),
      child: () {
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: ConstraintsBoxView(
                  padding: WidgetConstant.padding20,
                  child: PageTitleSubtitle(
                      title: "import_token_alert".tr,
                      body: Text("import_token_desc".tr))),
            ),
            EmptyItemSliverWidgetView(
              isEmpty: tokens.isEmpty,
              itemBuilder: () => SliverPadding(
                padding: WidgetConstant.paddingHorizontal20,
                sliver: SliverList.builder(
                  itemBuilder: (context, index) {
                    final TonAccountJettonResponse token = tokens[index];
                    final bool exist =
                        widget.account.tokens.contains(token.jettonToken);
                    getContent(token);
                    return Column(
                      children: [
                        APPAnimatedSwitcher(
                            enable: token.jettonToken != null,
                            widgets: {
                              true: (c) => _NonContentJettonView(
                                    token: token,
                                    state: this,
                                    exist: exist,
                                    key: const ValueKey<bool>(true),
                                  ),
                              false: (c) => _NonContentJettonView(
                                    token: token,
                                    state: this,
                                    exist: exist,
                                    key: const ValueKey<bool>(false),
                                  )
                            }),
                        const Divider(),
                      ],
                    );
                  },
                  itemCount: tokens.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NonContentJettonView extends StatelessWidget {
  const _NonContentJettonView(
      {Key? key, required this.token, required this.state, required this.exist})
      : super(key: key);
  final TonAccountJettonResponse token;
  final __TonImportJettonsViewState state;
  final bool exist;
  bool get isVerify => token.jettonToken?.verified ?? false;

  @override
  Widget build(BuildContext context) {
    return ContainerWithBorder(
      onRemove: () {
        if (token.jettonToken == null) return;
        context.openSliverDialog(
            (ctx) => DialogTextView(
                  buttomWidget: AsyncDialogDoubleButtonView(
                    firstButtonPressed: () {
                      return state.onTap(token.jettonToken!, exist);
                    },
                  ),
                  widget: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exist
                          ? "remove_token_from_account".tr
                          : "add_token_to_your_account".tr),
                      if (!exist && !token.jettonToken!.verified) ...[
                        WidgetConstant.height8,
                        ErrorTextContainer(
                          error: "token_decimals_desc".tr,
                          showErrorIcon: false,
                        )
                      ]
                    ],
                  ),
                ),
            exist ? "remove_token".tr : "add_token".tr);
      },
      onRemoveWidget: Column(
        children: [
          token.jettonToken != null
              ? IgnorePointer(
                  child: Checkbox(
                    value: exist,
                    onChanged: (value) {},
                  ),
                )
              : CircularProgressIndicator(
                  backgroundColor: context.colors.onPrimaryContainer),
          WidgetConstant.height8,
          LaunchBrowserIcon(
              url: state.widget.network.coinParam.getAccountExplorer(
                      token.tokenAddress.toFriendlyAddress()) ??
                  "")
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleTokenImgaeView(token.token, radius: 40),
              WidgetConstant.width8,
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isVerify)
                    Text(
                      token.jettonToken!.token.name,
                      style: context.textTheme.bodyLarge,
                      maxLines: 1,
                    ),
                  Text(token.tokenAddress.toFriendlyAddress(),
                      style: isVerify ? null : context.textTheme.labelLarge),
                  CoinPriceView(
                      balance: token.viewBalance,
                      token: token.token,
                      style: context.textTheme.titleLarge),
                ],
              ))
            ],
          ),
          if (token.jettonToken?.verified == false)
            ErrorTextContainer(
              error: "unable_to_retrieve_token_metadata".tr,
              oTapError: () => state.retryJettonContent(token),
              errorIcon: const Icon(Icons.refresh),
            ),
        ],
      ),
    );
  }
}
