import 'package:flutter/material.dart';
import '../services/biometric_service.dart';
import '../services/auth_service.dart';
import '../utils/session_manager.dart';

class BiometricTestScreen extends StatefulWidget {
  const BiometricTestScreen({super.key});

  @override
  State<BiometricTestScreen> createState() => _BiometricTestScreenState();
}

class _BiometricTestScreenState extends State<BiometricTestScreen> {
  String _status = 'Checking biometric capabilities...';
  bool _isLoading = false;
  bool _isBiometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricStatus();
  }

  Future<void> _checkBiometricStatus() async {
    setState(() {
      _isLoading = true;
      _status = 'Checking biometric capabilities...';
    });

    try {
      // Check device capabilities
      final capabilities = await BiometricService.getDeviceCapabilities();
      final isEnabled = await SessionManager.isBiometricEnabled();
      final canUse = await AuthService.canUseBiometricLogin();

      setState(() {
        _isBiometricEnabled = isEnabled;
        _status =
            '''
Device Capabilities:
- Has Capability: ${capabilities['hasCapability']}
- Message: ${capabilities['message']}
- Primary Type: ${capabilities['primaryType'] ?? 'None'}
- Available Types: ${capabilities['availableTypes'].length}

User Settings:
- Biometric Enabled: $isEnabled
- Can Use Biometric Login: $canUse

Status: Ready for testing
''';
      });
    } catch (e) {
      setState(() {
        _status = 'Error checking biometric status: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testBiometricAvailability() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing biometric availability...';
    });

    try {
      final isAvailable = await BiometricService.isBiometricAvailable();
      final availableTypes = await BiometricService.getAvailableBiometrics();
      final primaryType = await BiometricService.getPrimaryBiometricType();
      final icon = await BiometricService.getBiometricIcon();

      setState(() {
        _status =
            '''
Biometric Availability Test:
- Is Available: $isAvailable
- Available Types: ${availableTypes.map((t) => BiometricService.getBiometricTypeName(t)).join(', ')}
- Primary Type: $primaryType
- Icon: ${icon.codePoint}

Test completed successfully!
''';
      });
    } catch (e) {
      setState(() {
        _status = 'Error testing biometric availability: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testBiometricAuthentication() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing biometric authentication...';
    });

    try {
      final result = await BiometricService.authenticateWithBiometric(
        reason: 'Test biometric authentication for Sokofiti',
      );

      setState(() {
        _status =
            '''
Biometric Authentication Test:
- Result: ${result ? 'SUCCESS' : 'FAILED'}
- Timestamp: ${DateTime.now()}

${result ? 'Authentication was successful!' : 'Authentication failed or was cancelled.'}
''';
      });
    } catch (e) {
      setState(() {
        _status = 'Error during biometric authentication: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testEnableBiometric() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing biometric enable...';
    });

    try {
      final result = await BiometricService.enableBiometric();

      setState(() {
        _isBiometricEnabled = result;
        _status =
            '''
Enable Biometric Test:
- Result: ${result ? 'SUCCESS' : 'FAILED'}
- Biometric Enabled: $_isBiometricEnabled
- Timestamp: ${DateTime.now()}

${result ? 'Biometric authentication has been enabled!' : 'Failed to enable biometric authentication.'}
''';
      });
    } catch (e) {
      setState(() {
        _status = 'Error enabling biometric: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testDisableBiometric() async {
    setState(() {
      _isLoading = true;
      _status = 'Disabling biometric...';
    });

    try {
      await BiometricService.disableBiometric();
      final isEnabled = await SessionManager.isBiometricEnabled();

      setState(() {
        _isBiometricEnabled = isEnabled;
        _status =
            '''
Disable Biometric Test:
- Biometric Enabled: $isEnabled
- Timestamp: ${DateTime.now()}

Biometric authentication has been disabled.
''';
      });
    } catch (e) {
      setState(() {
        _status = 'Error disabling biometric: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biometric Test'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Display
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _status,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test Buttons
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              )
            else
              Column(
                children: [
                  ElevatedButton(
                    onPressed: _checkBiometricStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Check Status'),
                  ),

                  const SizedBox(height: 8),

                  ElevatedButton(
                    onPressed: _testBiometricAvailability,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Test Availability'),
                  ),

                  const SizedBox(height: 8),

                  ElevatedButton(
                    onPressed: _testBiometricAuthentication,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Test Authentication'),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isBiometricEnabled
                              ? null
                              : _testEnableBiometric,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            _isBiometricEnabled ? 'Enabled' : 'Enable',
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: ElevatedButton(
                          onPressed: !_isBiometricEnabled
                              ? null
                              : _testDisableBiometric,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Disable'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
