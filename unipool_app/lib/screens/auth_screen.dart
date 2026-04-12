import 'package:flutter/material.dart';
import 'package:unipool/theme/app_theme.dart';
import 'package:unipool/widgets/app_ui.dart';
import 'package:unipool/services/auth_service.dart';
import 'package:unipool/screens/home_screen.dart';
import 'package:unipool/screens/forgot_password_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final emailController = TextEditingController();
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  final otpController = TextEditingController();

  bool obscure = true;
  bool loading = false;
  bool isSignUp = false;
  bool showOtpField = false;

  @override
  void dispose() {
    emailController.dispose();
    nameController.dispose();
    passwordController.dispose();
    otpController.dispose();
    super.dispose();
  }

  void _showSnack(String message, {bool isError = true}) {
    if (!mounted) return;
    showAppSnackBar(context, message, isError: isError);
  }

  Future<void> _resetPassword() async {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnack('Please enter your email/username and password.');
      return;
    }

    setState(() => loading = true);
    try {
      await authService.login(email, password);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> signUp() async {
    final email = emailController.text.trim();
    final name = nameController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty || (isSignUp && name.isEmpty)) {
      _showSnack('Please fill all required fields.');
      return;
    }
    if (password.length < 8) {
      _showSnack('Password must be at least 8 characters.');
      return;
    }

    setState(() => loading = true);
    try {
      if (!showOtpField) {
        // Request OTP
        await authService.startRegistration(email);
        setState(() => showOtpField = true);
        _showSnack('OTP sent to your email. Please verify.', isError: false);
      } else {
        // Verify OTP and complete sign up
        final otp = otpController.text.trim();
        if (otp.isEmpty) {
          _showSnack('Please enter the OTP.');
          return;
        }
        await authService.verifyRegistration(
          email: email,
          name: name,
          password: password,
          otp: otp,
        );
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
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
                      _buildCompactIntro(),
                      const SizedBox(height: 24),
                      _buildAuthCard(),
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

  Widget _buildCompactIntro() {
    return Column(
      children: [
        Container(
          width: 74, height: 74,
          decoration: BoxDecoration(
            gradient: AppColors.warmGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.24),
                blurRadius: 24, offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(Icons.local_taxi_rounded, color: Colors.white, size: 34),
        ),
        const SizedBox(height: 16),
        Text('UniPool', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 8),
        const Text('Campus rides, one place.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, height: 1.45)),
      ],
    );
  }

  Widget _buildAuthCard() {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppPill(
            label: 'Welcome',
            icon: Icons.key_rounded,
            foregroundColor: AppColors.primary,
            backgroundColor: Color(0xFF182543),
          ),
          const SizedBox(height: 18),
          Text(isSignUp ? 'Create your account' : 'Sign in to continue', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            isSignUp ? 'Create an account to start using UniPool.' : 'Access your rides and messages.',
            style: const TextStyle(color: AppColors.muted, height: 1.45),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppColors.surfaceSoft, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                _buildTabButton('Sign in', !isSignUp),
                _buildTabButton('Create account', isSignUp),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _buildTextField(
            controller: emailController,
            label: isSignUp ? 'Email' : 'Email / Username',
            icon: Icons.mail_outline_rounded,
          ),
          if (isSignUp && !showOtpField) ...[
            const SizedBox(height: 16),
            _buildTextField(
              controller: nameController,
              label: 'Full Name',
              icon: Icons.person_outline_rounded,
            ),
          ],
          const SizedBox(height: 16),
          _buildTextField(
            controller: passwordController,
            label: 'Password',
            icon: Icons.lock_outline_rounded,
            isPassword: true,
          ),
          if (isSignUp && showOtpField) ...[
            const SizedBox(height: 16),
            _buildTextField(
              controller: otpController,
              label: 'Enter OTP sent to email',
              icon: Icons.numbers_rounded,
              keyboardType: TextInputType.number,
            ),
          ],
          if (!isSignUp) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: loading ? null : _resetPassword,
                child: const Text('Forgot password?'),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: AppPrimaryButton(
              label: isSignUp ? (showOtpField ? 'Verify & Create' : 'Next') : 'Sign in',
              icon: Icons.arrow_forward_rounded,
              isLoading: loading,
              onPressed: isSignUp ? signUp : login,
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                Text(
                  isSignUp ? 'Already have an account?' : 'New to UniPool?',
                  style: const TextStyle(color: AppColors.muted),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    isSignUp = !isSignUp;
                    showOtpField = false;
                  }),
                  child: Text(isSignUp ? 'Sign in' : 'Create account'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, bool active) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          isSignUp = label == 'Create account';
          showOtpField = false; // Reset OTP field on tab switch
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: active ? AppColors.accentGradient : null,
            color: active ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label, textAlign: TextAlign.center,
            style: TextStyle(color: active ? Colors.white : AppColors.muted, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? obscure : false,
      keyboardType: keyboardType,
      onSubmitted: isPassword ? (_) => isSignUp ? signUp() : login() : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        suffixIcon: isPassword
            ? IconButton(
                onPressed: () => setState(() => obscure = !obscure),
                icon: Icon(
                  obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppColors.muted,
                ),
              )
            : null,
      ),
    );
  }
}
