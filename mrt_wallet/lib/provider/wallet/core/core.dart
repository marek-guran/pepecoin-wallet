part of 'package:mrt_wallet/provider/wallet/wallet_provider.dart';

abstract class _WalletCore extends StateController
    with
        NativeSecureStorageImpl,
        WalletStorageImpl,
        WalletCryptoImpl,
        MasterKeyImpl,
        WalletNetworkImpl,
        Signer {}

abstract class WalletCore extends _WalletCore with WalletStatusImpl {
  WalletCore(this._navigatorKey);

  final GlobalKey<NavigatorState> _navigatorKey;

  final _lock = SynchronizedLock();

  Future<MethodResult<void>> setup(
      WalletMasterKeys mnemonic, String password) async {
    try {
      final result = await _callSynchronized(
          () async => await _setup(mnemonic, password),
          conditionStatus: WalletStatus.setup,
          onSuccessStatus: WalletStatus.lock);

      return result;
    } finally {
      notify();
    }
  }

  Future<MethodResult<void>> setupBackup(
      WalletBackupCore backup, String password) async {
    try {
      final result = await _callSynchronized(
          () async => await _setupBackup(backup, password),
          conditionStatus: WalletStatus.setup,
          onSuccessStatus: WalletStatus.lock);

      return result;
    } finally {
      notify();
    }
  }

  Future<MethodResult<void>> login(String password) async {
    try {
      final result = await _callSynchronized(() async => await _login(password),
          conditionStatus: WalletStatus.lock,
          onSuccessStatus: WalletStatus.unlock);

      return result;
    } finally {
      notify();
      if (walletIsUnlock) {
        updateBalance();
        _accountBalanceStream();
      }
    }
  }

  Future<MethodResult<void>> changePassword(
      String password, String newPassword) async {
    try {
      final result = await _callSynchronized(
          () async => await _changePassword(password, newPassword),
          conditionStatus: WalletStatus.unlock,
          onSuccessStatus: WalletStatus.lock);
      return result;
    } finally {
      notify();
    }
  }

  Future<MethodResult<void>> updateWlletSetting(
      String password, WalletSetting setting) async {
    try {
      final result = await _callSynchronized(
          () async => await _updateSetting(password, setting),
          conditionStatus: WalletStatus.unlock);
      return result;
    } finally {
      notify();
    }
  }

  Future<MethodResult<CryptoAccountAddress>> deriveNewAccount(
      NewAccountParams newAccountParams) async {
    try {
      final result = await _callSynchronized(
          () async => await _deriveNewAccount(newAccountParams),
          conditionStatus: WalletStatus.unlock);

      return result;
    } finally {
      notify();
      if (walletIsUnlock) {
        updateBalance();
      }
    }
  }

  Future<MethodResult<void>> importAccount(
      WalletCustomKeys newAccountParams, String password) async {
    try {
      final result = await _callSynchronized(
          () async => await _importNewKey(newAccountParams, password),
          conditionStatus: WalletStatus.unlock);
      return result;
    } finally {
      notify();
    }
  }

  Future<MethodResult<void>> addNewContact(ContactCore newContact) async {
    final result = await _callSynchronized(
        () async => await _addNewContact(newContact),
        conditionStatus: WalletStatus.unlock);
    return result;
  }

  Future<MethodResult<void>> addNewToken(
      TokenCore token, CryptoAccountAddress address) async {
    try {
      final result = await _callSynchronized(
          () async => await _addNewToken(token, address),
          conditionStatus: WalletStatus.unlock);
      return result;
    } finally {
      notify();
    }
  }

  Future<MethodResult<void>> removeToken(
      TokenCore token, CryptoAccountAddress address) async {
    try {
      final result = await _callSynchronized(
          () async => await _removeToken(token, address),
          conditionStatus: WalletStatus.unlock);
      return result;
    } finally {
      notify();
    }
  }

  Future<MethodResult<void>> updateToken({
    required TokenCore<dynamic> token,
    required Token updatedToken,
    required CryptoAccountAddress<dynamic, dynamic, dynamic> address,
  }) async {
    try {
      final result = await _callSynchronized(
          () async => await _updateToken(
              token: token, address: address, updatedToken: updatedToken),
          conditionStatus: WalletStatus.unlock);
      return result;
    } finally {
      notify();
    }
  }

