import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/legal_sheet.dart';
import '../widgets/pet.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = app.t;
    final annual = app.payPlan == PayPlan.annual;
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 22, 26, 34),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                PetView(
                  species: app.species,
                  mood: Mood.radiant,
                  activity: Activity.nap,
                  coat: app.color,
                ),
                const SizedBox(height: 18),
                Text(
                  t.fill(t.payT, {'n': app.displayName}),
                  textAlign: TextAlign.center,
                  style: nunito(size: 28, weight: FontWeight.w800, height: 1.15, letterSpacing: -0.5),
                ),
                const SizedBox(height: 10),
                Text(
                  t.payB,
                  textAlign: TextAlign.center,
                  style: nunito(size: 15, height: 1.5, color: AppColors.inkA(0.68)),
                ),
                const SizedBox(height: 18),
              ],
            ),
            ),
          ),
          _plan(
            title: t.payAnnual,
            price: t.priceA,
            note: t.payAnnualNote,
            selected: annual,
            badge: t.payBest,
            onTap: () => app.pickPay(PayPlan.annual),
          ),
          const SizedBox(height: 11),
          _plan(
            title: t.payMonthly,
            price: t.priceM,
            note: t.payMonthlyNote,
            selected: !annual,
            onTap: () => app.pickPay(PayPlan.monthly),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: app.trial ? t.payCtaActive : t.payCta,
            onTap: app.startTrial,
            height: 58,
          ),
          const SizedBox(height: 10),
          Text(
            t.payRemind,
            textAlign: TextAlign.center,
            style: nunito(size: 12.5, weight: FontWeight.w600, height: 1.5, color: AppColors.inkA(0.6)),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 18,
            runSpacing: 8,
            children: [
              _link(t.payRestore, app.restorePurchases),
              _link(
                t.payTerms,
                () => showLegalSheet(
                  context,
                  title: t.setTerms,
                  body: t.termsBody,
                  close: t.shareDone,
                ),
              ),
              _link(
                t.payPrivacy,
                () => showLegalSheet(
                  context,
                  title: t.setPrivacy,
                  body: t.privacyBody,
                  close: t.shareDone,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _link(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(label, style: nunito(size: 12, color: AppColors.inkA(0.42))),
    );
  }

  Widget _plan({
    required String title,
    required String price,
    required String note,
    required bool selected,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
            decoration: BoxDecoration(
              color: selected ? AppColors.greenA(0.12) : AppColors.inkA(0.05),
              borderRadius: BorderRadius.circular(22),
              border: selected ? Border.all(color: AppColors.green, width: 2.5) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (selected) ...[
                      const AppIcon(Icons.check_circle_rounded, size: 18, color: AppColors.green),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: nunito(size: 18, weight: FontWeight.w800),
                      ),
                    ),
                    Text(price, style: nunito(size: 20, weight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 5),
                Text(note, style: nunito(size: 13.5, color: AppColors.inkA(0.65))),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: -11,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  badge.toUpperCase(),
                  style: nunito(size: 10.5, weight: FontWeight.w700, height: 1.4, letterSpacing: 0.5, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
