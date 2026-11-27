import 'package:material_ui/material_ui.dart';

import '../../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../tokens/app_dimens.dart';

/// The only text field: label above, error below (from the server or the
/// form), optional show/hide for passwords.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.error,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? error;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final IconData? suffixIcon;
  final int maxLines;
  final TextCapitalization textCapitalization;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: color, width: width),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: t.small.copyWith(color: c.inkSecondary)),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: widget.controller,
          obscureText: _hidden,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          maxLines: widget.obscure ? 1 : widget.maxLines,
          textCapitalization: widget.textCapitalization,
          style: t.body,
          // Keeps the focused field above the keyboard with some air.
          scrollPadding: const EdgeInsets.all(AppSpacing.xxxl * 2),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: t.body.copyWith(color: c.inkTertiary),
            filled: true,
            fillColor: c.surface,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            enabledBorder: border(widget.error == null ? c.border : c.danger),
            focusedBorder: border(
              widget.error == null ? c.primary : c.danger,
              1.5,
            ),
            disabledBorder: border(c.border),
            errorText: null,
            suffixIcon: widget.obscure
                ? IconButton(
                    tooltip: _hidden ? CommonStrings.showPassword : CommonStrings.hidePassword,
                    icon: Icon(
                      _hidden
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: AppSizes.icon,
                      color: c.inkSecondary,
                    ),
                    onPressed: () => setState(() => _hidden = !_hidden),
                  )
                : widget.suffixIcon == null
                ? null
                : Icon(widget.suffixIcon, size: AppSizes.icon, color: c.inkSecondary),
          ),
        ),
        if (widget.error != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Semantics(
            liveRegion: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline, size: AppSizes.iconSm, color: c.danger),
                const SizedBox(width: AppSpacing.xxs),
                Expanded(
                  child: Text(
                    widget.error!,
                    style: t.small.copyWith(color: c.danger),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Checkbox with a wrapping label, the whole row is the touch target.
class AppCheckRow extends StatelessWidget {
  const AppCheckRow({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.error,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MergeSemantics(
          child: InkWell(
            onTap: () => onChanged(!value),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSizes.touch),
              child: Row(
                children: [
                  Checkbox(
                    value: value,
                    onChanged: (v) => onChanged(v ?? false),
                    activeColor: c.primary,
                  ),
                  Expanded(child: Text(label, style: context.text.small)),
                ],
              ),
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.md),
            child: Text(error!, style: context.text.small.copyWith(color: c.danger)),
          ),
      ],
    );
  }
}
