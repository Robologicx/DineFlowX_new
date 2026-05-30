// import 'package:flutter/material.dart';
// import 'package:hotel_management_system/core/constants/app_colors.dart';
// import 'package:hotel_management_system/presentation/common_widgets/custom_button.dart';

// class PaymentScreen extends StatefulWidget {
//   const PaymentScreen({super.key});

//   @override
//   State<PaymentScreen> createState() => _PaymentScreenState();
// }

// class _PaymentScreenState extends State<PaymentScreen> {
//   String selectedValue = 'Door delivery';
//   String selectedPayment = 'Card';
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.greyColor,
//       appBar: AppBar(
//         title: Text('Checkout'),
//         centerTitle: true,
//         backgroundColor: AppColors.transparentColor,
//         leading: IconButton(
//           onPressed: () {
//             Navigator.pop(context);
//           },
//           icon: Icon(Icons.arrow_back_ios_new_rounded),
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             Text(
//               'Payment',
//               style: Theme.of(context).textTheme.titleLarge!.copyWith(
//                 fontSize: 40,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             SizedBox(height: 30),
//             Center(
//               child: SizedBox(
//                 height: 220,
//                 width: 315,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Payment method',
//                       style: Theme.of(context).textTheme.titleMedium!.copyWith(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     SizedBox(height: 30),
//                     _buildPaymentOptionsCard(context),
//                   ],
//                 ),
//               ),
//             ),
//             SizedBox(height: 30),
//             _buildDeliveryMethodCard(context),
//             Padding(
//               padding: const EdgeInsets.only(left: 30, right: 30),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text('Total', style: TextStyle(fontSize: 20)),
//                   Spacer(),
//                   Text(
//                     '23,000',
//                     style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 15),
//             CustomButton(
//               text: 'Proceed to payment',
//               color: AppColors.backgroundColor,
//               onTap: () {},
//               textColor: AppColors.whiteColor,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPaymentOptionsCard(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.all(16),
//       height: 160,
//       width: 315,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(20),
//         color: AppColors.whiteColor,
//       ),
//       child: Column(
//         children: [
//           RadioListTile<String>(
//             activeColor: AppColors.backgroundColor,
//             onChanged: (val) {
//               setState(() {
//                 selectedPayment = val!;
//               });
//             },
//             value: 'Card',
//             groupValue: selectedPayment,
//             title: _buildPaymentOption(
//               color: AppColors.creditcardColor,
//               context,
//               title: 'Card',
//               icon: Icons.credit_card_rounded,
//             ),
//           ),
//           RadioListTile(
//             activeColor: AppColors.backgroundColor,
//             value: 'Bank Account',
//             groupValue: selectedPayment,
//             onChanged: (val) {
//               setState(() {
//                 selectedPayment = val!;
//               });
//             },
//             title: _buildPaymentOption(
//               color: AppColors.bankAccountColor,
//               context,
//               title: 'Bank account',
//               icon: Icons.account_balance,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPaymentOption(
//     BuildContext context, {
//     required String title,
//     required IconData icon,
//     required Color color,
//   }) {
//     return Row(
//       spacing: 15,
//       children: [
//         Container(
//           height: 40,
//           width: 40,
//           decoration: BoxDecoration(
//             color: color,
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: Icon(icon, color: AppColors.whiteColor),
//         ),
//         Text(
//           title,
//           style: Theme.of(context).textTheme.titleMedium!.copyWith(
//             fontSize: 14,
//             color: AppColors.hintTextColor,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildDeliveryMethodCard(BuildContext context) {
//     return SizedBox(
//       height: 289,
//       width: 318,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Delivery Method',
//             style: Theme.of(context).textTheme.titleMedium!.copyWith(
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           SizedBox(height: 30),
//           Container(
//             height: 156,
//             width: 315,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(20),
//               color: AppColors.whiteColor,
//             ),
//             child: Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Column(
//                 children: [
//                   RadioListTile(
//                     activeColor: AppColors.backgroundColor,
//                     value: 'Door delivery',
//                     groupValue: selectedValue,
//                     title: Text('Door delivery'),
//                     onChanged: (value) {
//                       setState(() {
//                         selectedValue = value!;
//                       });
//                     },
//                   ),
//                   Divider(
//                     color: AppColors.hintTextColor,
//                     thickness: 2,
//                     radius: BorderRadius.circular(20),
//                   ),
//                   RadioListTile(
//                     activeColor: AppColors.backgroundColor,
//                     value: 'Pick up',
//                     groupValue: selectedValue,
//                     title: Text('Pick up'),
//                     onChanged: (value) {
//                       setState(() {
//                         selectedValue = value!;
//                       });
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
