import 'package:flutter/material.dart';
import 'package:mrt_wallet/app/constant/page_path.dart';
import 'package:mrt_wallet/app/core.dart';
import 'package:mrt_wallet/future/widgets/custom_widgets.dart';
import 'package:mrt_wallet/models/wallet_models/nfts/networks/ripple/ripple_nft_token.dart';
import 'package:mrt_wallet/models/wallet_models/network/network_models.dart';

class RippleNFTokenView extends StatelessWidget {
  const RippleNFTokenView({super.key, required this.nft});
  final RippleNFToken nft;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("serial".tr, style: context.textTheme.labelLarge),
        CopyTextIcon(
          dataToCopy: nft.serial.toString(),
          widget: OneLineTextWidget(nft.serial.toString(),
              style: context.textTheme.bodySmall),
        ),
        WidgetConstant.height8,
        Text("nfts_id".tr, style: context.textTheme.labelLarge),
        CopyTextIcon(
          dataToCopy: nft.nftokenId,
          widget: OneLineTextWidget(nft.nftokenId,
              style: context.textTheme.bodySmall),
        ),
        if (nft.uri != null) ...[
          WidgetConstant.height8,
          Text("uri".tr, style: context.textTheme.labelLarge),
          CopyTextIcon(
              dataToCopy: nft.uri!,
              widget: OneLineTextWidget(nft.uri ?? "",
                  style: context.textTheme.bodySmall)),
        ],
        WidgetConstant.divider,
        AppListTile(
          title: const Text("NFTokenBurn"),
          trailing: const Icon(Icons.open_in_new),
          onTap: () {
            final validator = LiveTransactionValidator<RippeBurnTokenValidator>(
                validator: RippeBurnTokenValidator(offerID: nft.nftokenId));
            context.to(PagePathConst.rippleTransaction, argruments: validator);
          },
        ),
        AppListTile(
          title: const Text("NFTokenCreateOffer"),
          trailing: const Icon(Icons.open_in_new),
          onTap: () {
            final validator =
                LiveTransactionValidator<RippleCreateOfferValidator>(
                    validator:
                        RippleCreateOfferValidator(offerID: nft.nftokenId));
            context.to(PagePathConst.rippleTransaction, argruments: validator);
          },
        ),
        AppListTile(
          title: const Text("NFTokenCancelOffer"),
          trailing: const Icon(Icons.open_in_new),
          onTap: () {
            final validator =
                LiveTransactionValidator<RippleCancelOfferValidator>(
                    validator:
                        RippleCancelOfferValidator(offerID: nft.nftokenId));
            context.to(PagePathConst.rippleTransaction, argruments: validator);
          },
        ),
      ],
    );
  }
}
