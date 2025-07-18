import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import 'money_reader_screen.dart';
import 'document_reader_screen.dart';
import 'form_analyzer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  final List<TabData> _tabs = [
    TabData(
      title: 'تحليل العملات',
      icon: Icons.monetization_on_outlined,
      activeIcon: Icons.monetization_on,
      screen: const MoneyReaderScreen(),
    ),
    TabData(
      title: 'قراءة المستندات',
      icon: Icons.picture_as_pdf_outlined,
      activeIcon: Icons.picture_as_pdf,
      screen: const DocumentReaderScreen(),
    ),
    TabData(
      title: 'تحليل النماذج',
      icon: Icons.description_outlined,
      activeIcon: Icons.description,
      screen: const FormAnalyzerScreen(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      context.read<AppProvider>().setCurrentTabIndex(_tabController.index);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _tabs.map((tab) => tab.screen).toList(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.textSecondaryColor.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: TabBar(
            controller: _tabController,
            tabs: _tabs.map((tab) => _buildBottomTab(tab)).toList(),
            indicator: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.3),
              ),
            ),
            indicatorPadding: const EdgeInsets.all(4),
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textSecondaryColor,
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.surfaceColor,
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Image.asset(
                  'assets/icon/w-logo-02.png',
                  height: 40,
                  width: 40,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ساعدني',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    Text(
                      'المساعد الذكي للتحليل والقراءة',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomTab(TabData tabData) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final isActive = _tabs.indexOf(tabData) == provider.currentTabIndex;
        return Tab(
          height: 70,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? tabData.activeIcon : tabData.icon,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                tabData.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }


}

class TabData {
  final String title;
  final IconData icon;
  final IconData activeIcon;
  final Widget screen;

  TabData({
    required this.title,
    required this.icon,
    required this.activeIcon,
    required this.screen,
  });
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InfoItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 