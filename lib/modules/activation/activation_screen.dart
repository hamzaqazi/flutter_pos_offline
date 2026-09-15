// import 'package:ad_shop_pos/app/theme/app_theme.dart';
// import 'package:ad_shop_pos/app/widgets/app_widgets.dart';
// import 'package:ad_shop_pos/app/utils/launcher.dart';
// import 'package:ad_shop_pos/data/services/license_service.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class ActivationScreen extends StatefulWidget {
//   const ActivationScreen({super.key});

//   @override
//   State<ActivationScreen> createState() => _ActivationScreenState();
// }

// class _ActivationScreenState extends State<ActivationScreen> {
//   // ── License key activation ──
//   final _keyController = TextEditingController();
//   bool _loading = false;
//   String? _error;

//   // ── Phone verification for trial ──
//   final _phoneController = TextEditingController();
//   bool _phoneLoading = false;
//   String? _phoneError;

//   // ── Trial eligibility ──
//   bool _trialEligible = true;
//   bool _checkingTrialEligibility = true;

//   // ── Step tracking: 'choose' or 'phone' ──
//   String _step = 'choose';

//   @override
//   void initState() {
//     super.initState();
//     _checkTrialEligibility();
//   }

//   @override
//   void dispose() {
//     _keyController.dispose();
//     _phoneController.dispose();
//     super.dispose();
//   }

//   /// Check Firestore if this device can start a new trial.
//   Future<void> _checkTrialEligibility() async {
//     if (LicenseService.hasUsedTrial || LicenseService.isActivated) {
//       setState(() {
//         _trialEligible = false;
//         _checkingTrialEligibility = false;
//       });
//       return;
//     }
//     final eligible = await LicenseService.checkDeviceTrialEligibility();
//     setState(() {
//       _trialEligible = eligible != false;
//       _checkingTrialEligibility = false;
//     });
//   }

//   // ── License key activation ──
//   Future<void> _activate() async {
//     final key = _keyController.text.trim();
//     if (key.isEmpty) {
//       setState(() => _error = 'Please enter a license key');
//       return;
//     }
//     setState(() {
//       _loading = true;
//       _error = null;
//     });

//     final result = await LicenseService.validateLicense(key);
//     if (!mounted) return;
//     setState(() => _loading = false);

//     if (result.success) {
//       LicenseService.clearDeactivationReason();
//       Get.offAllNamed('/pin-setup');
//     } else {
//       setState(() => _error = result.message);
//     }
//   }

//   // ── Phone validation ──
//   /// Validate phone number format.
//   ///
//   /// Pakistani formats (03XX-XXXXXXX, 923XXXXXXXXXX) are accepted, but any
//   /// other international number is accepted too — the app is distributed on
//   /// Google Play, so reviewers and shop owners outside Pakistan must be able
//   /// to start the trial without being blocked by a country-specific rule.
//   bool _isValidPhone(String phone) {
//     final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
//     return digits.length >= 8 && digits.length <= 15;
//   }

//   /// Convert phone to international format (923XXXXXXXXXX) for WhatsApp.
//   String _phoneToInternational(String phone) {
//     final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
//     if (digits.startsWith('03')) return '92${digits.substring(1)}';
//     return digits; // already has 92 prefix
//   }

//   // ── Start trial with phone number ──
//   Future<void> _startTrialWithPhone() async {
//     final phone = _phoneController.text.trim();
//     if (phone.isEmpty) {
//       setState(() => _phoneError = 'Please enter your phone number');
//       return;
//     }
//     if (!_isValidPhone(phone)) {
//       setState(
//         () => _phoneError = 'Enter a valid phone number (e.g. 0315-3507075)',
//       );
//       return;
//     }

//     setState(() {
//       _phoneLoading = true;
//       _phoneError = null;
//     });

//     // Re-check Firestore eligibility before starting
//     final eligible = await LicenseService.checkDeviceTrialEligibility();
//     if (eligible == false) {
//       if (!mounted) return;
//       await LicenseService.markTrialAlreadyUsed();
//       setState(() {
//         _trialEligible = false;
//         _phoneLoading = false;
//         _step = 'choose';
//       });
//       Get.snackbar(
//         'Trial Already Used',
//         'This device has already used a free trial. Activate a license or continue with the free plan.',
//         snackPosition: SnackPosition.BOTTOM,
//       );
//       return;
//     }

//     // Start trial with phone number
//     final intlPhone = _phoneToInternational(phone);
//     await LicenseService.startTrial(customerPhone: intlPhone);

//     if (!mounted) return;
//     setState(() => _phoneLoading = false);
//     LicenseService.clearDeactivationReason();
//     Get.offAllNamed('/pin-setup');
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final cs = theme.colorScheme;

