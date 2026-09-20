import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'config.dart';
import 'login/login_form_controller.dart';
import 'utilities.dart';
import 'package:chat/app_theme.dart';
import 'package:chat/l10n/app_localizations.dart';
import 'package:chat/theme/app_colors.dart';
import 'package:chat/theme/app_typography.dart';
import 'package:chat/viewmodel/locale_view_model.dart';
import 'package:chat/widget/bottom_action_sheet.dart';
import 'package:imclient/imclient_platform.dart';

/// 移动端/平板登录页(手机壳)。表单状态与登录流程在共享的 [LoginFormController],
/// 桌面端 PCQRLoginScreen 的表单视图复用同一控制器(桌面是固定小窗的二维码页,
/// 不走本页的沉浸式排版)。
///
/// 沉浸式:整页不挂 AppBar,品牌色天光从状态栏后面一路铺下来渐隐到页面底色,
/// 状态栏/导航栏都只留图标(全局透明状态栏见 main.dart 的 AnnotatedRegion,
/// 本页再把导航栏压成与背景底端同色,避免底部出现一条接缝)。
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LoginFormController _form = LoginFormController();

  /// 密码是否遮蔽。纯视图状态,不进控制器 —— 控制器是两端共用的登录逻辑。
  bool _obscurePassword = true;

  // 协议链接手势:build 中创建会泄漏,作为 State 字段统一在 dispose 释放。
  late final TapGestureRecognizer _userAgreementRecognizer;
  late final TapGestureRecognizer _privacyPolicyRecognizer;

  @override
  void initState() {
    super.initState();
    _userAgreementRecognizer = TapGestureRecognizer()
      ..onTap = () => Utilities.openLink(context, Config.USER_AGREEMENT_URL);
    _privacyPolicyRecognizer = TapGestureRecognizer()
      ..onTap = () => Utilities.openLink(context, Config.PRIVACY_AGREEMENT_URL);
    _form.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    _userAgreementRecognizer.dispose();
    _privacyPolicyRecognizer.dispose();
    _form.removeListener(_onFormChanged);
    _form.dispose();
    super.dispose();
  }

  void _onFormChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // 语言入口要跟着当前选择刷新。订阅挂在 build 顶层,不放进下面 LayoutBuilder
    // 的 builder —— 那个回调在 layout 阶段执行,订阅关系放这里更直白。
    final localeMode = context.watch<LocaleViewModel>().localeMode;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // 全局那份把导航栏刷成 cellTop(列表页的灰),压在本页白/深底上是一条横带。
      value: AppTheme.systemOverlayStyle(Theme.of(context).brightness)
          .copyWith(systemNavigationBarColor: colors.loginBackdropBottom),
      child: Scaffold(
        // 背景绘在 Scaffold 上而不是只画在 body 里:键盘顶起 body 时
        // (resizeToAvoidBottomInset)让出来的那块仍是页面底色,不会闪出一条默认白。
        backgroundColor: colors.loginBackdropBottom,
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              // 天光只占上半屏,下半屏收干净 —— 输入框与按钮要落在纯底色上,
              // 渐变一路拖到底会让底部按钮的边缘显脏。
              colors: [colors.loginBackdropTop, colors.loginBackdropBottom],
              stops: const [0.0, 0.5],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 内容不足一屏时语言入口沉到底部(Spacer),超过一屏(大字号档、
                // 小屏、键盘弹起)整页可滚。IntrinsicHeight 把 Column 的高度钉成
                // 「至少一屏」,Spacer 才有伸展空间。
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Center(
                        child: ConstrainedBox(
                          // 平板屏幕宽,表单铺满整幅会把输入框拉成一条横线。
                          // 收成一栏居中。手机取不到这一层,原样铺满。
                          constraints: BoxConstraints(
                              maxWidth:
                                  WfcPlatform.isTablet ? 420 : double.infinity),
                          child: _buildContent(context, localeMode),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, String localeMode) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          _buildBrand(context),
          const SizedBox(height: 16),
          // 标语与启动页同一句,启动页到登录页看起来是同一块界面在继续。
          Text(
            l10n.appTagline,
            style: AppText.xxl.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 48),
          _buildPhoneField(context),
          const SizedBox(height: 4),
          _buildCodeOrPwdField(context),
          const SizedBox(height: 28),
          _buildAgreement(context),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _form.canSubmit ? () => _form.submit(context) : null,
            // 整页唯一主行动,叠大档。
            style: AppTheme.largeButtonStyle(),
            child: Text(l10n.login),
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: _form.toggleLoginMode,
              child: Text(_form.isPasswordLogin
                  ? l10n.loginWithPhoneCode
                  : l10n.loginWithPassword),
            ),
          ),
          const Spacer(),
          const SizedBox(height: 16),
          _buildLanguageEntry(context, localeMode),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// 图标 + 应用名。图标是白底不透明的方图,切成圆角方片才像一枚 app 图标,
  /// 暗色下也不至于糊成一块白方块。
  Widget _buildBrand(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child:
              Image.asset('assets/images/app_icon.png', width: 48, height: 48),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            AppLocalizations.of(context)!.appTitle,
            style: AppText.xl.copyWith(
              color: colors.accent,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField(BuildContext context) {
    final colors = context.colors;
    final hasText = _form.phoneController.text.isNotEmpty;
    return _UnderlineField(
      controller: _form.phoneController,
      hintText: AppLocalizations.of(context)!.phoneNumberHint,
      keyboardType: TextInputType.phone,
      // 旧版 CupertinoTextField 自带的一键清空,换成 Material 输入框后自己补上。
      suffix: hasText
          ? _FieldIconButton(
              icon: Icons.cancel,
              color: colors.textTertiary,
              onPressed: () => _form.phoneController.clear(),
            )
          : null,
    );
  }

  /// 验证码/密码共用一格:验证码模式右侧是发码按钮,密码模式右侧是明文开关。
  Widget _buildCodeOrPwdField(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final isPassword = _form.isPasswordLogin;
    return _UnderlineField(
      controller: _form.codeOrPwdController,
      hintText: isPassword ? l10n.inputPassword : l10n.inputVerificationCode,
      obscureText: isPassword && _obscurePassword,
      // 键盘类型保持旧版的默认(文本):验证码的字符集由服务端定,
      // 钉成数字键盘万一发的是字母数字混合就打不进来。
      suffix: isPassword
          ? _FieldIconButton(
              icon: _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: colors.iconSecondary,
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            )
          : TextButton(
              onPressed:
                  _form.canSendCode ? () => _form.sendCode(context) : null,
              // 收掉 M3 默认的 48 点击区与 64 最小宽:让输入框的高度只由文字
              // 决定,三种状态(手机号/验证码/密码)才是同一个高度。
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: AppText.base,
              ),
              child: _form.isSentCode
                  ? Text('${_form.waitResendCount} s')
                  : Text(l10n.sendCode),
            ),
    );
  }

  Widget _buildAgreement(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final linkStyle = AppText.sm.copyWith(color: colors.link);
    return Row(
      children: [
        // 只收紧观感,不动点击区:勾选框仍是 40 见方的可点面积。
        // 文案整段**不**做「点一下即同意」—— 它和 TextSpan 里两条协议链接的手势
        // 同处一个 arena,谁夺到不稳,可能把「打开用户协议」吃成「勾选同意」。
        Checkbox(
          value: _form.agreementChecked,
          onChanged: (bool? value) => _form.agreementChecked = value!,
          visualDensity: VisualDensity.compact,
        ),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: l10n.readAndAgree,
              children: <TextSpan>[
                TextSpan(
                  text: l10n.userAgreement,
                  style: linkStyle,
                  recognizer: _userAgreementRecognizer,
                ),
                TextSpan(text: l10n.and),
                TextSpan(
                  text: l10n.privacyPolicy,
                  style: linkStyle,
                  recognizer: _privacyPolicyRecognizer,
                ),
              ],
            ),
            style: AppText.sm.copyWith(color: colors.textSecondary),
          ),
        ),
      ],
    );
  }

  /// 登录前进不了设置页,语言入口放在这里 —— 装成中文包却跑在英文系统上的机器,
  /// 用户第一眼就能切回来。
  Widget _buildLanguageEntry(BuildContext context, String localeMode) {
    final colors = context.colors;
    return Center(
      child: TextButton.icon(
        onPressed: () => _showLanguageSheet(context),
        icon: Icon(Icons.language, size: 18, color: colors.textSecondary),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_localeLabel(context, localeMode)),
            Icon(Icons.keyboard_arrow_down,
                size: 18, color: colors.textSecondary),
          ],
        ),
        style: TextButton.styleFrom(foregroundColor: colors.textSecondary),
      ),
    );
  }

  String _localeLabel(BuildContext context, String mode) {
    final l10n = AppLocalizations.of(context)!;
    switch (mode) {
      case 'zh':
        return l10n.chinese;
      case 'en':
        return l10n.english;
      default:
        return l10n.followSystem;
    }
  }

  void _showLanguageSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final localeViewModel =
        Provider.of<LocaleViewModel>(context, listen: false);

    // 选中项用前导对勾标记;未选中的也占同样宽度,免得每行的文字左右跳。
    BottomActionSheetItem item(String label, String mode) =>
        BottomActionSheetItem(
          label: label,
          leading: SizedBox(
            width: 22,
            child: localeViewModel.localeMode == mode
                ? Icon(Icons.check, size: 20, color: colors.accent)
                : null,
          ),
          onTap: () => localeViewModel.setLocaleMode(mode),
        );

    showBottomActionSheet(
      context: context,
      items: [
        item(l10n.followSystem, 'follow_system'),
        item(l10n.chinese, 'zh'),
        item(l10n.english, 'en'),
      ],
    );
  }
}

/// 输入框右侧的小图标按钮(清空、明文开关)。
/// 裸 IconButton 在移动端会占满 48x48 的点击区,把输入框顶高一档,
/// 也把图标推离右边线 —— 这里统一收成 36 见方、无内边距。
class _FieldIconButton extends StatelessWidget {
  const _FieldIconButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: color),
      style: IconButton.styleFrom(
        minimumSize: const Size(36, 36),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// 下划线输入框:无边框、无底色,只有一条发丝线,聚焦时变品牌色。
/// 沉浸式背景上不能再摆一排实心灰底的输入框 —— 灰块会把天光切碎。
class _UnderlineField extends StatelessWidget {
  const _UnderlineField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      autocorrect: false,
      enableSuggestions: false,
      cursorColor: colors.accent,
      style: AppText.lg.copyWith(color: colors.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppText.lg.copyWith(color: colors.textTertiary),
        filled: false,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: colors.hairline)),
        focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: colors.accent, width: 1.5)),
        suffixIcon: suffix,
        // 默认是 48x48 的最小方框,会反过来决定整个输入框的高度;
        // 放开后高度只由文字 + contentPadding 决定,有没有 suffix 都一样高。
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
    );
  }
}
