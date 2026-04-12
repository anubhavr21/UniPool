import 'package:flutter/material.dart';
import 'package:unipool/theme/app_theme.dart';
import 'package:unipool/widgets/app_ui.dart';
import 'package:unipool/services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  final otpController = TextEditingController();
  final newPasswordController = TextEditingController();

  bool loading = false;
  bool showOtpField = false;

  @override
  void dispose() {
    emailController.dispose();
    otpController.dispose();
    newPasswordController.dispose();
    super.dispose();
  }

  void _showSnack(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent.shade700 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  Future<void> _handleResetStep() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      _showSnack('Please enter your email.');
      return;
    }

    setState(() => loading = true);
    try {
      if (!showOtpField) {
        await authService.forgotPassword(email);
        setState(() => showOtpField = true);
        _showSnack('Reset OTP sent to your email. Please check your inbox.', isError: false);
      } else {
        final otp = otpController.text.trim();
        final newPassword = newPasswordController.text.trim();

        if (otp.isEmpty || newPassword.isEmpty) {
          _showSnack('Please fill in the OTP and new password.');
          return;
        }

        if (newPassword.length < 8) {
          _showSnack('Password must be at least 8 characters long.');
          return;
        }

        await authService.resetPassword(
          target: email,
          otp: otp,
          newPassword: newPassword,
        );

        _showSnack('Password reset successfully! You can now sign in.', isError: false);
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(color: AppColors.muted),
          prefixIcon: Icon(icon, color: AppColors.muted, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        onSubmitted: (_) => _handleResetStep(),
      ),
    );
  }

  Widget _buildResetCard() {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: AppPill(
                  label: 'Account Recovery',
                  icon: Icons.lock_reset_rounded,
                  foregroundColor: AppColors.primary,
                  backgroundColor: Color(0xFF182543),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Reset Password', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            showOtpField
                ? 'Enter the 6-digit OTP sent to your email and your new password.'
                : 'Enter your account email to receive a password reset OTP.',
            style: const TextStyle(color: AppColors.muted, height: 1.45),
          ),
          const SizedBox(height: 28),
          _buildTextField(
            controller: emailController,
            label: 'Email Address',
            icon: Icons.mail_outline_rounded,
          ),
          if (showOtpField) ...[
            const SizedBox(height: 16),
            _buildTextField(
              controller: otpController,
              label: '6-digit OTP',
              icon: Icons.numbers_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: newPasswordController,
              label: 'New Password',
              icon: Icons.lock_outline_rounded,
              isPassword: true,
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: AppPrimaryButton(
              label: showOtpField ? 'Reset Password' : 'Send OTP',
              icon: Icons.arrow_forward_rounded,
              isLoading: loading,
              onPressed: _handleResetStep,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradientBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    children: [
                      Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          gradient: AppColors.warmGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.24),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.shield_rounded, color: Colors.white, size: 34),
                      ),
                      const SizedBox(height: 16),
                      Text('UniPool', style: Theme.of(context).textTheme.displaySmall),
                      const SizedBox(height: 32),
                      _buildResetCard(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
