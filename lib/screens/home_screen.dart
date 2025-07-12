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
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _tabs.map((tab) => tab.screen).toList(),
              ),
            ),
          ],
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Insight',
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
              IconButton(
                onPressed: () => Navigator.pushNamed(context, '/font_test'),
                icon: const Icon(
                  Icons.text_fields,
                  color: AppTheme.textSecondaryColor,
                ),
                tooltip: 'اختبار الخطوط',
              ),
              IconButton(
                onPressed: () => Navigator.pushNamed(context, '/signature_test'),
                icon: const Icon(
                  Icons.draw,
                  color: AppTheme.textSecondaryColor,
                ),
                tooltip: 'اختبار كشف التوقيع',
              ),
              IconButton(
                onPressed: () => _showInfoDialog(),
                icon: const Icon(
                  Icons.info_outline,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textSecondaryColor.withOpacity(0.1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: _tabs.map((tab) => _buildTab(tab)).toList(),
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
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildTab(TabData tabData) {
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

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.info,
              color: AppTheme.primaryColor,
            ),
            SizedBox(width: 8),
            Text(
              'حول التطبيق',
              style: TextStyle(
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Insight - المساعد الذكي',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'تطبيق ذكي يوفر ثلاث خدمات رئيسية:',
              style: TextStyle(color: AppTheme.textPrimaryColor),
            ),
            SizedBox(height: 8),
            _InfoItem(
              icon: Icons.description,
              title: 'تحليل النماذج',
              description: 'تحليل النماذج واستخراج الحقول',
            ),
            _InfoItem(
              icon: Icons.monetization_on,
              title: 'تحليل العملات',
              description: 'تحديد نوع وقيمة العملات',
            ),
            _InfoItem(
              icon: Icons.picture_as_pdf,
              title: 'قراءة المستندات',
              description: 'قراءة وتحليل ملفات PDF و PowerPoint',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
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