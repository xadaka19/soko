import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Effective Date: 7th June 2025\nLast Updated: 18th July 2025',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            _buildSection(
              '1. Introduction',
              'Sokofiti ("we", "us", "our", or "the Company") operates a digital listing platform ("the Platform") that connects vendors and buyers for the purpose of engaging in transactions. This Privacy Policy outlines how we collect, process, store, and protect personal data in accordance with the Kenya Data Protection Act, 2019 (DPA) and other applicable Kenyan laws. Our Platform does not sell goods or services directly; rather, it serves as a conduit for vendors to list their offerings and for buyers to engage with such listings. We are committed to safeguarding the privacy of our users ("you", "your", or "data subjects") and ensuring transparency in our data handling practices. For any queries regarding this Privacy Policy, please contact us at support@sokofiti.com. By accessing or using our Platform, you agree to the terms of this Privacy Policy. If you do not consent to these terms, please refrain from using the Platform.',
            ),

            _buildSection(
              '2. Scope',
              'This Privacy Policy applies to all personal data collected through the Platform, whether you are a vendor listing items, a buyer engaging with listings, or a visitor browsing our services. It encompasses data collected via our website, mobile application, or any other digital interface operated by Sokofiti.',
            ),

            _buildSection(
              '3. Definitions',
              'Personal Data: Any information relating to an identified or identifiable natural person, as defined under the Kenya DPA.\nData Controller: Patjo Marketplace, which determines the purposes and means of processing personal data.\nData Processor: Any third party engaged by us to process personal data on our behalf.\nProcessing: Any operation performed on personal data, including collection, storage, use, disclosure, or deletion.',
            ),

            _buildSection(
              '4. Data We Collect',
              'We collect personal data to operate the Platform effectively and provide you with a seamless experience. The types of data we may collect include:\n\nData Provided by You\n• Account Information: When you register as a vendor or buyer, we may collect your name, email address, phone number, and username.\n• Listing Information: Vendors may provide details such as business names, contact information, and descriptions of goods or services listed.\n• Communications: Any information you provide when contacting us via support@sokofiti.com or through the Platform\'s messaging features.\n\nData Collected Automatically\n• Technical Data: IP address, device type, browser type, operating system, and usage data (e.g., pages visited, time spent on the Platform).\n• Cookies and Tracking Technologies: We use cookies to enhance functionality and analyse usage.\n• Data from Third Parties: We may receive data from third-party service providers (e.g., analytics tools) to improve our Platform, provided such data complies with the DPA.\n\nWe do not sell goods or services directly, and thus we do not collect payment information. Transactions occur directly between vendors and buyers outside the scope of our Platform\'s data collection.',
            ),

            _buildSection(
              '5. Purpose of Processing',
              'We process personal data for the following lawful purposes, as permitted under the Kenya DPA:\n\n• To facilitate Platform operations: Enabling vendors to list items and buyers to browse and engage with listings.\n• To provide support: Responding to enquiries or complaints received at support@sokofiti.com.\n• To improve services: Analysing usage patterns to enhance the Platform\'s functionality and user experience.\n• To comply with legal obligations: Meeting requirements under Kenyan law, including the DPA.\n• To communicate: Sending service-related updates or notifications (with your consent where required).\n\nWe adhere to the principles of lawfulness, fairness, transparency, purpose limitation, data minimisation, accuracy, storage limitation, integrity, and confidentiality, as mandated by the DPA.',
            ),

            _buildSection(
              '6. Legal Basis for Processing',
              'We process personal data on the following legal bases under the Kenya DPA:\n\n• Consent: Where you have explicitly agreed to the processing (e.g., for marketing communications).\n• Contractual Necessity: To perform our obligations under the terms of use of the Platform.\n• Legitimate Interests: For purposes such as improving the Platform, provided your rights and freedoms are not overridden.\n• Legal Obligation: To comply with Kenyan laws and regulations.',
            ),

            _buildSection(
              '7. Data Sharing and Disclosure',
              'We do not sell your personal data. However, we may share it in the following circumstances:\n\n• With Vendors and Buyers: Contact details provided by vendors in listings may be shared with buyers to facilitate engagement, as per the Platform\'s purpose.\n• With Service Providers: We engage third-party processors (e.g., hosting providers, analytics services) to support Platform operations, subject to strict data protection agreements compliant with the DPA.\n• Legal Requirements: We may disclose data if required by law, court order, or regulatory authority in Kenya, such as the Office of the Data Protection Commissioner (ODPC).\n• Business Transfers: In the event of a merger, acquisition, or sale of assets, personal data may be transferred, with appropriate safeguards in place.',
            ),

            _buildSection(
              '8. Data Retention',
              'We retain personal data only for as long as necessary to fulfil the purposes outlined in Section 5, or as required by Kenyan law. For example:\n\n• Account data is retained while your account is active and for a reasonable period thereafter (e.g., 12 months) unless you request deletion.\n• Technical data is retained for analytical purposes in anonymised form where possible.\n\nUpon expiration of the retention period, data is securely deleted or anonymised in accordance with DPA requirements.',
            ),

            _buildSection(
              '9. Cookies and Tracking Technologies',
              'We use cookies and similar technologies to enhance your experience on the Platform. These may include:\n\n• Essential Cookies: Necessary for Platform functionality (e.g., session management).\n• Analytical Cookies: To understand usage patterns and improve services.\n\nYou may manage cookie preferences via your browser settings. However, disabling essential cookies may impair Platform functionality.',
            ),

            _buildSection(
              '10. Your Rights Under the Kenya DPA',
              'As a data subject, you have the following rights:\n\n• Right to be Informed: To know how your data is processed (as detailed in this policy).\n• Right of Access: To request a copy of your personal data held by us.\n• Right to Rectification: To correct inaccurate or incomplete data.\n• Right to Erasure: To request deletion of your data, subject to legal retention obligations.\n• Right to Object: To object to processing based on legitimate interests.\n• Right to Restrict Processing: To limit how your data is used in certain circumstances.\n• Right to Data Portability: To receive your data in a structured, machine-readable format.\n• Right to Withdraw Consent: Where processing is based on consent, you may withdraw it at any time.\n\nTo exercise these rights, contact us at support@sokofiti.com. We will respond within 30 days, as required by the DPA, subject to verification of your identity.',
            ),

            _buildSection(
              '11. Data Security',
              'We implement robust technical and organisational measures to protect your personal data, including:\n\n• Encryption of data in transit and at rest.\n• Access controls to limit data exposure to authorised personnel only.\n• Regular security assessments to identify and mitigate risks.\n\nDespite these measures, no online platform can guarantee absolute security. In the event of a data breach posing a risk to your rights, we will notify the ODPC within 72 hours and affected users promptly, as mandated by the DPA.',
            ),

            _buildSection(
              '12. Cross-Border Data Transfers',
              'Where personal data is transferred outside Kenya (e.g., to third-party processors), we ensure adequate safeguards are in place, such as:\n\n• Data processing agreements compliant with DPA requirements.\n• Verification that the recipient jurisdiction offers comparable data protection standards.',
            ),

            _buildSection(
              '13. Third-Party Links',
              'The Platform may contain links to third-party websites (e.g., vendor or buyer contact pages). We are not responsible for the privacy practices of such sites. We encourage you to review their policies before engaging with them.',
            ),

            _buildSection(
              '14. Children\'s Privacy',
              'Our Platform is not intended for individuals under the age of 18. We do not knowingly collect personal data from minors. If you believe we have inadvertently collected such data, please contact us at support@sokofiti.ke for immediate removal.',
            ),

            _buildSection(
              '15. Changes to This Privacy Policy',
              'We may update this Privacy Policy to reflect changes in our practices or legal requirements. The updated version will be posted on the Platform with the revised Last Updated date. Significant changes will be communicated via email or Platform notification where practicable.',
            ),

            _buildSection(
              '16. Contact Us',
              'For questions, complaints, or to exercise your data rights, please contact:\nData Protection Officer\nhttps://sokofiti.ke/\nEmail: support@sokofiti.ke',
            ),

            _buildSection(
              '17. Complaints',
              'If you believe we have not handled your personal data appropriately, you may lodge a complaint with the Office of the Data Protection Commissioner (ODPC):\n\nWebsite: www.odpc.go.ke\nEmail: info@odpc.go.ke\n\nWe encourage you to contact us first to resolve any issues amicably.',
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
