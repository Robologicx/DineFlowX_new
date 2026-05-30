import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:hotel_management_system/state_management/app_providers.dart";

class CustomButton extends ConsumerWidget {
  final VoidCallback onTap;
  final String text;

  const CustomButton({super.key, required this.text, required this.onTap});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authRef = ref.watch(authNotifierProvider);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.065,
      width: MediaQuery.sizeOf(context).width * 0.4,
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 5,
          child: Center(
            child: authRef.isLoading
                ? CircularProgressIndicator()
                : Text(
                    text,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
