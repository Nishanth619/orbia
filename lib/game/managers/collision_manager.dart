import '../components/obstacle.dart';
import '../components/player.dart';

abstract final class CollisionManager {
  /// Returns true if player and obstacle circles overlap.
  /// Uses squared distance — no sqrt.
  static bool checkPlayerObstacle(Player player, Obstacle obstacle) {
    final double dx = player.worldX - obstacle.worldX;
    final double dy = player.worldY - obstacle.worldY;
    final double distSq   = dx * dx + dy * dy;
    final double radiiSum = player.collisionRadius + obstacle.collisionRadius;
    return distSq < radiiSum * radiiSum;
  }
}
