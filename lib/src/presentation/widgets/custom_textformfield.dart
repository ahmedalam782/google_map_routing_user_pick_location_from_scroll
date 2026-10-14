import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mdsoft_google_map_user_pick_location_from_scroll/md_user_pick_location_google_map_config.dart';

class CustomTextFormFeild extends StatelessWidget {
  final Color? color;
  final Function()? onTap;
  final Function()? onComplete;
  final Function(String val)? onChange;
  final Function(String? val)? onSave;
  final Function(String val)? onSubmit;
  final String? Function(String? val)? validator;
  final TextInputType? textInputType;
  final TextEditingController? controller;
  final String? label;
  final bool? haveBorder;
  final bool readOnly;
  final bool? isObSecure;
  final Widget? suffixIconButton;
  final Widget? prefixIcon;
  final int? maxLine;
  final int? maxLeanth;
  final double? contentPadding;
  final bool? haveShadow;
  final bool? isNumber;
  final String? hentText;
  final FocusNode? focusNode;
  final TextDirection textDirection;
  final Color? cursorColor;
  final Color? textColor;
  final Color? hintColor;
  final String? fontFamily;

  const CustomTextFormFeild({
    super.key,
    this.maxLeanth,
    this.textInputType,
    this.maxLine,
    this.isObSecure,
    this.suffixIconButton,
    this.prefixIcon,
    this.onTap,
    this.onChange,
    this.onComplete,
    this.controller,
    this.onSave,
    this.onSubmit,
    this.validator,
    this.readOnly = false,
    this.haveShadow = false,
    this.label,
    this.contentPadding,
    this.haveBorder = false,
    this.isNumber = false,
    this.hentText,
    this.color,
    this.focusNode,
    this.textDirection = TextDirection.rtl,
    this.cursorColor,
    this.textColor,
    this.hintColor,
    this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedFont =
        fontFamily ?? MdUserPickLocationGoogleMapConfig.current.fontFamily;
    return Directionality(
      textDirection: textDirection,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(38),
          boxShadow: haveShadow!
              ? [BoxShadow(color: Colors.grey.shade100, blurRadius: 10)]
              : null,
        ),
        child: TextFormField(
          onTapOutside: (event) {
            FocusScope.of(context).unfocus();
          },
          cursorColor: cursorColor ?? const Color(0xffD60020),
          autofocus: false,
          focusNode: focusNode,
          maxLines: maxLine ?? 1,
          controller: controller,
          maxLength: maxLeanth,
          style: TextStyle(
            color: textColor ?? const Color(0xff242021),
            fontSize: 16,
            fontFamily: resolvedFont,
          ),
          // autovalidateMode: AutovalidateMode.onUnfocus,
          onTap: onTap,
          // style: AppFont.font16ColorBlackregular(context),
          onChanged: onChange,
          onEditingComplete: onComplete,
          onFieldSubmitted: onSubmit,
          onSaved: onSave,
          validator: validator,
          keyboardType: textInputType,
          obscureText: isObSecure ?? false,
          readOnly: readOnly,
          inputFormatters: isNumber!
              ? <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d{0,10}(\.\d{0,1})?$'),
                  ),

                  // Only numbers allowed
                ]
              : null,
          obscuringCharacter: '•',
          decoration: InputDecoration(
            prefixIcon: prefixIcon,
            hintText: label!,
            contentPadding: EdgeInsets.all(contentPadding ?? 12),
            suffixIcon: suffixIconButton,
            hintStyle: TextStyle(
              color: hintColor ?? const Color(0xff606060),
              fontSize: 16,
              fontFamily: resolvedFont,
            ),
            fillColor: color ?? Colors.white,
            filled: true,
            focusedBorder: _activeBorder(),
            enabledBorder: _unActiveBorder(),
            border: _activeBorder(),
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _activeBorder() {
    return OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(38)),
      borderSide: haveBorder!
          ? BorderSide(
              width: 1,
              color: MdUserPickLocationGoogleMapConfig.current.primaryColor)
          : BorderSide.none,
    );
  }

  OutlineInputBorder _unActiveBorder() {
    return OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(38)),
      borderSide: haveBorder!
          ? BorderSide(
              width: .5, color: const Color(0xff242021).withValues(alpha: 0.6))
          : BorderSide.none,
    );
  }
}
