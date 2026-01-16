import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'analytics_service.dart';
import 'error_service.dart';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  static SecurityService get instance => _instance;
  SecurityService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Security configuration
  static const int maxLoginAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);
  static const int sessionTimeoutMinutes = 30;
  static const int passwordMinLength = 8;
  
  // Rate limiting and brute force protection
  final Map<String, List<DateTime>> _loginAttempts = {};
  final Map<String, DateTime> _lockedAccounts = {};
  final Map<String, DateTime> _sessionTimestamps = {};
  
  // Content filtering
  final List<String> _bannedWords = [
    // Add your content filtering words here
    'spam', 'abuse', 'harassment'
  ];
  
  // Security audit log
  final List<SecurityEvent> _auditLog = [];

  void initialize() {
    _startSecurityMonitoring();
    _loadSecurityConfiguration();
  }

  // Authentication security
  bool canAttemptLogin(String identifier) {
    // Check if account is locked
    final lockTime = _lockedAccounts[identifier];
    if (lockTime != null) {
      if (DateTime.now().difference(lockTime) < lockoutDuration) {
        _logSecurityEvent(SecurityEventType.accountLocked, {
          'identifier': _hashIdentifier(identifier),
          'reason': 'account_locked',
        });
        return false;
      } else {
        // Unlock account
        _lockedAccounts.remove(identifier);
        _loginAttempts.remove(identifier);
      }
    }
    
    return true;
  }

  void recordLoginAttempt(String identifier, bool success) {
    final now = DateTime.now();
    
    if (success) {
      // Clear failed attempts on successful login
      _loginAttempts.remove(identifier);
      _lockedAccounts.remove(identifier);
      _sessionTimestamps[identifier] = now;
      
      _logSecurityEvent(SecurityEventType.successfulLogin, {
        'identifier': _hashIdentifier(identifier),
      });
    } else {
      // Record failed attempt
      _loginAttempts[identifier] ??= [];
      _loginAttempts[identifier]!.add(now);
      
      // Remove attempts older than 1 hour
      _loginAttempts[identifier]!.removeWhere(
        (time) => now.difference(time).inHours >= 1,
      );
      
      // Check if account should be locked
      if (_loginAttempts[identifier]!.length >= maxLoginAttempts) {
        _lockedAccounts[identifier] = now;
        
        _logSecurityEvent(SecurityEventType.accountLocked, {
          'identifier': _hashIdentifier(identifier),
          'attempts': _loginAttempts[identifier]!.length,
        });
        
        // Report suspicious activity
        AnalyticsService.instance.logCustomEvent('security_account_locked', {
          'identifier_hash': _hashIdentifier(identifier),
          'attempts': _loginAttempts[identifier]!.length,
        });
      } else {
        _logSecurityEvent(SecurityEventType.failedLogin, {
          'identifier': _hashIdentifier(identifier),
          'attempts': _loginAttempts[identifier]!.length,
        });
      }
    }
  }

  // Session management
  bool isSessionValid(String userId) {
    final sessionTime = _sessionTimestamps[userId];
    if (sessionTime == null) return false;
    
    final now = DateTime.now();
    if (now.difference(sessionTime).inMinutes > sessionTimeoutMinutes) {
      _sessionTimestamps.remove(userId);
      
      _logSecurityEvent(SecurityEventType.sessionExpired, {
        'user_id': _hashIdentifier(userId),
      });
      
      return false;
    }
    
    // Update session timestamp
    _sessionTimestamps[userId] = now;
    return true;
  }

  void invalidateSession(String userId) {
    _sessionTimestamps.remove(userId);
    
    _logSecurityEvent(SecurityEventType.sessionInvalidated, {
      'user_id': _hashIdentifier(userId),
    });
  }

  // Password security
  bool isPasswordSecure(String password) {
    if (password.length < passwordMinLength) return false;
    
    // Check for at least one uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(password)) return false;
    
    // Check for at least one lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(password)) return false;
    
    // Check for at least one digit
    if (!RegExp(r'\d').hasMatch(password)) return false;
    
    // Check for at least one special character
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) return false;
    
    // Check against common passwords
    if (_isCommonPassword(password)) return false;
    
    return true;
  }

  String generateSecurePassword({int length = 12}) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()';
    final random = Random.secure();
    
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  String hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64.encode(bytes);
  }

  // Content security
  bool isContentSafe(String content) {
    final lowerContent = content.toLowerCase();
    
    // Check for banned words
    for (final word in _bannedWords) {
      if (lowerContent.contains(word.toLowerCase())) {
        _logSecurityEvent(SecurityEventType.unsafeContent, {
          'content_hash': _hashContent(content),
          'matched_word': word,
        });
        return false;
      }
    }
    
    // Check for suspicious patterns
    if (_containsSuspiciousPatterns(content)) {
      _logSecurityEvent(SecurityEventType.suspiciousContent, {
        'content_hash': _hashContent(content),
      });
      return false;
    }
    
    return true;
  }

  String sanitizeContent(String content) {
    // Remove potentially harmful HTML tags
    content = content.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Remove script tags and javascript
    content = content.replaceAll(RegExp(r'javascript:', caseSensitive: false), '');
    content = content.replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), '');
    
    // Remove potentially harmful URLs
    content = content.replaceAll(RegExp(r'(http|https|ftp)://[^\s]+'), '[URL REMOVED]');
    
    // Limit length
    if (content.length > 10000) {
      content = '${content.substring(0, 10000)}...';
    }
    
    return content.trim();
  }

  // File security
  bool isFileTypeSafe(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    
    const safeExtensions = [
      'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp',
      'pdf', 'doc', 'docx', 'txt', 'rtf',
      'mp4', 'mov', 'avi', 'mkv', 'webm',
      'mp3', 'wav', 'aac', 'm4a',
      'zip', 'rar', '7z',
    ];
    
    const dangerousExtensions = [
      'exe', 'bat', 'cmd', 'com', 'pif', 'scr', 'vbs', 'js',
      'jar', 'app', 'deb', 'pkg', 'dmg', 'iso',
    ];
    
    if (dangerousExtensions.contains(extension)) {
      _logSecurityEvent(SecurityEventType.dangerousFile, {
        'file_name': fileName,
        'extension': extension,
      });
      return false;
    }
    
    return safeExtensions.contains(extension);
  }

  bool isFileSizeAcceptable(int sizeInBytes) {
    const maxFileSize = 50 * 1024 * 1024; // 50MB
    
    if (sizeInBytes > maxFileSize) {
      _logSecurityEvent(SecurityEventType.oversizedFile, {
        'size': sizeInBytes,
        'max_size': maxFileSize,
      });
      return false;
    }
    
    return true;
  }

  // Data validation and sanitization
  Map<String, dynamic> sanitizeUserInput(Map<String, dynamic> input) {
    final sanitized = <String, dynamic>{};
    
    for (final entry in input.entries) {
      if (entry.value is String) {
        sanitized[entry.key] = sanitizeContent(entry.value);
      } else if (entry.value is List) {
        sanitized[entry.key] = (entry.value as List).map((item) {
          if (item is String) {
            return sanitizeContent(item);
          }
          return item;
        }).toList();
      } else {
        sanitized[entry.key] = entry.value;
      }
    }
    
    return sanitized;
  }

  // Permission validation
  Future<bool> hasPermission(String userId, String resource, String action) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;
      
      final userData = userDoc.data()!;
      final permissions = userData['permissions'] as Map<String, dynamic>? ?? {};
      
      // Check specific permission
      final resourcePermissions = permissions[resource] as List<dynamic>? ?? [];
      if (resourcePermissions.contains(action)) return true;
      
      // Check admin permission
      if (permissions['admin'] == true) return true;
      
      return false;
    } catch (e) {
      ErrorService.instance.reportError(
        AppError(
          type: ErrorType.permission,
          message: 'Permission check failed',
          context: 'userId: $userId, resource: $resource, action: $action',
        ),
      );
      return false;
    }
  }

  // Encryption utilities
  String encryptSensitiveData(String data, String key) {
    // In a real implementation, use proper encryption like AES
    // This is a simplified example
    final bytes = utf8.encode(data + key);
    final digest = sha256.convert(bytes);
    return base64.encode(digest.bytes);
  }

  // Security monitoring
  void _startSecurityMonitoring() {
    // Monitor for suspicious activities
    Timer.periodic(const Duration(minutes: 5), (timer) {
      _analyzeSecurityEvents();
      _cleanupOldEvents();
    });
  }

  void _analyzeSecurityEvents() {
    final recentEvents = _auditLog.where(
      (event) => DateTime.now().difference(event.timestamp).inMinutes < 60,
    ).toList();
    
    // Check for suspicious patterns
    final failedLogins = recentEvents.where(
      (event) => event.type == SecurityEventType.failedLogin,
    ).length;
    
    if (failedLogins > 20) {
      AnalyticsService.instance.logCustomEvent('security_alert', {
        'type': 'high_failed_login_rate',
        'count': failedLogins,
      });
    }
    
    // Check for content violations
    final contentViolations = recentEvents.where(
      (event) => event.type == SecurityEventType.unsafeContent,
    ).length;
    
    if (contentViolations > 10) {
      AnalyticsService.instance.logCustomEvent('security_alert', {
        'type': 'high_content_violation_rate',
        'count': contentViolations,
      });
    }
  }

  void _cleanupOldEvents() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    _auditLog.removeWhere((event) => event.timestamp.isBefore(cutoff));
  }

  void _logSecurityEvent(SecurityEventType type, Map<String, dynamic> data) {
    final event = SecurityEvent(
      type: type,
      timestamp: DateTime.now(),
      data: data,
    );
    
    _auditLog.add(event);
    
    // Log to analytics for monitoring
    AnalyticsService.instance.logCustomEvent('security_event', {
      'type': type.toString(),
      'timestamp': event.timestamp.millisecondsSinceEpoch,
      ...data,
    });
  }

  // Helper methods
  String _hashIdentifier(String identifier) {
    final bytes = utf8.encode(identifier);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 8); // First 8 characters for privacy
  }

  String _hashContent(String content) {
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  bool _isCommonPassword(String password) {
    const commonPasswords = [
      'password', '123456', '123456789', 'qwerty', 'abc123',
      'password123', 'admin', 'letmein', 'welcome', 'monkey',
    ];
    
    return commonPasswords.contains(password.toLowerCase());
  }

  bool _containsSuspiciousPatterns(String content) {
    // Check for potential SQL injection
    if (RegExp(r'(union|select|insert|update|delete|drop|create|alter)\s', 
        caseSensitive: false).hasMatch(content)) {
      return true;
    }
    
    // Check for potential XSS
    if (RegExp(r'<script|javascript:|on\w+\s*=', caseSensitive: false).hasMatch(content)) {
      return true;
    }
    
    // Check for excessive special characters (potential obfuscation)
    final specialCharCount = RegExp(r'[!@#$%^&*()_+\-=\[\]{};:"\\|,.<>\/?]').allMatches(content).length;
    if (specialCharCount > content.length * 0.3) {
      return true;
    }
    
    return false;
  }

  void _loadSecurityConfiguration() {
    // Load security configuration from remote config or local settings
    // This would typically load from Firebase Remote Config
  }

  // Public API for security checks
  SecurityCheckResult performSecurityCheck(String userId, String action, Map<String, dynamic> data) {
    final violations = <String>[];
    
    // Check session validity
    if (!isSessionValid(userId)) {
      violations.add('Invalid or expired session');
    }
    
    // Check content safety
    for (final entry in data.entries) {
      if (entry.value is String && !isContentSafe(entry.value)) {
        violations.add('Unsafe content detected in ${entry.key}');
      }
    }
    
    // Check rate limiting
    if (isRateLimited(action, userId)) {
      violations.add('Rate limit exceeded for $action');
    }
    
    return SecurityCheckResult(
      isValid: violations.isEmpty,
      violations: violations,
    );
  }

  bool isRateLimited(String action, String userId) {
    // Implementation would check rate limits per action type
    return false; // Simplified for example
  }

  List<SecurityEvent> getAuditLog({int? limit}) {
    final events = List<SecurityEvent>.from(_auditLog);
    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    if (limit != null && limit < events.length) {
      return events.take(limit).toList();
    }
    
    return events;
  }

  void dispose() {
    _auditLog.clear();
    _loginAttempts.clear();
    _lockedAccounts.clear();
    _sessionTimestamps.clear();
  }
}

// Security models
class SecurityEvent {
  final SecurityEventType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  
  SecurityEvent({
    required this.type,
    required this.timestamp,
    required this.data,
  });
}

enum SecurityEventType {
  successfulLogin,
  failedLogin,
  accountLocked,
  sessionExpired,
  sessionInvalidated,
  unsafeContent,
  suspiciousContent,
  dangerousFile,
  oversizedFile,
  permissionDenied,
  rateLimitExceeded,
}

class SecurityCheckResult {
  final bool isValid;
  final List<String> violations;
  
  SecurityCheckResult({
    required this.isValid,
    required this.violations,
  });
}