//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               cs.primary.withValues(alpha: 0.05),
//               cs.surface,
//               cs.primary.withValues(alpha: 0.03),
//             ],
//           ),
//         ),
//         child: SafeArea(
//           child: Center(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(AppSpacing.lg),
//               child: ConstrainedBox(
//                 constraints: const BoxConstraints(maxWidth: 440),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     // ── Brand Logo ──
//                     Container(
//                       width: 100,
//                       height: 100,
//                       decoration: BoxDecoration(
//                         border: Border.all(
//                           color: cs.primary.withValues(alpha: 0.3),
//                           width: 2,
//                         ),
//                         borderRadius: BorderRadius.circular(24),
//                       ),
//                       child: const Center(
//                         child: Image(
//                           image: AssetImage(
//                             'lib/assets/images/cn_pos_logo_rm.png',
//                           ),
//                           width: 80,
//                           height: 80,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: AppSpacing.xxl),

//                     Text(
//                       'Codynest POS',
//                       style: theme.textTheme.displaySmall?.copyWith(
//                         fontWeight: FontWeight.w900,
//                       ),
//                     ),
//                     const SizedBox(height: AppSpacing.xs),
//                     Text(
//                       'Point of Sale System',
//                       style: theme.textTheme.bodyLarge?.copyWith(
//                         color: cs.onSurfaceVariant,
//                         fontWeight: FontWeight.w500,
//                         fontSize: 12,
//                       ),
//                     ),
//                     const SizedBox(height: AppSpacing.xxl),

//                     // ── Trial Expired Banner ──
//                     if (LicenseService.trialStartDate != null &&
//                         !LicenseService.isTrialActive &&
//                         !LicenseService.isActivated)
//                       Padding(
//                         padding: const EdgeInsets.only(bottom: AppSpacing.lg),
//                         child: AppBanner.warning(
//                           title: 'Free Trial Expired',
//                           subtitle:
//                               'Your 14-day free trial has ended. Activate a license or continue with the free plan (${LicenseService.freeMaxProducts} products max).',
//                           icon: Icons.timer_off_outlined,
//                         ),
//                       ),

//                     // ── Deactivation Reason Banner ──
//                     if (LicenseService.hasDeactivationReason)
//                       Padding(
//                         padding: const EdgeInsets.only(bottom: AppSpacing.lg),
//                         child: AppBanner.danger(
//                           title: 'License Deactivated',
//                           subtitle:
//                               '${LicenseService.deactivationReason} Contact: 0315-3507075',
//                           icon: Icons.warning_amber_rounded,
//                         ),
//                       ),

