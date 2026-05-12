// import 'package:flutter/material.dart';

// class PaymentsScreen extends StatefulWidget {
//   const PaymentsScreen({super.key});

//   @override
//   State<PaymentsScreen> createState() => _PaymentsScreenState();
// }

// class _PaymentsScreenState extends State<PaymentsScreen> {
//   String selectedMethod = 'mtn';

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F7F7),
//       body: SafeArea(
//         child: ListView(
//           padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
//           children: [
//             Align(
//               alignment: Alignment.centerLeft,
//               child: IconButton(
//                 onPressed: () => Navigator.pop(context),
//                 icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
//                 padding: EdgeInsets.zero,
//                 constraints: const BoxConstraints(),
//               ),
//             ),
//             const SizedBox(height: 24),

//             const Text(
//               'Payment methods',
//               style: TextStyle(
//                 fontSize: 28,
//                 fontWeight: FontWeight.w800,
//                 color: Colors.black,
//                 letterSpacing: -0.5,
//               ),
//             ),
//             const SizedBox(height: 38),

//             const _SectionTitle('Cards and accounts'),
//             const SizedBox(height: 16),

//             _WhiteCard(child: _AddCardTile(onTap: () {})),

//             const SizedBox(height: 24),

//             _WhiteCard(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const _SectionTitle('Other methods'),
//                   const SizedBox(height: 20),
//                   _PaymentMethodTile(
//                     logo: const _TelecelLogo(),
//                     title: 'Telecel Cash',
//                     subtitle: 'Pay with mobile money',
//                     selected: selectedMethod == 'telecel',
//                     onTap: () => setState(() => selectedMethod = 'telecel'),
//                   ),
//                   const _TileDivider(),
//                   _PaymentMethodTile(
//                     logo: const _AirtelTigoLogo(),
//                     title: 'Airtel Tigo',
//                     subtitle: 'Pay with mobile money',
//                     selected: selectedMethod == 'airteltigo',
//                     onTap: () => setState(() => selectedMethod = 'airteltigo'),
//                   ),
//                   const _TileDivider(),
//                   _PaymentMethodTile(
//                     logo: const _MtnLogo(),
//                     title: 'MTN',
//                     subtitle: 'Pay with mobile money',
//                     selected: selectedMethod == 'mtn',
//                     onTap: () => setState(() => selectedMethod = 'mtn'),
//                   ),
//                   const _TileDivider(),
//                   _PaymentMethodTile(
//                     logo: const _CashLogo(),
//                     title: 'Cash',
//                     subtitle: null,
//                     selected: selectedMethod == 'cash',
//                     onTap: () => setState(() => selectedMethod = 'cash'),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 24),

//             _WhiteCard(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: const [
//                   _SectionTitle('Unavailable'),
//                   SizedBox(height: 20),
//                   _UnavailablePaymentTile(),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _WhiteCard extends StatelessWidget {
//   final Widget child;

//   const _WhiteCard({required this.child});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(26),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.025),
//             blurRadius: 20,
//             offset: const Offset(0, 10),
//           ),
//         ],
//       ),
//       child: child,
//     );
//   }
// }

// class _SectionTitle extends StatelessWidget {
//   final String text;

//   const _SectionTitle(this.text);

//   @override
//   Widget build(BuildContext context) {
//     return Text(
//       text,
//       style: const TextStyle(
//         fontSize: 22,
//         height: 1.15,
//         fontWeight: FontWeight.w800,
//         color: Colors.black,
//         letterSpacing: -0.3,
//       ),
//     );
//   }
// }

// class _AddCardTile extends StatelessWidget {
//   final VoidCallback onTap;

//   const _AddCardTile({required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(20),
//       child: Row(
//         children: const [
//           _CardLogo(),
//           SizedBox(width: 18),
//           Expanded(
//             child: Text(
//               'Add card',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w500,
//                 color: Colors.black,
//               ),
//             ),
//           ),
//           Icon(Icons.arrow_forward_ios_rounded, size: 20, color: Colors.black),
//         ],
//       ),
//     );
//   }
// }

// class _PaymentMethodTile extends StatelessWidget {
//   final Widget logo;
//   final String title;
//   final String? subtitle;
//   final bool selected;
//   final VoidCallback onTap;

//   const _PaymentMethodTile({
//     required this.logo,
//     required this.title,
//     required this.subtitle,
//     required this.selected,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(20),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 14),
//         child: Row(
//           children: [
//             SizedBox(width: 70, child: Center(child: logo)),
//             const SizedBox(width: 14),

//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     style: const TextStyle(
//                       fontSize: 18,
//                       height: 1.15,
//                       fontWeight: FontWeight.w500,
//                       color: Colors.black,
//                     ),
//                   ),
//                   if (subtitle != null) ...[
//                     const SizedBox(height: 4),
//                     Text(
//                       subtitle!,
//                       style: const TextStyle(
//                         fontSize: 15,
//                         height: 1.15,
//                         fontWeight: FontWeight.w400,
//                         color: Color(0xFF999999),
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),

//             AnimatedContainer(
//               duration: const Duration(milliseconds: 180),
//               width: 52,
//               height: 52,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: selected ? const Color(0xFFFF5A3D) : Colors.white,
//                 boxShadow: selected
//                     ? []
//                     : [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.04),
//                           blurRadius: 18,
//                           offset: const Offset(0, 8),
//                         ),
//                       ],
//               ),
//               child: selected
//                   ? const Icon(
//                       Icons.check_rounded,
//                       size: 34,
//                       color: Colors.white,
//                     )
//                   : null,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _TileDivider extends StatelessWidget {
//   const _TileDivider();

