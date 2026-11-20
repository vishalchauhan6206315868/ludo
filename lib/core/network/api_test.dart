import 'dart:convert';
import 'package:flutter/material.dart';
import 'api_config.dart';
import 'api_service.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  final _emailController = TextEditingController(text: 'test@example.com');
  final _passwordController = TextEditingController(text: 'password123');
  final _registerNameController = TextEditingController(text: 'Ludo Pro');
  final _registerEmailController = TextEditingController(text: 'ludopro@example.com');
  final _registerPasswordController = TextEditingController(text: 'password123');
  final _joinRoomCodeController = TextEditingController(text: '123456');
  final _getRoomCodeController = TextEditingController(text: 'AB89X2');
  final _leaveRoomCodeController = TextEditingController(text: 'AB89X2');
  final _customUrlController = TextEditingController();

  bool isLoading = false;
  String result = 'Backend connection, Login, ya Register test karne ke liye button dabayein.';

  @override
  void initState() {
    super.initState();
    _customUrlController.text = ApiConfig.baseUrl;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _joinRoomCodeController.dispose();
    _getRoomCodeController.dispose();
    _leaveRoomCodeController.dispose();
    _customUrlController.dispose();
    super.dispose();
  }

  void _applyUrl(String url) {
    setState(() {
      ApiConfig.customBaseUrl = url;
      _customUrlController.text = url;
      result = 'Base URL updated to: $url';
    });
  }

  Future<void> testConnection() async {
    setState(() {
      isLoading = true;
      result = 'Connecting to backend health check...\nURL: ${ApiConfig.baseUrl}${ApiConfig.health}';
    });

    try {
      final response = await ApiService().getHealth();
      if (!mounted) return;

      setState(() {
        result = const JsonEncoder.withIndent('  ').convert(response);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        result = 'Connection Failed:\n$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> testLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        result = 'Please enter both email and password.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      result = 'Testing Login API...\nPOST ${ApiConfig.baseUrl}${ApiConfig.login}\nEmail: $email';
    });

    try {
      final response = await ApiService().login(
        email: email,
        password: password,
      );

      if (!mounted) return;

      final prettyJson = const JsonEncoder.withIndent('  ').convert(response);
      final token = await ApiService().getToken();

      setState(() {
        result = 'Status Code: ${response['statusCode']}\n'
            'Success: ${response['success']}\n'
            'Saved Token: ${token ?? "No token found in response"}\n\n'
            'Full Response:\n$prettyJson';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        result = 'Login Request Failed:\n$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> testRegister() async {
    final name = _registerNameController.text.trim();
    final email = _registerEmailController.text.trim();
    final password = _registerPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() {
        result = 'Please enter name, email, and password for registration.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      result = 'Testing Register API...\nPOST ${ApiConfig.baseUrl}${ApiConfig.register}\nName: $name\nEmail: $email';
    });

    try {
      final response = await ApiService().register(
        name: name,
        email: email,
        password: password,
      );

      if (!mounted) return;

      final prettyJson = const JsonEncoder.withIndent('  ').convert(response);
      final token = await ApiService().getToken();

      setState(() {
        result = 'Status Code: ${response['statusCode']}\n'
            'Success: ${response['success']}\n'
            'Message: ${response['message']}\n'
            'Saved Token: ${token ?? "No token saved"}\n\n'
            'Full Response:\n$prettyJson';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        result = 'Register Request Failed:\n$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> testProfile() async {
    setState(() {
      isLoading = true;
      result = 'Testing Profile API...\nGET ${ApiConfig.baseUrl}${ApiConfig.profile}';
    });

    try {
      final token = await ApiService().getToken();
      final response = await ApiService().getProfile();
      if (!mounted) return;

      final prettyJson = const JsonEncoder.withIndent('  ').convert(response);
      setState(() {
        result = 'Endpoint: ${ApiConfig.baseUrl}${ApiConfig.profile}\n'
            'Bearer Token Sent: ${token ?? "No Token Found! (Login first to get token)"}\n'
            'Status Code: ${response['statusCode']}\n'
            'Success: ${response['success']}\n'
            'Message: ${response['message']}\n\n'
            'Full Response:\n$prettyJson';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        result = 'Profile Request Failed:\n$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> testCreateRoom() async {
    setState(() {
      isLoading = true;
      result = 'Testing Create Room API...\nPOST ${ApiConfig.baseUrl}${ApiConfig.createRoom}';
    });

    try {
      final token = await ApiService().getToken();
      final response = await ApiService().createRoom(
        maxPlayers: 2,
        gameMode: 'twoPlayer',
      );
      if (!mounted) return;

      final prettyJson = const JsonEncoder.withIndent('  ').convert(response);
      setState(() {
        result = 'Endpoint: ${ApiConfig.baseUrl}${ApiConfig.createRoom}\n'
            'Bearer Token Sent: ${token ?? "No Token Found! (Login first to get token)"}\n'
            'Status Code: ${response['statusCode']}\n'
            'Success: ${response['success']}\n'
            'Message: ${response['message']}\n\n'
            'Full Response:\n$prettyJson';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        result = 'Create Room Request Failed:\n$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> testJoinRoom() async {
    final code = _joinRoomCodeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        result = 'Please enter a valid Room Code to test join.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      result = 'Testing Join Room API...\nPOST ${ApiConfig.baseUrl}${ApiConfig.joinRoom}\nRoom Code: $code';
    });

    try {
      final token = await ApiService().getToken();
      final response = await ApiService().joinRoom(roomCode: code);
      if (!mounted) return;

      final prettyJson = const JsonEncoder.withIndent('  ').convert(response);
      setState(() {
        result = 'Endpoint: ${ApiConfig.baseUrl}${ApiConfig.joinRoom}\n'
            'Bearer Token Sent: ${token ?? "No Token Found! (Login first to get token)"}\n'
            'Room Code Sent: $code\n'
            'Status Code: ${response['statusCode']}\n'
            'Success: ${response['success']}\n'
            'Message: ${response['message']}\n\n'
            'Full Response:\n$prettyJson';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        result = 'Join Room Request Failed:\n$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> testGetRoom() async {
    final code = _getRoomCodeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        result = 'Please enter a valid Room Code to test GET room details.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      result = 'Testing Get Room API...\nGET ${ApiConfig.baseUrl}${ApiConfig.getRoom(code)}\nRoom Code: $code';
    });

    try {
      final token = await ApiService().getToken();
      final response = await ApiService().getRoomDetails(roomCode: code);
      if (!mounted) return;

      final prettyJson = const JsonEncoder.withIndent('  ').convert(response);
      setState(() {
        result = 'Endpoint: ${ApiConfig.baseUrl}${ApiConfig.getRoom(code)}\n'
            'Bearer Token Sent: ${token ?? "No Token Found! (Login first to get token)"}\n'
            'Room Code Queried: $code\n'
            'Status Code: ${response['statusCode']}\n'
            'Success: ${response['success']}\n'
            'Message: ${response['message']}\n\n'
            'Full Response:\n$prettyJson';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        result = 'Get Room Request Failed:\n$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> testLeaveRoom() async {
    final code = _leaveRoomCodeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        result = 'Please enter a valid Room Code to test leaving/cancelling room.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      result = 'Testing Leave Room API...\nPOST ${ApiConfig.baseUrl}${ApiConfig.leaveRoom}\nRoom Code: $code';
    });

    try {
      final token = await ApiService().getToken();
      final response = await ApiService().leaveRoom(roomCode: code);
      if (!mounted) return;

      final prettyJson = const JsonEncoder.withIndent('  ').convert(response);
      setState(() {
        result = 'Endpoint: ${ApiConfig.baseUrl}${ApiConfig.leaveRoom}\n'
            'Bearer Token Sent: ${token ?? "No Token Found! (Login first to get token)"}\n'
            'Room Code Sent: $code\n'
            'Status Code: ${response['statusCode']}\n'
            'Success: ${response['success']}\n'
            'Message: ${response['message']}\n\n'
            'Full Response:\n$prettyJson';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        result = 'Leave Room Request Failed:\n$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> testWallet() async {
    setState(() {
      isLoading = true;
      result = 'Testing Get Wallet API...\nGET ${ApiConfig.baseUrl}${ApiConfig.wallet}';
    });

    try {
      final token = await ApiService().getToken();
      final response = await ApiService().getWallet();
      if (!mounted) return;

      final prettyJson = const JsonEncoder.withIndent('  ').convert(response);
      setState(() {
        result = 'Endpoint: ${ApiConfig.baseUrl}${ApiConfig.wallet}\n'
            'Bearer Token Sent: ${token ?? "No Token Found! (Login first to get token)"}\n'
            'Status Code: ${response['statusCode']}\n'
            'Success: ${response['success']}\n'
            'Message: ${response['message']}\n\n'
            'Full Response:\n$prettyJson';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        result = 'Get Wallet Request Failed:\n$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> testWalletMe() async {
    setState(() {
      isLoading = true;
      result = 'Testing Get Wallet Me API...\nGET ${ApiConfig.baseUrl}${ApiConfig.walletMe}';
    });

    try {
      final token = await ApiService().getToken();
      final response = await ApiService().getMyWallet();
      if (!mounted) return;

      final prettyJson = const JsonEncoder.withIndent('  ').convert(response);
      setState(() {
        result = 'Endpoint: ${ApiConfig.baseUrl}${ApiConfig.walletMe}\n'
            'Bearer Token Sent: ${token ?? "No Token Found! (Login first to get token)"}\n'
            'Status Code: ${response['statusCode']}\n'
            'Success: ${response['success']}\n'
            'Message: ${response['message']}\n\n'
            'Full Response:\n$prettyJson';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        result = 'Get Wallet Me Request Failed:\n$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> testWalletTransactions() async {
    setState(() {
      isLoading = true;
      result = 'Testing Get Wallet Transactions API...\nGET ${ApiConfig.baseUrl}${ApiConfig.walletTransactionsPaginated(page: 1, limit: 20)}';
    });

    try {
      final token = await ApiService().getToken();
      final response = await ApiService().getTransactions(1, 20);
      if (!mounted) return;

      final prettyJson = const JsonEncoder.withIndent('  ').convert(response);
      setState(() {
        result = 'Endpoint: ${ApiConfig.baseUrl}${ApiConfig.walletTransactionsPaginated(page: 1, limit: 20)}\n'
            'Bearer Token Sent: ${token ?? "No Token Found! (Login first to get token)"}\n'
            'Status Code: ${response['statusCode']}\n'
            'Success: ${response['success']}\n'
            'Message: ${response['message']}\n\n'
            'Full Response:\n$prettyJson';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        result = 'Get Wallet Transactions Request Failed:\n$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend API Test Lab'),
        backgroundColor: const Color(0xFF0D5C5B),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // URL Configuration Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Base URL Settings',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _customUrlController,
                      decoration: InputDecoration(
                        labelText: 'API Base URL',
                        hintText: 'http://localhost:5000/api',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.check_circle, color: Color(0xFF0D5C5B)),
                          onPressed: () => _applyUrl(_customUrlController.text.trim()),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('Quick Presets:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        ActionChip(
                          label: const Text('Emulator (10.0.2.2)'),
                          onPressed: () => _applyUrl('http://10.0.2.2:5000/api'),
                        ),
                        ActionChip(
                          label: const Text('Localhost (Port 5000)'),
                          onPressed: () => _applyUrl('http://localhost:5000/api'),
                        ),
                        ActionChip(
                          label: const Text('Wi-Fi (192.168.1.15)'),
                          onPressed: () => _applyUrl('http://192.168.1.15:5000/api'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Health Check Action
            ElevatedButton.icon(
              onPressed: isLoading ? null : testConnection,
              icon: const Icon(Icons.favorite),
              label: const Text('1. Test Connection (Health Check)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D5C5B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),

            const SizedBox(height: 16),

            // Login Test Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '2. Test Login API (/auth/login)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : testLogin,
                      icon: const Icon(Icons.login),
                      label: const Text('Send Login Request'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Register Test Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '3. Test Register API (/auth/register)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _registerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Player Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _registerEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _registerPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : testRegister,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Send Register Request'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Profile Test Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '4. Test Profile API (/users/me)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Fetches authenticated user profile, coins, gems, level & statistics using stored Bearer token.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : testProfile,
                      icon: const Icon(Icons.badge_rounded),
                      label: const Text('Get My Profile (/users/me)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Create Room Test Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '5. Test Create Room API (/rooms/create)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Creates a new multiplayer game room, generates a 6-digit room code and initializes host session.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : testCreateRoom,
                      icon: const Icon(Icons.meeting_room_rounded),
                      label: const Text('Create Game Room (/rooms/create)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Join Room Test Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '6. Test Join Room API (/rooms/join)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Joins an existing multiplayer game room using a 6-digit room code with authenticated player session.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _joinRoomCodeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Room Code',
                        hintText: 'e.g. 123456 or ABCD12',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.pin_rounded),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : testJoinRoom,
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('Join Game Room (/rooms/join)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Get Room by Code Test Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '7. Test Get Room By Code API (/rooms/:roomCode)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Fetches real-time details, players list, host, status, and game mode for a room code.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _getRoomCodeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Room Code',
                        hintText: 'e.g. AB89X2 or 20FC1I',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.travel_explore_rounded),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : testGetRoom,
                      icon: const Icon(Icons.search_rounded),
                      label: const Text('Get Room Details (/rooms/:roomCode)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Leave / Cancel Room Test Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '8. Test Leave Room API (/rooms/leave)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Leaves an active room. If host leaves, the room is cancelled and fees refunded for all.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _leaveRoomCodeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Room Code',
                        hintText: 'e.g. AB89X2 or 20FC1I',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.exit_to_app_rounded),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : testLeaveRoom,
                      icon: const Icon(Icons.exit_to_app_rounded),
                      label: const Text('Leave / Cancel Room (/rooms/leave)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Wallet Test Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '8. Test Wallet APIs (/wallet, /wallet/me, /wallet/transactions)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tests wallet info, current user balance, and paginated transaction history using JWT token.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: isLoading ? null : testWallet,
                          icon: const Icon(Icons.account_balance_wallet_rounded),
                          label: const Text('GET /wallet'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: isLoading ? null : testWalletMe,
                          icon: const Icon(Icons.monetization_on_rounded),
                          label: const Text('GET /wallet/me'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB45309),
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: isLoading ? null : testWalletTransactions,
                          icon: const Icon(Icons.receipt_long_rounded),
                          label: const Text('GET /wallet/transactions?page=1&limit=20'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF047857),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Response Box
            const Text(
              'API Response Output:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(color: Colors.tealAccent),
                      ),
                    )
                  : SelectableText(
                      result,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.greenAccent,
                        fontSize: 12,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}