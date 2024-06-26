import 'package:flutter/material.dart';
import 'package:mrt_wallet/app/core.dart';
import 'package:mrt_wallet/future/pages/wallet_pages/global_pages/token_details.dart';
import 'package:mrt_wallet/future/widgets/custom_widgets.dart';
import 'package:mrt_wallet/models/wallet_models/wallet_models.dart';
import 'package:mrt_wallet/provider/transaction_validator/core/validator.dart';
import 'package:mrt_wallet/provider/transaction_validator/solana/solana.dart';

class SolanaAccountPageView extends StatelessWidget {
  const SolanaAccountPageView({required this.chainAccount, super.key});
  final AppChain chainAccount;
  @override
  Widget build(BuildContext context) {
    return TabBarView(children: [
      const _SolanaServices(),
      _SolanaTokenView(account: chainAccount.account.address as ISolanaAddress),
    ]);
  }
}

class _SolanaTokenView extends StatelessWidget {
  const _SolanaTokenView({required this.account});
  final ISolanaAddress account;

  @override
  Widget build(BuildContext context) {
    final tokens = account.tokens;

    if (tokens.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.token, size: AppGlobalConst.double80),
              WidgetConstant.height8,
              Text("no_tokens_found".tr),
              WidgetConstant.height20,
              FilledButton(
                  onPressed: () {
                    context.to(PagePathConst.importSPLTokens);
                  },
                  child: Text("import_token".tr))
            ],
          ),
        ),
      );
    }
    return SingleChildScrollView(
      child: Column(
        children: [
          AppListTile(
            leading: const Icon(Icons.token),
            onTap: () {
              context.to(PagePathConst.importSPLTokens);
            },
            title: Text("manage_tokens".tr),
            subtitle: Text("add_or_remove_tokens".tr),
          ),
          WidgetConstant.divider,
          ListView.builder(
            physics: WidgetConstant.noScrollPhysics,
            itemBuilder: (context, index) {
              final SolanaSPLToken token = account.tokens[index];
              return ContainerWithBorder(
                onRemove: () {
                  context.openDialogPage<TokenAction>("token_info".tr,
                      child: (ctx) => TokenDetailsModalView(
                            token: token,
                            address: account,
                            transferPath: PagePathConst.solanaTransfer,
                          ));
                },
                onRemoveWidget: WidgetConstant.sizedBox,
                child: Row(
                  children: [
                    CircleTokenImgaeView(token.token, radius: 40),
                    WidgetConstant.width8,
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(token.token.name,
                            style: context.textTheme.labelLarge),
                        Text(token.issuer!, style: context.textTheme.bodySmall),
                        CoinPriceView(
                            liveBalance: token.balance,
                            token: token.token,
                            style: context.textTheme.titleLarge),
                      ],
                    )),
                  ],
                ),
              );
            },
            itemCount: account.tokens.length,
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: false,
            shrinkWrap: true,
          )
        ],
      ),
    );
  }
}

class _SolanaServices extends StatelessWidget {
  const _SolanaServices();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          AppListTile(
            title: Text("associated_token_program".tr),
            subtitle: Text("create_associated_token_account".tr),
            onTap: () {
              final validator = LiveTransactionValidator<
                      SolanaCreateAssociatedTokenAccountValidator>(
                  validator: SolanaCreateAssociatedTokenAccountValidator());
              context.to(PagePathConst.solanaTransaction,
                  argruments: validator);
            },
          ),
          AppListTile(
            title: Text("create_account".tr),
            subtitle: Text("solana_create_account_desc".tr),
            onTap: () {
              final validator =
                  LiveTransactionValidator<SolanaCreateAccountValidator>(
                      validator: SolanaCreateAccountValidator());
              context.to(PagePathConst.solanaTransaction,
                  argruments: validator);
            },
          ),
          AppListTile(
            title: Text("initialize_mint".tr),
            subtitle: Text("initiailize_mint_desc".tr),
            onTap: () {
              final validator =
                  LiveTransactionValidator<SolanaInitializeMintValidator>(
                      validator: SolanaInitializeMintValidator());
              context.to(PagePathConst.solanaTransaction,
                  argruments: validator);
            },
          ),
          AppListTile(
            title: Text("mint_to".tr),
            subtitle: Text("mint_to_desc".tr),
            onTap: () {
              final validator = LiveTransactionValidator<SolanaMintToValidator>(
                  validator: SolanaMintToValidator());
              context.to(PagePathConst.solanaTransaction,
                  argruments: validator);
            },
          ),
        ],
      ),
    );
  }
}
