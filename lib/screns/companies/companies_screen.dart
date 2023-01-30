import 'package:els/screns/companies/top_button.dart';
import 'package:flutter/material.dart';
import '../../helper/class_colors.dart';
import 'cart_info_companies.dart';

///Компании =======================================

class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Container(
      color: ColorApp.myColorTransparent,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: const [
            TopButtonCompanies(),
            SizedBox(height: 20.0),
            CartInfoCompanies(),
          ],
        ),
      ),
    );
  }
}

/// ===============================================
