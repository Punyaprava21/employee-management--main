import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kredipal/views/credit_card_details_screen.dart';
import 'package:kredipal/widgets/custom_app_bar.dart';

class CreditCardScreen extends StatefulWidget {
  const CreditCardScreen({super.key});

  @override
  _CreditCardScreenState createState() => _CreditCardScreenState();
}

class _CreditCardScreenState extends State<CreditCardScreen> {
  String? _selectedSection;
  String? _selectedFilter;
  String? _selectedMonth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(title: 'Credit Card', actions: [
        IconButton(
          onPressed: () => _showFilter(),
          icon: const Icon(
            Icons.filter_list,
            size: 22,
            color: Colors.white,
          ),
        ),
      ]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 0, bottom: 10),
              child: _buildSectionTitle(
                _selectedMonth != null
                    ? 'This Month: $_selectedMonth'
                    : 'This Month',
              ),
            ),
            _buildGridView(context),
            const SizedBox(height: 12),
            _buildTotalSummary(),
            if (_selectedSection != null) ...[
              const SizedBox(height: 16),
              _buildSectionTitle(
                (_selectedFilter ?? _selectedSection!) +
                    (_selectedMonth != null ? ' - $_selectedMonth' : ''),
              ),
              _buildListView(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 5),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }

  void _showFilter() {
    String? tempFilter = _selectedFilter;
    String? tempMonth = _selectedMonth;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Text(
                        'Filter Options',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Month',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      ...['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']
                          .map((month) => _buildFilterItem(
                                label: month,
                                color: Colors.teal,
                                isSelected: tempMonth == month,
                                onTap: () {
                                  setModalState(() {
                                    tempMonth = month;
                                  });
                                },
                              ))
                          .toList(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedFilter = tempFilter;
                          _selectedMonth = tempMonth;
                          _selectedSection = _selectedFilter ?? _selectedSection;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'Apply Filter',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterItem({
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? color : Colors.transparent,
                border: Border.all(color: color),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isSelected ? color : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(BuildContext context) {
    // Calculate counts based on selected month
    final appliedCount = _appliedItems()
        .where((item) => _selectedMonth == null || item['month'] == _selectedMonth)
        .length
        .toString();
    final approvedCount = _approvedItems()
        .where((item) => _selectedMonth == null || item['month'] == _selectedMonth)
        .length
        .toString();
    final rejectedCount = _rejectedItems()
        .where((item) => _selectedMonth == null || item['month'] == _selectedMonth)
        .length
        .toString();
    final commissionCount = _commissionItems()
        .where((item) => _selectedMonth == null || item['month'] == _selectedMonth)
        .fold<int>(0, (sum, item) => sum + (int.tryParse(item['Amount'] ?? '0') ?? 0))
        .toString();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.0,
      children: [
        _buildGridItem(
          label: 'Applied',
          value: appliedCount,
          icon: Icons.pending_actions_rounded,
          textColor: const Color(0xFF60A5FA),
        ),
        _buildGridItem(
          label: 'Approved',
          value: approvedCount,
          icon: Icons.check_circle_rounded,
          textColor: const Color(0xFF4CAF50),
        ),
        _buildGridItem(
          label: 'Rejected',
          value: rejectedCount,
          icon: Icons.cancel_rounded,
          textColor: const Color(0xFFEF5350),
        ),
        _buildGridItem(
          label: 'Commission',
          value: commissionCount,
          icon: Icons.attach_money_rounded,
          textColor: const Color(0xFFFF9800),
        ),
      ],
    );
  }

  Widget _buildGridItem({
    required String label,
    required String value,
    required IconData icon,
    required Color textColor,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSection = (_selectedSection == label) ? null : label;
          _selectedFilter = null;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSummary() {
    final totalApplications = (_appliedItems() + _approvedItems() + _rejectedItems())
        .where((item) => _selectedMonth == null || item['month'] == _selectedMonth)
        .length;
    final totalCommission = (_commissionItems())
        .where((item) => _selectedMonth == null || item['month'] == _selectedMonth)
        .fold<int>(0, (sum, item) => sum + (int.tryParse(item['Amount'] ?? '0') ?? 0));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Applications: $totalApplications',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          Text(
            'Total Commission: ₹$totalCommission',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(BuildContext context) {
    List<Map<String, String>> items;
    String sectionToShow = _selectedFilter ?? _selectedSection ?? '';

    switch (sectionToShow) {
      case 'Applied':
        items = _appliedItems();
        break;
      case 'Approved':
        items = _approvedItems();
        break;
      case 'Rejected':
        items = _rejectedItems();
        break;
      case 'Commission':
        items = _commissionItems();
        break;
      default:
        items = [];
    }

    if (_selectedMonth != null) {
      items = items.where((item) => item['month'] == _selectedMonth).toList();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildListItem(
          slNo: item['sl no']!,
          name: item['Name']!,
          bankName: item['Bank Name']!,
          amount: item['Amount']!,
          phoneNo: item['Phone no']!,
          email: item['email']!,
          location: item['location']!,
          statusColor: item['statusColor']!,
          index: index,
          context: context,
        );
      },
    );
  }

  Widget _buildListItem({
    required String slNo,
    required String name,
    required String bankName,
    required String amount,
    required String phoneNo,
    required String email,
    required String location,
    required String statusColor,
    required int index,
    required BuildContext context,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 120,
            decoration: BoxDecoration(
              color: Color(int.parse(statusColor)),
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sl No: $slNo',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        'Name: $name',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bank: $bankName',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      'Amount: ₹$amount',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Phone No: $phoneNo',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Email: $email',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'Location: $location',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              Get.to(() => CreditCardDetailsScreen(
                    slNo: slNo,
                    name: name,
                    bankName: bankName,
                    amount: amount,
                    phoneNo: phoneNo,
                    email: email,
                    location: location,
                    statusColor: statusColor,
                  ));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(int.parse(statusColor)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'View',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(int.parse(statusColor)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _appliedItems() {
    return [
      {
        'sl no': '1',
        'Name': 'Punya',
        'Bank Name': 'SBI',
        'Amount': '4000',
        'Phone no': '8144021906',
        'email': 'punyapravasahoo17@gmail.com',
        'location': 'Bhubaneswar, Odisha',
        'statusColor': '0xFF60A5FA',
        'month': 'June',
      },
      {
        'sl no': '2',
        'Name': 'Jayashree',
        'Bank Name': 'HDFC',
        'Amount': '3000',
        'Phone no': '8797345621',
        'email': 'jjena2002@gmail.com',
        'location': 'Cuttack, Odisha',
        'statusColor': '0xFF60A5FA',
        'month': 'May',
      },
      {
        'sl no': '3',
        'Name': 'Susant',
        'Bank Name': 'ICICI',
        'Amount': '4000',
        'Phone no': '8797345621',
        'email': 'susants2001@gmail.com',
        'location': 'Puri, Odisha',
        'statusColor': '0xFF60A5FA',
        'month': 'June',
      },
    ];
  }

  List<Map<String, String>> _approvedItems() {
    return [
      {
        'sl no': '1',
        'Name': 'Ravi',
        'Bank Name': 'SBI',
        'Amount': '5000',
        'Phone no': '9876543210',
        'email': 'ravi.kumar@gmail.com',
        'location': 'Delhi, India',
        'statusColor': '0xFF4CAF50',
        'month': 'June',
      },
      {
        'sl no': '2',
        'Name': 'Anita',
        'Bank Name': 'HDFC',
        'Amount': '4500',
        'Phone no': '8765432109',
        'email': 'anita.sharma@gmail.com',
        'location': 'Mumbai, Maharashtra',
        'statusColor': '0xFF4CAF50',
        'month': 'April',
      },
      {
        'sl no': '3',
        'Name': 'Vikram',
        'Bank Name': 'ICICI',
        'Amount': '6000',
        'Phone no': '7654321098',
        'email': 'vikram.singh@gmail.com',
        'location': 'Bangalore, Karnataka',
        'statusColor': '0xFF4CAF50',
        'month': 'June',
      },
    ];
  }

  List<Map<String, String>> _rejectedItems() {
    return [
      {
        'sl no': '1',
        'Name': 'Suresh',
        'Bank Name': 'Axis',
        'Amount': '3500',
        'Phone no': '6543210987',
        'email': 'suresh.verma@gmail.com',
        'location': 'Chennai, Tamil Nadu',
        'statusColor': '0xFFEF5350',
        'month': 'June',
      },
      {
        'sl no': '2',
        'Name': 'Neha',
        'Bank Name': 'SBI',
        'Amount': '4000',
        'Phone no': '5432109876',
        'email': 'neha.mehta@gmail.com',
        'location': 'Kolkata, West Bengal',
        'statusColor': '0xFFEF5350',
        'month': 'March',
      },
      {
        'sl no': '3',
        'Name': 'Kiran',
        'Bank Name': 'HDFC',
        'Amount': '3200',
        'Phone no': '4321098765',
        'email': 'kiran.patel@gmail.com',
        'location': 'Ahmedabad, Gujarat',
        'statusColor': '0xFFEF5350',
        'month': 'June',
      },
    ];
  }

  List<Map<String, String>> _commissionItems() {
    return [
      {
        'sl no': '1',
        'Name': 'Pooja',
        'Bank Name': 'ICICI',
        'Amount': '2000',
        'Phone no': '3210987654',
        'email': 'pooja.rani@gmail.com',
        'location': 'Hyderabad, Telangana',
        'statusColor': '0xFFFF9800',
        'month': 'June',
      },
      {
        'sl no': '2',
        'Name': 'Amit',
        'Bank Name': 'SBI',
        'Amount': '1500',
        'Phone no': '2109876543',
        'email': 'amit.jain@gmail.com',
        'location': 'Jaipur, Rajasthan',
        'statusColor': '0xFFFF9800',
        'month': 'February',
      },
      {
        'sl no': '3',
        'Name': 'Rohit',
        'Bank Name': 'HDFC',
        'Amount': '1500',
        'Phone no': '1098765432',
        'email': 'rohit.sharma@gmail.com',
        'location': 'Pune, Maharashtra',
        'statusColor': '0xFFFF9800',
        'month': 'June',
      },
    ];
  }
}