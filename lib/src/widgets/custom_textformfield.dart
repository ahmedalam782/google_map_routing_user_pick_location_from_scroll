import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/src/utils/constants.dart';

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
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
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
          cursorColor: const Color(0xffD60020),
          autofocus: false,
          focusNode: focusNode,
          maxLines: maxLine ?? 1,
          controller: controller,
          maxLength: maxLeanth,
          style: TextStyle(
            color: const Color(0xff242021),
            fontSize: 16,
            fontFamily: MdUserPickLocationGoogleMapConfig.fontFamily,
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
              color: const Color(0xff606060),
              fontSize: 16,
              fontFamily: MdUserPickLocationGoogleMapConfig.fontFamily,
            ),
            fillColor: color ?? Colors.white,
            filled: true,
            focusedBorder: activeBorder(),
            enabledBorder: unActiveBorder(),
            border: activeBorder(),
          ),
        ),
      ),
    );
  }

  OutlineInputBorder activeBorder() {
    return OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(38)),
      borderSide: haveBorder!
          ? BorderSide(
              width: 1, color: MdUserPickLocationGoogleMapConfig.primaryColor!)
          : BorderSide.none,
    );
  }

  OutlineInputBorder unActiveBorder() {
    return OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(38)),
      borderSide: haveBorder!
          ? BorderSide(
              width: .5, color: const Color(0xff242021).withValues(alpha: 0.6))
          : BorderSide.none,
    );
  }
}
