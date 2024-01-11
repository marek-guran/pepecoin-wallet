import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/services.dart';
import 'package:mrt_wallet/app/utility/price/price_utils.dart';

class RangeTextInputFormatter extends TextInputFormatter {
  final int min;
  final int? max;

  RangeTextInputFormatter({required this.min, required this.max});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String newString = newValue.text;

    if (newString.isNotEmpty) {
      int? enteredNumber = int.tryParse(newString);
      if (enteredNumber != null) {
        if (enteredNumber < min) {
          return BigRetionalRangeTextInputFormatter._buildOldValue(oldValue);
        } else if (max != null && enteredNumber > max!) {
          return BigRetionalRangeTextInputFormatter._buildOldValue(oldValue);
        }
      } else {
        return BigRetionalRangeTextInputFormatter._buildOldValue(oldValue);
      }
    }
    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}

class BigRetionalRangeTextInputFormatter extends TextInputFormatter {
  final BigRational? min;
  final BigRational? max;
  final int? maxPrecision;
  final bool allowDecimal;
  final bool allowSign;

  BigRetionalRangeTextInputFormatter(
      {required this.min,
      required this.max,
      this.maxPrecision,
      this.allowSign = true,
      this.allowDecimal = true});

  static TextEditingValue _buildOldValue(TextEditingValue oldValue) {
    BigRational? enteredNumber = BigRational.tryParseDecimaal(oldValue.text);
    if (enteredNumber == null) {
      return const TextEditingValue(
        text: "",
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    return oldValue;
  }

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String newString = newValue.text;
    if (newString.isNotEmpty) {
      BigRational? enteredNumber = BigRational.tryParseDecimaal(newString);
      if (enteredNumber != null) {
        if (min != null && enteredNumber < min!) {
          return _buildOldValue(oldValue);
        } else if (max != null && enteredNumber > max!) {
          return _buildOldValue(oldValue);
        } else if (maxPrecision != null &&
            enteredNumber.precision > maxPrecision!) {
          return _buildOldValue(oldValue);
        } else if (!allowDecimal && enteredNumber.isDecimal) {
          return _buildOldValue(oldValue);
        } else if (!allowSign && enteredNumber.isNegative) {
          return _buildOldValue(oldValue);
        }
      } else {
        return _buildOldValue(oldValue);
      }
    }
    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}

class DecodePriceTextInputFormater extends TextInputFormatter {
  const DecodePriceTextInputFormater({this.max, required this.decimal});
  final BigInt? max;
  final int decimal;
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.trim().isEmpty) {
      return newValue;
    }
    final pr = PriceUtils.tryDecodePrice(newValue.text, decimal);
    if (pr != null) {
      if (max == null) return newValue;
      if (pr <= max!) return newValue;
    }
    return oldValue;
  }
}
