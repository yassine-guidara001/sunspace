import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/custom_sidebar.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/dashboard_topbar.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/training_sessions_page.dart';

class SessionsView extends StatelessWidget {
  const SessionsView({super.key});

  static const _pageBg = Color(0xFFF1F5F9);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _pageBg,
      body: Row(
        children: [
          CustomSidebar(),
          Expanded(
            child: Column(
              children: [
                DashboardTopBar(),
                Expanded(child: TrainingSessionsPage()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
