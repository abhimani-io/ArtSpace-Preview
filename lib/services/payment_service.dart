import 'package:flutter/foundation.dart';
import 'package:payhere_mobilesdk_flutter/payhere_mobilesdk_flutter.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class PaymentService {
  /// Initializes and starts a PayHere payment using the PayHere Mobile SDK.
  /// 
  /// Uses the Sandbox Merchant ID `1236590` and mock customer details as requested.
  static void startPayherePayment({
    required double amount,
    required String orderId,
    required Function(String paymentId) onSuccess,
    required Function(String error) onError,
    required VoidCallback onDismissed,
  }) {
    const String merchantId = "1236590";
    const String merchantSecret = "MjYwMDg2NDg3NjIxMjgwOTEyMjUxNzQ1NDY0MzIyMzk3MDM4MjIyMQ=="; //sandbox secret
    final String formattedAmount = amount.toStringAsFixed(2);
    const String currency = "LKR";

    // Generate MD5 hash
    final String hashedSecret = md5.convert(utf8.encode(merchantSecret)).toString().toUpperCase();
    final String amountFormated = formattedAmount;
    final String hashString = merchantId + orderId + amountFormated + currency + hashedSecret;
    final String md5Hash = md5.convert(utf8.encode(hashString)).toString().toUpperCase();

    // Creating the payment object with dummy mock data for the customer
    Map paymentObject = {
      "sandbox": true, // true for sandbox/testing
      "merchant_id": merchantId, // Sandbox Merchant ID
      "return_url": "", 
      "cancel_url": "",
      "notify_url": "",
      "order_id": orderId,
      "items": "ArtSpace Order $orderId",
      "amount": formattedAmount,
      "currency": currency, // Ensure your merchant account supports the currency
      "hash": md5Hash,
      
      // Dummy mock customer details
      "first_name": "John",
      "last_name": "Doe",
      "email": "john.doe@example.com",
      "phone": "+94771234567",
      "address": "No 123, Art Lane",
      "city": "Colombo",
      "country": "Sri Lanka",
      
      // Dummy delivery details
      "delivery_address": "No 123, Art Lane",
      "delivery_city": "Colombo",
      "delivery_country": "Sri Lanka",
      "custom_1": "",
      "custom_2": ""
    };

    PayHere.startPayment(
      paymentObject,
      (paymentId) {
        debugPrint("PayHere Payment Success. Payment ID: $paymentId");
        onSuccess(paymentId);
      },
      (error) {
        debugPrint("PayHere Payment Failed. Error: $error");
        onError(error);
      },
      () {
        debugPrint("PayHere Payment Dismissed.");
        onDismissed();
      },
    );
  }
}
