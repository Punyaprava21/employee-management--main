import 'package:flutter/material.dart';
import 'package:kredipal/widgets/custom_app_bar.dart';

class CreditCardDetailsScreen extends StatelessWidget {
  final String slNo;
  final String name;
  final String bankName;
  final String amount;
  final String statusColor;
  final String phoneNo;
  final String email;
  final String location;

  const CreditCardDetailsScreen({
    super.key,
    required this.slNo,
    required this.name,
    required this.bankName,
    required this.amount,
    required this.statusColor,
    required this.phoneNo,
    required this.email,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    final statusColorValue = Color(int.parse(statusColor));
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: CustomAppBar(
        title: 'Credit Card Details',
        actions: [],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCreditCardVisual(context, statusColorValue),
              const SizedBox(height: 24),
              _buildApplicationDetails(statusColorValue),
              const SizedBox(height: 24),
              _buildActionButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreditCardVisual(BuildContext context, Color statusColor) {
    String cardType = _getCardType(bankName);
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            statusColor.withOpacity(0.8),
            statusColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Card pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.network(
                'https://www.transparenttextures.com/patterns/asfalt-dark.png',
                repeat: ImageRepeat.repeat,
                errorBuilder: (context, error, stackTrace) => Container(),
              ),
            ),
          ),
          // Card details
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Card Type and Bank
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      cardType.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Image.network(
                      _getCardBrandLogo(cardType),
                      height: 30,
                      errorBuilder: (context, error, stackTrace) => Container(),
                    ),
                  ],
                ),
                // Card Number (masked)
                Text(
                  '**** **** **** ${slNo.padLeft(4, '0')}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2.0,
                  ),
                ),
                // Card Holder & Amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Card Holder',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Credit Limit',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '₹$amount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationDetails(Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Application Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusLabel(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 16),
          _buildDetailTile('Application No.', slNo, statusColor),
          _buildDetailTile('Bank Name', bankName, statusColor),
          _buildDetailTile('Phone Number', phoneNo, statusColor),
          _buildDetailTile('Email', email, statusColor),
          _buildDetailTile('Location', location, statusColor),
        ],
      ),
    );
  }

  Widget _buildDetailTile(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
        child: const Text(
          'Back to List',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  String _getStatusLabel() {
    if (statusColor == '0xFF60A5FA') return 'Applied';
    if (statusColor == '0xFF4CAF50') return 'Approved';
    if (statusColor == '0xFFEF5350') return 'Rejected';
    if (statusColor == '0xFFFF9800') return 'Commission';
    return 'Unknown';
  }

  String _getCardType(String bankName) {
    bankName = bankName.toLowerCase();
    if (bankName.contains('visa')) return 'Visa';
    if (bankName.contains('master')) return 'MasterCard';
    if (bankName.contains('amex')) return 'American Express';
    if (bankName.contains('discover')) return 'Discover';
    return 'Visa';
  }

  String _getCardBrandLogo(String cardType) {
    switch (cardType.toLowerCase()) {
      case 'visa':
        return 'https://upload.wikimedia.org/wikipedia/commons/4/41/Visa_Logo.png';
      case 'mastercard':
        return 'https://upload.wikimedia.org/wikipedia/commons/2/2a/Mastercard-logo.svg';
      case 'american express':
        return 'https://upload.wikimedia.org/wikipedia/commons/3/30/American_Express_logo.svg';
      case 'discover':
        return 'https://upload.wikimedia.org/wikipedia/commons/5/5e/Discover_Card_logo.svg';
      default:
        return 'https://upload.wikimedia.org/wikipedia/commons/4/41/Visa_Logo.png';
    }
  }
}
