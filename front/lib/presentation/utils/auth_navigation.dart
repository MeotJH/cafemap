import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front/presentation/providers/auth_providers.dart';
import 'package:go_router/go_router.dart';

Future<bool> ensureSignedInForReview(
  BuildContext context,
  WidgetRef ref, {
  String message = '리뷰 작성은 로그인 후 이용할 수 있어요.',
}) async {
  final user =
      ref.read(authStateProvider).asData?.value ??
      ref.read(authControllerProvider).currentUser;
  if (user != null) {
    return true;
  }

  await Flushbar<void>(
    message: message,
    duration: const Duration(seconds: 2),
    flushbarPosition: FlushbarPosition.TOP,
    backgroundColor: const Color(0xFF2A2A2A),
    margin: const EdgeInsets.all(12),
    borderRadius: BorderRadius.circular(10),
    icon: const Icon(Icons.info_outline, color: Colors.white),
  ).show(context);

  if (context.mounted) {
    context.push('/auth');
  }
  return false;
}
