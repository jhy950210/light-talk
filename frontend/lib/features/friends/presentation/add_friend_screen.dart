import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../providers/friends_provider.dart';

class AddFriendScreen extends ConsumerStatefulWidget {
  const AddFriendScreen({super.key});

  @override
  ConsumerState<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends ConsumerState<AddFriendScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(userSearchProvider.notifier).search(query);
    });
  }

  Future<void> _addFriend(String email) async {
    final success =
        await ref.read(friendsProvider.notifier).addFriend(email);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Friend request sent!' : 'Failed to send request.',
          ),
          backgroundColor: success ? AppTheme.onlineGreen : AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      if (success) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(userSearchProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Add Friend'),
      ),
      body: Column(
        children: [
          // ── Search Bar ───────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by email or nickname',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(userSearchProvider.notifier).clear();
                        },
                      )
                    : null,
              ),
            ),
          ),

          // ── Results ──────────────────────────────────
          Expanded(
            child: searchState.isSearching
                ? const Center(child: CircularProgressIndicator())
                : searchState.results.isEmpty &&
                        _searchController.text.isNotEmpty
                    ? _buildNoResults(context)
                    : searchState.results.isEmpty
                        ? _buildSearchHint(context)
                        : _buildResults(context, searchState),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHint(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Search for users by email',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF8E8E93),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No users found',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF8E8E93),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try a different email or nickname',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFC7C7CC),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context, UserSearchState searchState) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: searchState.results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final user = searchState.results[index];
        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          leading: AvatarWidget(
            name: user.nickname,
            imageUrl: user.profileImageUrl,
            radius: 22,
          ),
          title: Text(
            user.nickname,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            user.email,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF8E8E93),
            ),
          ),
          trailing: SizedBox(
            width: 100,
            height: 36,
            child: ElevatedButton(
              onPressed: () => _addFriend(user.email),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(100, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle: const TextStyle(fontSize: 13),
              ),
              child: const Text('Add'),
            ),
          ),
        );
      },
    );
  }
}