//                     // ── STEP: Choose (Free Trial or License Key) ──
//                     if (_step == 'choose') ...[
//                       // ── Free Trial Card ──
//                       if (_trialEligible && !LicenseService.isActivated)
//                         Card(
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(
//                               AppSpacing.radiusLg,
//                             ),
//                           ),
//                           child: InkWell(
//                             onTap: () => setState(() => _step = 'phone'),
//                             borderRadius: BorderRadius.circular(
//                               AppSpacing.radiusLg,
//                             ),
//                             child: Padding(
//                               padding: const EdgeInsets.all(AppSpacing.xl),
//                               child: Column(
//                                 children: [
//                                   Container(
//                                     padding: const EdgeInsets.all(
//                                       AppSpacing.md,
//                                     ),
//                                     decoration: BoxDecoration(
//                                       color: AppColors.seed.withValues(
//                                         alpha: 0.1,
//                                       ),
//                                       borderRadius: BorderRadius.circular(
//                                         AppSpacing.radiusSm,
//                                       ),
//                                     ),
//                                     child: Icon(
//                                       Icons.celebration_outlined,
//                                       color: AppColors.seed,
//                                       size: 40,
//                                     ),
//                                   ),
//                                   const SizedBox(height: AppSpacing.md),
//                                   Text(
//                                     'Try Free for 14 Days',
//                                     style: theme.textTheme.titleLarge?.copyWith(
//                                       fontWeight: FontWeight.w800,
//                                       color: AppColors.seed,
//                                     ),
//                                   ),
//                                   const SizedBox(height: AppSpacing.xs),
//                                   Text(
//                                     'Full access to all Premium features.\nNo credit card required — just verify your phone number.',
//                                     style: theme.textTheme.bodySmall?.copyWith(
//                                       color: cs.onSurfaceVariant,
//                                       height: 1.5,
//                                     ),
//                                     textAlign: TextAlign.center,
//                                   ),
//                                   const SizedBox(height: AppSpacing.md),
//                                   SizedBox(
//                                     width: double.infinity,
//                                     height: 48,
//                                     child: FilledButton.tonal(
//                                       onPressed: () =>
//                                           setState(() => _step = 'phone'),
//                                       style: FilledButton.styleFrom(
//                                         shape: RoundedRectangleBorder(
//                                           borderRadius: BorderRadius.circular(
//                                             AppSpacing.radiusMd,
//                                           ),
//                                         ),
//                                       ),
//                                       child: Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.center,
//                                         children: [
//                                           const Icon(
//                                             Icons.rocket_launch_outlined,
//                                             size: 18,
//                                           ),
//                                           const SizedBox(width: AppSpacing.sm),
//                                           Text(
//                                             'Start Free Trial',
//                                             style: theme.textTheme.titleSmall
//                                                 ?.copyWith(
//                                                   fontWeight: FontWeight.w700,
//                                                 ),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),

//                       const SizedBox(height: AppSpacing.lg),

//                       // ── License Key Card ──
//                       Card(
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(
//                             AppSpacing.radiusLg,
//                           ),
//                         ),
//                         child: Padding(
//                           padding: const EdgeInsets.all(AppSpacing.xl),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(
//                                 children: [
//                                   Container(
//                                     padding: const EdgeInsets.all(
//                                       AppSpacing.sm,
//                                     ),
//                                     decoration: BoxDecoration(
//                                       color: cs.primary.withValues(alpha: 0.1),
//                                       borderRadius: BorderRadius.circular(
//                                         AppSpacing.radiusSm,
//                                       ),
//                                     ),
//                                     child: Icon(
//                                       Icons.vpn_key_outlined,
//                                       color: cs.primary,
//                                       size: 20,
//                                     ),
//                                   ),
//                                   const SizedBox(width: AppSpacing.md),
//                                   Text(
//                                     'Activate Your License',
//                                     style: theme.textTheme.titleMedium
//                                         ?.copyWith(fontWeight: FontWeight.w700),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: AppSpacing.md),
//                               Text(
//                                 'Enter the license key provided to you to activate this application. Each key is linked to your shop and device.',
//                                 style: theme.textTheme.bodySmall?.copyWith(
//                                   color: cs.onSurfaceVariant,
//                                   height: 1.5,
//                                 ),
//                               ),
//                               const SizedBox(height: AppSpacing.xl),

//                               TextField(
//                                 controller: _keyController,
//                                 textCapitalization:
//                                     TextCapitalization.characters,
//                                 style: theme.textTheme.titleMedium?.copyWith(
//                                   fontWeight: FontWeight.w700,
//                                   letterSpacing: 3,
//                                   fontFamily: 'monospace',
//                                 ),
//                                 decoration: InputDecoration(
//                                   labelText: 'License Key',
//                                   hintText: 'CNPO-XXXX-XXXX-XXXX',
//                                   prefixIcon: const Icon(
//                                     Icons.vpn_key_outlined,
//                                   ),
//                                   filled: true,
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(
//                                       AppSpacing.radiusMd,
//                                     ),
//                                   ),
//                                 ),
//                                 onSubmitted: (_) => _activate(),
//                               ),

//                               if (_error != null) ...[
//                                 const SizedBox(height: AppSpacing.md),
//                                 Container(
//                                   width: double.infinity,
//                                   padding: const EdgeInsets.all(AppSpacing.md),
//                                   decoration: BoxDecoration(
//                                     color: AppColors.danger.withValues(
//                                       alpha: 0.08,
//                                     ),
//                                     borderRadius: BorderRadius.circular(
//                                       AppSpacing.radiusSm,
//                                     ),
//                                     border: Border.all(
//                                       color: AppColors.danger.withValues(
//                                         alpha: 0.25,
//                                       ),
//                                     ),
//                                   ),
//                                   child: Row(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Icon(
//                                         Icons.error_outline,
//                                         color: AppColors.danger,
//                                         size: 18,
//                                       ),
//                                       const SizedBox(width: AppSpacing.sm),
//                                       Expanded(
//                                         child: Text(
//                                           _error!,
//                                           style: theme.textTheme.bodySmall
//                                               ?.copyWith(
//                                                 color: AppColors.danger,
//                                                 fontWeight: FontWeight.w600,
//                                               ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],

//                               const SizedBox(height: AppSpacing.xl),

//                               SizedBox(
//                                 width: double.infinity,
//                                 height: 52,
//                                 child: FilledButton(
//                                   onPressed: _loading ? null : _activate,
//                                   style: FilledButton.styleFrom(
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(
//                                         AppSpacing.radiusMd,
//                                       ),
//                                     ),
//                                   ),
//                                   child: _loading
//                                       ? const SizedBox(
//                                           width: 24,
//                                           height: 24,
//                                           child: CircularProgressIndicator(
//                                             strokeWidth: 2.5,
//                                             color: Colors.white,
//                                           ),
//                                         )
//                                       : Row(
//                                           mainAxisAlignment:
//                                               MainAxisAlignment.center,
//                                           children: [
//                                             const Icon(
//                                               Icons.verified_user_outlined,
//                                               size: 20,
//                                             ),
//                                             const SizedBox(
//                                               width: AppSpacing.sm,
//                                             ),
//                                             Text(
//                                               'Activate License',
//                                               style: theme.textTheme.titleSmall
//                                                   ?.copyWith(
//                                                     color: cs.onPrimary,
//                                                     fontWeight: FontWeight.w700,
//                                                   ),
//                                             ),
//                                           ],
//                                         ),
//                                 ),
//                               ),

//                               const SizedBox(height: AppSpacing.md),
//                               // ── Buy license via WhatsApp ──
//                               SizedBox(
//                                 width: double.infinity,
//                                 height: 48,
//                                 child: OutlinedButton.icon(
//                                   onPressed: () => Launcher.openWhatsApp(
//                                     '923153507075',
//                                     'Hi! I want to buy a Codynest POS license key. My device ID: ${LicenseService.deviceId}',
//                                   ),
//                                   // asset image with WhatsApp logo can also be used instead of icon
//                                   icon: Image.asset(
//                                     'lib/assets/images/whatsapp-logo1.png',
//                                     width: 28,
//                                     height: 28,

//                                     // color: const Color(0xFF25D366),
//                                   ),
//                                   label: Text(
//                                     'Buy via WhatsApp',
//                                     style: theme.textTheme.titleSmall?.copyWith(
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                                   ),
//                                   style: OutlinedButton.styleFrom(
//                                     foregroundColor: const Color(0xFF25D366),
//                                     side: const BorderSide(
//                                       color: Color(0xFF25D366),
//                                     ),
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(
//                                         AppSpacing.radiusMd,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],

//                     // ── STEP: Phone verification for trial ──
//                     if (_step == 'phone') ...[
//                       Card(
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(
//                             AppSpacing.radiusLg,
//                           ),
//                         ),
//                         child: Padding(
//                           padding: const EdgeInsets.all(AppSpacing.xl),
//                           child: Column(
//                             children: [
//                               // Back button
//                               Align(
//                                 alignment: Alignment.centerLeft,
//                                 child: TextButton.icon(
//                                   onPressed: () =>
//                                       setState(() => _step = 'choose'),
//                                   icon: const Icon(Icons.arrow_back, size: 18),
//                                   label: const Text('Back'),
//                                   style: TextButton.styleFrom(
//                                     foregroundColor: cs.onSurfaceVariant,
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(height: AppSpacing.md),

//                               Icon(
//                                 Icons.phone_android_rounded,
//                                 color: AppColors.seed,
//                                 size: 48,
//                               ),
//                               const SizedBox(height: AppSpacing.md),
//                               Text(
//                                 'Verify Your Phone Number',
//                                 style: theme.textTheme.titleLarge?.copyWith(
//                                   fontWeight: FontWeight.w800,
//                                 ),
//                               ),
//                               const SizedBox(height: AppSpacing.xs),
//                               Text(
//                                 'We need your phone number to set up your 14-day free trial. We may contact you via WhatsApp about your subscription.',
//                                 style: theme.textTheme.bodyMedium?.copyWith(
//                                   color: cs.onSurfaceVariant,
//                                   height: 1.5,
//                                 ),
//                                 textAlign: TextAlign.center,
//                               ),
//                               const SizedBox(height: AppSpacing.xl),

//                               TextField(
//                                 controller: _phoneController,
//                                 keyboardType: TextInputType.phone,
//                                 style: theme.textTheme.titleMedium?.copyWith(
//                                   fontWeight: FontWeight.w700,
//                                   letterSpacing: 1,
//                                 ),
//                                 decoration: InputDecoration(
//                                   labelText: 'Phone Number',
//                                   hintText: '0315-3507075',
//                                   prefixIcon: const Icon(Icons.phone_outlined),
//                                   prefixText: '+92 ',
//                                   filled: true,
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(
//                                       AppSpacing.radiusMd,
//                                     ),
//                                   ),
//                                 ),
//                                 onSubmitted: (_) => _startTrialWithPhone(),
//                               ),

//                               if (_phoneError != null) ...[
//                                 const SizedBox(height: AppSpacing.md),
//                                 Container(
//                                   width: double.infinity,
//                                   padding: const EdgeInsets.all(AppSpacing.md),
//                                   decoration: BoxDecoration(
//                                     color: AppColors.danger.withValues(
//                                       alpha: 0.08,
//                                     ),
//                                     borderRadius: BorderRadius.circular(
//                                       AppSpacing.radiusSm,
//                                     ),
//                                     border: Border.all(
//                                       color: AppColors.danger.withValues(
//                                         alpha: 0.25,
//                                       ),
//                                     ),
//                                   ),
//                                   child: Row(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Icon(
//                                         Icons.error_outline,
//                                         color: AppColors.danger,
//                                         size: 18,
//                                       ),
//                                       const SizedBox(width: AppSpacing.sm),
//                                       Expanded(
//                                         child: Text(
//                                           _phoneError!,
//                                           style: theme.textTheme.bodySmall
//                                               ?.copyWith(
//                                                 color: AppColors.danger,
//                                                 fontWeight: FontWeight.w600,
//                                               ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],

//                               const SizedBox(height: AppSpacing.xl),

//                               SizedBox(
//                                 width: double.infinity,
//                                 height: 52,
//                                 child: FilledButton(
//                                   onPressed: _phoneLoading
//                                       ? null
//                                       : _startTrialWithPhone,
//                                   style: FilledButton.styleFrom(
//                                     backgroundColor: AppColors.seed,
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(
//                                         AppSpacing.radiusMd,
//                                       ),
//                                     ),
//                                   ),
//                                   child: _phoneLoading
//                                       ? const SizedBox(
//                                           width: 24,
//                                           height: 24,
//                                           child: CircularProgressIndicator(
//                                             strokeWidth: 2.5,
//                                             color: Colors.white,
//                                           ),
//                                         )
//                                       : Row(
//                                           mainAxisAlignment:
//                                               MainAxisAlignment.center,
//                                           children: [
//                                             const Icon(
//                                               Icons.rocket_launch_outlined,
//                                               size: 20,
//                                             ),
//                                             const SizedBox(
//                                               width: AppSpacing.sm,
//                                             ),
//                                             Text(
//                                               'Start 14-Day Free Trial',
//                                               style: theme.textTheme.titleSmall
//                                                   ?.copyWith(
//                                                     color: Colors.white,
//                                                     fontWeight: FontWeight.w700,
//                                                   ),
//                                             ),
//                                           ],
//                                         ),
//                                 ),
//                               ),

//                               const SizedBox(height: AppSpacing.md),
//                               Text(
//                                 'Your trial starts immediately after verification.\nFull access to all Premium features for 14 days.',
//                                 style: theme.textTheme.bodySmall?.copyWith(
//                                   color: cs.onSurfaceVariant,
//                                   height: 1.5,
//                                 ),
//                                 textAlign: TextAlign.center,
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],

//                     // ── Continue with Free Plan ──
//                     if (LicenseService.trialStartDate != null &&
//                         !LicenseService.isTrialActive &&
//                         !LicenseService.isActivated)
//                       Padding(
//                         padding: const EdgeInsets.only(top: AppSpacing.sm),
//                         child: TextButton(
//                           onPressed: () => Get.offAllNamed('/'),
//                           child: Text(
//                             'Continue with Free Plan (${LicenseService.freeMaxProducts} products max)',
//                             style: TextStyle(
//                               color: cs.onSurfaceVariant,
//                               fontSize: 13,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                       ),

//                     const SizedBox(height: AppSpacing.xl),

//                     // ── Device ID ──
//                     FutureBuilder<String>(
//                       future: LicenseService.deviceId,
//                       builder: (context, snapshot) {
//                         if (!snapshot.hasData) return const SizedBox.shrink();
//                         final deviceId = snapshot.data!;
//                         return Container(
//                           padding: const EdgeInsets.all(AppSpacing.md),
//                           decoration: BoxDecoration(
//                             color: cs.surfaceContainerHighest.withValues(
//                               alpha: 0.4,
//                             ),
//                             borderRadius: BorderRadius.circular(
//                               AppSpacing.radiusSm,
//                             ),
//                           ),
//                           child: Row(
//                             children: [
//                               Icon(
//                                 Icons.devices,
//                                 size: 16,
//                                 color: cs.onSurfaceVariant,
//                               ),
//                               const SizedBox(width: AppSpacing.sm),
//                               Expanded(
//                                 child: Text(
//                                   'Device: ${deviceId.length > 20 ? deviceId.substring(0, 20) : deviceId}...',
//                                   style: theme.textTheme.bodySmall?.copyWith(
//                                     color: cs.onSurfaceVariant,
//                                     fontFamily: 'monospace',
//                                     fontSize: 11,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         );
//                       },
//                     ),

//                     const SizedBox(height: AppSpacing.xl),

//                     // ── Footer ──
//                     Column(
//                       children: [
//                         Text(
//                           'Need help? Contact support',
//                           style: theme.textTheme.bodySmall?.copyWith(
//                             color: cs.onSurfaceVariant,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(
//                               Icons.call,
//                               size: 14,
//                               color: cs.onSurfaceVariant,
//                             ),
//                             const SizedBox(width: 4),
//                             Text(
//                               '0315-3507075',
//                               style: theme.textTheme.bodySmall?.copyWith(
//                                 color: cs.onSurfaceVariant,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: AppSpacing.lg),
//                         Text(
//                           'Powered by Codynest.com',
//                           style: theme.textTheme.labelSmall?.copyWith(
//                             color: cs.onSurfaceVariant.withValues(alpha: 0.6),
//                             letterSpacing: 1,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/app/widgets/app_widgets.dart';
import 'package:ad_shop_pos/app/utils/launcher.dart';
import 'package:ad_shop_pos/data/services/license_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  // ── Business logic (UNCHANGED) ──
  final _keyController = TextEditingController();
  bool _loading = false;
  String? _error;

  final _phoneController = TextEditingController();
  bool _phoneLoading = false;
  String? _phoneError;

  bool _trialEligible = true;
  bool _checkingTrialEligibility = true;
  String _step = 'choose';
  bool expanded = false;

  @override
  void initState() {
    super.initState();
    _checkTrialEligibility();
  }

  @override
  void dispose() {
    _keyController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _checkTrialEligibility() async {
    if (LicenseService.hasUsedTrial || LicenseService.isActivated) {
      setState(() {
        _trialEligible = false;
        _checkingTrialEligibility = false;
      });
      return;
    }
    final eligible = await LicenseService.checkDeviceTrialEligibility();
    if (!mounted) return;
    setState(() {
      _trialEligible = eligible != false;
      _checkingTrialEligibility = false;
    });
  }

  Future<void> _activate() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      setState(() => _error = 'Please enter a license key');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await LicenseService.validateLicense(key);
    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      LicenseService.clearDeactivationReason();
      Get.offAllNamed('/pin-setup');
    } else {
      setState(() => _error = result.message);
    }
  }

  bool _isValidPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    return digits.length >= 8 && digits.length <= 15;
  }

  String _phoneToInternational(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.startsWith('03')) return '92${digits.substring(1)}';
    return digits;
  }

  Future<void> _startTrialWithPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _phoneError = 'Please enter your phone number');
      return;
    }
    if (!_isValidPhone(phone)) {
      setState(
        () => _phoneError = 'Enter a valid phone number (e.g. 0315-3507075)',
      );
      return;
    }

    setState(() {
      _phoneLoading = true;
      _phoneError = null;
    });

    final eligible = await LicenseService.checkDeviceTrialEligibility();
    if (eligible == false) {
      if (!mounted) return;
      await LicenseService.markTrialAlreadyUsed();
      setState(() {
        _trialEligible = false;
        _phoneLoading = false;
        _step = 'choose';
      });
      Get.snackbar(
        'Trial Already Used',
        'This device has already used a free trial. Activate a license or continue with the free plan.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final intlPhone = _phoneToInternational(phone);
    await LicenseService.startTrial(customerPhone: intlPhone);

    if (!mounted) return;
    setState(() => _phoneLoading = false);
    LicenseService.clearDeactivationReason();
    Get.offAllNamed('/pin-setup');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    const breakpoint = 768.0;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.8,
            colors: [cs.primary.withOpacity(0.03), cs.surface],
            stops: const [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xxl,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1024),
                child: Column(
                  children: [
                    // ── Header ──
                    Image.asset(
                      'lib/assets/images/cn_pos_logo_rm.png',
                      width: 90,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Codynest POS',
                      style: GoogleFonts.righteous(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        fontSize: 24,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Choose an option below to get started.',
                      style: GoogleFonts.poppins(color: cs.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // ── Banners ──
                    if (LicenseService.trialStartDate != null &&
                        !LicenseService.isTrialActive &&
                        !LicenseService.isActivated)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: AppBanner.warning(
                          title: 'Free Trial Expired',
                          subtitle:
                              'Your 14-day free trial has ended. Activate a license or continue with the free plan (${LicenseService.freeMaxProducts} products max).',
                          icon: Icons.timer_off_outlined,
                        ),
                      ),
                    if (LicenseService.hasDeactivationReason)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: AppBanner.danger(
                          title: 'License Deactivated',
                          subtitle:
                              '${LicenseService.deactivationReason} Contact: 0315-3507075',
                          icon: Icons.warning_amber_rounded,
                        ),
                      ),

                    // ── Main Content Switcher ──
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, animation) {
                        final slideAnimation =
                            Tween<Offset>(
                              begin: const Offset(0.0, 0.1),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeInOutCubic,
                              ),
                            );
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: slideAnimation,
                            child: child,
                          ),
                        );
                      },
                      child: LayoutBuilder(
                        key: ValueKey(_step),
                        builder: (context, constraints) {
                          if (_step == 'phone') {
                            return _buildPhoneVerificationCard(context);
                          }
                          // ── Responsive Layout: Column on mobile, Row on tablet/desktop ──
                          if (constraints.maxWidth > breakpoint) {
                            return _buildDesktopLayout(context);
                          } else {
                            return _buildMobileLayout(context);
                          }
                        },
                      ),
                    ),

                    // ── Conditional "Continue with Free Plan" ──
                    if (LicenseService.trialStartDate != null &&
                        !LicenseService.isTrialActive &&
                        !LicenseService.isActivated)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.lg),
                        child: TextButton(
                          onPressed: () => Get.offAllNamed('/'),
                          child: Text(
                            'Continue with Free Plan (${LicenseService.freeMaxProducts} products max)',
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: AppSpacing.xxl),
                    _buildFooter(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── UI Builder Methods for different layouts and steps ──

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_trialEligible && !LicenseService.isActivated) ...[
          _buildTrialCard(context),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Text(
                    'OR',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
          ),
        ],
        _buildActivationCard(context),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_trialEligible && !LicenseService.isActivated) ...[
            Expanded(child: _buildTrialCard(context)),
            const SizedBox(width: AppSpacing.lg),
          ],
          Expanded(child: _buildActivationCard(context)),
        ],
      ),
    );
  }

  Widget _buildTrialCard(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: InkWell(
        onTap: _checkingTrialEligibility
            ? null
            : () => setState(() => _step = 'phone'),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.seed.withOpacity(0.15),
                AppColors.seed.withOpacity(0.05),
              ],
            ),
            border: Border.all(color: AppColors.seed.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.rocket_launch_outlined,
                  color: AppColors.seed,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Text(
              //   'Start 14-Day Free Trial',
              //   style: theme.textTheme.titleLarge?.copyWith(
              //     fontWeight: FontWeight.bold,
              //     color: AppColors.seed,

              //   ),
              //   textAlign: TextAlign.center,
              // ),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                    fontSize: 16,
                  ),
                  children: [
                    const TextSpan(text: 'Start '),
                    TextSpan(
                      text: '14-Day',
                      style: GoogleFonts.poppins(
                        color: AppColors.seed,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const TextSpan(text: ' Free Trial'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Get full access to all premium features. No credit card required.',
                style: GoogleFonts.poppins(
                  color: cs.onSurfaceVariant.withOpacity(0.8),
                  height: 1.5,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_checkingTrialEligibility) const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivationCard(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return StatefulBuilder(
      builder: (context, setCardState) {
        return Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: cs.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // ─────────────────────────────────────
              // COLLAPSED HEADER
              // ─────────────────────────────────────
              InkWell(
                onTap: () {
                  setCardState(() {
                    expanded = !expanded;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(
                            alpha: expanded ? 0.14 : 0.08,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                        child: Icon(
                          Icons.vpn_key_rounded,
                          color: AppColors.seed.withValues(
                            alpha: expanded ? 0.9 : 0.7,
                          ),
                          size: 22,
                        ),
                      ),

                      const SizedBox(width: AppSpacing.md),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Activate License',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Already have a license key?',
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),

                      AnimatedRotation(
                        turns: expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: cs.onSurfaceVariant,
                          size: 25,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ─────────────────────────────────────
              // ANIMATED CONTENT
              // ─────────────────────────────────────
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                firstCurve: Curves.easeOut,
                secondCurve: Curves.easeInOut,
                sizeCurve: Curves.easeOutCubic,
                crossFadeState: expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox(width: double.infinity, height: 0),
                secondChild: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Divider(
                        height: 1,
                        color: cs.outlineVariant.withValues(alpha: 0.25),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      Text(
                        'Unlock your full POS experience',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Enter the license key provided with your Codynest POS subscription.',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          height: 1.5,
                          color: cs.onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // ─────────────────────────────
                      // LICENSE FIELD
                      // ─────────────────────────────
                      TextField(
                        controller: _keyController,
                        textCapitalization: TextCapitalization.characters,
                        style: GoogleFonts.robotoMono(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                        decoration: InputDecoration(
                          labelText: 'License Key',
                          hintText: 'CNPO-XXXX-XXXX-XXXX',
                          prefixIcon: Icon(Icons.key, color: AppColors.seed),
                          filled: true,
                          fillColor: cs.surfaceContainerHighest.withValues(
                            alpha: 0.35,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            borderSide: BorderSide(
                              color: cs.outlineVariant.withValues(alpha: 0.35),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            borderSide: BorderSide(
                              color: cs.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                        onSubmitted: (_) => _activate(),
                      ),

                      // ─────────────────────────────
                      // ERROR
                      // ─────────────────────────────
                      if (_error != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        _buildErrorBox(_error!, theme),
                      ],

                      const SizedBox(height: AppSpacing.lg),

                      // ─────────────────────────────
                      // ACTIVATE BUTTON
                      // ─────────────────────────────
                      SizedBox(
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: _loading ? null : _activate,
                          style: FilledButton.styleFrom(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd,
                              ),
                            ),
                          ),
                          icon: _loading
                              ? const SizedBox.shrink()
                              : const Icon(Icons.verified_rounded, size: 19),
                          label: _loading
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: cs.onPrimary,
                                  ),
                                )
                              : Text(
                                  'Activate License',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // ─────────────────────────────
                      // WHATSAPP
                      // ─────────────────────────────
                      SizedBox(
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: () => Launcher.openWhatsApp(
                            '923153507075',
                            'Hi! I want to buy a Codynest POS license key. ',
                          ),
                          icon: Image.asset(
                            'lib/assets/images/whatsapp-logo1.png',
                            width: 22,
                            height: 22,
                          ),
                          label: Text(
                            'Need a license? Buy via WhatsApp',
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF075E54),
                            side: BorderSide(
                              color: const Color(
                                0xFF075E54,
                              ).withValues(alpha: 0.25),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget _buildActivationCard(BuildContext context) {
  //   final theme = Theme.of(context);
  //   final cs = theme.colorScheme;
  //   return Card(
  //     elevation: 0,
  //     margin: EdgeInsets.zero,
  //     color: cs.surfaceContainerLowest,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
  //       side: BorderSide(color: cs.outlineVariant.withOpacity(0.3)),
  //     ),
  //     child: Padding(
  //       padding: const EdgeInsets.all(AppSpacing.xl),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.stretch,
  //         children: [
  //           Text(
  //             'Activate Your License',
  //             style: GoogleFonts.poppins(
  //               fontWeight: FontWeight.bold,
  //               fontSize: 18,
  //             ),
  //           ),
  //           const SizedBox(height: AppSpacing.sm),
  //           Text(
  //             'Have a license key? Enter it here to unlock the full version.',
  //             style: GoogleFonts.poppins(
  //               color: cs.onSurfaceVariant,
  //               fontSize: context.textTheme.bodySmall?.fontSize,
  //             ),
  //           ),
  //           const SizedBox(height: AppSpacing.xl),
  //           TextField(
  //             controller: _keyController,
  //             textCapitalization: TextCapitalization.characters,
  //             style: theme.textTheme.titleMedium?.copyWith(
  //               fontWeight: FontWeight.w700,
  //               letterSpacing: 3,
  //               fontFamily: 'monospace',
  //             ),
  //             decoration: InputDecoration(
  //               labelText: 'License Key',
  //               hintText: 'CNPO-XXXX-XXXX-XXXX',
  //               prefixIcon: const Icon(Icons.vpn_key_outlined),
  //               border: OutlineInputBorder(
  //                 borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
  //               ),
  //             ),
  //             onSubmitted: (_) => _activate(),
  //           ),
  //           if (_error != null) ...[
  //             const SizedBox(height: AppSpacing.md),
  //             _buildErrorBox(_error!, theme),
  //           ],
  //           const SizedBox(height: AppSpacing.xl),
  //           SizedBox(
  //             height: 52,
  //             child: FilledButton.icon(
  //               onPressed: _loading ? null : _activate,
  //               style: FilledButton.styleFrom(
  //                 shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
  //                 ),
  //               ),
  //               icon: _loading
  //                   ? const SizedBox.shrink()
  //                   : const Icon(Icons.verified_user_outlined, size: 20),
  //               label: _loading
  //                   ? SizedBox(
  //                       width: 24,
  //                       height: 24,
  //                       child: CircularProgressIndicator(
  //                         strokeWidth: 2.5,
  //                         color: cs.onPrimary,
  //                       ),
  //                     )
  //                   : Text(
  //                       'Activate License',
  //                       style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
  //                     ),
  //             ),
  //           ),
  //           const SizedBox(height: AppSpacing.lg),
  //           SizedBox(
  //             height: 48,
  //             child: OutlinedButton.icon(
  //               onPressed: () => Launcher.openWhatsApp(
  //                 '923153507075',
  //                 'Hi! I want to buy a Codynest POS license key. My device ID: ${LicenseService.deviceId}',
  //               ),
  //               icon: Image.asset(
  //                 'lib/assets/images/whatsapp-logo1.png',
  //                 width: 24,
  //                 height: 24,
  //               ),
  //               label: Text(
  //                 'Buy via WhatsApp',
  //                 style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
  //               ),
  //               style: OutlinedButton.styleFrom(
  //                 foregroundColor: const Color(0xFF075E54),
  //                 side: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
  //                 shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildPhoneVerificationCard(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Card(
        elevation: 2,
        shadowColor: cs.primary.withOpacity(0.1),
        margin: EdgeInsets.zero,
        color: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          side: BorderSide(color: cs.outlineVariant.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _step = 'choose'),
                  icon: const Icon(Icons.arrow_back, size: 20),
                  label: const Text('Back'),
                  style: TextButton.styleFrom(
                    foregroundColor: cs.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Icon(
                Icons.phone_android_rounded,
                color: AppColors.seed,
                size: 40,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Just one more step',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Enter your phone number to start your 14-day trial.',
                style: GoogleFonts.poppins(
                  color: cs.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  // hintText: '3153507075',
                  prefixIcon: const Icon(
                    Icons.phone_outlined,
                    color: AppColors.seed,
                  ),
                  // prefixText: '+92 ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                onSubmitted: (_) => _startTrialWithPhone(),
              ),
              if (_phoneError != null) ...[
                const SizedBox(height: AppSpacing.md),
                _buildErrorBox(_phoneError!, theme),
              ],
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _phoneLoading ? null : _startTrialWithPhone,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.seed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  icon: _phoneLoading
                      ? const SizedBox.shrink()
                      : const Icon(Icons.rocket_launch_outlined, size: 20),
                  label: _phoneLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Confirm & Start Trial',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBox(String error, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.danger, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              error,
              style: GoogleFonts.poppins(color: AppColors.danger, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      children: [
        FutureBuilder<String>(
          future: LicenseService.deviceId,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final deviceId = snapshot.data!;
            return Tooltip(
              message: 'Copy Device ID',
              child: InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: deviceId));
                  Get.snackbar(
                    'Copied to Clipboard',
                    'Device ID: $deviceId',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: cs.inverseSurface,
                    colorText: cs.onInverseSurface,
                    borderRadius: AppSpacing.radiusMd,
                    margin: const EdgeInsets.all(AppSpacing.md),
                  );
                },
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.perm_device_information_rounded,
                        size: 16,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          'Device ID: $deviceId',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontFamily: 'monospace',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Icon(
                        Icons.copy_all_outlined,
                        size: 14,
                        color: cs.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Need help? Contact support at 0315-3507075',
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Powered by Codynest.com',
          style: theme.textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant.withOpacity(0.6),
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
