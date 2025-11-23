import 'package:flutter/material.dart';
/// CommunityChatPage
/// Placeholder community messaging surface partitioned into personal chats
/// and multi-channel servers. Current implementation is static (no backend)
/// serving as a UX prototype: avatar colors, message bubble layout, member
/// drawer, create/join affordances. Future work: integrate real-time backend
/// (e.g., Firebase Firestore or WebSocket) with presence, typing indicators,
/// permissions, and persistent channels.

/// Entry point widget
class CommunityChatPage extends StatefulWidget {
  const CommunityChatPage({super.key});

  @override
  State<CommunityChatPage> createState() => _CommunityChatPageState();
}

class _CommunityChatPageState extends State<CommunityChatPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF5EFE7);
    const ink = Color(0xFF2F2E2C);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: const Text('Community', style: TextStyle(color: ink)),
        bottom: TabBar(
          controller: _tab,
          labelColor: ink,
          unselectedLabelColor: Colors.black54,
          indicatorColor: ink,
          tabs: const [
            Tab(icon: Icon(Icons.chat_bubble_rounded), text: 'Chats'),
            Tab(icon: Icon(Icons.groups_rounded), text: 'Servers'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _ChatsTab(),
          _ServersTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFF2B8A0),
        foregroundColor: ink,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New'),
        onPressed: () {
          // Placeholder action (non-functional)
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            builder: (_) => const _CreateSheet(),
          );
        },
      ),
    );
  }
}

/* ----------------------------- Chats tab ----------------------------- */

class _ChatsTab extends StatelessWidget {
  const _ChatsTab();

  @override
  Widget build(BuildContext context) {
    final items = [
      const _ChatPreview(
        name: 'Aanya',
        lastMessage: 'See you at 6 for yoga! 🙌',
        time: '5:42 PM',
        color: Colors.teal,
      ),
      const _ChatPreview(
        name: 'Samir',
        lastMessage: 'Shared a breathing exercise link',
        time: '4:11 PM',
        color: Colors.indigo,
      ),
      const _ChatPreview(
        name: 'Josiah',
        lastMessage: 'Can you review the journal UI?',
        time: 'Yesterday',
        color: Colors.orange,
      ),
      const _ChatPreview(
        name: 'Daniyal',
        lastMessage: 'Group coloring tonight?',
        time: 'Yesterday',
        color: Colors.pink,
      ),
    ];

    return Column(
      children: [
        const _SearchBar(hint: 'Search chats'),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => items[i],
          ),
        ),
      ],
    );
  }
}

class _ChatPreview extends StatelessWidget {
  final String name;
  final String lastMessage;
  final String time;
  final Color color;

  const _ChatPreview({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF2F2E2C);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: _Avatar(initials: name[0].toUpperCase(), color: color),
        title: Text(name,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: ink,
            )),
        subtitle: Text(
          lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(time, style: const TextStyle(fontSize: 12)),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatThreadPage(title: name, color: color),
            ),
          );
        },
      ),
    );
  }
}

/* --------------------------- Servers tab --------------------------- */

class _ServersTab extends StatelessWidget {
  const _ServersTab();

  @override
  Widget build(BuildContext context) {
    final featured = [
      _ServerCardData(
        title: 'Group Yoga',
        subtitle: 'Daily 6 PM • Gentle flow',
        color: Colors.teal,
        channels: const ['#announcements', '#chat', '#resources'],
      ),
      _ServerCardData(
        title: 'Coloring Corner',
        subtitle: 'Relax & color together',
        color: Colors.pink,
        channels: const ['#general', '#share-art', '#prompts'],
      ),
      _ServerCardData(
        title: 'Mindful Music',
        subtitle: 'Ambient playlists, requests',
        color: Colors.indigo,
        channels: const ['#now-playing', '#chat'],
      ),
    ];

    return Column(
      children: [
        const _SearchBar(hint: 'Search servers'),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
            itemCount: featured.length,
            itemBuilder: (_, i) => _ServerCard(data: featured[i]),
          ),
        ),
      ],
    );
  }
}

class _ServerCardData {
  final String title;
  final String subtitle;
  final Color color;
  final List<String> channels;

  _ServerCardData({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.channels,
  });
}

