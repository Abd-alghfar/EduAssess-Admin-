import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class Failure {
  final String message;
  Failure(this.message);

  static String getFriendlyMessage(dynamic error) {
    if (error is String) {
      if (error.contains('SocketException')) {
        return 'عذراً، لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
      }
      if (error.contains('AuthException')) {
        return 'بيانات الدخول غير صحيحة أو انتهت صلاحية الجلسة.';
      }
      return 'عذراً، حدث خطأ غير متوقع. يرجى المحاولة لاحقاً.';
    }

    if (error is SocketException) {
      return 'عذراً، لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
    } else if (error is AuthException) {
      if (error.message.contains('Invalid login credentials')) {
        return 'بيانات الدخول غير صحيحة. يرجى التأكد من اسم المستخدم وكلمة المرور.';
      }
      return 'حدث خطأ في عملية تسجيل الدخول. يرجى المحاولة لاحقاً.';
    } else if (error is PostgrestException) {
      return 'عذراً، حدث خطأ أثناء جلب البيانات من الخادم. يرجى المحاولة مرة أخرى.';
    } else {
      // For any other unexpected errors, show a generic friendly message instead of a technical one
      return 'عذراً، حدث خطأ غير متوقع. نحن نعمل على إصلاحه، يرجى المحاولة لاحقاً.';
    }
  }

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  ServerFailure([String? message])
    : super(message ?? 'حدث خطأ في الاتصال بالخادم.');
}

class AuthFailure extends Failure {
  AuthFailure([String? message]) : super(message ?? 'فشلت عملية المصادقة.');
}

class NetworkFailure extends Failure {
  NetworkFailure() : super('لا يوجد اتصال بالإنترنت.');
}