  Future<MethodResult<void>> addNewNFT(
      NFTCore nft, CryptoAccountAddress address) async {
    try {
      final result = await _callSynchronized(
          () async => await _addNewNFT(nft, address),
          conditionStatus: WalletStatus.unlock);
      return result;
    } finally {
      notify();
    }
  }

  Future<MethodResult<void>> removeNFT(
      NFTCore nft, CryptoAccountAddress address) async {
    try {
      final result = await _callSynchronized(
          () async => await _removeNFT(nft, address),
          conditionStatus: WalletStatus.unlock);
      return result;
    } finally {
      notify();
    }
  }

  Future<MethodResult<void>> setupAccountName(
      String? name, CryptoAccountAddress address) async {
    try {
      final result = await _callSynchronized(() async {
        if (name == null || !AppGlobalConst.accountNameRegExp.hasMatch(name)) {
          return;
        }
        await _setAccountName(name.trim().isEmpty ? null : name, address);
      }, conditionStatus: WalletStatus.unlock);
      return result;
    } finally {
      notify();
    }
  }

  Future<MethodResult<List<EncryptedCustomKey>>> getImportedAccounts(
      String password) {
    final result = _callSynchronized(() async {
      _validatePassword(password);
      return List<EncryptedCustomKey>.from(_massterKey!.customKeys);
    }, conditionStatus: WalletStatus.unlock);
    return result;
  }

  Future<MethodResult<void>> removeImportedKey(
      EncryptedCustomKey key, String password) {
    try {
      final result = _callSynchronized(() async {
        return await _removeKey(key, password);
      }, conditionStatus: WalletStatus.unlock);
      return result;
    } finally {
      notify();
    }
  }

  Future<MethodResult<void>> removeAccount(CryptoAccountAddress account) async {
    try {
      final result = await _callSynchronized(
          () async => await _removeAccount(account),
          conditionStatus: WalletStatus.unlock);

      return result;
    } finally {
      notify();
    }
  }

  Future<void> switchNetwork(int? networkId) async {
    if (networkId == null || network.value == networkId) return;
    pageStatusHandler.progressText("switching_network".tr);
    await _callSynchronized(() async => await _switchNetwork(networkId),
        conditionStatus: WalletStatus.unlock);
    _backToHome();
    pageStatusHandler.success();
    updateAccountBalance();
    notify();
  }

  Future<void> changeProvider(ApiProviderService? provider) async {
    if (provider == null) return;
    await _callSynchronized(() async => _changeNetworkApiProvider(provider),
        conditionStatus: WalletStatus.unlock, delay: null);
    notify();
  }

  Future<MethodResult<List<AccessPubliKeyResponse>>> getAccountPubKys(
      {required CryptoAccountAddress account}) async {
    final result = await _callSynchronized(
        () async => _getAccountPubKys(account: account),
        conditionStatus: WalletStatus.unlock);
    return result;
  }

  Future<MethodResult<List<AccessKeyResponse>>> accsess(
      WalletAccsessType accsessType, String password,
      {CryptoAccountAddress? account, String? accountId}) async {
    final result = await _callSynchronized(
        () async => await _accsess(accsessType, password,
            account: account, accountId: accountId),
        conditionStatus: WalletStatus.unlock);
    return result;
  }

  Future<MethodResult<String>?> generateBackup(
      String data, String password, SecretWalletEncoding encoding) async {
    final result = await _callSynchronized(
        () async => await _generateBackup(data, password, encoding),
        conditionStatus: WalletStatus.unlock);
    return result;
  }

  Future<void> updateImportNetwork(AppNetworkImpl network) async {
    try {
      final result = await _callSynchronized(
          () async => await _updateImportNetwork(network),
          conditionStatus: WalletStatus.unlock);
      if (result.hasError) {
        throw result.exception!;
      }
      return result.result;
    } finally {
      notify();
    }
  }

  Future<MethodResult<String>?> generateWalletBackup(
      String password, SecretWalletEncoding encoding) async {
    final result = await _callSynchronized(() async {
      return await _getWalletBackupV2(password, encoding: encoding);
    }, conditionStatus: WalletStatus.unlock);
    return result;
  }

