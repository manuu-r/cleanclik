import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mock_providers.dart';

// Mock screens for golden tests

class ARCameraScreen extends ConsumerWidget {
  const ARCameraScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameraState = ref.watch(cameraStateProvider);
    final detectedObjects = ref.watch(detectedObjectsProvider);
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview placeholder
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[800],
            child: const Center(
              child: Icon(
                Icons.camera_alt,
                size: 100,
                color: Colors.white54,
              ),
            ),
          ),
          // AR overlays
          if (detectedObjects.isNotEmpty)
            ...detectedObjects.map((obj) => Positioned(
              left: 50,
              top: 200,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  obj['category'] ?? 'Unknown',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            )),
          // Mode switching UI
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cameraState['mode'] == 'ml_detection' 
                        ? Colors.green 
                        : Colors.grey,
                  ),
                  child: const Text('ML Detection'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cameraState['mode'] == 'qr_scanning' 
                        ? Colors.green 
                        : Colors.grey,
                  ),
                  child: const Text('QR Scanner'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MapScreen extends ConsumerWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final binLocations = ref.watch(binLocationsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bin Locations'),
        backgroundColor: Colors.green,
      ),
      body: binLocations.when(
        data: (bins) => Stack(
          children: [
            // Map placeholder
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.grey[300],
              child: const Center(
                child: Icon(
                  Icons.map,
                  size: 100,
                  color: Colors.grey,
                ),
              ),
            ),
            // Bin markers
            ...bins.asMap().entries.map((entry) => Positioned(
              left: 100.0 + (entry.key * 50),
              top: 200.0 + (entry.key * 30),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            )),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider);
    final userStats = ref.watch(userStatsProvider);
    final achievements = ref.watch(userAchievementsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.green,
      ),
      body: userProfile.when(
        data: (profile) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Profile header
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.green,
                child: Text(
                  profile['username']?.toString().substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(fontSize: 32, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                profile['username'] ?? 'User',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                profile['email'] ?? 'user@example.com',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              // Stats cards
              userStats.when(
                data: (stats) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Points',
                        value: stats['totalPoints']?.toString() ?? '0',
                        icon: Icons.star,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        title: 'Level',
                        value: stats['level']?.toString() ?? '1',
                        icon: Icons.trending_up,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        title: 'Items',
                        value: stats['itemsRecycled']?.toString() ?? '0',
                        icon: Icons.recycling,
                      ),
                    ),
                  ],
                ),
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => Text('Error: $error'),
              ),
              const SizedBox(height: 32),
              // Achievements
              achievements.when(
                data: (achievementList) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Achievements',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: achievementList.map((achievement) => Chip(
                        label: Text(achievement),
                        backgroundColor: Colors.green[100],
                      )).toList(),
                    ),
                  ],
                ),
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => Text('Error: $error'),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.green),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboard = ref.watch(leaderboardProvider);
    final userRank = ref.watch(userRankProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            key: const Key('share_achievement_button'),
            onPressed: () {},
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: Column(
        children: [
          // Period selector
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Daily'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Weekly'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('All Time'),
                ),
              ],
            ),
          ),
          // User rank
          userRank.when(
            data: (rank) => Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    'Your Rank: #$rank',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (error, stack) => const SizedBox.shrink(),
          ),
          // Leaderboard list
          Expanded(
            child: leaderboard.when(
              data: (users) => ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final isTop3 = index < 3;
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isTop3 ? Colors.amber : Colors.grey,
                      child: Text('${index + 1}'),
                    ),
                    title: Text(user['username'] ?? 'User'),
                    trailing: Text(
                      '${user['points'] ?? 0} pts',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}

// Auth screens
class LoginScreen extends ConsumerWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.recycling,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'CleanClik',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 48),
            // Email field
            const TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Password field
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            // Login button
            authState.when(
              data: (state) => ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Sign In'),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Column(
                children: [
                  Text(
                    'Error: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Google sign in
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.login),
              label: const Text('Sign in with Google'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 16),
            // Demo mode
            TextButton(
              onPressed: () {},
              child: const Text('Try Demo Mode'),
            ),
          ],
        ),
      ),
    );
  }
}

class SignUpScreen extends ConsumerWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: const Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: null,
              child: Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }
}

class EmailVerificationScreen extends StatelessWidget {
  const EmailVerificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: const Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.email, size: 100, color: Colors.green),
            SizedBox(height: 24),
            Text(
              'Check your email',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'We sent a verification link to your email address.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: null,
              child: Text('Resend Email'),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  final Widget child;
  
  const AuthWrapper({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    
    return authState.when(
      data: (state) {
        if (state['status'] == 'signed_in') {
          return child;
        } else {
          return const LoginScreen();
        }
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Auth Error: $error')),
      ),
    );
  }
}

// Navigation components
class ARNavigationShell extends ConsumerWidget {
  const ARNavigationShell({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentNavigationIndexProvider);
    final notificationBadge = ref.watch(notificationBadgeProvider);
    
    final screens = [
      const ARCameraScreen(),
      const MapScreen(),
      const ProfileScreen(),
      const LeaderboardScreen(),
    ];
    
    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(currentNavigationIndexProvider.notifier).state = index;
        },
        destinations: [
          const NavigationDestination(
            key: Key('navigation_tab_camera'),
            icon: Icon(Icons.camera_alt),
            label: 'Camera',
          ),
          const NavigationDestination(
            key: Key('navigation_tab_map'),
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: notificationBadge > 0,
              label: Text('$notificationBadge'),
              child: const Icon(Icons.person),
            ),
            label: 'Profile',
          ),
          const NavigationDestination(
            icon: Icon(Icons.leaderboard),
            label: 'Leaderboard',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    
    return authState.when(
      data: (state) {
        final isDemoMode = state['isDemoMode'] == true;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('CleanClik'),
            backgroundColor: Colors.green,
          ),
          body: Column(
            children: [
              if (isDemoMode)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.orange[100],
                  child: const Text(
                    'Demo Mode - Your progress won\'t be saved',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              const Expanded(
                child: ARNavigationShell(),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}