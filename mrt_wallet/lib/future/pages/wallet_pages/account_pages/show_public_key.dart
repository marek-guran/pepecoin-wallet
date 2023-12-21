import 'package:flutter/material.dart';
import 'package:mrt_wallet/app/core.dart';
import 'package:mrt_wallet/future/pages/wallet_pages/wallet_pages.dart';
import 'package:mrt_wallet/future/widgets/custom_widgets.dart';
import 'package:mrt_wallet/models/wallet_models/keys/exported_pubkes.dart';
import 'package:mrt_wallet/models/wallet_models/wallet_models.dart';

class AccountPublicKeyView extends StatelessWidget {
  final CryptoAccountAddress address;
  const AccountPublicKeyView({required this.address, super.key});
  @override
  Widget build(BuildContext context) {
    return _BipAccountPublicKey(bip: address as Bip32AddressCore);
  }
}

class _BipAccountPublicKey extends StatefulWidget {
  const _BipAccountPublicKey({required this.bip});
  final Bip32AddressCore bip;
  @override
  State<_BipAccountPublicKey> createState() => __BipAccountPublicKeyState();
}

class __BipAccountPublicKeyState extends State<_BipAccountPublicKey> {
  ExportedPublicKey? publicKey;

  void initPubKey() {
    publicKey = BlockchainUtils.exportPublicKey(
        widget.bip.publicKey, widget.bip.coin, widget.bip.network);
  }

  @override
  void initState() {
    super.initState();
    initPubKey();
  }

  @override
  Widget build(BuildContext context) {
    if (publicKey == null) {
      return Column(
        children: [
          WidgetConstant.errorIconLarge,
          WidgetConstant.height8,
          Text("cannot_export_public_key".tr)
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageTitleSubtitle(
            title: "export_public_key".tr,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text("export_public_key_desc1".tr)],
            )),
        Text("address_details".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
          child: CopyTextWithBarcode(
              dataToCopy: widget.bip.address.toAddress,
              widget:
                  AddressDetailsView(address: widget.bip, isSelected: false),
              barcodeTitle: "address_sharing".tr),
        ),
        WidgetConstant.height20,
        Text("extended_public_key".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
            child: CopyTextWithBarcode(
          dataToCopy: publicKey!.extendedKey,
          barcodeTitle: "extended_public_key".tr,
          widget: SelectableText(publicKey!.extendedKey),
        )),
        WidgetConstant.height20,
        Text("comperessed_public_key".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
            child: CopyTextWithBarcode(
          barcodeTitle: "comperessed_public_key".tr,
          dataToCopy: publicKey!.comprossed,
          widget: SelectableText(publicKey!.comprossed),
        )),
        if (publicKey!.uncomprossed != null) ...[
          WidgetConstant.height20,
          Text("uncomperessed_public_key".tr,
              style: context.textTheme.titleMedium),
          WidgetConstant.height8,
          ContainerWithBorder(
              child: CopyTextWithBarcode(
            dataToCopy: publicKey!.uncomprossed!,
            barcodeTitle: "uncomperessed_public_key".tr,
            widget: SelectableText(publicKey!.uncomprossed!),
          )),
        ]
      ],
    );
  }
}