class _ServerCard extends StatelessWidget {
  final _ServerCardData data;
  const _ServerCard({required this.data});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF2F2E2C);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _Avatar(initials: data.title[0].toUpperCase(), color: data.color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
              ),
              FilledButton.tonal(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ServerRoomPage(
                        serverName: data.title,
                        color: data.color,
                        channels: data.channels,
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              )
            ]),
            const SizedBox(height: 8),
            Text(data.subtitle),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: data.channels
                  .map((c) => Chip(
                        label: Text(c),
                        backgroundColor: data.color.withValues(alpha: 0.12),
                        side: BorderSide(color: data.color.withValues(alpha: 0.35)),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/* ------------------------- Chat thread page ------------------------- */

class ChatThreadPage extends StatelessWidget {
  final String title;
  final Color color;

  const ChatThreadPage({super.key, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF5EFE7);
    const ink = Color(0xFF2F2E2C);

    final messages = [
      _Message(sender: 'You', text: 'Hey! Ready for yoga tonight?', mine: true),
      _Message(sender: title, text: 'Yes! I’ll be there 😊'),
      _Message(
          sender: 'You',
          text: 'Nice. I’ll bring the breathing timer we liked last time.',
          mine: true),
      _Message(sender: title, text: 'Perfect!'),
    ];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Row(
          children: [
            _Avatar(initials: title[0].toUpperCase(), color: color),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(color: ink)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              itemCount: messages.length,
              itemBuilder: (_, i) =>
                  _MessageBubble(msg: messages[i], color: color),
            ),
          ),
          const _TypingBar(),
        ],
      ),
    );
  }
}

/* ------------------------- Server room page ------------------------- */

class ServerRoomPage extends StatefulWidget {
  final String serverName;
  final Color color;
  final List<String> channels;

  const ServerRoomPage({
    super.key,
    required this.serverName,
    required this.color,
    required this.channels,
  });

  @override
  State<ServerRoomPage> createState() => _ServerRoomPageState();
}

class _ServerRoomPageState extends State<ServerRoomPage> {
  int _channelIndex = 0;

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF5EFE7);
    const ink = Color(0xFF2F2E2C);
    final channel = widget.channels[_channelIndex];

    // Dummy messages per channel
    final messages = <String, List<_Message>>{
      '#announcements': [
        _Message(sender: 'Host', text: 'Welcome to Group Yoga 🌿'),
        _Message(sender: 'Host', text: 'Class at 6 PM daily—bring water!'),
      ],
      '#chat': [
        _Message(sender: 'Maya', text: 'Anyone joining today?'),
        _Message(sender: 'Rahul', text: 'I’ll be there!'),
        _Message(sender: 'You', text: 'See you all soon.', mine: true),
      ],
      '#resources': [
        _Message(sender: 'Host', text: 'Gentle flow sequence (PDF)'),
        _Message(sender: 'Alex', text: 'Breathing timer link'),
      ],
      '#general': [
        _Message(sender: 'Host', text: 'Welcome to Coloring Corner 🎨'),
      ],
      '#share-art': [
        _Message(sender: 'Zee', text: 'Posted a new mandala set!'),
      ],
      '#prompts': [
        _Message(sender: 'Host', text: 'Today: ocean blues + clouds'),
      ],
      '#now-playing': [
        _Message(sender: 'Bot', text: 'Playing: Soft Focus – Ambient Mix'),
      ],
    };

    final current = messages[channel] ??
        [_Message(sender: 'System', text: 'No messages yet—say hello!')];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Row(
          children: [
            _Avatar(
              initials: widget.serverName[0].toUpperCase(),
              color: widget.color,
            ),
            const SizedBox(width: 10),
            Text('${widget.serverName}  •  $channel',
                style: const TextStyle(color: ink)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Members',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
                builder: (_) => _MembersSheet(color: widget.color),
              );
            },
            icon: const Icon(Icons.group_rounded, color: ink),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              ListTile(
                leading: _Avatar(
                  initials: widget.serverName[0].toUpperCase(),
                  color: widget.color,
                ),
                title: Text(widget.serverName,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Activity Server'),
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Channels',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.channels.length,
                  itemBuilder: (_, i) => ListTile(
                    leading: const Icon(Icons.tag_rounded),
                    title: Text(widget.channels[i]),
                    selected: _channelIndex == i,
                    onTap: () {
                      setState(() => _channelIndex = i);
                      Navigator.of(context).maybePop();
                    },
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.link_rounded),
                title: const Text('Invite via link'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.settings_rounded),
                title: const Text('Server settings'),
                onTap: () {},
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Message list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              itemCount: current.length,
              itemBuilder: (_, i) => _MessageBubble(
                msg: current[i],
                color: widget.color,
              ),
            ),
          ),
          // Typing bar
          const _TypingBar(),
        ],
      ),
    );
  }
}