  Future<MethodResult<void>> switchAccount(
      CryptoAccountAddress? account) async {
    if (account == null ||
        !chain.haveAddress ||
        account == chain.account.address) {
      return MethodResult.succsess(null);
    }
    pageStatusHandler.progressText("switching_account".tr);
    final result = await _callSynchronized(() async => _switchAccount(account),
        conditionStatus: WalletStatus.unlock);
    pageStatusHandler.success();
    return result;
  }

  Future<MethodResult<void>> eraseWallet(String password) async {
    try {
      final result = await _callSynchronized(() async => _eraseWallet(password),
          conditionStatus: WalletStatus.unlock,
          onSuccessStatus: WalletStatus.setup);
      return result;
    } finally {
      _backToHome();
      notify();
    }
  }

  void lock() async {
    try {
      await _callSynchronized(() async {
        _logout();
      },
          conditionStatus: WalletStatus.unlock,
          onSuccessStatus: WalletStatus.lock,
          delay: null);
    } finally {
      _backToHome();
      _logout();
      notify();
      _disposeBalanceUpdater();
    }
  }

  Future<String> _getPassword(SigningRequest request) async {
    bool inRetry = false;

    final pw =
        await _navigatorKey.currentContext?.openSliverBottomSheet<String>(
      "sign_transaction".tr,
      child: WalletSigningPassword(
        onPasswordValidator: (p0) async {
          try {
            if (inRetry) {
              throw WalletExceptionConst.toManyRequests;
            }
            inRetry = true;
            await Future.delayed(AppGlobalConst.oneSecoundDuration);
            _validatePassword(p0);
            return true;
          } finally {
            inRetry = false;
          }
        },
        request: request,
      ),
    );
    if (pw == null) {
      throw WalletExceptionConst.rejectSigning;
    }
    return pw;
  }

  Future<MethodResult<T>> signTransaction<T>(
      {required SigningRequest<T> request}) async {
    final result = await _callSynchronized(() async {
      final password = await _getPassword(request);
      return _sign(request: request, password: _validatePassword(password));
    }, conditionStatus: WalletStatus.unlock);
    return result;
  }

  @override
  Future<void> _initWallet() async {
    await _lock.synchronized(() async => await super._initWallet());
    pageStatusHandler.success();
    notify();
  }

  Future<MethodResult<T>> _callSynchronized<T>(Future<T> Function() t,
      {required WalletStatus conditionStatus,
      WalletStatus? onSuccessStatus,
      Duration? delay = AppGlobalConst.oneSecoundDuration}) async {
    return await _lock.synchronized(() async {
      final result = await MethodCaller.call(() async {
        if (_status != conditionStatus || inProgress) {
          throw WalletExceptionConst.incorrectStatus;
        }
        _inProgress = true;
        return await t();
      }, delay: delay);
      if (result.hasResult) {
        _status = onSuccessStatus ?? conditionStatus;
      }
      _inProgress = false;
      return result;
    });
  }

  Future<void> updateBalance() async {
    await MethodCaller.call(() async {
      await _updateAccountBalance(chain);
    });
  }

  Future<void> updateAccountBalance() async {
    await MethodCaller.call(() async {
      await _updateAccountsBalance(chain);
    });
  }

  List<EncryptedCustomKey> getCustomKeysForCoin(List<CryptoCoins> coin) {
    if (walletIsUnlock) {
      final curves = coin.map((e) => e.conf.type).toList();
      return List<EncryptedCustomKey>.unmodifiable(
        _massterKey!.customKeys.where((element) {
          return coin.contains(element.coin) ||
              (element.keyType.isPrivateKey &&
                  curves.contains(element.coin.conf.type));
        }),
      );
    }
    return [];
  }

  void _backToHome() {
    _navigatorKey.currentContext?.popToHome();
  }

  void _onTimer() {
    try {
      _status = WalletStatus.lock;
      _backToHome();
    } finally {
      notify();
    }
  }

  late final LifeCycleTracker _lifeCycleTracker = LifeCycleTracker(
    _onTimer,
    () {
      if (walletIsUnlock) return _massterKey?.setting.lockTime;
      return null;
    },
  );

  @override
  void init() {
    _initWallet();
    // _lifeCycleTracker.init();
    super.init();
  }

  @override
  void close() {
    _lifeCycleTracker.dispose();
    super.close();
  }
}
