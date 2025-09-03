import 'package:flutter/material.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Use'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terms of Use',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Last updated: 2025',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            _buildSection(
              '1. ACCEPTANCE OF TERMS AND CONDITIONS',
              'These Terms of Use ("Terms") form a legally binding agreement between Sokofiti ("Company", "we", "us") and you, the user ("you", "your"). By accessing, browsing, or using the sokofiti.ke website, mobile applications, or any related services (collectively, the "Platform"), you acknowledge and agree to comply with these Terms. If you do not agree to these Terms, you must immediately cease using the Platform. By accessing or using the Platform, you confirm that you are legally capable of entering into a binding agreement under the laws of Kenya and that you are a Kenyan citizen aged 18 years or older. These Terms may be modified periodically, and your continued use of the Platform constitutes your acceptance of any such revisions.',
            ),

            _buildSection(
              '2. DISCLAIMERS OF WARRANTIES AND LIMITATION OF LIABILITY',
              'The Platform and all related services are provided "as is" and "as available", without any representations or warranties, express or implied. We disclaim all warranties, including, but not limited to, the merchantability, fitness for a particular purpose, accuracy, or reliability of the services provided. We make no guarantees regarding the functionality, availability, or security of the Platform. You are solely responsible for ensuring the legality of your activities while using the Platform. We are not responsible for any legal consequences that may arise from your use of the Platform or your failure to comply with these Terms.',
            ),

            _buildSection(
              '3. ELIGIBILITY REQUIREMENTS AND ACCOUNT REGISTRATION',
              'To use the Platform, you must meet the following eligibility criteria:\n\n• Kenyan Citizenship: Only Kenyan citizens who are at least 18 years old are eligible to use the Platform, as they are bound by Kenyan law.\n• Registration: You must complete the account registration process, providing accurate, current, and complete information. You are responsible for keeping your account credentials confidential and are fully accountable for all activities under your account.\n\nWe reserve the right to suspend or terminate your account if we find that you have violated any of these Terms or if your account is involved in any fraudulent, illegal, or suspicious activities.',
            ),

            _buildSection(
              '4. SERVICE DESCRIPTION AND LIMITATIONS',
              'The Platform allows users to create and manage listings for goods and services. While we facilitate these interactions, Sokofiti is not a party to any transactions that occur between users. We do not assume responsibility for the quality, safety, legality, or accuracy of any goods, services, or content posted on the Platform. Users are responsible for ensuring that their listings comply with all applicable Kenyan laws, including but not limited to the Sale of Goods Act, Consumer Protection Act, and other relevant statutory regulations.',
            ),

            _buildSection(
              '5. PROHIBITED ACTIVITIES AND ILLEGAL CONTENT',
              'By using the Platform, you agree to refrain from any activities that are deemed unlawful, unethical, or in violation of Kenyan laws, international conventions, or treaties. This includes but is not limited to the following activities:\n\n• Listing of prohibited items: Any listing that involves counterfeit goods, illegal substances, stolen property, unlicensed services, or goods that violate intellectual property rights.\n• Fraudulent activities: Engaging in any form of fraud, misrepresentation, or deception, including posting misleading listings or using fake identities to conduct transactions.\n• Harmful conduct: Posting content or engaging in actions that could harm other users, the Platform, or third parties, including but not limited to harassment, threats, or defamatory statements.\n• Violation of laws: Engaging in activities that violate Kenyan criminal, civil, or commercial law, or international conventions and treaties related to commerce, human rights, environmental protection, and anti-corruption.\n• Hate speech or violence: Promoting any content that incites discrimination, violence, or hate speech based on race, ethnicity, gender, religion, or any other protected characteristic.\n\nPatjo Marketplace adheres to Kenyan and international conventions, such as the UN Convention on the Rights of the Child, UNESCO\'s Convention on the Protection and Promotion of the Diversity of Cultural Expressions, and other relevant international treaties that protect human rights, promote fair trade, and ensure consumer protection. We reserve the right to remove any content or listings that violate these Terms and to report any illegal activities to the appropriate authorities.',
            ),

            _buildSection(
              '6. FEES, PAYMENTS, AND REFUNDS',
              'Certain features of the Platform may require payment. Fees associated with specific services will be clearly outlined at the time of use. All fees are non-refundable, except where mandated by applicable Kenyan law. We reserve the right to revise the fee structure, change payment methods, or introduce new charges at any time, subject to notice on the Platform.',
            ),

            _buildSection(
              '7. INTELLECTUAL PROPERTY RIGHTS',
              'Users retain ownership of any content they upload or post on the Platform ("User Content"). However, by submitting such content, you grant Patjo Marketplace a non-exclusive, perpetual, irrevocable, royalty-free, and transferable license to use, reproduce, modify, display, and distribute your User Content for the purposes of operating and promoting the Platform.',
            ),

            _buildSection(
              '8. LIMITATION OF LIABILITY',
              'To the fullest extent permitted by Kenyan law, Sokofiti is not liable for any indirect, consequential, punitive, or exemplary damages, including but not limited to loss of profit, loss of data, or business interruption, arising from your use or inability to use the Platform, even if we have been advised of the possibility of such damages.',
            ),

            _buildSection(
              '9. GOVERNING LAW AND DISPUTE RESOLUTION',
              'These Terms shall be governed by and construed in accordance with the laws of the Republic of Kenya. Any disputes or claims arising from these Terms shall be resolved through binding arbitration under the Arbitration Act of Kenya. The proceedings shall be conducted in Nairobi, Kenya.',
            ),

            _buildSection(
              '10. INDEMNIFICATION',
              'You agree to indemnify, defend, and hold harmless Sokofiti and its affiliates, employees, officers, directors, agents, and other representatives from any and all claims, liabilities, damages, losses, costs, or expenses (including legal fees) arising from:\n\n• Your use or misuse of the Platform.\n• Your breach of any provision of these Terms.\n• Your violation of any law, regulation, or third-party right.',
            ),

            _buildSection(
              '11. CONTACT INFORMATION',
              'For any inquiries or clarifications regarding these Terms, or if you wish to report any prohibited activity, please contact us at:\nEmail: support@sokofiti.ke',
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 8),
        Text(content, style: const TextStyle(fontSize: 14, height: 1.5)),
        const SizedBox(height: 24),
      ],
    );
  }
}
