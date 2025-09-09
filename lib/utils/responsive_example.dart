import 'package:flutter/material.dart';
import 'responsive_helper.dart';

/// مثال على كيفية استخدام ResponsiveHelper في صفحات أخرى
class ResponsiveExampleScreen extends StatelessWidget {
  const ResponsiveExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'مثال على التصميم المتجاوب',
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(
              context,
              mobile: 18,
              tablet: 20,
              desktop: 22,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          mobile: const EdgeInsets.all(16),
          tablet: const EdgeInsets.all(20),
          desktop: const EdgeInsets.all(24),
        ),
        child: Column(
          children: [
            // مثال على ResponsiveBuilder
            ResponsiveBuilder(
              mobile: _buildMobileCard(),
              tablet: _buildTabletCard(),
              desktop: _buildDesktopCard(),
            ),
            
            const SizedBox(height: 20),
            
            // مثال على ResponsiveLayoutBuilder
            ResponsiveLayoutBuilder(
              builder: (context, isMobile, isTablet, isDesktop) {
                return Container(
                  padding: EdgeInsets.all(
                    isMobile ? 16 : (isTablet ? 20 : 24),
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.getBorderRadius(context),
                    ),
                    boxShadow: ResponsiveHelper.getResponsiveShadow(context),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.devices,
                        size: ResponsiveHelper.getResponsiveIconSize(
                          context,
                          mobile: 48,
                          tablet: 56,
                          desktop: 64,
                        ),
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isMobile 
                            ? 'عرض الموبايل'
                            : (isTablet ? 'عرض التابلت' : 'عرض الديسكتوب'),
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 16,
                            tablet: 18,
                            desktop: 20,
                          ),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'هذا مثال على كيفية استخدام ResponsiveLayoutBuilder',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 15,
                            desktop: 16,
                          ),
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
            
            const SizedBox(height: 20),
            
            // مثال على شبكة متجاوبة
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: ResponsiveHelper.getGridCrossAxisCount(context),
                crossAxisSpacing: ResponsiveHelper.getGridSpacing(context),
                mainAxisSpacing: ResponsiveHelper.getGridSpacing(context),
                childAspectRatio: ResponsiveHelper.getGridChildAspectRatio(context),
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.getBorderRadius(context),
                    ),
                    boxShadow: ResponsiveHelper.getResponsiveShadow(context),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.star,
                        size: ResponsiveHelper.getResponsiveIconSize(
                          context,
                          mobile: 32,
                          tablet: 36,
                          desktop: 40,
                        ),
                        color: Colors.amber,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'عنصر ${index + 1}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 15,
                            desktop: 16,
                          ),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileCard() {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Column(
          children: [
            Icon(
              Icons.phone_android,
              size: 48,
              color: Colors.blue[600],
            ),
            const SizedBox(height: 12),
            Text(
              'تصميم الموبايل',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'مخصص للشاشات الصغيرة',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletCard() {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Column(
          children: [
            Icon(
              Icons.tablet_android,
              size: 56,
              color: Colors.green[600],
            ),
            const SizedBox(height: 16),
            Text(
              'تصميم التابلت',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'مخصص للشاشات المتوسطة',
              style: TextStyle(
                fontSize: 16,
                color: Colors.green[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopCard() {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.purple[50],
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.purple[200]!),
        ),
        child: Column(
          children: [
            Icon(
              Icons.desktop_windows,
              size: 64,
              color: Colors.purple[600],
            ),
            const SizedBox(height: 20),
            Text(
              'تصميم الديسكتوب',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.purple[800],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'مخصص للشاشات الكبيرة',
              style: TextStyle(
                fontSize: 18,
                color: Colors.purple[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// مثال على كيفية إنشاء widget متجاوب مخصص
class ResponsiveCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const ResponsiveCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getBorderRadius(context),
        ),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(
            ResponsiveHelper.isMobile(context) ? 16 : 20,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getBorderRadius(context),
            ),
            border: Border.all(color: color.withOpacity(0.3)),
            boxShadow: ResponsiveHelper.getResponsiveShadow(context),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: ResponsiveHelper.getResponsiveIconSize(
                  context,
                  mobile: 40,
                  tablet: 48,
                  desktop: 56,
                ),
                color: color,
              ),
              SizedBox(height: ResponsiveHelper.isMobile(context) ? 12 : 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(
                    context,
                    mobile: 16,
                    tablet: 18,
                    desktop: 20,
                  ),
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ResponsiveHelper.isMobile(context) ? 8 : 12),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(
                    context,
                    mobile: 14,
                    tablet: 15,
                    desktop: 16,
                  ),
                  color: color.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 