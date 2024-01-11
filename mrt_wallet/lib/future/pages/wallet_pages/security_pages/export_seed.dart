import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';
import 'package:flutter/material.dart';
import 'package:mrt_wallet/app/core.dart';
import 'package:mrt_wallet/future/pages/wallet_pages/wallet_pages.dart';
import 'package:mrt_wallet/future/widgets/custom_widgets.dart';

class ExportSeedView extends StatelessWidget {
  const ExportSeedView({super.key});
  @override
  Widget build(BuildContext context) {
    return PasswordCheckerView(
        accsess: WalletAccsessType.seed,
        onAccsess: (p0, p1) {
          return _ExportSeedView(mnemonic: p0, password: p1);
        },
        title: "export_mnemonic".tr,
        subtitle: PageTitleSubtitle(
            title: "export_mnemonic_desc".tr,
            body: Text("export_mnemonic_desc2".tr)));
  }
}

class _ExportSeedView extends StatefulWidget {
  const _ExportSeedView({required this.mnemonic, required this.password});
  final String mnemonic;
  final String password;

  @override
  State<_ExportSeedView> createState() => _ExportSeedViewState();
}

class _ExportSeedViewState extends State<_ExportSeedView>
    with SafeState, SecureState {
  final GlobalKey<FormState> form =
      GlobalKey<FormState>(debugLabel: "ExportSeedView");
  final GlobalKey<PageProgressState> progressKey = GlobalKey();
  late final Mnemonic _mnemonic = Mnemonic.fromString(widget.mnemonic);
  bool _showMnemonic = false;

  void onChangeShowMnemonic() {
    _showMnemonic = !_showMnemonic;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PageProgress(
      key: progressKey,
      backToIdle: AppGlobalConst.oneSecoundDuration,
      child: () => ConstraintsBoxView(
        alignment: Alignment.center,
        padding: WidgetConstant.paddingHorizontal20,
        child: AnimatedSwitcher(
          duration: AppGlobalConst.animationDuraion,
          child: SingleChildScrollView(
            child: Column(
              children: [
                WidgetConstant.height20,
                PageTitleSubtitle(
                    title: "export_mnemonic_desc".tr,
                    body: Text("export_mnemonic_desc2".tr)),
                Column(
                  children: [
                    PageTitleSubtitle(
                        title: "more_security".tr,
                        body: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("mnemonic_security_des1".tr),
                            WidgetConstant.height8,
                            Text("mnemonic_security_des2".tr),
                            WidgetConstant.height8,
                            Text("mnemonic_security_des3".tr),
                          ],
                        )),
                    Stack(
                      children: [
                        AnimatedSwitcher(
                          duration: AppGlobalConst.animationDuraion,
                          child: Container(
                            key: ValueKey<bool>(_showMnemonic),
                            decoration: BoxDecoration(
                              color: context.colors.primaryContainer,
                              borderRadius: WidgetConstant.border8,
                            ),
                            foregroundDecoration: _showMnemonic
                                ? null
                                : BoxDecoration(
                                    color: context.colors.secondary,
                                    borderRadius: WidgetConstant.border8,
                                  ),
                            child: Stack(
                              children: [
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  children: List.generate(
                                      _mnemonic.toList().length,
                                      (index) => Padding(
                                            padding: WidgetConstant.padding5,
                                            child: Stack(
                                              children: [
                                                Chip(
                                                    padding: WidgetConstant
                                                        .padding10,
                                                    label: Text(_mnemonic
                                                        .toList()[index])),
                                                Badge.count(count: index + 1),
                                              ],
                                            ),
                                          )),
                                )
                              ],
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment.center,
                            child: AnimatedSize(
                              duration: AppGlobalConst.animationDuraion,
                              child: _showMnemonic
                                  ? const SizedBox()
                                  : FilledButton.icon(
                                      onPressed: onChangeShowMnemonic,
                                      icon: const Icon(Icons.remove_red_eye),
                                      label: Text("show_mnemonic".tr)),
                            ),
                          ),
                        )
                      ],
                    ),
                    WidgetConstant.height20,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CopyTextIcon(
                            dataToCopy: _mnemonic.toStr(),
                            size: AppGlobalConst.double40),
                        WidgetConstant.width8,
                        IconButton(
                          icon: const Icon(Icons.qr_code,
                              size: AppGlobalConst.double40),
                          onPressed: () {
                            context.openSliverDialog(
                                (ctx) => BarcodeView(
                                    underBarcodeWidget: ErrorTextContainer(
                                        margin:
                                            WidgetConstant.paddingVertical10,
                                        error: "image_store_alert_keys".tr),
                                    secure: true,
                                    title: ContainerWithBorder(
                                        child: CopyTextIcon(
                                            dataToCopy: _mnemonic.toStr(),
                                            widget: ObscureTextView(
                                                _mnemonic.toStr(),
                                                maxLine: 5))),
                                    barcodeData: _mnemonic.toStr()),
                                "share_mnemonic".tr);
                          },
                        ),
                        WidgetConstant.width8,
                        FilledButton.icon(
                            label: Text("create_backup".tr),
                            onPressed: () {
                              context.openSliverDialog(
                                  (ctx) => SecureBackupView(
                                        data: _mnemonic.toStr(),
                                        password: widget.password,
                                        descriptions: [
                                          WidgetConstant.height8,
                                          Text(
                                              "about_web3_defination_desc1".tr),
                                        ],
                                      ),
                                  "backup_mnemonic".tr);
                            },
                            icon: const Icon(Icons.backup))
                      ],
                    ),
                    WidgetConstant.height20,
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