/* ------------------------------ Widgets ------------------------------ */

class _SearchBar extends StatelessWidget {
  final String hint;
  const _SearchBar({required this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search_rounded),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.20)),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  final Color color;

  const _Avatar({required this.initials, required this.color});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: color.withValues(alpha: 0.18),
      child: Text(
        initials,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: color.withValues(alpha: 0.95),
        ),
      ),
    );
  }
}

class _Message {
  final String sender;
  final String text;
  final bool mine;

  _Message({required this.sender, required this.text, this.mine = false});
}

class _MessageBubble extends StatelessWidget {
  final _Message msg;
  final Color color;

  const _MessageBubble({required this.msg, required this.color});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(msg.mine ? 16 : 4),
      bottomRight: Radius.circular(msg.mine ? 4 : 16),
    );

    final bg = msg.mine ? color.withValues(alpha: 0.15) : Colors.white;
    final border = Border.all(
      color: (msg.mine ? color : Colors.black).withValues(alpha: 0.15),
    );

    return Align(
      alignment: msg.mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
            border: border,
          ),
          child: Column(
            crossAxisAlignment:
                msg.mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                msg.sender,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: Colors.black.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 2),
              Text(msg.text, style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border_rounded,
                      size: 16, color: Colors.black.withValues(alpha: 0.45)),
                  const SizedBox(width: 8),
                  Icon(Icons.emoji_emotions_outlined,
                      size: 16, color: Colors.black.withValues(alpha: 0.45)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingBar extends StatelessWidget {
  const _TypingBar();

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF2F2E2C);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.black.withValues(alpha: 0.07)),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Attach',
              onPressed: () {},
              icon: const Icon(Icons.attach_file_rounded, color: ink),
            ),
            Expanded(
              child: TextField(
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Message',
                  filled: true,
                  fillColor: const Color(0xFFF8F8F8),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide:
                        BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide:
                        BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide:
                        BorderSide(color: Colors.black.withValues(alpha: 0.20)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Emoji',
              onPressed: () {},
              icon: const Icon(Icons.emoji_emotions_rounded, color: ink),
            ),
            const SizedBox(width: 2),
            FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF2B8A0),
                foregroundColor: ink,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Icon(Icons.send_rounded, size: 18),
            )
          ],
        ),
      ),
    );
  }
}

class _MembersSheet extends StatelessWidget {
  final Color color;
  const _MembersSheet({required this.color});

  @override
  Widget build(BuildContext context) {
    final members = [
      ('Host', Icons.verified_rounded),
      ('Aanya', Icons.person_rounded),
      ('Rahul', Icons.person_rounded),
      ('Maya', Icons.person_rounded),
      ('You', Icons.person_rounded),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: SizedBox(
                width: 36,
                child: Divider(thickness: 3),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Members',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: members.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.18),
                    child: Icon(members[i].$2, color: color),
                  ),
                  title: Text(members[i].$1),
                  trailing: Icon(Icons.circle,
                      size: 12, color: i == 0 ? Colors.green : Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateSheet extends StatelessWidget {
  const _CreateSheet();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 36, child: Divider(thickness: 3)),
            const SizedBox(height: 10),
            const Text(
              'Create or Join',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: cs.primary.withValues(alpha: 0.12),
                child: const Icon(Icons.groups_rounded),
              ),
              title: const Text('Create a server'),
              subtitle: const Text('For yoga, coloring, study groups, etc.'),
              onTap: () {},
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: cs.tertiary.withValues(alpha: 0.12),
                child: const Icon(Icons.link_rounded),
              ),
              title: const Text('Join with invite link'),
              subtitle: const Text('Paste a code or URL'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => const _JoinDialog(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinDialog extends StatelessWidget {
  const _JoinDialog();

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController();
    return AlertDialog(
      title: const Text('Join a Server'),
      content: TextField(
        controller: ctrl,
        decoration: const InputDecoration(
          labelText: 'Invite link or code',
          hintText: 'e.g. aurora.gg/abc123',
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(context), child: const Text('Join')),
      ],
    );
  }
}