//   @override
//   Widget build(BuildContext context) {
//     return const Padding(
//       padding: EdgeInsets.only(left: 84),
//       child: Divider(height: 1, thickness: 1, color: Color(0xFFEAEAEA)),
//     );
//   }
// }

// class _UnavailablePaymentTile extends StatelessWidget {
//   const _UnavailablePaymentTile();

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         const SizedBox(width: 70, child: Center(child: _ApplePayLogo())),
//         const SizedBox(width: 14),
//         const Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Apple Pay',
//                 style: TextStyle(
//                   fontSize: 17,
//                   height: 1.15,
//                   fontWeight: FontWeight.w500,
//                   color: Color(0xFFB8B8B8),
//                 ),
//               ),
//               SizedBox(height: 4),
//               Text(
//                 'Apple Pay currently\nunavailable',
//                 style: TextStyle(
//                   fontSize: 15,
//                   height: 1.2,
//                   fontWeight: FontWeight.w400,
//                   color: Color(0xFFB8B8B8),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         Container(
//           width: 52,
//           height: 52,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: Colors.white,
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.035),
//                 blurRadius: 18,
//                 offset: const Offset(0, 8),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _CardLogo extends StatelessWidget {
//   const _CardLogo();

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 58,
//       height: 36,
//       decoration: BoxDecoration(
//         color: const Color(0xFFFFC9D9),
//         borderRadius: BorderRadius.circular(5),
//       ),
//       child: Stack(
//         children: [
//           Positioned(
//             left: 7,
//             top: 8,
//             child: Container(
//               width: 11,
//               height: 8,
//               decoration: BoxDecoration(
//                 color: const Color(0xFFFFC763),
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//           ),
//           Positioned(
//             left: 8,
//             bottom: 9,
//             child: Row(
//               children: List.generate(
//                 4,
//                 (_) => Container(
//                   margin: const EdgeInsets.only(right: 3),
//                   width: 4,
//                   height: 2.5,
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.9),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           Positioned(
//             right: 7,
//             top: 7,
//             child: Row(
//               children: [
//                 Container(
//                   width: 10,
//                   height: 10,
//                   decoration: BoxDecoration(
//                     color: Colors.pink.withOpacity(0.45),
//                     shape: BoxShape.circle,
//                   ),
//                 ),
//                 Transform.translate(
//                   offset: const Offset(-4, 0),
//                   child: Container(
//                     width: 10,
//                     height: 10,
//                     decoration: BoxDecoration(
//                       color: Colors.red.withOpacity(0.35),
//                       shape: BoxShape.circle,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _TelecelLogo extends StatelessWidget {
//   const _TelecelLogo();

//   @override
//   Widget build(BuildContext context) {
//     return const Text(
//       't\ntelecel',
//       textAlign: TextAlign.center,
//       style: TextStyle(
//         fontSize: 17,
//         height: 0.9,
//         fontWeight: FontWeight.w900,
//         color: Color(0xFFE71921),
//       ),
//     );
//   }
// }

// class _AirtelTigoLogo extends StatelessWidget {
//   const _AirtelTigoLogo();

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 62,
//       height: 34,
//       alignment: Alignment.center,
//       decoration: BoxDecoration(
//         color: const Color(0xFF0055A5),
//         borderRadius: BorderRadius.circular(2),
//       ),
//       child: const Text(
//         'airteltigo',
//         style: TextStyle(
//           fontSize: 12,
//           fontWeight: FontWeight.w800,
//           color: Colors.white,
//         ),
//       ),
//     );
//   }
// }

// class _MtnLogo extends StatelessWidget {
//   const _MtnLogo();

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 62,
//       height: 34,
//       alignment: Alignment.center,
//       color: const Color(0xFFFFCC00),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//         decoration: BoxDecoration(
//           border: Border.all(color: Colors.black, width: 1.6),
//           borderRadius: BorderRadius.circular(50),
//         ),
//         child: const Text(
//           'MTN',
//           style: TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w900,
//             color: Colors.black,
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _CashLogo extends StatelessWidget {
//   const _CashLogo();

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: 62,
//       height: 38,
//       child: Stack(
//         children: [
//           Positioned(
//             left: 0,
//             top: 5,
//             child: Container(
//               width: 38,
//               height: 28,
//               decoration: BoxDecoration(
//                 color: const Color(0xFFD8B777),
//                 borderRadius: BorderRadius.circular(5),
//               ),
//             ),
//           ),
//           Positioned(
//             right: 0,
//             top: 8,
//             child: Container(
//               width: 38,
//               height: 28,
//               decoration: BoxDecoration(
//                 color: const Color(0xFF8A5A2B),
//                 borderRadius: BorderRadius.circular(5),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _ApplePayLogo extends StatelessWidget {
//   const _ApplePayLogo();

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 62,
//       height: 32,
//       alignment: Alignment.center,
//       color: Colors.black,
//       child: const Text(
//         'Pay',
//         style: TextStyle(
//           fontSize: 18,
//           fontWeight: FontWeight.w700,
//           color: Colors.white,
//         ),
//       ),
//     );
//   }
// }
