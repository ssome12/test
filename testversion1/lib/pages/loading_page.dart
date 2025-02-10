import 'package:flutter/material.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({Key? key}) : super(key: key);

  @override
  _LoadingPageState createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // 3초 동안 천천히 커졌다 작아졌다 하는 펄스 애니메이션 (auto reverse)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // 변화 범위를 미세하게 0.9 ~ 1.08로 조정
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.08).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 중앙 원의 크기를 화면 너비의 70%로 지정
    final double logoSize = MediaQuery.of(context).size.width * 0.7;

    return Scaffold(
      backgroundColor: Colors.black, // 전체 배경색을 블랙으로 지정
      body: Stack(
        children: [
          // 배경에 채팅 버블 애니메이션 추가
          const ChatBubbleAnimation(),
          // 중앙에 주요 컨텐츠 배치
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 로고에 천천히 펄스 애니메이션 적용 (크기가 미세하게 커졌다 작아졌다)
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: logoSize, // 예: 화면 너비의 70%
                    height: logoSize,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/some2.png', // 실제 이미지 파일 경로
                        fit: BoxFit.cover, // 전체 이미지가 보이도록 함
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // 텍스트: 흰색, 가운데 정렬
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "AI Dating Advisor",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // 챗하기 버튼에도 같은 펄스 애니메이션 효과 적용
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: ElevatedButton(
                    onPressed: () {
                      print("✅ 챗하기 버튼 클릭됨");
                      Navigator.pushNamed(context, '/logs'); // ChatPage로 이동
                    },
                    child: const Text(
                      "시작하기",
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      backgroundColor: Colors.blueAccent, // 버튼 배경색
                      foregroundColor: Colors.white, // 버튼 텍스트 색
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 배경에서 여러 개의 채팅 버블이 떠오르는 애니메이션 위젯
class ChatBubbleAnimation extends StatelessWidget {
  const ChatBubbleAnimation({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: const [
          // 추가된 5개의 채팅 버블
          FloatingBubble(
            startX: 0.1,
            startY: 0.95,
            endY: 0.05,
            size: 45,
            duration: Duration(seconds: 6),
            icon: Icons.chat_bubble_outline,
          ),
          FloatingBubble(
            startX: 0.2,
            startY: 0.9,
            endY: 0.1,
            size: 50,
            duration: Duration(seconds: 5),
            icon: Icons.chat_bubble,
          ),
          FloatingBubble(
            startX: 0.5,
            startY: 1.0,
            endY: 0.0,
            size: 60,
            duration: Duration(seconds: 7),
            icon: Icons.message,
          ),
          FloatingBubble(
            startX: 0.7,
            startY: 0.95,
            endY: 0.1,
            size: 40,
            duration: Duration(seconds: 4),
            icon: Icons.forum,
          ),
          FloatingBubble(
            startX: 0.85,
            startY: 0.9,
            endY: 0.2,
            size: 55,
            duration: Duration(seconds: 5),
            icon: Icons.chat,
          ),
        ],
      ),
    );
  }
}

/// 개별 채팅 버블 애니메이션 위젯
class FloatingBubble extends StatefulWidget {
  /// startX: 화면 너비에 대한 상대값 (0.0 ~ 1.0)
  /// startY, endY: 화면 높이에 대한 상대값 (0.0 ~ 1.0)
  final double startX;
  final double startY;
  final double endY;
  final double size;
  final Duration duration;
  final IconData icon;

  const FloatingBubble({
    Key? key,
    required this.startX,
    required this.startY,
    required this.endY,
    required this.size,
    required this.duration,
    required this.icon,
  }) : super(key: key);

  @override
  _FloatingBubbleState createState() => _FloatingBubbleState();
}

class _FloatingBubbleState extends State<FloatingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _verticalAnimation;

  @override
  void initState() {
    super.initState();
    // 버블이 위로 떠오르는 애니메이션 컨트롤러
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
    _verticalAnimation = Tween<double>(
      begin: widget.startY,
      end: widget.endY,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: widget.startX * screenWidth,
          top: _verticalAnimation.value * screenHeight,
          child: Opacity(
            // 버블이 위로 이동할수록 서서히 사라지게 함
            opacity: 1.0 - _controller.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withOpacity(0.3),
              ),
              child: Icon(
                widget.icon,
                color: Colors.white70,
                size: widget.size * 0.6,
              ),
            ),
          ),
        );
      },
    );
  }
}
