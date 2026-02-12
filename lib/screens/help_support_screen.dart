import 'package:flutter/material.dart';
import 'package:multigame/design_system/design_system.dart';
import 'package:multigame/models/faq_item.dart';
import 'package:multigame/widgets/shared/ds_button.dart';
import 'package:multigame/widgets/shared/game_header.dart';

/// Help & Support screen with FAQ and contact options
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  String _selectedCategory = 'General';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FaqItem> get _filteredFaqs {
    var faqs = _searchQuery.isEmpty
        ? FaqItem.getByCategory(_selectedCategory)
        : FaqItem.defaultFaqs.where((faq) {
            final query = _searchQuery.toLowerCase();
            return faq.question.toLowerCase().contains(query) ||
                faq.answer.toLowerCase().contains(query);
          }).toList();
    return faqs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DSColors.backgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            GameHeader(
              title: 'Help & Support',
              onBack: () => Navigator.pop(context),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(DSSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search bar
                    _buildSearchBar(),
                    SizedBox(height: DSSpacing.lg),

                    // Category filter
                    if (_searchQuery.isEmpty) ...[
                      _buildCategoryFilter(),
                      SizedBox(height: DSSpacing.lg),
                    ],

                    // FAQ list
                    if (_filteredFaqs.isEmpty)
                      _buildEmptyState()
                    else
                      ..._buildFaqList(),

                    SizedBox(height: DSSpacing.xl),

                    // Contact support section
                    _buildContactSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: DSColors.surface,
        borderRadius: DSSpacing.borderRadiusMD,
        border: Border.all(
          color: DSColors.textSecondary.withValues(alpha: 0.2),
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: DSTypography.bodyMedium.copyWith(color: DSColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search FAQs...',
          hintStyle: DSTypography.bodyMedium.copyWith(
            color: DSColors.textSecondary,
          ),
          prefixIcon: Icon(Icons.search_rounded, color: DSColors.textSecondary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: DSColors.textSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: DSSpacing.md,
            vertical: DSSpacing.sm,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = FaqItem.categories;

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == _selectedCategory;

          return Padding(
            padding: EdgeInsets.only(right: DSSpacing.xs),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              backgroundColor: DSColors.surface,
              selectedColor: DSColors.primary.withValues(alpha: 0.2),
              checkmarkColor: DSColors.primary,
              labelStyle: DSTypography.bodyMedium.copyWith(
                color: isSelected ? DSColors.primary : DSColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected
                    ? DSColors.primary
                    : DSColors.textSecondary.withValues(alpha: 0.2),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildFaqList() {
    return _filteredFaqs.map((faq) {
      return TweenAnimationBuilder<double>(
        duration: DSAnimations.normal,
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Opacity(opacity: value, child: child),
          );
        },
        child: Padding(
          padding: EdgeInsets.only(bottom: DSSpacing.sm),
          child: _FaqCard(faq: faq),
        ),
      );
    }).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(DSSpacing.xxxl),
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: DSColors.textTertiary,
            ),
            SizedBox(height: DSSpacing.md),
            Text(
              'No results found',
              style: DSTypography.titleLarge.copyWith(
                color: DSColors.textSecondary,
              ),
            ),
            SizedBox(height: DSSpacing.xs),
            Text(
              'Try a different search term',
              style: DSTypography.bodyMedium.copyWith(
                color: DSColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: DSSpacing.paddingLG,
      decoration: BoxDecoration(
        gradient: DSColors.gradientGlass,
        borderRadius: DSSpacing.borderRadiusLG,
        border: Border.all(color: DSColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(DSSpacing.xs),
                decoration: BoxDecoration(
                  gradient: DSColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(DSSpacing.radiusSM),
                ),
                child: Icon(
                  Icons.support_agent_rounded,
                  color: Colors.white,
                  size: DSSpacing.iconMedium,
                ),
              ),
              SizedBox(width: DSSpacing.sm),
              Text(
                'Still need help?',
                style: DSTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: DSSpacing.sm),
          Text(
            'Can\'t find what you\'re looking for? Our support team is here to help!',
            style: DSTypography.bodyMedium.copyWith(
              color: DSColors.textSecondary,
            ),
          ),
          SizedBox(height: DSSpacing.md),
          DSButton(
            text: 'Contact Support',
            icon: Icons.email_rounded,
            variant: DSButtonVariant.primary,
            fullWidth: true,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Support contact coming soon!',
                    style: DSTypography.bodyMedium,
                  ),
                  backgroundColor: DSColors.info,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FaqCard extends StatefulWidget {
  final FaqItem faq;

  const _FaqCard({required this.faq});

  @override
  State<_FaqCard> createState() => _FaqCardState();
}

class _FaqCardState extends State<_FaqCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DSAnimations.normal,
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DSColors.surface,
        borderRadius: DSSpacing.borderRadiusMD,
        border: Border.all(
          color: _isExpanded
              ? DSColors.primary.withValues(alpha: 0.3)
              : DSColors.textSecondary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          // Question (always visible)
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: DSSpacing.borderRadiusMD,
            child: Padding(
              padding: DSSpacing.paddingMD,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.faq.question,
                      style: DSTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: DSColors.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(width: DSSpacing.xs),
                  RotationTransition(
                    turns: _rotationAnimation,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: DSColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Answer (expandable)
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                DSSpacing.md,
                0,
                DSSpacing.md,
                DSSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(
                    color: DSColors.textSecondary.withValues(alpha: 0.2),
                    height: 1,
                  ),
                  SizedBox(height: DSSpacing.sm),
                  Text(
                    widget.faq.answer,
                    style: DSTypography.bodyMedium.copyWith(
                      color: DSColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
